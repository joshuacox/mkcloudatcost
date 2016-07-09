# mkcloudatcost
Make a cloudatcost cloud PDQ

## Usage

### make fullList

`make fullLIst` or `make f`  will get you a file name fullLIst,

### workingList

copy the fullList file to `workingList`  i.e. `cp fullList workingList`
now open this file and delete the lines containing servers you do NOT want to work with
leaving the servers you DO want to work with, now most other commands work on this `workingList`
it will look something like this:
```
 555697574 Not Assigned null 64.196.201.216 VyHequ 555697574  
 555697575 Not Assigned null 64.196.201.215 A3eRHn 555697575  
 555697576 Not Assigned null 64.196.201.214 qagp6u 555697576  
 555697577 Not Assigned null 64.196.201.213 JAaate 555697577  
 555697578 Not Assigned null 64.196.201.212 sEmn8y 555697578  
```

### make trusty
 should build you a trusty machine, but the API is not working with the newest datacenter (DC3) and as we are only able to provision into that datacenter this is broken for now
 but should work with cloudatcost fixes things on their end

### make movein

`make movein` this will execute my movein script on a fresh trusty instance getting you a 3.19 kernel docker 1.11 and overlayFS as your storage driver

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
