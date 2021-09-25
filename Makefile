CAM_IP ?= axiscam
CAM_USER ?= root

IMAGE_NAME ?= cam-builder:latest
PYTHON_NAME ?= python

APP_NAME ?= app
APP_DEPLOY_DIR ?= /tmp

PYTHON_DEPLOY_DIR ?= /samba/tmp/app# Relative to mount point

HOST_MOUNT ?= /mnt/storage
CAM_MOUNT = /var/spool/storage/NetworkShare/
HOST_INSTALL=${HOST_MOUNT}/${PYTHON_DEPLOY_DIR}
CAM_INSTALL=${CAM_MOUNT}/${PYTHON_DEPLOY_DIR}

DOCKER_RUN = docker run --rm ${IMAGE_NAME}
DOCKER_RUN_MOUNT = docker run --rm -v `pwd`:/opt/app/ ${IMAGE_NAME}

CAM_RUN = ssh -t ${CAM_USER}@${CAM_IP}
CAM_PYTHON = PYTHONHOME=${CAM_INSTALL}/generated/usr ${CAM_INSTALL}/generated/${PYTHON_NAME}

.PHONY: build-docker
build-docker:
	docker build -t ${IMAGE_NAME} .

.PHONY: build-app
build-app:
	${DOCKER_RUN_MOUNT} bash -c "cd ${APP_NAME} && ../build_ext.sh"

.PHONY: clean-app
clean-app:
	rm ${APP_NAME}/*.so -rf ${APP_NAME}/build

.PHONY: deploy-app
deploy-app:
	scp -r ./${APP_NAME} ${CAM_USER}@${CAM_IP}:${APP_DEPLOY_DIR}

.PHONY: deploy-python
deploy-python:
	${DOCKER_RUN} tar -czf - /generated | tar -C ${HOST_INSTALL} -xzvf -

.PHONY: run-interpreter
run-interpreter:
	${CAM_RUN} ${CAM_PYTHON}

.PHONY: run-app
run-app:
	${CAM_RUN} "cd ${APP_DEPLOY_DIR}/${APP_NAME} && ${CAM_PYTHON} ${APP_NAME}.py"
