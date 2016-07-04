all: workingList hostnamer normalizer next

next: workingList keyscan keyer tester22
	-@echo "next try trustymovein for a trustyhost"

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

mkjessieclusty:
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

mktrustyclusty:
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

mkcentosclusty:
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

mkglustyclusty:
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

fullList: listservers
	jq -r '.data[] | " \(.sid) \(.hostname) \(.label) \(.ip) \(.rootpass) \(.id)  " ' listservers >> fullList

hostnamer:
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

normalizer:
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

kargo:
	$(eval TMP := $(shell mktemp -d --suffix=DOCKERTMP))
	echo  '#!/bin/bash' > $(TMP)/mkargo.sh
	echo -n 'kargo prepare --nodes ' >> $(TMP)/mkargo.sh
	while read SID HOSTNAME NAME IP ROOTPASSWORD ID; \
		do \
		echo -n "$$NAME[ansible_host=$$IP,">> $(TMP)/mkargo.sh ; \
		echo -n "ansible_private_key_file=~/.ssh/id_ecdsa,">> $(TMP)/mkargo.sh ; \
		echo -n "ansible_port=16222,ansible_ssh_user=root] ">> $(TMP)/mkargo.sh ; \
		done < workingList
	@bash $(TMP)/mkargo.sh
	@rm -Rf $(TMP)

installCurl:
	$(eval TMP := $(shell mktemp -d --suffix=DOCKERTMP))
	while read SID HOSTNAME NAME IP ROOTPASSWORD ID; \
		do \
		echo "./curler root $$ROOTPASSWORD $$IP" 22; \
		done < workingList > $(TMP)/working.sh
	@bash $(TMP)/working.sh
	@rm -Rf $(TMP)

keyer:
	$(eval TMP := $(shell mktemp -d --suffix=DOCKERTMP))
	while read SID HOSTNAME NAME IP ROOTPASSWORD ID; \
		do \
		echo "./keymaster root $$ROOTPASSWORD $$IP" 22; \
		done < workingList > $(TMP)/working.sh
	@bash $(TMP)/working.sh
	@rm -Rf $(TMP)

keyer16222:
	$(eval TMP := $(shell mktemp -d --suffix=DOCKERTMP))
	while read SID HOSTNAME NAME IP ROOTPASSWORD ID; \
		do \
		echo "./keymaster root $$ROOTPASSWORD $$IP" 16222; \
		done < workingList > $(TMP)/working.sh
	@bash $(TMP)/working.sh
	@rm -Rf $(TMP)

tester: listservers workingList
	$(eval TMP := $(shell mktemp -d --suffix=DOCKERTMP))
	while read SID HOSTNAME NAME IP ROOTPASSWORD ID; \
		do \
		echo "ssh -p16222 root@$$IP 'uname -a ;docker ps'"; \
		done < workingList > $(TMP)/tester 
	-/usr/bin/time parallel  --jobs 5 -- < $(TMP)/tester
	-@rm -Rf $(TMP)

tester22: listservers workingList
	$(eval TMP := $(shell mktemp -d --suffix=DOCKERTMP))
	while read SID HOSTNAME NAME IP ROOTPASSWORD ID; \
		do \
		echo "ssh -p22 root@$$IP 'which curl;uname -a '"; \
		done < workingList > $(TMP)/tester 
	-/usr/bin/time parallel  --jobs 5 -- < $(TMP)/tester
	-@rm -Rf $(TMP)

sshrebooter: listservers workingList
	$(eval TMP := $(shell mktemp -d --suffix=DOCKERTMP))
	while read SID HOSTNAME NAME IP ROOTPASSWORD ID; \
		do \
		echo "ssh -p16222 root@$$IP 'shutdown -r +1 &'"; \
		done < workingList > $(TMP)/rebooter 
	-/usr/bin/time parallel  --jobs 5 -- < $(TMP)/rebooter
	-@rm -Rf $(TMP)

sshrebooter22: listservers workingList
	$(eval TMP := $(shell mktemp -d --suffix=DOCKERTMP))
	while read SID HOSTNAME NAME IP ROOTPASSWORD ID; \
		do \
		echo "ssh -p22 root@$$IP 'shutdown -r +1 &'"; \
		done < workingList > $(TMP)/rebooter 
	-/usr/bin/time parallel  --jobs 5 -- < $(TMP)/rebooter
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
	-@rm -f listservers
	-@rm -f listtemplates
	-@rm -f listtasks

movein: jessiemovein

jessiemovein:
	$(eval TMP := $(shell mktemp -d --suffix=DOCKERTMP))
	while read SID HOSTNAME NAME IP ROOTPASSWORD ID; \
		do \
		echo "ssh root@$$IP 'curl https://raw.githubusercontent.com/joshuacox/potential-octo-ironman/jessie-cloudatcost-base/movein.sh | bash ;hostname $$HOSTNAME; echo $$HOSTNAME > /etc/hostname '"; \
		done < workingList > $(TMP)/working.sh
	-/usr/bin/time parallel  --jobs 5 -- < $(TMP)/working.sh
	@rm -Rf $(TMP)

trustymovein:
	$(eval TMP := $(shell mktemp -d --suffix=DOCKERTMP))
	while read SID HOSTNAME NAME IP ROOTPASSWORD ID; \
		do \
		echo "ssh root@$$IP 'curl https://raw.githubusercontent.com/joshuacox/potential-octo-ironman/trusty-cloudatcost-base/movein.sh | bash ;hostname $$HOSTNAME; echo $$HOSTNAME > /etc/hostname '"; \
		done < workingList > $(TMP)/working.sh
	-/usr/bin/time parallel  --jobs 5 -- < $(TMP)/working.sh
	@rm -Rf $(TMP)

trustymovein16222:
	$(eval TMP := $(shell mktemp -d --suffix=DOCKERTMP))
	while read SID HOSTNAME NAME IP ROOTPASSWORD ID; \
		do \
		echo "ssh -p16222 root@$$IP 'curl https://raw.githubusercontent.com/joshuacox/potential-octo-ironman/trusty-cloudatcost-base/movein.sh | bash ;hostname $$HOSTNAME; echo $$HOSTNAME > /etc/hostname '"; \
		done < workingList > $(TMP)/working.sh
	-/usr/bin/time parallel  --jobs 5 -- < $(TMP)/working.sh
	@rm -Rf $(TMP)

centosmovein:
	$(eval TMP := $(shell mktemp -d --suffix=DOCKERTMP))
	while read SID HOSTNAME NAME IP ROOTPASSWORD ID; \
		do \
		echo "ssh root@$$IP 'echo "nameserver 8.8.8.8" >>/etc/resolv.conf echo "nameserver 8.8.4.4" >>/etc/resolv.conf; echo "DNS1=8.8.8.8" >>/etc/sysconfig/network-scripts/ifcfg-eth0; echo "DNS2=8.8.4.4" >>/etc/sysconfig/network-scripts/ifcfg-eth0'"; \
		done < workingList > $(TMP)/working.sh
	-/usr/bin/time parallel  --jobs 5 -- < $(TMP)/working.sh
	- rm  $(TMP)/working.sh
	while read SID HOSTNAME NAME IP ROOTPASSWORD ID; \
		do \
		echo "ssh root@$$IP 'curl https://raw.githubusercontent.com/joshuacox/potential-octo-ironman/centos-cloudatcost-base/movein.sh | bash ;hostname $$HOSTNAME; echo $$HOSTNAME > /etc/hostname '"; \
		done < workingList > $(TMP)/working.sh
	-/usr/bin/time parallel  --jobs 5 -- < $(TMP)/working.sh
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
