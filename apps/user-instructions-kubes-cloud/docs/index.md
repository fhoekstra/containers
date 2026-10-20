# First-time setup of your kubes.cloud account and sign in to Matrix

You just received an account on Freek's cluster.
In order to sign in to Matrix with this account, you'll need to do 2 things:

- First, sign in to the centralized account management (Authelia) to secure your kubes.cloud account: set up 2FA and change your password.
- Then, sign in to Matrix using the kubes.cloud account that you are already signed in to.

## Secure your account in Authelia

If at any point during the signup, you get the following picture, just refresh and it should go away:

<img src="img/anubis-error.png" alt="anubis-error" width="200"/>

- Go to [https://auth.kubes.cloud](https://auth.kubes.cloud)
- Sign in with the provided username / password and tick "remember me" if this is your own device

<img src="img/auth-kubes-cloud-login.png" alt="login" width="200"/>

### Add 2FA app

- Now add your authenticator app (Aegis, Bitwarden premium, Proton or Google Authenticator all work) by clicking "Add OTP"

<img src="img/set-2fa-1-add-otp.png" alt="set-2fa-1-add-otp" width="500"/>

- Authelia will then send an e-mail to you to confirm it's you, enter the code from the mail you receive from authelia@freekhoekstra.nl , check your spam folder

<img src="img/set-2fa-2-put-in-code-from-mail-check-spam.png" alt="set-2fa-2-mail-verification" width="400"/>

- afterward, follow the prompts to add your authenticator app

### Change password

- after that is done, go to [https://auth.kubes.cloud/settings/security](https://auth.kubes.cloud/settings/security) and change your password

<img src="img/auth-change-password.png" alt="Change password in authelia" width="400"/>

## Sign in to Matrix (sable)

In the following steps, you'll need to provide permission twice: first, allow the Continuwuity Matrix server to connect the Matrix account to your account in Authelia, then to Sable so you can sign in to the Matrix account with it.

```mermaid
---
title: Setup
---
graph TB
sable[Sable Matrix Client] -- signs in to --> c10y[Continuwuity Matrix server]
subgraph your-device[your device]
sable -- saves messages to --> local[local  storage]
end
subgraph freeks-machines[kubes.cloud AKA Freek's machines]
c10y -- checks it's you using --> auth[Authelia account registry where you are already signed in]
end
```

- Go to [https://sable.kubes.cloud](https://sable.kubes.cloud)
- Click "Sign in with kubes.cloud"

<img src="img/Sable-kubes-cloud-login.png" alt="Login screen at sable.kubes.cloud" width="600"/>

- Here comes the first "allow": this allows the Continuwuity Matrix server to connect your account at auth.kubes.cloud to your Matrix account

<img src="img/c10y-continue.png" alt="Continuwuity forwards you to auth.kubes.cloud" height="300"/>
->
<img src="img/oidc-allow.png" alt="Allow Continuwuity to connect your kubes.cloud account" height="300"/>

- You can then choose your Matrix account username. This will be your _global_ handle across all of Matrix, visible to people from other servers too if you use public rooms.

<img src="img/c10y-choose-username.png" alt="Choose your global Matrix username" height="600"/>

- the second "authorize" step allows the client (Sable) on your device to interact with the Continuwuity Matrix server while signed in to your Matrix account

<img src="img/c10y-authorize-sable.png" alt="Give the client on your device access to your Matrix account" height="400"/>

- Follow the instructions in Sable's onboarding

- After you are signed in to Sable, choose "start DM" and send a message to me: `@freek:kubes.cloud` and I will add you to the space with all the channels.

<img src="img/after-login-to-sable-send-message-to-freek.png" alt="Choose 'send DM' " width="600"/>

<img src="img/sable-message-to-freek.png" alt="Send a message to @freek:kubes.cloud" width="600"/>
