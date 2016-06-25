auto: listservers hostnames

listtemplates:
	$(eval API_KEY := $(shell cat API_KEY))
	$(eval API_USERNAME := $(shell cat API_USERNAME))
	$(eval URL :=https://panel.cloudatcost.com/api/v1/listtemplates.php?key=$(API_KEY)&login=$(API_USERNAME))
	echo "curl -k -o listtemplates '$(URL)' "|bash
	cat listtemplates|jq .

trusty: mktrustyclusty lstrusties

mktrustyclusty:
	$(eval API_KEY := $(shell cat API_KEY))
	$(eval API_USERNAME := $(shell cat API_USERNAME))
	$(eval URL :=https://panel.cloudatcost.com/api/v1/cloudpro/build.php)
	$(eval DATA :=key=$(API_KEY)&login=$(API_USERNAME)&cpu=4&ram=2048&storage=40&os=27)
	echo "curl -k -v -o mktrustyclusty --data '$(DATA)' '$(URL)'"|bash
	cat mktrustyclusty|jq .
	cat mktrustyclusty>>trusties
	rm mktrustyclusty

lstrusties:
	cat trusties|jq .

listservers:
	$(eval API_KEY := $(shell cat API_KEY))
	$(eval API_USERNAME := $(shell cat API_USERNAME))
	$(eval URL :=https://panel.cloudatcost.com/api/v1/listservers.php?key=$(API_KEY)&login=$(API_USERNAME))
	echo "curl -k -o listservers '$(URL)' "|bash
	cat listservers|jq .

hostnames:
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

keyer:
	while read SID HOSTNAME NAME IP ROOTPASSWORD ID; \
		do \
		echo "./keymaster root $$ROOTPASSWORD $$IP"; \
		done < hostnames > keyer

tester:
	$(eval TMP := $(shell mktemp -d --suffix=DOCKERTMP))
	while read SID HOSTNAME NAME IP ROOTPASSWORD ID; \
		do \
		echo "ssh -p16222 root@$$IP 'uname -a '"; \
		done < hostnames > $(TMP)/tester 
	-/usr/bin/time -v parallel  --jobs 5 -- < $(TMP)/tester
	-@rm -Rf $(TMP)

clean:
	-@rm -f keyer
	-@rm -f namer
	-@rm -f hostnamer
	-@rm -f hostnames
	-@rm -f listservers
	-@rm -f listtemplates 

movein:
	while read SID HOSTNAME NAME IP ROOTPASSWORD ID; \
		do \
		echo "ssh root@$$IP 'curl https://raw.githubusercontent.com/joshuacox/potential-octo-ironman/trusty-cloudatcost-base/movein.sh | bash ;hostname $$HOSTNAME; echo $$HOSTNAME > /etc/hostname '"; \
		done < hostnames > movein 
