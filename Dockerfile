FROM centos:7.9.2009

LABEL org.opencontainers.image.source="https://github.com/giovtorres/docker-centos7-slurm" \
      org.opencontainers.image.title="docker-centos7-slurm" \
      org.opencontainers.image.description="Slurm All-in-one Docker container on CentOS 7" \
      org.label-schema.docker.cmd="docker run -it -h slurmctl giovtorres/docker-centos7-slurm:latest" \
      maintainer="Giovanni Torres"

ENV PATH "/usr/sbin:/usr/bin:/sbin:/bin:/usr/local/bin"

EXPOSE 6817 6818 6819 6820 3306

RUN set -ex \
    && yum -y update \
    && yum -y install https://repo.ius.io/ius-release-el7.rpm \
    && yum install -y \
        docker \
        gcc \
        gcc-c++ \
        git \
        glibc-devel \
        http-parser-devel \
        json-c-devel \
        make \
        munge \
        munge-devel \
        mariadb-server \
        mariadb-devel \
        pam-devel \
        perl-Switch \
        perl-core \
        psmisc \
        python3 \
        readline-devel \
        rpm-build \
        supervisor \
        tmux \
        wget \
        vim

# Compile, build and install Slurm from Release page
RUN wget https://download.schedmd.com/slurm/slurm-23.02.5.tar.bz2 \
    && MAKEFLAGS="-j 4" rpmbuild -ta slurm-*.tar.bz2 --with mysql --with slurmrestd \
    && rpm --install /root/rpmbuild/RPMS/x86_64/slurm-* \
    && groupadd -r slurm  \
    && useradd -r -g slurm slurm \
    && mkdir -p /etc/sysconfig/slurm \
        /var/spool/slurmd \
        /var/spool/slurmctld \
        /var/log/slurm \
        /var/run/slurm \
    && chown -R slurm:slurm /var/spool/slurmd \
        /var/spool/slurmctld \
        /var/log/slurm \
        /var/run/slurm \
    && /sbin/create-munge-key

# Mark externally mounted volumes
VOLUME ["/var/lib/mysql", "/var/lib/slurmd", "/var/spool/slurm", "/var/log/slurm"]

COPY --chown=slurm files/slurm/slurm.conf files/slurm/gres.conf files/slurm/slurmdbd.conf \
     files/slurm/cgroup.conf /etc/slurm/
COPY files/supervisord.conf /etc/

RUN chmod 0600 /etc/slurm/slurmdbd.conf

COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
CMD ["/bin/bash"]