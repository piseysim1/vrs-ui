cd ..
call flutter build web --release --base-href /vrms/
cd .docker

call C:\Docker\vbsxr\vbsxr-cmd.cmd

docker build .. --file ../.docker/Dockerfile -t %REGISTRY%/vrs-ui:dev
docker push %REGISTRY%/vrs-ui:dev
docker-compose -f ui.yml -p vrs up -d

Timeout 20