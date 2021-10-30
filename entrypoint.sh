#!/bin/bash

SSH_USER=$1
SSH_HOST=$2
SSH_PORT=$3
PATH_SOURCE=$4
OWNER=$5

mkdir -p .ssh
ssh-keyscan -H "$SSH_HOST" >> .ssh/known_hosts

if [ -z "$DEPLOY_KEY" ];
then
	echo $'\n' "------ DEPLOY KEY NOT SET YET! ----------------" $'\n'
	exit 1
else
	printf '%b\n' "$DEPLOY_KEY" > .ssh/id_ed25519
	chmod 400 .ssh/id_ed25519

	echo $'\n' "------ CONFIG SUCCESSFUL! ---------------------" $'\n'
fi

if [ ! -z "$SSH_PORT" ];
then
        printf "Host %b\n\tPort %b\n" "$SSH_HOST" "$SSH_PORT" > .ssh/config
	ssh-keyscan -p $SSH_PORT -H "$SSH_HOST" >> .ssh/known_hosts
fi

rsync --progress -avzh \
	--exclude='.git/' \
	--exclude='.git*' \
	--exclude='.editorconfig' \
	--exclude='.styleci.yml' \
	--exclude='.idea/' \
	--exclude='Dockerfile' \
	--exclude='readme.md' \
	--exclude='README.md' \
	-e "ssh -i .ssh/id_ed25519" \
	--rsync-path="sudo rsync" . $SSH_USER@$SSH_HOST:$PATH_SOURCE

if [ $? -eq 0 ]
then
	echo $'\n' "------ SYNC SUCCESSFUL! -----------------------" $'\n'
	echo $'\n' "------ RELOADING PERMISSION -------------------" $'\n'

	ssh -i .ssh/id_ed25519 -t $SSH_USER@$SSH_HOST "sudo chown -R $OWNER:$OWNER $PATH_SOURCE"
	ssh -i .ssh/id_ed25519 -t $SSH_USER@$SSH_HOST "sudo chmod 775 -R $PATH_SOURCE"
	ssh -i .ssh/id_ed25519 -t $SSH_USER@$SSH_HOST "sudo chmod 777 -R $PATH_SOURCE/storage"
	ssh -i .ssh/id_ed25519 -t $SSH_USER@$SSH_HOST "sudo chmod 777 -R $PATH_SOURCE/public"

	echo $'\n' "------ CONGRATS! DEPLOY SUCCESSFUL!!! ---------" $'\n'
	exit 0
else
	echo $'\n' "------ DEPLOY FAILED! -------------------------" $'\n'
	exit 1
fi
