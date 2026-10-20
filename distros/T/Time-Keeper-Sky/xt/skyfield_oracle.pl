package SkyfieldOracle;

# Shared by the two Skyfield author tests: runs xt/skyfield.py on a list of
# jobs and returns its answers.

use 5.010;
use strict;
use warnings;
use File::Spec;
use File::Temp qw(tempfile);

sub python { $ENV{TKS_SKYFIELD} }
sub data   { $ENV{TKS_SKYFIELD_DATA} }

sub usable {
    return 'set TKS_SKYFIELD to a python with skyfield, and TKS_SKYFIELD_DATA to a directory holding de421.bsp'
        unless python() && data();
    return 'that python has no skyfield' if system(python() . " -I -c 'import skyfield' 2>/dev/null") != 0;
    return "no de421.bsp in " . data() unless -e File::Spec->catfile(data(), 'de421.bsp');
    return '';
}

sub ask {
    my ($jobs) = @_;
    my ($fh, $file) = tempfile(UNLINK => 1);
    print $fh encode($jobs);
    close $fh;
    my $script = File::Spec->catfile('xt', 'skyfield.py');
    my $json = `"${\ python() }" -I "$script" "${\ data() }" < "$file"`;
    die "skyfield.py failed\n" if $? || !length $json;
    return decode($json);
}

# The jobs are flat lists of numbers and short words, and the answers lists
# of lists of numbers or [word, number]: core JSON::PP does both.
sub encode { require JSON::PP; JSON::PP->new->canonical->encode($_[0]) }
sub decode { require JSON::PP; JSON::PP->new->decode($_[0]) }

1;
