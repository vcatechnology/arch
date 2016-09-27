FROM vcatechnology/base-archlinux:latest
MAINTAINER VCA Technology <developers@vcatechnology.com>

RUN pacman --noconfirm -Syyu && \
  pacman-db-upgrade && \
  pacman --noconfirm -S reflector rsync && \
  cp -vf /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.backup && \
  reflector -l 200 -p https --sort rate --save /etc/pacman.d/mirrorlist

# remove reflector
RUN pacman -Rsn --noconfirm reflector python rsync

# update system
RUN pacman -Su --noconfirm

# update db
RUN pacman-db-upgrade

# remove orphaned packages
RUN if [ ! -z "$(pacman -Qtdq)" ]; then \
    pacman --noconfirm -Rns $(pacman -Qtdq) ; \
  fi

# clear pacman caches
RUN pacman --noconfirm -Scc

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
