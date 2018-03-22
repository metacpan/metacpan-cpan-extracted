# install needed packages
    cpanm --installdeps --with-develop .

# run all test with prove
    prove -rl -j9

## helper for development
Run first all the tests and perlcritic on severity level 1(brutal) for t and lib

    prove -rl -j9; perlcritic -1 t lib/