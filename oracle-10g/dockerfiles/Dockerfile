FROM aelsnz/oraclelinux:oel5

## Using aelsnz/oraclelinux:oel5 image which include all prerequisites, oracle user and directory structure


USER root

# Make sure all requirements are met and install a few useful additional packages 
RUN rpm --rebuilddb \
  && yum -y install net-tools perl wget unzip perl-Test-Simple e2fsprogs e2fsprogs-libs screen sudo man cpan tar gzip which gcc binutils libaio glibc.i686 libgcc.i686 libXp.i686 libXp.x86_64 libXp-devel.i686 libXp-devel.x86_64 libXpm.i686 libXpm-devel.i686 libXpm-devel.x86_64 libXpm.x86_64 libXtst.x86_64 libXtst-devel.x86_64 libXtst.i686 libXtst-devel.i686 binutils* compat-libstdc++-* elfutils-libelf-* elfutils-libelf-devel-* elfutils-libelf-devel-static-* gcc-* gcc-c++-* glibc-* glibc-common-* glibc-devel-* glibc-headers-* ksh libaio-* libaio-devel-* libgcc libstdc++-* libstdc++-devel make sysstat unixODBC unixODBC-devel compat-libstdc++-33.i686 compat-libstdc++-296.i686 glibc.i686 glibc-devel.i686 unixODBC.i686 unixODBC-devel.i686 libaio.i686 libaio-devel.i686 libgcc.i686 libstdc++.i686 libstdc++-devel.i686 libaio-devel.i686 libXp.i686 libXt.i386 libXt.x86_64 ibXp.i386 libXp.x86_64 libXtst.i386 libXtst.x86_64 libstdc++-devel.i386 glibc-devel.i386 libaio-devel.i386 \
  && yum clean all \
  && rm -rf /var/cache/yum/*

# Copy software and response files into /install
#
COPY software/10201_database_linux_x86_64.tar.gz /install/
COPY software/p8202632_10205_Linux-x86-64.zip /install/
#
COPY scripts/db_install.rsp /home/oracle/bin/
COPY scripts/patch_install.rsp /home/oracle/bin/
COPY scripts/create-db.sh /home/oracle/bin/

# make sure oracle user own /install and /home/oracle/bin
#
RUN chown -R oracle:oinstall /install \
  && chown -R oracle:oinstall /home/oracle/bin/*.rsp \
  && chown -R oracle:oinstall /home/oracle/bin/*.sh \
  && chmod u+rx /home/oracle/bin/*.sh

# Switch to user Oracle
#
USER	oracle
WORKDIR	/install

# set current environment
#
ENV ORACLE_BASE=/u01/app/oracle
ENV ORACLE_HOME=/u01/app/oracle/product/10.2.0/db_1
ENV PATH=/u01/app/oracle/product/10.2.0/db_1/bin:$PATH
ENV LD_LIBRARY_PATH=/u01/app/oracle/product/10.2.0/db_1/lib:$LD_LIBRARY_PATH
ENV NLS_DATE_FORMAT=dd/mm/yyyy:hh24:mi:ss
ENV DISABLE_HUGETLBFS=1

# Unzip software
RUN	cd /install \
  && tar xzf 10201_database_linux_x86_64.tar.gz \
  && rm -rf 10201_database*.tar.gz \
  && unzip p8202632_10205_Linux-x86-64.zip \
  && rm -rf p8202632_10205_Linux-x86-64.zip

# Install Oracle Software
# 
RUN /install/database/runInstaller -silent -force -waitforcompletion -responsefile /home/oracle/bin/db_install.rsp -ignoresysprereqs -ignoreprereq

# Switch back to root
#
USER	root
RUN /u01/app/oracle/oraInventory/orainstRoot.sh \
  && /u01/app/oracle/product/10.2.0/db_1/root.sh -silent \
  && rm -rf /install/database \
  && echo "export DISABLE_HUGETLBFS=1" >> /home/oracle/.bashrc

## Switch to Oracle user to install patch 10205
USER oracle 

# Install patch
#
RUN cd /install/Disk1 \
  && ./runInstaller -waitForCompletion -silent -responseFile /home/oracle/bin/patch_install.rsp -ignoresysprereqs -ignoreprereq


# Switch to root and clean up
#
RUN cd /install \
  && rm -rf Disk1 \
  && rm -rf README* 

# Expose ports - oracle 
#
EXPOSE 1521 

# Switch back to Oracle user
#
USER oracle
WORKDIR	/home/oracle

# set current environment
#
ENV ORACLE_BASE=/u01/app/oracle
ENV ORACLE_HOME=/u01/app/oracle/product/10.2.0/db_1
ENV PATH=/u01/app/oracle/product/10.2.0/db_1/bin:$PATH
ENV NLS_DATE_FORMAT=dd/mm/yyyy:hh24:mi:ss 
ENV DISABLE_HUGETLBFS=1

##
# A Sample script that can be used to create the database 
# or you can call it as entrypoint to create database and then tail alert log
##
# RUN cd /home/oracle/bin \
#   && ./create-db.sh -d DEV -a Y

CMD ["/usr/bin/bash"]

