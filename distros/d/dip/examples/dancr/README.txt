This is a simple Dancer web application used to demonstrate some
features of dip. The web application itself consists of these files:

    dancr.pl
    public/css/style.css
    schema.sql
    views/layouts/main.tt
    views/login.tt
    views/show_entries.tt

Then there is a test program that uses Plack::Test to do some simple
requests.

    test.pl

Finally we have a few simple dip scripts:

    count-new.dip       # Shows which objects are created
    dbi-prepare.dip     # Shows each DBI statement as it is prepared
    dump-requests.dip   # Dumps each server request
    request-quant.dip   # How long do requests take, grouped by URI?

To run the dip script, use a command like:

    dip -d -s dip/request-quant.dip test.pl 50

This means to run 50 iterations of the tests so request-quant.dip has
some data to work on. Defaults to 1 iteration.
