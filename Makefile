CAM_IP ?= axiscam
CAM_USER ?= root

IMAGE_NAME ?= cam-builder:latest
APP_NAME ?= python

INSTALL_DIR ?= /samba/tmp/app# Relative to mount point

HOST_MOUNT ?= /mnt/storage
CAM_MOUNT = /var/spool/storage/NetworkShare/
HOST_INSTALL=${HOST_MOUNT}/${INSTALL_DIR}
CAM_INSTALL=${CAM_MOUNT}/${INSTALL_DIR}


.PHONY: build-docker
build-docker:
	docker build -t ${IMAGE_NAME} .

.PHONY: deploy
deploy:
	docker run --rm ${IMAGE_NAME} tar -czf - /generated | tar -C ${HOST_INSTALL} -xzvf -

.PHONY: run
run:
	ssh -t ${CAM_USER}@${CAM_IP} PYTHONHOME=${CAM_INSTALL}/generated/usr ${CAM_INSTALL}/generated/${APP_NAME}
