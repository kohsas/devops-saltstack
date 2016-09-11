#
# Docker install for Ubuntu 14.04, 15.10 and 16.04
#
{% if grains['os'] == 'Ubuntu' %}
{% if grains['osrelease'] == '14.04' or grains['osrelease'] == '15.10' or grains['osrelease'] == '16.04' %}
{% set osfinger = grains['osfinger'] %}

install-ca-certificates:
  pkg.installed:
    - pkgs:
      - apt-transport-https 
      - ca-certificates

import-docker-key:  
  cmd.run:
    - name: apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys 58118E89F3A912897C070ADBF76221572C52609D
    - creates: /etc/apt/sources.list.d/docker.list

/etc/apt/sources.list.d/docker.list:
  file.managed:
    - source: salt://software/files/docker-{{ osfinger }}.list

purge-lxc-docker:
  pkg.purged:
    - name: lxc-docker

#sudo apt-get install linux-image-extra-$(uname -r) linux-image-extra-virtual
docker-prerequisites:
  pkg.installed:
    - pkgs:
      - linux-image-extra-{{grains['kernelrelease']}}
      - linux-image-extra-virtual

install docker and ensure it is running:
  pkg.installed:
    - name: docker-engine
  service.running:  
    - name: docker

{% endif %}
{% endif %}
