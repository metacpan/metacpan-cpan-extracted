FROM preaction/yancy:latest-sqlite

# First install prereqs, so this can be cached
RUN mkdir /zapp
COPY ./cpanfile /zapp/cpanfile
RUN cpanm --installdeps --notest /zapp

# Then install the rest of Zapp
COPY ./ /zapp/
RUN cpanm --notest -v /zapp \
    && rm -rf /zapp

# XXX: Create all-in-one process
CMD [ "./myapp.pl", "daemon" ]
