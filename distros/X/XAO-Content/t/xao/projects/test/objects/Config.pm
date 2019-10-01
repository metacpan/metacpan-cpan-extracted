package XAO::DO::Config;
use strict;
use XAO::Utils;
use XAO::SimpleHash;
use XAO::Objects;
use base XAO::Objects->load(objname => 'Config', baseobj => 1);

sub init {
    my $self=shift;

    my $webconfig=XAO::Objects->new(objname => 'Web::Config');

    my %d;
    open(F,'.config') ||
        throw $self "init - no .config found, run 'perl Makefile.PL'";
    local($/);
    my $t=<F>;
    close(F);
    eval $t;
    $@ && throw $self "init - error in .config file: $@";

    # There may not be a database connector. Tests will be restricted
    # to non-database in that case.
    #
    if($d{'test_dsn'} ne 'none') {
        my $fsconfig=XAO::Objects->new(
            objname => 'FS::Config',
            odb_args => {
                dsn                 => $d{'test_dsn'},
                user                => $d{'test_user'},
                password            => $d{'test_password'},
                empty_database      => 'confirm',
                check_consistency   => 1,
            },
        );

        $self->embed(
            fs => $fsconfig,
        );
    }

    return $self->SUPER::init();
}

1;
