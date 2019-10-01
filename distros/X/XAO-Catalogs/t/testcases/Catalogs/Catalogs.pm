package testcases::Catalogs::Catalogs;
use strict;
use XAO::Objects;
use Error qw(:try);

use base qw(testcases::Catalogs::base);

sub test_everything {
    my $self=shift;

    my $cobj=XAO::Objects->new(objname => 'Catalogs');
    $self->assert(ref($cobj),
                  "Can't load Catalogs object");

     ##
     # Building structure
     #
     my $structure=$cobj->data_structure;
     $self->assert(ref($structure) eq 'HASH',
                   "No database structure returned");

    my $errstr;
    try {
        $cobj->build_structure;
    }
    otherwise {
        my $e=shift;
        $errstr="Problem building the structure ($e)";
    };

    $self->assert(!$errstr,
                  $errstr);
}

1;
