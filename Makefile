auto: listservers hostnames

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

trusty: mktrustyclusty lstrusties

glusty: mkglustyclusty lsglusties

mktrustyclusty:
	$(eval API_KEY := $(shell cat API_KEY))
	$(eval API_USERNAME := $(shell cat API_USERNAME))
	$(eval URL :=https://panel.cloudatcost.com/api/v1/cloudpro/build.php)
	$(eval DATA :=key=$(API_KEY)&login=$(API_USERNAME)&cpu=4&ram=2048&storage=40&os=27)
	echo "curl -k -v -o mktrustyclusty --data '$(DATA)' '$(URL)'"|bash
	cat mktrustyclusty|jq .
	cat mktrustyclusty>>trusties
	rm mktrustyclusty

mkglustyclusty:
	$(eval API_KEY := $(shell cat API_KEY))
	$(eval API_USERNAME := $(shell cat API_USERNAME))
	$(eval URL :=https://panel.cloudatcost.com/api/v1/cloudpro/build.php)
	$(eval DATA :=key=$(API_KEY)&login=$(API_USERNAME)&cpu=8&ram=4096&storage=120&os=27)
	echo "curl -k -v -o mkglustyclusty --data '$(DATA)' '$(URL)'"|bash
	cat mkglustyclusty|jq .
	cat mkglustyclusty>>glusties
	rm mkglustyclusty

lstrusties:
	cat trusties|jq .

lsglusties:
	cat glusties|jq .

listservers:
	$(eval API_KEY := $(shell cat API_KEY))
	$(eval API_USERNAME := $(shell cat API_USERNAME))
	$(eval URL :=https://panel.cloudatcost.com/api/v1/listservers.php?key=$(API_KEY)&login=$(API_USERNAME))
	echo "curl -k -o listservers '$(URL)' "|bash
	cat listservers|jq .

hostnames: listservers
	jq -r '.data[] | " \(.sid) \(.hostname) \(.label) \(.ip) \(.rootpass) \(.id)  " ' listservers >> hostnames

hostnamer:
	$(eval TMP := $(shell mktemp -d --suffix=DOCKERTMP))
	$(eval API_KEY := $(shell cat API_KEY))
	$(eval API_USERNAME := $(shell cat API_USERNAME))
	$(eval URL :=https://panel.cloudatcost.com/api/v1/rdns.php)
	$(eval DATA :=key=$(API_KEY)&login=$(API_USERNAME))
	while read SID HOSTNAME NAME IP ROOTPASSWORD ID; \
	do \
	echo "curl -k -v --data '$(DATA)&sid=$$SID&hostname=$$HOSTNAME' '$(URL)'" ; \
	echo "curl -k -v --data '$(DATA)&sid=$$SID&name=$$NAME' '$(URL)'" ; \
	done < hostnames > hostnamer
	rm -Rf $(TMP)

namer:
	$(eval TMP := $(shell mktemp -d --suffix=DOCKERTMP))
	$(eval API_KEY := $(shell cat API_KEY))
	$(eval API_USERNAME := $(shell cat API_USERNAME))
	$(eval URL :=https://panel.cloudatcost.com/api/v1/renameserver.php)
	$(eval DATA :=key=$(API_KEY)&login=$(API_USERNAME))
	while read SID HOSTNAME NAME; \
		do \
		echo "curl -k -v --data '$(DATA)&sid=$$SID&name=$$NAME' '$(URL)'" ; \
		done < hostnames > namer
	rm -Rf $(TMP)

normal:
	$(eval TMP := $(shell mktemp -d --suffix=DOCKERTMP))
	$(eval API_KEY := $(shell cat API_KEY))
	$(eval API_USERNAME := $(shell cat API_USERNAME))
	$(eval URL :=https://panel.cloudatcost.com/api/v1/runmode.php)
	$(eval DATA :=key=$(API_KEY)&login=$(API_USERNAME))
	while read SID HOSTNAME NAME IP ROOTPASSWORD ID; \
		do \
		echo "curl -k -v --data '$(DATA)&sid=$$SID&mode=normal' '$(URL)'" ; \
		done < hostnames > $(TMP)/normalizer 
	-/usr/bin/time -v parallel  --jobs 5 -- < $(TMP)/normalizer
	rm -Rf $(TMP)

kargo:
	$(eval TMP := $(shell mktemp -d --suffix=DOCKERTMP))
	echo  '#!/bin/bash' > $(TMP)/mkargo.sh
	echo -n 'kargo prepare --nodes ' >> $(TMP)/mkargo.sh
	while read SID HOSTNAME NAME IP ROOTPASSWORD ID; \
		do \
		echo -n "$$NAME[ansible_host=$$IP,">> $(TMP)/mkargo.sh ; \
		echo -n "ansible_private_key_file=~/.ssh/id_ecdsa,">> $(TMP)/mkargo.sh ; \
		echo -n "ansible_port=16222,ansible_ssh_user=root] ">> $(TMP)/mkargo.sh ; \
		done < hostnames > $(TMP)/normalizer 
	@cp $(TMP)/mkargo.sh ./kargo
	@rm -Rf $(TMP)

keyer:
	while read SID HOSTNAME NAME IP ROOTPASSWORD ID; \
		do \
		echo "./keymaster root $$ROOTPASSWORD $$IP" 22; \
		done < hostnames > keyer

keyer16222:
	while read SID HOSTNAME NAME IP ROOTPASSWORD ID; \
		do \
		echo "./keymaster root $$ROOTPASSWORD $$IP" 16222; \
		done < hostnames > keyer

tester: listservers hostnames
	$(eval TMP := $(shell mktemp -d --suffix=DOCKERTMP))
	while read SID HOSTNAME NAME IP ROOTPASSWORD ID; \
		do \
		echo "ssh -p16222 root@$$IP 'uname -a '"; \
		done < hostnames > $(TMP)/tester 
	-/usr/bin/time parallel  --jobs 5 -- < $(TMP)/tester
	-@rm -Rf $(TMP)

sshrebooter: listservers hostnames
	$(eval TMP := $(shell mktemp -d --suffix=DOCKERTMP))
	while read SID HOSTNAME NAME IP ROOTPASSWORD ID; \
		do \
		echo "ssh -p16222 root@$$IP 'shutdown -r +1 &'"; \
		done < hostnames > $(TMP)/rebooter 
	-/usr/bin/time parallel  --jobs 5 -- < $(TMP)/rebooter
	-@rm -Rf $(TMP)

keyscan: listservers hostnames
	$(eval TMP := $(shell mktemp -d --suffix=DOCKERTMP))
	while read SID HOSTNAME NAME IP ROOTPASSWORD ID; \
		do \
		echo "ssh-keyscan -p22 $$IP "; \
		echo "ssh-keyscan -p16222 $$IP "; \
		done < hostnames > $(TMP)/keyscan
	-/usr/bin/time -v parallel  --jobs 5 -- < $(TMP)/keyscan

clean:
	-@rm -f keyer
	-@rm -f namer
	-@rm -f hostnamer
	-@rm -f hostnames
	-@rm -f listservers
	-@rm -f listtemplates 
	-@rm -f listtasks 

movein:
	while read SID HOSTNAME NAME IP ROOTPASSWORD ID; \
		do \
		echo "ssh root@$$IP 'curl https://raw.githubusercontent.com/joshuacox/potential-octo-ironman/trusty-cloudatcost-base/movein.sh | bash ;hostname $$HOSTNAME; echo $$HOSTNAME > /etc/hostname '"; \
		done < hostnames > movein 
