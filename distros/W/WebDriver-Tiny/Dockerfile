FROM perl:5.28

RUN cpanm -n Test::Deep URI

CMD ["prove", "-lv", "xt"]
