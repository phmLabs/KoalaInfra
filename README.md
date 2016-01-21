- [What you get](#what-you-get)
- [One-Time Prerequisites setup](#one-time-prerequisites-setup)
  - [Get VirtualBox with Guest additions](#get-virtualbox-with-guest-additions)
  - [Create the VM](#create-the-vm)
  - [Set environment variables](#set-environment-variables)
  - [Get the code](#get-the-code)
  - [Set up NFS](#set-up-nfs)
  - [Mount the NFS share into VM](#mount-the-nfs-share-into-vm)
  - [Setup the docker containers](#setup-the-docker-containers)
  - [Start or stop the docker containers](#start-or-stop-the-docker-containers)
  - [See the logs](#see-the-logs)
  - [Recreate the containers](#recreate-the-containers)
    - [Access commandline](#access-commandline)
  - [Install symfony dependencies](#install-symfony-dependencies)
- [Executing tests](#executing-tests)
- [FAQ](#faq)
  - [Restart docker](#restart-docker)
  - [Remove docker container](#remove-docker-container)
  - [Access commandline](#access-commandline)
  - [Machine is not reachable](#machine-is-not-reachable)

# What you get

- [http://koalamon.local](The App itself)

# One-Time Prerequisites setup

To enable coherent environments across all stages of development to production, we are using a Docker-managed server setup.
Follow the next bits of the ***one-time prerequisites setup*** carefully and you will be fine. It is assumed you are using
Mac OS with homebrew properly set up.

## Get VirtualBox with Guest additions

Brew is a good choice here.

```
brew install caskroom/cask/brew-cask
brew cask install dockertoolbox
```
## Create the VM


    docker-machine \
      create --driver virtualbox \
      --virtualbox-hostonly-cidr "192.168.59.1/24" \
      --virtualbox-memory 4096 \
      koalamon

## Set environment variables

```
docker-machine env koalamon
eval "$(docker-machine env koalamon)"
```

## Get the code

Clone this repository to some directory that suits your workflow best.
For example, in your `~/Site` or `~/code` directory:

```
mkdir koalamon && cd koalamon && git clone https://github.com/koalamon/Koalamon
```

## Set up NFS
run the following in your Koalamon's **parent directory**:
```
sudo touch /etc/exports
echo "# Boot2docker
\"`$(echo pwd)`\" -alldirs -mapall=$(whoami) -network 192.168.59.0 -mask 255.255.255.0" | sudo tee -a /etc/exports
sudo nfsd checkexports && sudo nfsd restart
```

## Mount the NFS share into VM

Then, in your `Koalamon` directory, type:

```
eval "$(docker-machine env koalamon)"
docker-machine ssh koalamon "grep -q '8.8.8.8' /etc/resolv.conf; [ $? -ne 0 ] && echo 'nameserver 8.8.8.8' >> /etc/resolv.conf;"
docker-machine ssh koalamon "echo '#\!/bin/sh' | sudo tee /var/lib/boot2docker/bootlocal.sh && sudo chmod 755 /var/lib/boot2docker/bootlocal.sh && echo 'sudo mkdir -p /var/www/koalamon && sudo mount -t nfs -o noatime,soft,nolock,vers=3,udp,proto=udp,rsize=8192,wsize=8192,namlen=255,timeo=10,retrans=3,nfsvers=3 -v 192.168.59.1:`$(echo pwd)`/.. /var/www/koalamon' | sudo tee -a /var/lib/boot2docker/bootlocal.sh"
docker-machine restart koalamon
```
***Important***: Write each command for itself. Might return 1. Then just repeat.


Then enter koalamon.local to your /etc/hosts file:

```
sudo echo "\n ${docker-machine ip koalamon} koalamon.local >> /etc/hosts
```

## Setup the docker containers

Run in your `KoalaInfra/Docker` directory:

```
eval "$(docker-machine env koalamon)" && docker-compose up
```

## Start or stop the docker containers

If you just have exited from the setup command and no rebuilt is needed you can just start the existing containers by
`eval "$(docker-machine env koalamon)" && docker-compose start`.

or if needed to stop use:
`eval "$(docker-machine env koalamon)" && docker-compose stop`

## See the logs

You can see the log files of the running containers by executing: `eval "$(docker-machine env koalamon)" && docker-compose logs`

## Recreate the containers

Just execute `docker-compose up`. Be aware of warnings. Maybe you have to remove existing containers. (FAQ)(#faq)

### Access commandline

Run `docker ps` to get a list of available containers. The can be accessed like for example `docker exec -it koalamonapi_php_1 bash` or `docker exec -it koalamonapi_db_1 bash`

## Install symfony dependencies

Attach to the php docker container with `docker exec -it koalamonapi_php_1` and then in the container execute `composer install` or `composer update`.

# Executing tests

Tests of can be executed by: `bin/phpunit -c app/`

# FAQ

## Restart docker

`docker-machine ssh koalamon sudo /etc/init.d/docker restart

## Remove docker container

`docker-compose rm <id>`
 Example:
 `docker-compose rm php`

You can also remove all: `docker-compose rm`.

## Access commandline

`docker exec -it <container_id> bash`

For example:

`docker exec -it app_koalamon_api_php bash`


## Machine is not reachable
Du to a bug in docker-machine in combination with VirtualBox in some cases the docker-machine command cannot execute commands on
the virtual box image.

```
sudo route -nv delete -net 192.168.59 -interface vboxnet0
sudo route -nv add -net 192.168.59 -interface vboxnet0
docker-machine regenerate-certs koalamon
docker-machine env koalamon
eval "${docker-machine env koalamon}"
```

vboxnet0 has to be replaced by your virtualhost network adapter which is used by the vm.

# Features

Settings in `docker-composer.yml` can be overwritten per-environment by using [multiple files](https://docs.docker.com/compose/extends/#different-environments).

You can link containers in `docker-compose.yml` [doc](https://docs.docker.com/compose/compose-file/#links). This will create a hostname alias and several environment variables inside that container, allowing it to access the linked container. For example linking a `mysql` container to the web container ensures access to the MySQL using the environment variable `$MYSQL_PORT`.

Possible available dependencies for `composer.json` [php-support](https://devcenter.heroku.com/articles/php-support).
