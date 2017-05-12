use strict;

use File::Spec;
use File::Temp qw( tempdir );

use lib File::Spec->curdir, File::Spec->catdir( File::Spec->curdir, 't' );

use SharedTests;


my $dir = tempdir( CLEANUP => 1 );
my $filename = File::Spec->catfile( $dir, 'thesaurus.db' );

eval
{
    SharedTests::run_tests( class   => 'Thesaurus::BerkeleyDB',
                            require => 'BerkeleyDB',
                            p       => { filename => $filename,
                                         locking => 1,
                                       },
                          );
};

warn $@ if $@;
