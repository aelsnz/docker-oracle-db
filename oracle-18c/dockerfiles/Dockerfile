FROM aelsnz/oraclelinux:oel7

## Using aelsnz/oraclelinux:oel7 image which include all prerequisites, oracle user and directory structure

USER root

# Expose Oracle listener and SSH Ports 
#
EXPOSE 22 1521 

# Copy software and response files into /install
#
COPY	software/LINUX.X64_180000_db_home.zip /install/
COPY	scripts/db.rsp /home/oracle/bin/
COPY	scripts/create-db.sh /home/oracle/bin/

# make sure oracle user own /install
#
RUN chown -R oracle:oinstall /install \
  && chown -R oracle:oinstall /home/oracle/bin/*.rsp \
  && chown -R oracle:oinstall /home/oracle/bin/*.sh \
  && chmod u+rx /home/oracle/bin/*.sh \
  && mkdir -p /u01/app/oracle \
  && chown -R oracle:oinstall /u01/app/oracle 

# Switch to oracle user
#
USER	oracle
WORKDIR	/install

# set current environment
#
ENV ORACLE_BASE=/u01/app/oracle
ENV ORACLE_HOME=/u01/app/oracle/product/18.0.0/dbhome_1
ENV PATH=/u01/app/oracle/product/18.0.0/dbhome_1/bin:/u01/app/oracle/product/18.0.0/dbhome_1/OPatch:$PATH
ENV NLS_DATE_FORMAT=dd/mm/yyyy:hh24:mi:ss

# Unzip software
RUN	cd /u01/app/oracle/product/18.0.0/dbhome_1 \
  && unzip /install/LINUX.X64_180000_db_home.zip \
  && rm -rf /install/LINUX.X64_180000_db_home.zip 

# Install Oracle Software
# 
RUN cd /u01/app/oracle/product/18.0.0/dbhome_1 \
  && ./runInstaller -silent -waitForCompletion -responsefile /home/oracle/bin/db.rsp -ignorePrereqFailure || echo "Installer warnings..."

# Switch back to root to run the root.sh script
#
USER	root
RUN /u01/app/oraInventory/orainstRoot.sh \
  && /u01/app/oracle/product/18.0.0/dbhome_1/root.sh -silent \
  && cd ~

# Switch back to Oracle user
#
USER oracle
WORKDIR	/home/oracle

# set current environment
#
ENV ORACLE_BASE=/u01/app/oracle
ENV ORACLE_HOME=/u01/app/oracle/product/18.0.0/dbhome_1
ENV PATH=/u01/app/oracle/product/18.0.0/dbhome_1/bin:/u01/app/oracle/product/18.0.0/dbhome_1/OPatch:$PATH
ENV NLS_DATE_FORMAT="dd/mm/yyyy:hh24:mi:ss"

#####
# If you want to include a database in the image - which can be useful for testing, you can uncomment below to create DEV 
# database with one PDB called PDBX
#####
# RUN cd /home/oracle/bin/ \
#   && ./create-db.sh -d DEV -c Y -p PDBX -o Y -e Y 

# set entrypoint and run default bash command
#
CMD ["/bin/bash"]
