use strict;
use warnings;

=head1 NAME

46-tester-synopsis.t - test the Test::Group::Tester synopsis code

=cut

use Test::Group::Tester;
use File::Slurp;

my $filename = $INC{"Test/Group/Tester.pm"};
my $source = read_file $filename;

my ($snip) = ($source =~
               m/=for tests "synopsis" begin(.*)=for tests "synopsis" end/s);
$snip =~ s/^  //mg; # indented heredoc terminator won't work.

eval $snip;
die $@ if $@;

