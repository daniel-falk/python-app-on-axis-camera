DEPLOY_TO ?= nfs  # nfs or sd-card

CAM_IP ?= axiscam
CAM_USER ?= root

IMAGE_NAME ?= cam-builder:latest
PYTHON_NAME ?= python

APP_NAME ?= app
APP_DEPLOY_DIR ?= /tmp

ifeq ($(strip ${DEPLOY_TO}),nfs)
# When using NFS we copy direct to the network share
PYTHON_DEPLOY_DIR ?= /samba/tmp/app# Relative to mount point
HOST_MOUNT ?= /mnt/storage
CAM_MOUNT = /var/spool/storage/NetworkShare/
HOST_INSTALL_DIR = ${HOST_MOUNT}/${PYTHON_DEPLOY_DIR}
CAM_INSTALL_DIR=${CAM_MOUNT}/${PYTHON_DEPLOY_DIR}
INSTALL_CMD=tar -C ${HOST_INSTALL_DIR} -xzvf -
else ifeq ($(strip ${DEPLOY_TO}),sd_card)
# When using SD-card we copy the data over ssh
CAM_MOUNT = /var/spool/storage/SD_DISK
CAM_INSTALL_DIR=${CAM_MOUNT}/
INSTALL_CMD=ssh ${CAM_USER}@${CAM_IP} tar -C ${CAM_INSTALL_DIR} -xzvf -
else
$(error Unknwon DEPLOY_TO="${DEPLOY_TO}", should be "nfs" or "sd_card")
endif


DOCKER_RUN = docker run --rm ${IMAGE_NAME}
DOCKER_RUN_MOUNT = docker run --rm -v `pwd`:/opt/app/ ${IMAGE_NAME}

CAM_RUN = ssh -t ${CAM_USER}@${CAM_IP}
CAM_PYTHON = LD_LIBRARY_PATH=${CAM_INSTALL_DIR}/generated/libs \
	     PYTHONHOME=${CAM_INSTALL_DIR}/generated/usr \
	     ${CAM_INSTALL_DIR}/generated/${PYTHON_NAME}

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
	${DOCKER_RUN} tar -czf - /generated | ${INSTALL_CMD}

.PHONY: run-interpreter
run-interpreter:
	${CAM_RUN} ${CAM_PYTHON}

.PHONY: run-app
run-app:
	${CAM_RUN} "cd ${APP_DEPLOY_DIR}/${APP_NAME} && ${CAM_PYTHON} ${APP_NAME}.py"

.PHONY: mount-exec
mount-exec:
	ssh ${CAM_USER}@${CAM_IP} mount -o remount,exec ${CAM_MOUNT}
