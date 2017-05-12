use strict;
use warnings;
use Test::More tests => 2;
use Text::XLogfile ':all';
use File::Temp qw/tempfile/;

my @xlogfile = (
    { name => 'Lawrence',  role => 'Computer Scientist', gender => 'Mal' },
    { name => 'Catherine', role => 'Death Queen',        gender => 'Fem' },
    { name => 'Fred',      role => 'Zombie',             gender => 'Mal' },
);

# just need a temp filename
my ($fh, $filename) = tempfile(UNLINK => 1);
close $fh;

write_xlogfile(\@xlogfile, $filename);

{
    open my $handle, '<', $filename
        or BAIL_OUT("Unable to open '$filename' for reading: $!");

    my @people;
    while (<$handle>) {
        push @people, parse_xlogline($_);
    }

    is_deeply(\@people, \@xlogfile, "write_xlogfile appears to work 1/2");
}

{
    my @people = read_xlogfile($filename);
    is_deeply(\@people, \@xlogfile, "write_xlogfile appears to work 2/2");
}

