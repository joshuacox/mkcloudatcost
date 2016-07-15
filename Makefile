all: help

help:
	-@echo "make fullList -- will initialize the fullList, which is a list of servers @ cloudatcost"
	-@echo "make generals -- will replace the 'Not Assigned null' in the workingList with generals"
	-@echo "make auto -- will initialize some servers from a workingList"
	-@echo "read the README.md for more"

auto: trustyauto

trustyauto: API_USERNAME API_KEY newList newnamer hostnamer normalizer trustynext

trustynext: API_USERNAME API_KEY workingList keyscan keyer trustymovein tester22 sshrebooter22
	-@echo "next try trustymovein for a trustyhost"

jessieauto: API_USERNAME API_KEY newList newnamer hostnamer normalizer workingList keyscan jessienext

jessienext: debkeyer installCurl jessiemovein tester22 sshrebooter22

centosauto: API_USERNAME API_KEY newList newnamer hostnamer normalizer centosnext

centosnext: API_USERNAME API_KEY workingList keyscan keyer centosmovein tester22 sshrebooter22
	-@echo "next try make kargo for a kubernetes cluster"

listtemplates:
	$(eval API_KEY := $(shell cat API_KEY))
	$(eval API_USERNAME := $(shell cat API_USERNAME))
	$(eval URL :=https://panel.cloudatcost.com/api/v1/listtemplates.php?key=$(API_KEY)&login=$(API_USERNAME))
	echo "curl -k -o listtemplates '$(URL)' "|bash
	cat listtemplates|jq .

listtasks:
	$(eval API_KEY := $(shell cat API_KEY))
	$(eval API_USERNAME := $(shell cat API_USERNAME))
	$(eval URL :=https://panel.cloudatcost.com/api/v1/listtasks.php?key=$(API_KEY)&login=$(API_USERNAME))
	echo "curl -k -o listtasks '$(URL)' "|bash

jessie: mkjessieclusty

trusty: mktrustyclusty

centos: mkcentosclusty

glusty: mkglustyclusty

lsjessies:
	jq . jessies

mkjessieclusty: API_USERNAME API_KEY 
	$(eval TMP := $(shell mktemp -d --suffix=DOCKERTMP))
	$(eval API_KEY := $(shell cat API_KEY))
	$(eval API_USERNAME := $(shell cat API_USERNAME))
	$(eval URL :=https://panel.cloudatcost.com/api/v1/cloudpro/build.php)
	$(eval DATA :=key=$(API_KEY)&login=$(API_USERNAME)&cpu=4&ram=2048&storage=40&os=3)
	echo "curl -k -v -o $(TMP)/mkjessieclusty --data '$(DATA)' '$(URL)'"|bash
	cat $(TMP)/mkjessieclusty>>jessies
	-@rm -Rf $(TMP)

lstrusties:
	cat trusties|jq .

mktrustyclusty: API_USERNAME API_KEY 
	$(eval TMP := $(shell mktemp -d --suffix=DOCKERTMP))
	$(eval API_KEY := $(shell cat API_KEY))
	$(eval API_USERNAME := $(shell cat API_USERNAME))
	$(eval URL :=https://panel.cloudatcost.com/api/v1/cloudpro/build.php)
	$(eval DATA :=key=$(API_KEY)&login=$(API_USERNAME)&cpu=4&ram=2048&storage=40&os=27)
	echo "curl -k -v -o $(TMP)/mktrustyclusty --data '$(DATA)' '$(URL)'"|bash
	cat $(TMP)/mktrustyclusty>>trusties
	-@rm -Rf $(TMP)

lscentoss:
	jq . centoss

mkcentosclusty: API_USERNAME API_KEY 
	$(eval TMP := $(shell mktemp -d --suffix=DOCKERTMP))
	$(eval API_KEY := $(shell cat API_KEY))
	$(eval API_USERNAME := $(shell cat API_USERNAME))
	$(eval URL :=https://panel.cloudatcost.com/api/v1/cloudpro/build.php)
	$(eval DATA :=key=$(API_KEY)&login=$(API_USERNAME)&cpu=4&ram=2048&storage=40&os=26)
	echo "curl -k -v -o $(TMP)/mkcentosclusty --data '$(DATA)' '$(URL)'"|bash
	cat $(TMP)/mkcentosclusty>>centoss
	-@rm -Rf $(TMP)

lsglusties:
	cat glusties|jq .

mkglustyclusty: API_USERNAME API_KEY 
	$(eval TMP := $(shell mktemp -d --suffix=DOCKERTMP))
	$(eval API_KEY := $(shell cat API_KEY))
	$(eval API_USERNAME := $(shell cat API_USERNAME))
	$(eval URL :=https://panel.cloudatcost.com/api/v1/cloudpro/build.php)
	$(eval DATA :=key=$(API_KEY)&login=$(API_USERNAME)&cpu=8&ram=4096&storage=120&os=27)
	echo "curl -k -v -o $(TMP)/mkglustyclusty --data '$(DATA)' '$(URL)'"|bash
	cat $(TMP)/mkglustyclusty>>glusties
	-@rm -Rf $(TMP)

listservers:
	$(eval API_KEY := $(shell cat API_KEY))
	$(eval API_USERNAME := $(shell cat API_USERNAME))
	$(eval URL :=https://panel.cloudatcost.com/api/v1/listservers.php?key=$(API_KEY)&login=$(API_USERNAME))
	echo "curl -k -o listservers '$(URL)' "|bash

fullList: API_USERNAME API_KEY  listservers
	jq -r '.data[] | " \(.sid) \(.hostname) \(.label) \(.ip) \(.rootpass) \(.id)  " ' listservers >> fullList

hostnamer: API_USERNAME API_KEY 
	$(eval TMP := $(shell mktemp -d --suffix=DOCKERTMP))
	$(eval API_KEY := $(shell cat API_KEY))
	$(eval API_USERNAME := $(shell cat API_USERNAME))
	$(eval URL :=https://panel.cloudatcost.com/api/v1/rdns.php)
	$(eval URL2 :=https://panel.cloudatcost.com/api/v1/renameserver.php)
	$(eval DATA :=key=$(API_KEY)&login=$(API_USERNAME))
	while read SID HOSTNAME NAME IP ROOTPASSWORD ID; \
	do \
	echo "curl -k -v --data '$(DATA)&sid=$$SID&hostname=$$HOSTNAME' '$(URL)'" ; \
	echo "curl -k -v --data '$(DATA)&sid=$$SID&name=$$NAME' '$(URL2)'" ; \
	done < workingList > $(TMP)/hostnamer
	-/usr/bin/time parallel  --jobs 2 -- < $(TMP)/hostnamer
	-@rm -Rf $(TMP)

normalizer: API_USERNAME API_KEY 
	$(eval TMP := $(shell mktemp -d --suffix=DOCKERTMP))
	$(eval API_KEY := $(shell cat API_KEY))
	$(eval API_USERNAME := $(shell cat API_USERNAME))
	$(eval URL :=https://panel.cloudatcost.com/api/v1/runmode.php)
	$(eval DATA :=key=$(API_KEY)&login=$(API_USERNAME))
	while read SID HOSTNAME NAME IP ROOTPASSWORD ID; \
		do \
		echo "curl -k -v --data '$(DATA)&sid=$$SID&mode=normal' '$(URL)'" ; \
		done < workingList > $(TMP)/normalizer 
	-/usr/bin/time parallel  --jobs 2 -- < $(TMP)/normalizer
	-@rm -Rf $(TMP)

rebooter:
	$(eval TMP := $(shell mktemp -d --suffix=DOCKERTMP))
	$(eval API_KEY := $(shell cat API_KEY))
	$(eval API_USERNAME := $(shell cat API_USERNAME))
	$(eval URL :=https://panel.cloudatcost.com/api/v1/powerop.php)
	$(eval DATA :=key=$(API_KEY)&login=$(API_USERNAME)&action=reset)
	while read SID HOSTNAME NAME IP ROOTPASSWORD ID; \
		do \
		echo "curl -k -v --data '$(DATA)&sid=$$SID&mode=normal' '$(URL)'" ; \
		done < workingList > $(TMP)/rebooter 
	-/usr/bin/time parallel  --jobs 2 -- < $(TMP)/rebooter
	@rm -Rf $(TMP)

kargo: SSH_PORT
	$(eval TMP := $(shell mktemp -d --suffix=DOCKERTMP))
	$(eval SSH_PORT := $(shell cat SSH_PORT))
	echo  '#!/bin/bash' > $(TMP)/mkargo.sh
	echo -n 'kargo prepare --nodes ' >> $(TMP)/mkargo.sh
	while read SID HOSTNAME NAME IP ROOTPASSWORD ID; \
		do \
		echo -n "$$NAME[ansible_host=$$IP,">> $(TMP)/mkargo.sh ; \
		echo -n "ansible_private_key_file=~/.ssh/id_ecdsa,">> $(TMP)/mkargo.sh ; \
		echo -n "ansible_port=$(SSH_PORT),ansible_ssh_user=root] ">> $(TMP)/mkargo.sh ; \
		done < workingList
	@bash $(TMP)/mkargo.sh
	cd ~/kargo
	kargo deploy 
	@rm -Rf $(TMP)

kargoConfig:
	$(eval TMP := $(shell mktemp -d --suffix=DOCKERTMP))
	$(eval SSH_PORT := $(shell cat SSH_PORT))
	$(eval PWD := $(shell `pwd`))
	head -n1 workingList > $(TMP)/masterList
	echo  '#!/bin/bash' > $(TMP)/mkargo.sh
	while read SID HOSTNAME NAME IP ROOTPASSWORD ID; \
		do \
		mkdir -p certs/$$NAME ; \
	    echo "scp -P $(SSH_PORT) root@$$IP:/etc/kubernetes/ssl/admin-key.pem certs/$$NAME/" >> $(TMP)/mkargo.sh ; \
	    echo "scp -P $(SSH_PORT) root@$$IP:/etc/kubernetes/ssl/ca.pem certs/$$NAME/" >> $(TMP)/mkargo.sh ; \
	    echo "scp -P $(SSH_PORT) root@$$IP:/etc/kubernetes/ssl/admin.pem certs/$$NAME/" >> $(TMP)/mkargo.sh ; \
		echo -n "kubectl config set-cluster default-cluster " >> $(TMP)/mkargo.sh ; \
		echo -n " --embed-certs=true  " >> $(TMP)/mkargo.sh ; \
		echo -n " --server=https://$$IP " >> $(TMP)/mkargo.sh ; \
		echo " --certificate-authority=$(PWD)/certs/$$NAME/ca.pem " >> $(TMP)/mkargo.sh ; \
		echo -n "kubectl config set-credentials default-admin " >> $(TMP)/mkargo.sh ; \
		echo -n " --kubeconfig=~/.kube/config  " >> $(TMP)/mkargo.sh ; \
		echo -n " --embed-certs=true  " >> $(TMP)/mkargo.sh ; \
		echo -n " --certificate-authority=$(PWD)/certs/$$NAME/ca.pem " >> $(TMP)/mkargo.sh ; \
		echo -n " --client-key=$(PWD)/certs/$$NAME/admin-key.pem " >> $(TMP)/mkargo.sh ; \
		echo " --client-certificate=$(PWD)/certs/$$NAME/admin.pem " >> $(TMP)/mkargo.sh ; \
		echo -n "kubectl config set-context default-system " >> $(TMP)/mkargo.sh ; \
		echo " --cluster=default-cluster --user=default-admin " >> $(TMP)/mkargo.sh ; \
		done < $(TMP)/masterList
	@bash $(TMP)/mkargo.sh
	@rm -Rf $(TMP)


installCurl:
	$(eval TMP := $(shell mktemp -d --suffix=DOCKERTMP))
	while read SID HOSTNAME NAME IP ROOTPASSWORD ID; \
		do \
		echo "./sshcurler root $$ROOTPASSWORD $$IP 22"; \
		done < workingList > $(TMP)/working.sh
	-/usr/bin/time parallel  --jobs 25 -- < $(TMP)/working.sh
	@rm -Rf $(TMP)

debkeyer:
	$(eval TMP := $(shell mktemp -d --suffix=DOCKERTMP))
	while read SID HOSTNAME NAME IP ROOTPASSWORD ID; \
		do \
		echo "./debkeymaster root $$ROOTPASSWORD $$IP" 22; \
		done < workingList > $(TMP)/working.sh
	-/usr/bin/time parallel  --jobs 25 -- < $(TMP)/working.sh
	@rm -Rf $(TMP)

keyer:
	$(eval TMP := $(shell mktemp -d --suffix=DOCKERTMP))
	while read SID HOSTNAME NAME IP ROOTPASSWORD ID; \
		do \
		echo "./keymaster root $$ROOTPASSWORD $$IP" 22; \
		done < workingList > $(TMP)/working.sh
	-/usr/bin/time parallel  --jobs 25 -- < $(TMP)/working.sh
	@rm -Rf $(TMP)

keyer16222:
	$(eval TMP := $(shell mktemp -d --suffix=DOCKERTMP))
	while read SID HOSTNAME NAME IP ROOTPASSWORD ID; \
		do \
		echo "./keymaster root $$ROOTPASSWORD $$IP" 16222; \
		done < workingList > $(TMP)/working.sh
	-/usr/bin/time parallel  --jobs 25 -- < $(TMP)/working.sh
	@rm -Rf $(TMP)

tester: listservers workingList
	$(eval TMP := $(shell mktemp -d --suffix=DOCKERTMP))
	while read SID HOSTNAME NAME IP ROOTPASSWORD ID; \
		do \
		echo "ssh -p16222 root@$$IP 'uname -a ;docker ps'"; \
		done < workingList > $(TMP)/tester 
	-/usr/bin/time parallel  --jobs 25 -- < $(TMP)/tester
	-@rm -Rf $(TMP)

tester22: listservers workingList
	$(eval TMP := $(shell mktemp -d --suffix=DOCKERTMP))
	while read SID HOSTNAME NAME IP ROOTPASSWORD ID; \
		do \
		echo "ssh -p22 root@$$IP 'which curl;uname -a '"; \
		done < workingList > $(TMP)/tester 
	-/usr/bin/time parallel  --jobs 25 -- < $(TMP)/tester
	-@rm -Rf $(TMP)

sshrebooter: listservers workingList
	$(eval TMP := $(shell mktemp -d --suffix=DOCKERTMP))
	while read SID HOSTNAME NAME IP ROOTPASSWORD ID; \
		do \
		echo "ssh -p16222 root@$$IP 'shutdown -r +1 &'"; \
		done < workingList > $(TMP)/rebooter 
	-/usr/bin/time parallel  --jobs 25 -- < $(TMP)/rebooter
	-@rm -Rf $(TMP)

sshrebooter22: listservers workingList
	$(eval TMP := $(shell mktemp -d --suffix=DOCKERTMP))
	while read SID HOSTNAME NAME IP ROOTPASSWORD ID; \
		do \
		echo "ssh -p22 root@$$IP 'shutdown -r +1 &'"; \
		done < workingList > $(TMP)/rebooter 
	-/usr/bin/time parallel  --jobs 25 -- < $(TMP)/rebooter
	-@rm -Rf $(TMP)

keyscan: listservers workingList
	$(eval TMP := $(shell mktemp -d --suffix=DOCKERTMP))
	while read SID HOSTNAME NAME IP ROOTPASSWORD ID; \
		do \
		echo "ssh-keyscan -p22 $$IP >>~/.ssh/known_hosts"; \
		done < workingList > $(TMP)/keyscan
	-bash $(TMP)/keyscan
	-@rm -Rf $(TMP)

keyscan16222: listservers workingList
	$(eval TMP := $(shell mktemp -d --suffix=DOCKERTMP))
	while read SID HOSTNAME NAME IP ROOTPASSWORD ID; \
		do \
		echo "ssh-keyscan -p16222 $$IP >>~/.ssh/known_hosts"; \
		done < workingList > $(TMP)/keyscan
	-bash $(TMP)/keyscan
	-@rm -Rf $(TMP)

clean:
	-@rm -f keyer
	-@rm -f kargo
	-@rm -f namer
	-@rm -f hostnamer
	-@rm -f fullList
	-@rm -f workingList
	-@rm -f listservers
	-@rm -f listtemplates
	-@rm -f listtasks
	-@rm -f names.list
	-@rm -f certs

movein: trustymovein

jessiemovein:
	$(eval TMP := $(shell mktemp -d --suffix=DOCKERTMP))
	while read SID HOSTNAME NAME IP ROOTPASSWORD ID; \
		do \
		echo "ssh root@$$IP 'curl https://raw.githubusercontent.com/joshuacox/potential-octo-ironman/jessie-cloudatcost-base/movein.sh | bash ;hostname $$HOSTNAME; echo $$HOSTNAME > /etc/hostname '"; \
		done < workingList > $(TMP)/working.sh
	-/usr/bin/time parallel  --jobs 25 -- < $(TMP)/working.sh
	@rm -Rf $(TMP)

trustymovein:
	$(eval TMP := $(shell mktemp -d --suffix=DOCKERTMP))
	while read SID HOSTNAME NAME IP ROOTPASSWORD ID; \
		do \
		echo "ssh root@$$IP 'curl https://raw.githubusercontent.com/joshuacox/potential-octo-ironman/trusty-cloudatcost-base/movein.sh | bash ;hostname $$HOSTNAME; echo $$HOSTNAME > /etc/hostname '"; \
		done < workingList > $(TMP)/working.sh
	-/usr/bin/time parallel  --jobs 25 -- < $(TMP)/working.sh
	@rm -Rf $(TMP)

trustymovein16222:
	$(eval TMP := $(shell mktemp -d --suffix=DOCKERTMP))
	while read SID HOSTNAME NAME IP ROOTPASSWORD ID; \
		do \
		echo "ssh -p16222 root@$$IP 'curl https://raw.githubusercontent.com/joshuacox/potential-octo-ironman/trusty-cloudatcost-base/movein.sh | bash ;hostname $$HOSTNAME; echo $$HOSTNAME > /etc/hostname '"; \
		done < workingList > $(TMP)/working.sh
	-/usr/bin/time parallel  --jobs 25 -- < $(TMP)/working.sh
	@rm -Rf $(TMP)

centosmovein:
	$(eval TMP := $(shell mktemp -d --suffix=DOCKERTMP))
	while read SID HOSTNAME NAME IP ROOTPASSWORD ID; \
		do \
		echo "ssh root@$$IP 'echo "nameserver 8.8.8.8" >>/etc/resolv.conf echo "nameserver 8.8.4.4" >>/etc/resolv.conf; echo "DNS1=8.8.8.8" >>/etc/sysconfig/network-scripts/ifcfg-eth0; echo "DNS2=8.8.4.4" >>/etc/sysconfig/network-scripts/ifcfg-eth0'"; \
		done < workingList > $(TMP)/working.sh
	-/usr/bin/time parallel  --jobs 25 -- < $(TMP)/working.sh
	- rm  $(TMP)/working.sh
	while read SID HOSTNAME NAME IP ROOTPASSWORD ID; \
		do \
		echo "ssh root@$$IP 'curl https://raw.githubusercontent.com/joshuacox/potential-octo-ironman/centos-cloudatcost-base/movein.sh | bash ;hostname $$HOSTNAME; echo $$HOSTNAME > /etc/hostname '"; \
		done < workingList > $(TMP)/working.sh
	-/usr/bin/time parallel  --jobs 25 -- < $(TMP)/working.sh
	@rm -Rf $(TMP)

workingList: fullList
	-@ echo "now you should copy fullList to workinglist and edit it to only the server you wish to work on the next line errors on purpose"
	-@ echo -n "WARNING!!! the next line errors on purpose to break"
	-@sleep 1
	-@ echo -n "!"
	-@sleep 1
	-@ echo -n "!"
	-@sleep 1
	-@ echo -n "!"
	-@sleep 1
	-@ echo -n "!"
	-@sleep 1
	-@ echo -n "!"
	-@sleep 1
	cat workingList

newList: fullList
	cat fullList|grep 'Not Assigned null'>newList

enter:
	$(eval TMP := $(shell mktemp -d --suffix=DOCKERTMP))
	while read SID HOSTNAME NAME IP ROOTPASSWORD ID; \
		do \
		echo "ssh -p16222 root@$$IP"; \
		done < workingList > $(TMP)/working.sh
	-bash $(TMP)/working.sh
	@rm -Rf $(TMP)

enter22:
	$(eval TMP := $(shell mktemp -d --suffix=DOCKERTMP))
	while read SID HOSTNAME NAME IP ROOTPASSWORD ID; \
		do \
		echo "ssh -p22 root@$$IP"; \
		done < workingList > $(TMP)/working.sh
	-bash $(TMP)/working.sh
	@rm -Rf $(TMP)

generals: SHELL:=/bin/bash
generals:	workingList
	$(eval TMP := $(shell mktemp -d --suffix=DOCKERTMP))
	$(eval CWD := $(shell pwd))
	COUNTZERO=0
	while read NAME DOMAIN; \
		do \
		((COUNTZERO++)) ; \
		echo "sed -i '$$COUNTZERO s/Not\ Assigned\ null/$$NAME.$$DOMAIN $$NAME/' $(CWD)/workingList"; \
		done < generals.txt > $(TMP)/working.sh
	-bash $(TMP)/working.sh
	@rm -Rf $(TMP)
	-@cat workingList

full: fullList

f: full

API_KEY:
	@while [ -z "$$API_KEY" ]; do \
		read -r -p "Enter the API KEY you wish to associate with this container [API_KEY]: " API_KEY; echo "$$API_KEY">>API_KEY; cat API_KEY; \
	done ;

ASK_K8S_PASSWD:
	@while [ -z "$$K8S_PASSWD" ]; do \
		read -r -p "Enter the K8S_PASSWD you wish to associate with this container [K8S_PASSWD]: " K8S_PASSWD; echo "$$K8S_PASSWD">>K8S_PASSWD; cat K8S_PASSWD; \
	done ;

KUBE_NETWORK:
	@while [ -z "$$KUBE_NETWORK" ]; do \
		read -r -p "Enter the KUBE_NETWORK you wish to associate with this container [KUBE_NETWORK]: " KUBE_NETWORK; echo "$$KUBE_NETWORK">>KUBE_NETWORK; cat KUBE_NETWORK; \
	done ;

SSH_PORT:
	@while [ -z "$$SSH_PORT" ]; do \
		read -r -p "Enter the SSH_PORT you wish to associate with this container [SSH_PORT]: " SSH_PORT; echo "$$SSH_PORT">>SSH_PORT; cat SSH_PORT; \
	done ;

SSH_KEY:
	@while [ -z "$$SSH_KEY" ]; do \
		read -r -p "Enter the SSH_KEY you wish to associate with this container [SSH_KEY]: " SSH_KEY; echo "$$SSH_KEY">>SSH_KEY; cat SSH_KEY; \
	done ;

API_USERNAME:
	@while [ -z "$$API_USERNAME" ]; do \
		read -r -p "Enter the API USERNAME you wish to associate with this container [API_USERNAME]: " API_USERNAME; echo "$$API_USERNAME">>API_USERNAME; cat API_USERNAME; \
	done ;

names.list: fullList
	$(eval TMP := $(shell mktemp -d --suffix=DOCKERTMP))
	cat *.names > $(TMP)/names.list
	while read SID HOSTNAME NAME IP ROOTPASSWORD ID; \
		do \
	    cat $(TMP)/names.list|grep -v $$NAME > $(TMP)/names.list.tmp ; \
	    mv $(TMP)/names.list.tmp $(TMP)/names.list ; \
	    cat $(TMP)/names.list|grep -v $$HOSTNAME > $(TMP)/names.list.tmp ; \
	    mv $(TMP)/names.list.tmp $(TMP)/names.list ; \
		done < fullList
	cat $(TMP)/names.list| sort -R --random-source=/dev/urandom > $(TMP)/names.list.tmp
	mv $(TMP)/names.list.tmp $(TMP)/names.list
	cat $(TMP)/names.list > names.list

newnamer: SHELL:=/bin/bash
newnamer: fullList names.list newList
	$(eval TMP := $(shell mktemp -d --suffix=DOCKERTMP))
	$(eval CWD := $(shell pwd))
	COUNTZERO=0
	while read NAME DOMAIN; \
		do \
		((COUNTZERO++)) ; \
		echo "sed -i '$$COUNTZERO s/Not\ Assigned\ null/$$NAME.$$DOMAIN $$NAME/' $(CWD)/newList"; \
		done < names.list > $(TMP)/working.sh
	-bash $(TMP)/working.sh
	@rm -Rf $(TMP)
	-@mv -i newList workingList

requirements:
	apt-get install rsnapshot parallel rsync git jq build-essential

K8S_PASSWD:
	$(eval K8S_PASSWD := $(shell tr -cd '[:alnum:]' < /dev/urandom | fold -w11 | head -n1 ))
	-@echo $(K8S_PASSWD) > K8S_PASSWD

example: K8S_PASSWD
	-@cp -i KUBE_NETWORK.example KUBE_NETWORK
	-@cp -i SSH_KEY.example SSH_KEY
	-@cp -i SSH_PORT.example SSH_PORT

