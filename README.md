# mkcloudatcost
Make a cloudatcost cloud PDQ

## Auto

for the next commands in the future you will be able to precede by incanting
`make trusty` (or `make jessie`, `make centos`, etc) a number of times which will
create a trusty (jessie/centos) host each time,
but the API is broken for now, 
so you'll have to create them yourself using the [GUI](https://panel.cloudatcost.com/)

Then once you have some fresh unnamed hosts, you can use my auto provisioners to finish up on them.
This will change their run mode to normal, which prevents them from turning off in 7 days.
Then it will rename, and set reverse DNS, key the server, do all normal updates, and install the newest docker.

`make auto` this will prepare a trusty host for docker hosting

`make jessieauto` this will prepare a jessie host for docker hosting

`make centosauto` this will prepare a centos host for docker hosting

## Detailed Usage

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

### make auto

`make movein` this will execute my movein script on a fresh trusty instance getting you a 3.19 kernel docker 1.11 and overlayFS as your storage driver

### make jessieauto

much like `make auto` but intended for jessie machines

### make centosauto

much like auto but for centos7 machines

### auto naming

All of the auto methods above invoke `make names.list`, which invokes `make chosenNames`,
if you wanted to override and only use the greek gods,
simply copy that list to chosenNames and the Makefile will skip that step,

e.g.
```
cp greekgods.names chosenNames
rm names.list
make names.list
cat names.list
```

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

### Kargo (WIP)

`make kargo` should get you a kargo cluster made out of the `workingList`,
at the moment this only works on centos machines using port22, I'm working on that though

`make kargoConfig` should use the first master (the first machine in the `workingList`), 
grab the certs, and setup `~/.kube/config` for you, this WIP though, thar be dragons

### Gluster (WIP)

`make gluster` should get you a cluster of glusterFS made out of the `workingList`,
at the moment this only works on Trusty hosts as the ansible was written by Geerling for Trusty

### Waffle.io

[![Stories in Ready](https://badge.waffle.io/joshuacox/mkcloudatcost.svg?label=ready&title=Ready)](http://waffle.io/joshuacox/mkcloudatcost)
