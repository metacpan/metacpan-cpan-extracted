FROM perl:5.30

RUN cpanm -n Test::Deep URI

CMD ["prove", "-lv", "xt"]
