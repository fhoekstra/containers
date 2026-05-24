sudo docker buildx version
sudo docker buildx create --name multiarch --driver docker-container --use
sudo docker buildx inspect --bootstrap

echo $CR_PAT | sudo docker login ghcr.io -u fhoekstra --password-stdin
sudo docker buildx build . --file ./Containerfile --platform linux/amd64,linux/arm64 -t ghcr.io/fhoekstra/kubectl-shell:v1.36.1 --push
