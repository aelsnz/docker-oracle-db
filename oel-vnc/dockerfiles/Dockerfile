FROM aelsnz/oraclelinux:oel7

USER root

# Add a font to fix installer text rendering - dejavu-*
# update - this was added to the main oraclelinux:oel7 image
#

# Expose Ports for oracle and SSH and VNC 
#
EXPOSE 22 5900

## Copy Fluxbox, x11vnc and a basic start script for vnc in the oracle user account
# this can be useful if you want to run the oracle installer via VNC or do something else that might require vnc.
COPY software/fluxbox-1.3.7.tar.gz /install/
COPY software/x11vnc-0.9.13-11.el7.x86_64.rpm /install/
COPY scripts/start-vnc.sh /home/oracle/bin/

## Install fluxbox
#
RUN cd /install \
    && tar xzf fluxbox*.tar.gz \
    && cd fluxbox-1.3.7 \
    && ./configure --prefix /usr/local/fluxbox \
    && make \
    && make install \
    && rm -rf fluxbox-1.3.7 \
    && sed -i '/background/d' /usr/local/fluxbox/share/fluxbox/styles/bloe/theme.cfg \
    && echo "background:                     mod" >> /usr/local/fluxbox/share/fluxbox/styles/bloe/theme.cfg \
    && echo "background.modX:                33" >> /usr/local/fluxbox/share/fluxbox/styles/bloe/theme.cfg \
    && echo "background.modY:                33" >> /usr/local/fluxbox/share/fluxbox/styles/bloe/theme.cfg \ 
    && echo "background.color:               black" >> /usr/local/fluxbox/share/fluxbox/styles/bloe/theme.cfg \ 
    && echo "background.colorTo:             grey15" >> /usr/local/fluxbox/share/fluxbox/styles/bloe/theme.cfg 

## Install x11vnc
#
RUN cd /install \
    && rpm -ivh x11vnc-0.9.13-11.el7.x86_64.rpm \
    && chown oracle:oinstall /home/oracle/bin/*.sh \
    && chmod u+x /home/oracle/bin/*.sh

## switch to oracle user and set vnc password
#
USER oracle
WORKDIR /home/oracle

## This is not ideal - ARGS can be used, but they are still visible.
# this is just an example, you could copy the passwd file into the image to have this more secure.
RUN mkdir ~/.vnc \
    && x11vnc -storepasswd Demo1234567 ~/.vnc/passwd 

ENV PATH=/home/oracle/bin:$PATH

## Specify Entrypoint - and default is to run bash shell
#
CMD ["/bin/bash"]



