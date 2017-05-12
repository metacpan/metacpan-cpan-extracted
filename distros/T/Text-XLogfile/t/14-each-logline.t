use strict;
use warnings;
use Test::More tests => 3;
use Text::XLogfile ':all';
use File::Temp qw/tempfile/;

my $xlogfile = << "XLOGFILE";
name=Lawrence:role=Computer Scientist:gender=Mal
name=Catherine:role=Death Queen:gender=Fem
name=Fred:role=Zombie:gender=Mal
XLOGFILE

my @xlogfile = (
    { name => 'Lawrence',  role => 'Computer Scientist', gender => 'Mal' },
    { name => 'Catherine', role => 'Death Queen',        gender => 'Fem' },
    { name => 'Fred',      role => 'Zombie',             gender => 'Mal' },
);

my ($fh, $filename) = tempfile(UNLINK => 1);

print {$fh} $xlogfile;
close $fh;

my $lines_read = 0;
my @people_arg;
my @people_it;

each_xlogline($filename => sub {
    push @people_arg, shift;
    push @people_it, $_;
    ++$lines_read;
});

is_deeply(\@people_arg, \@xlogfile, "each_xlogline gets each xlogline as arg");
is_deeply(\@people_it,  \@xlogfile, "each_xlogline gets each xlogline as \$_");
is($lines_read, 3, "three xloglines");

