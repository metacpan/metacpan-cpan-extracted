use strict;
use warnings;
use utf8;
use Test::More;
use Test::mysqld::DatadirDumper;
use File::Temp qw/tempdir/;
use File::Spec;

my $dir = tempdir( CLEANUP => 1 );
my $datadir = File::Spec->catdir($dir, 'd');

ok ! -d $datadir;
my $d = Test::mysqld::DatadirDumper->new(
    datadir  => $datadir,
    ddl_file => 't/data/ddl.sql',
    fixtures => ['t/data/item.yml'],
);
$d->dump;
ok -d $datadir;

done_testing;
