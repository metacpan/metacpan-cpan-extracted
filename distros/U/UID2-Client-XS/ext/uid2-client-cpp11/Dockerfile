FROM madduci/docker-cpp-env:latest
RUN apk add libressl-dev
RUN apk add gtest-dev
COPY . /uid2client
RUN rm -rf /uid2client/build; mkdir -p /uid2client/build; cd /uid2client/build; cmake .. && make && make test && make install
ENTRYPOINT ["/uid2client/build/app/example"]
