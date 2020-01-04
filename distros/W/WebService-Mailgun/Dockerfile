FROM perl:5.24.0

WORKDIR /work/p5-webservice-mailgun
COPY cpanfile /work/p5-webservice-mailgun

RUN cpanm --with-develop --installdeps .

CMD cp -r . /mylib && cd /mylib && minil build && minil test
