FROM aelsnz/oraclelinux:oel7

## Using aelsnz/oraclelinux:oel7 image which include all prerequisites, oracle user and directory structure

USER root

# Expose Oracle and SSH Ports 
#
EXPOSE 22 1521

# Copy software and response files into /install
#
COPY	software/oracle-database-12201-linux-x86-64.zip /install/
COPY	scripts/db_install.rsp /home/oracle/bin/
COPY	scripts/manage-db.sh /home/oracle/bin/
COPY	scripts/create-db.sh /home/oracle/bin/

# make sure oracle user own /install
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
ENV ORACLE_HOME=/u01/app/oracle/product/12.2.0.1/dbhome_1
ENV PATH=/u01/app/oracle/product/12.2.0.1/dbhome_1/bin:/u01/app/oracle/product/12.2.0.1/dbhome_1/OPatch:$PATH
ENV NLS_DATE_FORMAT="dd/mm/yyyy:hh24:mi:ss"

# Unzip software
RUN	unzip oracle-database-12201-linux-x86-64.zip \
  && rm -rf oracle-database-12201-linux-x86-64.zip 

USER root

# Temporary change to fix - java null pointer exception during silent install
RUN echo "inventory_loc=/u01/app/oraInventory" >> /etc/oraInst.loc \
  && echo "inst_group=oinstall" >> /etc/oraInst.loc

USER oracle
WORKDIR /install

# Install Oracle Software
# 
RUN /install/database/runInstaller -silent -force -waitforcompletion -responsefile /home/oracle/bin/db_install.rsp -ignoresysprereqs -ignoreprereq

# Switch back to root
#
# removed - /u01/app/oraInventory/orainstRoot.sh  du to updating /etc/oraInst.loc above
#
USER	root
RUN /u01/app/oracle/product/12.2.0.1/dbhome_1/root.sh -silent \
  && rm -rf /install/database 

# Switch back to Oracle user
#
USER oracle
WORKDIR	/home/oracle

# set current environment
#
ENV ORACLE_BASE=/u01/app/oracle
ENV ORACLE_HOME=/u01/app/oracle/product/12.2.0.1/dbhome_1
ENV PATH=/u01/app/oracle/product/12.2.0.1/dbhome_1/bin:/u01/app/oracle/product/12.2.0.1/dbhome_1/OPatch:$PATH
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
