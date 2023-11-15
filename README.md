# github-runner-docker

Heavily (90%) based on [ubuntu-nested-qemu-docker](https://github.com/eltorio/ubuntu-nested-qemu-docker).  

## What differs ?

[Github action runner](https://github.com/actions/runner) is embedded in the container.  
Providing `/ext/entrypoint` can automate the start of the runner.  
The runner lives at /actions-runner .  
Launch the container interactively with `make _run` and log into the nested Ubuntu as root or runner without password, cd to /actions-runner and play !

## Automation

[myoung34](https://github.com/myoung34/docker-github-actions-runner/tree/master) entrypoint is embedded so you can use it like:

```sh
export REPO_URL='https://github.com/herokukms/github-runner-docker'
export ACCESS_TOKEN='ghp_DA2KUNAo01OI3vtF59P5ZdzGLmQ63u3XG7KS'
cd /actions-runner
/entrypoint.sh ./bin/Runner.Listener run --startuptype service
```

## Why this strange  idea ?

Because most of docker container can't run in a privileged environment and so cannot run Docker.  
This Docker image runs an Alpine linux in a QEMU virtual machine so the docker daemon runs like in a real machine.

## How to mod

For modding you need **/sources/ubuntu.iso**. It is the official Ubuntu 22.0.4 x64 live server iso. You can find it [at](https://ubuntu.com/download/alternative-downloads) or download it via the official .torrent.  
A copy of the torrent is here… But trusting is something difficulkt :).  

## How to

```sh
docker run -p 5900:5900 -p 8080:80 -p 2323:23 -it -v ./ext:/ext eltorio/ubuntu-nested-qemu-docker  
```

`./ext/entrypoint` is a mandatory shell script. It will be run after all services in the Ubuntu virtual machine.  
From inside the docker container you can log in the qemu guest via `telnet localhost` as runner or root without password.

## Connnect to

You can use vnc on port 5900 (:0) , web vnc on port 80 or telnet on port 23
<img width="1036" alt="Capture d’écran 2023-11-14 à 16 00 20" src="https://github.com/eltorio/ubuntu-nested-qemu-docker/assets/6966689/8fd2909a-4bcf-41dd-9045-f120138e39ab">

## Clean

Before packaging this clean was done:

```sh
apt-get clean autoclean
apt-get autoremove --yes
echo "" > ~/.bash_history
halt
````

## Connect to nested Ubuntu

While connected to the qemu container you can reach the nested Alpine vm with

```sh
telnet localhost
```

hit enter and connect as root
For leaving telnet hit CTRL+$ and quit

## Kubernetes sample deployement

This launch 10 replicas of action-runner on Kubernetes without special privilege

```yaml
---
apiVersion: v1
kind: Secret
metadata:
  name: heartbeat
  namespace: runner-sandbox
type: Opaque
stringData:
  now: "19792921"
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: entrypoint
  namespace: runner-sandbox
data:
  entrypoint: |
    #!/bin/sh
    while (! docker stats --no-stream ); do
      # Docker takes a few seconds to initialize
      echo "Waiting for Docker to launch..."
      sleep $((`od -vAn -N2 -tu2 < /dev/urandom` %15))
    done
    export ACCESS_TOKEN=ghp_DA2KUNAo01OI3vtF59P5ZdzGLmQ63u3XG7KS
    export ORG_NAME=Heroku
    export RUNNER_GROUP=k8s
    export RUNNER_SCOPE=org
    export RUNNER_NAME_PREFIX=heroku
    cd /actions-runner || exit
    /entrypoint.sh ./bin/Runner.Listener run --startuptype service
---
apiVersion: apps/v1
#kind: Deployment
kind: StatefulSet
metadata:
  name: herokukms-runner
  namespace: runner-sandbox
  labels:
    app: herokukms-runner
spec:
  replicas: 1
  #strategy:
  #  type: Recreate
  selector:
    matchLabels:
      app: herokukms-runner
  template:
    metadata:
      labels:
        app: herokukms-runner
    spec:
      containers:
      - name: herokukms-runner
        image: herokukms/github-runner-docker:1.0.0
        volumeMounts:
        - name: entrypoint
          mountPath: /ext
        env:
          - name: ACCESS_TOKEN
            value: ghp_DA2KUNAo01OI3vtF59P5ZdzGLmQ63u3XG7KS
          - name: ORG_NAME
            value: "Heroku"
          - name: RUNNER_GROUP
            value: "k8s"
          - name: RUNNER_SCOPE
            value: org
          - name: TIMESTAMP
            value: "19792921"
          - name: RANDOM_RUNNER_SUFFIX
            value: "hostname"
          - name: QEMU_CPU
            value: "1"
          - name: QEMU_RAM
            value: "2048"
          #- name: UPDATED                      
          #  value: "19792921" 
#        securityContext:
#          privileged: true
      volumes:
      - name: entrypoint
        configMap: 
          name: entrypoint
          defaultMode: 0777
```
