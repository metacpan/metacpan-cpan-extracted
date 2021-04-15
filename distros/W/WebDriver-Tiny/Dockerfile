FROM perl:5.32

WORKDIR /root

RUN cpanm -n Test::Deep URI

CMD ["prove", "-lv", "xt"]
