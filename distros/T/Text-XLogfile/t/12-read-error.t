use strict;
use warnings;
use Test::More tests => 1;
use Text::XLogfile ':all';
use File::Temp qw/tempfile/;

my $xlogfile = << "XLOGFILE";
name=Lawrence:role=Computer Scientist:gender=Mal
name=Catherine:roleDeath Queen:gender=Fem
name=Fred:role=Zombie:gender=Mal
XLOGFILE

my @xlogfile = (
    { name => 'Lawrence',  role => 'Computer Scientist', gender => 'Mal' },
    { },
    { name => 'Fred',      role => 'Zombie',             gender => 'Mal' },
);

my ($fh, $filename) = tempfile(UNLINK => 1);

print {$fh} $xlogfile;
close $fh;

my @people = read_xlogfile($filename);
is_deeply(\@people, \@xlogfile, "read_xlogfile appears to work even with an erroneous entry");

