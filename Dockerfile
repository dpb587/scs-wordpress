FROM ubuntu:precise
RUN /bin/echo "deb http://archive.ubuntu.com/ubuntu/ precise universe" >> /etc/apt/sources.list && /usr/bin/apt-get update && /usr/bin/apt-get install -y wget ca-certificates && /usr/bin/wget https://apt.puppetlabs.com/puppetlabs-release-precise.deb && /usr/bin/dpkg -i puppetlabs-release-precise.deb && /bin/rm puppetlabs-release-precise.deb && /usr/bin/apt-get update && /usr/bin/apt-get install -y puppet && /usr/bin/puppet module install puppetlabs/stdlib && /usr/bin/apt-get clean && /bin/rm -rf /var/cache/apt/archives/* /var/lib/apt/lists/*
ADD . /scs
VOLUME /scs/mnt/uploads
EXPOSE 80
CMD [ "default", "/scs/scs/bin/run" ]
ENTRYPOINT [ "/scs/scs/bin/boot" ]
