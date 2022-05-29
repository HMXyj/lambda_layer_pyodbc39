#Dockerfile
FROM public.ecr.aws/lambda/python:3.9

ARG UNIXODBC_VERSION=2.3.9
WORKDIR /root

RUN yum -y update
RUN yum install -y gzip tar openssl-devel && yum groupinstall "Development Tools" -y

RUN curl ftp://ftp.unixodbc.org/pub/unixODBC/unixODBC-${UNIXODBC_VERSION}.tar.gz -O \
    && tar xzvf unixODBC-${UNIXODBC_VERSION}.tar.gz \
    && cd unixODBC-${UNIXODBC_VERSION} \
    && ./configure --sysconfdir=/opt/python --disable-gui --disable-drivers --enable-iconv --with-iconv-char-enc=UTF8 --with-iconv-ucode-enc=UTF16LE --prefix=/home \
    && make install \
    && cd .. \
    && mv /home/* . \
    && mv unixODBC-${UNIXODBC_VERSION} unixODBC-${UNIXODBC_VERSION}.tar.gz /tmp
    
RUN curl https://packages.microsoft.com/config/rhel/6/prod.repo > /etc/yum.repos.d/mssql-release.repo \
    && yum -y install freetds e2fsprogs openssl \
    && ACCEPT_EULA=Y yum -y install msodbcsql mssql-tools --disablerepo=amzn*
RUN export CFLAGS="-I/root/include" \
    && export LDFLAGS="-L/root/lib" \
    && pip install pyodbc adodbapi pyDes --upgrade -t .
RUN cp -r /opt/microsoft/msodbcsql .
RUN echo $'[ODBC Driver 17 for SQL Server]\nDriver = ODBC Driver 17 for SQL Server\nDescription = My ODBC Driver 17 for SQL Server\nTrace = No' > /root/odbc.ini
RUN echo $'[ODBC Driver 17 for SQL Server]\nDescription = Microsoft ODBC Driver 17 for SQL Server\nDriver = /opt/microsoft/msodbcsql17/lib64/libmsodbcsql-17.7.so.2.1\nUsageCount = 1' > /root/odbcinst.ini
RUN mkdir -p /opt/python \
    && cp -r /root/* /opt/python \
    && mv /opt/python/lib /opt \
    && mv /opt/python/bin /opt \
    && cd /opt \
    && zip -r /pyodbc.zip .
