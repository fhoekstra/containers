#!/usr/bin/env sh
# Fork of melody's entrypoint (git.shork.ch/oci-images/out-of-your-element),
# patched to support read-only root filesystems.
#
# Out Of Your Element resolves ooye.db, registration.yaml and custom-webroot
# relative to the process working directory (see start.js and
# src/matrix/read-registration.js), while reading all app assets relative to
# __dirname. Instead of symlinking datadir files into /usr/src/app (which
# requires a writable rootfs), we simply run the app FROM the datadir.
#
# Also provides a maintenance mode for running scripts/*.js against the
# datadir. This replaces `npm run <script>`, which cannot be used here because
# npm always changes the working directory to the package root (/usr/src/app).

set -e

DATADIR="${OOYE_DATADIR:-/usr/src/app}"

if [ "$DATADIR" = "/usr/src/app" ]; then
  echo "OOYE_DATADIR is not set; running from /usr/src/app."
  echo "This is deprecated and might be removed in the future."
  echo "Please set it to a writable directory and bind-mount it to persist your data."
fi

if [ ! -d "$DATADIR" ]; then
  echo "Error: OOYE_DATADIR '$DATADIR' does not exist or is not a directory." >&2
  exit 1
fi
if [ ! -w "$DATADIR" ]; then
  echo "Error: $DATADIR is not writable by this container (uid $(id -u))." >&2
  echo "The datadir must be a writable volume: chown it to the image user" >&2
  echo "(uid 1000, 'node') or run the container with a matching user." >&2
  exit 1
fi

cd "$DATADIR"
touch ooye.db

# Maintenance mode: /entrypoint.sh <script> [args...]
# e.g. /entrypoint.sh setup, /entrypoint.sh reset-web-password, /entrypoint.sh wal
# Unknown or invalid script names exit 1 with a list of available scripts.
if [ "$#" -gt 0 ]; then
  script="$1"
  shift
  case "$script" in
  */*)
    echo "Error: invalid script name '$script'." >&2
    exit 1
    ;;
  esac
  if [ ! -f "/usr/src/app/scripts/$script.js" ]; then
    echo "Error: no such script '$script'." >&2
    echo "Available scripts:" >&2
    for f in /usr/src/app/scripts/*.js; do
      [ -e "$f" ] || continue
      echo "  /entrypoint.sh $(basename "$f" .js)" >&2
    done
    exit 1
  fi
  exec node --enable-source-maps "/usr/src/app/scripts/$script.js" "$@"
fi

# First boot gate: setup has not run yet (empty database or no registration).
# Like upstream's entrypoint, stay alive for a while so the container remains
# exec-able, then start automatically if setup completed in the meantime.
if [ ! -s ooye.db ] || [ ! -s registration.yaml ]; then
  if [ ! -s registration.yaml ]; then
    echo "No registration.yaml in $DATADIR yet."
  else
    echo "Database file $DATADIR/ooye.db is empty."
  fi
  echo "Run setup inside the running container:"
  echo "  kubectl exec -it <pod> -- /entrypoint.sh setup"
  echo "(or with plain docker: docker compose exec ooye /entrypoint.sh setup)"
  sleep 1800
fi

if [ ! -s ooye.db ] || [ ! -s registration.yaml ]; then
  echo "Database or registration.yaml is still not ready. Exiting."
  exit 1
fi

if [ "$OOYE_WAL" = "true" ]; then
  node /usr/src/app/scripts/wal.js
  echo "WAL mode enabled!"
else
  # journal_mode is persisted in the database header, so merely unsetting
  # OOYE_WAL does not undo a previously enabled WAL. Switch back to the
  # rollback journal explicitly, like upstream does; the switch also
  # checkpoints any leftover -wal content into the main database file.
  # require() needs an absolute path because cwd is the datadir, so the
  # heredoc cannot resolve better-sqlite3 on its own.
  node <<'EOF'
const sqlite = require("/usr/src/app/node_modules/better-sqlite3")
const db = new sqlite("ooye.db", {fileMustExist: true})
db.pragma("journal_mode = delete")
db.close()
EOF
  rm -f ooye.db-wal ooye.db-shm
  echo "WAL mode disabled!"
fi

exec node --enable-source-maps /usr/src/app/start.js
