FROM perl:5.26

RUN cpanm -n Test::Deep URI

CMD ["prove", "-lv", "xt"]
