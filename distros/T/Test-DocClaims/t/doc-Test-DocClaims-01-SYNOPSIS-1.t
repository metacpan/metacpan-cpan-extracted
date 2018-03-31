#!perl

use strict;
use warnings;
use Test::More tests => 2;

use lib "t/lib";
use TestTester;

BEGIN { use_ok('Test::DocClaims'); }

=head1 NAME

Test::DocClaims - Help assure documentation claims are tested

=head1 SYNOPSIS

To automatically scan for source files containing POD, find the
corresponding tests and verify that those tests match the POD, create the
file t/doc_claims.t with the following lines:

=cut

subtest 'all_doc_claims works' => sub {

=begin DC_CODE

=cut

  use Test::More;
  eval "use Test::DocClaims";
  plan skip_all => "Test::DocClaims not found" if $@;
  all_doc_claims();

=end DC_CODE

=cut

# end of subtest
};

