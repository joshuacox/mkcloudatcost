# mkcloudatcost
Make a cloudatcost cloud PDQ

## Usage

`make fullLIst` or `make f`  will get you a file name fullLIst,
copy this file to `workingList`  i.e. `cp fullList workingList`
now open this file and delete the lines containing servers you do NOT want to work with
leaving the servers you DO want to work with, now most other commands work on this `workingList`

### deleter

a delete function is not included for good reasons, 
but every now and then I want to delete enmasse, 
and I copy this section in and double check my `workingList` twice to not be naughty but nice!

```
deleter:
	$(eval TMP := $(shell mktemp -d --suffix=DOCKERTMP))
	$(eval API_KEY := $(shell cat API_KEY))
	$(eval API_USERNAME := $(shell cat API_USERNAME))
	$(eval URL :=https://panel.cloudatcost.com/api/v1/delete.php)
	$(eval DATA :=key=$(API_KEY)&login=$(API_USERNAME))
	while read SID HOSTNAME NAME IP ROOTPASSWORD ID; \
		do \
		echo "curl -k -v --data '$(DATA)&sid=$$SID&mode=normal' '$(URL)'" ; \
		done < workingList > $(TMP)/deleter 
	-/bin/bash $(TMP)/deleter
	-@rm -Rf $(TMP)
```
