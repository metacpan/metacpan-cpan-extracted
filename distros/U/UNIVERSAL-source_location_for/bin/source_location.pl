#!/usr/bin/env perl
use strict;
use warnings;
use lib 'lib';
use lib 't/lib';
use Term::ANSIColor qw(colored);
use UNIVERSAL::require;
use UNIVERSAL::source_location_for;
use Pod::Usage;
my ($class, $method) = @ARGV;
unless ($class && $method) {
    pod2usage;
}

$class->require or die $@;
my ($file, $line) = do {
    local $SIG{__WARN__} = sub {};
    $class->source_location_for($method)
};

unless (defined($file) && defined($line)) {
    print colored(qq|method "${class}::$method" is not found.|, 'red'), "\n";
    exit 1;
}

print colored('FILENAME ', 'green') .  "$file\n";
print colored('LINE     ', 'green') .  "$line\n";

=encoding utf-8

=head1 SYNOPSIS

  $ source_location.pl <Module> <method>

=cut
