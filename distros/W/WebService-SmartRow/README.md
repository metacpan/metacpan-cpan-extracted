# WebService-SmartRow
Perl module to access data from SmartRow workout dataa.

## Development setup.

### Pre-requisites
* Git
* Perl
* Dist::Zilla

With perl installed; ensure you have Dist::Zilla installed (`cpanm Dist::Zilla` or equivalent).

Then install author dependencies with:

`dzil authordeps --missing | cpanm` 

then module dependencies with:

`dzil listdeps --develop | cpanm`

Run the tests:

`dzil test`


## XT Testing against the real API

The `xt` folder holds tests that talk to the real API, for them to work you must:

* Have a valid account on https://smartrow.fit
* set the `SMARTROW_USERNAME` environment variable
* set the `SMARTROW_PASSWORD` environment variable

(I suggest using https://direnv.net/ via a `.envrc` file)
