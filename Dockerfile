FROM vcatechnology/base-archlinux:latest
MAINTAINER VCA Technology <developers@vcatechnology.com>

# Optimise the mirror list
RUN pacman --noconfirm -Syyu && \
  pacman-db-upgrade && \
  pacman --noconfirm -S reflector rsync && \
  reflector -l 200 -p https --sort rate --save /etc/pacman.d/mirrorlist && \
  pacman -Rsn --noconfirm reflector python rsync

# Update system
RUN pacman -Su --noconfirm

# Update db
RUN pacman-db-upgrade

# Remove orphaned packages
RUN if [ ! -z "$(pacman -Qtdq)" ]; then \
    pacman --noconfirm -Rns $(pacman -Qtdq); \
  fi

# Clear pacman caches
RUN pacman --noconfirm -Scc

# Optimise pacman database
RUN pacman-optimize  --nocolor

# Housekeeping
RUN rm -f /etc/pacman.d/mirrorlist.pacnew
RUN if [ -f /etc/systemd/coredump.conf.pacnew ]; then \
    mv -f /etc/systemd/coredump.conf.pacnew /etc/systemd/coredump.conf ; \
  fi
RUN if [ -f /etc/locale.gen.pacnew ];  then \
    mv -f /etc/locale.gen.pacnew /etc/locale.gen ; \
  fi

# Generate locales
RUN cat /etc/locale.gen | expand | sed 's/^# .*$//g' | sed 's/^#$//g' | egrep -v '^$' | sed 's/^#//g' > /tmp/locale.gen \
  && mv -f /tmp/locale.gen /etc/locale.gen \
  && locale-gen
ENV LANG=en_GB.utf8

# Create install script
RUN touch                                            /usr/local/bin/vca-install-package && \
  chmod +x                                           /usr/local/bin/vca-install-package && \
  echo '#! /bin/sh'                               >> /usr/local/bin/vca-install-package && \
  echo 'set -e'                                   >> /usr/local/bin/vca-install-package && \
  echo 'pacman --noprogressbar --noconfirm -S $@' >> /usr/local/bin/vca-install-package && \
  echo 'pacman --noprogressbar --noconfirm -Scc'  >> /usr/local/bin/vca-install-package && \
  echo 'pacman-optimize --nocolor'                >> /usr/local/bin/vca-install-package

# Create uninstall script
RUN touch                                                              /usr/local/bin/vca-uninstall-package && \
  chmod +x                                                             /usr/local/bin/vca-uninstall-package && \
  echo '#! /bin/sh'                                                 >> /usr/local/bin/vca-uninstall-package && \
  echo 'set -e'                                                     >> /usr/local/bin/vca-uninstall-package && \
  echo 'pacman --noprogressbar -Rsn --noconfirm $@'                 >> /usr/local/bin/vca-uninstall-package && \
  echo 'if [ ! -z "$(pacman -Qtdq)" ]; then'                        >> /usr/local/bin/vca-uninstall-package && \
  echo '  pacman --noprogressbar --noconfirm -Rns $(pacman -Qtdq);' >> /usr/local/bin/vca-uninstall-package && \
  echo 'fi'                                                         >> /usr/local/bin/vca-uninstall-package && \
  echo 'pacman-optimise --nocolor'                                  >> /usr/local/bin/vca-uninstall-package
