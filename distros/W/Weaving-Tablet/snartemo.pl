#!/usr/local/bin/perl
use warnings;
use strict;
use Weaving::Tablet::Tk;

use Getopt::Euclid;

my $pattern;
my %args;
$args{is_twill} = exists $ARGV{-t};

if (exists $ARGV{-i})
{
    $pattern = Weaving::Tablet::Tk->new_pattern(file => $ARGV{-i}, %args);
}
else
{
    $pattern = Weaving::Tablet::Tk->new_pattern(cards => $ARGV{-c}, rows => $ARGV{-r}, %args);
}
Tk::MainLoop();

__END__

=head1 OPTIONS

=over 4

=item -i <file>

=for Euclid:
    file.type: readable

The input pattern file to work with. 

=item -c[ards] <number>

=for Euclid:
    number.type: integer
    number.default: 20

The number of cards to generate if an input file is not given. Defaults to 20.

=item -r[ows] <number>

=for Euclid:
    number.type: integer
    number.default: 10

The number of turns to generate if an input file is not given. Defaults to 10.

=item -t[will]

Create or interpret the pattern as a 3/1 twill/repp pattern.

=back

