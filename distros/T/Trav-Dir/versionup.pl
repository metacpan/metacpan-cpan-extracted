#!/home/ben/software/install/bin/perl

# The CPAN perl-reversion script seems to be making a muddle of things
# sometimes, and it doesn't edit Changes, so I've made my own script.

use Z;
use Perl::Build 'versionup';
use Deploy 'make_date';

my $newversion = '0.02';
my $version = '0.01';

my @pmfiles = qw!
    lib/Trav/Dir.pm
!;
versionup ($Bin, \@pmfiles, $version, $newversion);

my $date = make_date ('-');
my $changes = "$Bin/Changes";
my $text = read_text ($changes);
if ($text =~ s/(\Q$version\E|\Q$newversion\E) ([0-9-]+)/$newversion $date/) {
    write_text ($changes, $text);
}
else {
    warn "$changes failed";
}


