FROM ubuntu:24.04

# Install dependencies
RUN apt-get update && apt-get install -y cm-super cpanminus curl dvipng dvisvgm gcc git imagemagick \
    libarchive-zip-perl libarray-utils-perl libcrypt-jwt-perl libcryptx-perl \
    libdata-dump-perl libdata-structure-util-perl libdatetime-perl libemail-stuffer-perl \
    libexception-class-perl libfile-copy-recursive-perl libfile-find-rule-perl \
    libfile-sharedir-install-perl libfuture-asyncawait-perl libgd-barcode-perl libgd-perl \
    libhttp-async-perl libiterator-perl libiterator-util-perl libcpanel-json-xs-perl \
    liblocale-maketext-lexicon-perl libmath-random-secure-perl libmime-base32-perl \
    libminion-perl libminion-backend-sqlite-perl libmojolicious-perl \
    libmojolicious-plugin-renderfile-perl libnet-ip-perl libnet-ldap-perl \
    libnet-oauth-perl libossp-uuid-perl libpandoc-wrapper-perl libpath-class-perl \
    libphp-serialization-perl libpod-wsdl-perl libsoap-lite-perl libsql-abstract-perl \
    libstring-shellquote-perl libsvg-perl libtext-csv-perl libtimedate-perl \
    libuniversal-can-perl libuniversal-isa-perl libuuid-tiny-perl libxml-libxml-perl \
    libxml-parser-easytree-perl libxml-parser-perl libxml-writer-perl libyaml-libyaml-perl \
    make netpbm openssh-server perltidy preview-latex-style texlive texlive-lang-arabic \
    texlive-latex-extra texlive-science texlive-xetex unzip


# Install Perl dependencies
RUN yes | cpanm --notest Archive::Zip::SimpleZip

# Install mariadb server
RUN apt-get install -y mariadb-server libmariadb3 libmariadb-dev libdevel-checklib-perl
RUN cpanm --notest DBD::MariaDB

# Install WebWork2
RUN mkdir /opt/webwork
WORKDIR /opt/webwork
RUN mkdir /opt/webwork/courses /opt/webwork/libraries
RUN git clone https://github.com/openwebwork/webwork2.git
RUN git clone https://github.com/openwebwork/pg.git
WORKDIR /opt/webwork/libraries
RUN git clone https://github.com/openwebwork/webwork-open-problem-library.git
RUN cp /opt/webwork/webwork2/courses.dist/*.lst /opt/webwork/courses/
WORKDIR /opt/webwork/webwork2/courses.dist
RUN rsync -a modelCourse /opt/webwork/courses
RUN chmod -R u+rwX,go+rX /opt/webwork/pg
RUN chmod -R u+rwX,go+rX /opt/webwork/webwork2
WORKDIR /opt/webwork/webwork2/
RUN chgrp -R www-data DATA /opt/webwork/courses/ /opt/webwork/webwork2/htdocs/tmp /opt/webwork/webwork2/logs /opt/webwork/webwork2/tmp
WORKDIR /opt/webwork/webwork2
RUN chmod -R g+w DATA /opt/webwork/courses/ htdocs/tmp logs tmp

# Install Node and JS Libraries
WORKDIR /tmp/
RUN mkdir /tmp/node
RUN curl -sL https://deb.nodesource.com/setup_16.x -o nodesource_setup.sh
RUN bash nodesource_setup.sh
RUN apt-get install -y nodejs
WORKDIR /opt/webwork/webwork2/htdocs
RUN npm ci
WORKDIR /opt/webwork/pg/htdocs/
RUN npm ci

# System Patches
RUN patch -p1 -d / < /opt/webwork/webwork2/docker-config/pgfsys-dvisvmg-bbox-fix.patch


# System config
WORKDIR /opt/webwork/webwork2/conf
COPY ./site.conf /opt/webwork/webwork2/conf/site.conf 
RUN cp localOverrides.conf.dist localOverrides.conf
COPY ./mojolicious.conf /opt/webwork/webwork2/conf/webwork2.mojolicious.yml
COPY ./webwork2.service /opt/webwork/webwork2/conf/webwork2.service
RUN cp /opt/webwork/webwork2/htdocs/index.dist.html /opt/webwork/webwork2/htdocs/index.html
RUN cp webwork2.service /etc/systemd/system/webwork2.service
RUN cpanm --notest Mojolicious::Plugin::SetUserGroup
RUN mkdir /run/webwork2 &&  touch /run/webwork2/webwork2.pid


EXPOSE 8080
ENTRYPOINT ["hypnotoad", "-f", "/opt/webwork/webwork2/bin/webwork2"]
