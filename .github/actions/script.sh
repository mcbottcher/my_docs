# script starts in the repo root, print directory for debug
echo $(pwd)

# build image
docker build -t my_image -f .github/actions/Dockerfile .

# run image: don't delete container
docker run -t my_image

# copy the build folder from container to host machine
docker cp $(docker ps -a -q):/home/my_docs/docs/build ./docs/

# remove the container
docker rm $(docker ps -a -q)

# remove the image
docker rmi $(docker images -q)