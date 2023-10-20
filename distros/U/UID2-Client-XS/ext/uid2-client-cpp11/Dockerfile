FROM ubuntu:22.04 as cpp-devtools
COPY --chmod=755 ./tools/install-ubuntu-devtools.sh .

RUN ./install-ubuntu-devtools.sh

FROM cpp-devtools
COPY ./tools/install-ubuntu-deps.sh .
RUN ./install-ubuntu-deps.sh
