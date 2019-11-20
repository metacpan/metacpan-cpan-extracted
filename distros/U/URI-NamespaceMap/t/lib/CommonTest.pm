package CommonTest;

use strict;
use warnings;
use Test::More;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(test_to_ns);
use Types::Namespace qw( to_Namespace );

sub test_to_ns {
  my $uri = shift;
  my $nsiri = to_Namespace($uri);
  isa_ok($nsiri, 'URI::Namespace');
  is($nsiri->as_string, 'http://www.example.net/', 'Correct string URI from ' . ref($uri));
  ok($nsiri->equals($uri), 'Is the same URI');
}

1;
