FROM google/cloud-sdk

RUN apt-get update
RUN apt-get install git -y
RUN apt-get install vim -y
RUN apt-get install sudo -y
RUN apt-get install curl -y

RUN adduser --disabled-password --gecos '' saltuser
RUN adduser saltuser sudo
RUN echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers
RUN cp .bashrc /home/saltuser
RUN mkdir /home/saltuser/.ssh



#ssh authentication
COPY config/google_compute_engine /home/saltuser/.ssh/
COPY config/google_compute_engine.pub /home/saltuser/.ssh/
RUN chown -R saltuser:saltuser /home/saltuser/.ssh
USER saltuser
ENV HOME /home/saltuser
WORKDIR /home/saltuser 

ADD config /tmp/config
RUN /bin/bash -c "/tmp/config/script.sh /tmp/config/salt.conf"