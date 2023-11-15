default: join
	docker build .

join: 
	cat sources/disk/hda.qcow2-part* > sources/hda.qcow2

split:
	rm -f sources/disk/*
	split -b 10M sources/hda.qcow2 sources/disk/hda.qcow2-part

launch-tianon-it: join
	touch ./sources/hda-compressed.qcow2
	echo -e "Useful tip for shrinking the hda image:\ncd /tmp\nqemu-img convert -O qcow2 -p -c hda.qcow2 hda-compressed.qcow2\n"
	docker run -it --rm \
		--name qemu-container-tianon \
		-p 5900:5900 \
		-p 23:23 \
		-v ./sources/hda.qcow2:/tmp/hda.qcow2 \
		-v ./sources/hda-compressed.qcow2:/tmp/hda-compressed.qcow2 \
		-e QEMU_HDA=/tmp/hda.qcow2 \
		-e QEMU_HDA_SIZE=8G \
		-e QEMU_CPU=4 \
		-e QEMU_RAM=3000 \
		-v ./sources/ubuntu.iso:/tmp/ubuntu.iso:ro \
		-v ./sources/ext/entrypoint:/ext/entrypoint \
		-e QEMU_BOOT='order=c,menu=on' \
		-e QEMU_PORTS='2375 2376' \
		--entrypoint "" \
		tianon/qemu \
		/bin/bash

launch-tianon: join launch-simply

launch-simply: 
	touch ./sources/hda.qcow2
	docker run -it --rm \
		--name qemu-container-tianon \
		-p 5900:5900 \
		-p 23:23 \
		-v ./sources/hda.qcow2:/tmp/hda.qcow2 \
		-e QEMU_HDA=/tmp/hda.qcow2 \
		-e QEMU_HDA_SIZE=8G \
		-e QEMU_CPU=4 \
		-e QEMU_RAM=3000 \
		-v ./install.sh:/ext/entrypoint:ro \
		-e QEMU_BOOT='order=c,menu=on' \
		-e QEMU_PORTS='2375 2376' \
		tianon/qemu  start-qemu -virtfs local,path=/ext,mount_tag=host0,security_model=passthrough,id=host0 -serial telnet:127.0.0.1:23,server,nowait

launch-test-compressed: 
	touch ./sources/hda.qcow2
	docker run -it --rm \
		--name qemu-container-tianon \
		-p 5900:5900 \
		-p 23:23 \
		-v ./sources/hda-compressed.qcow2:/tmp/hda.qcow2 \
		-e QEMU_HDA=/tmp/hda.qcow2 \
		-e QEMU_HDA_SIZE=8G \
		-e QEMU_CPU=4 \
		-e QEMU_RAM=3000 \
		-v ./install.sh:/ext/entrypoint:ro \
		-e QEMU_BOOT='order=c,menu=on' \
		-e QEMU_PORTS='2375 2376' \
		tianon/qemu  start-qemu -virtfs local,path=/ext,mount_tag=host0,security_model=passthrough,id=host0 -serial telnet:127.0.0.1:23,server,nowait

demo:
	docker run -it -v ./demo-entrypoint:/ext/entrypoint:ro herokukms/github-runner-docker:1.0.0

build: join
	docker build -t herokukms/github-runner-docker:1.0.0 .

test: build
	docker run -it -v ./demo-entrypoint:/ext/entrypoint:ro herokukms/github-runner-docker:1.0.0 /bin/bash

run: build _run
_run: 
	docker run -it \
		-p 5900:5900 \
		-p 23:23 \
		-p 8080:80 \
		-v ./demo-entrypoint:/ext/entrypoint:ro herokukms/github-runner-docker:1.0.0 \
		start-qemu -virtfs local,path=/ext,mount_tag=host0,security_model=passthrough,id=host0 -serial telnet:127.0.0.1:23,server,nowait