#!/use/bin/env perl -w

use strict;
use Test::More;
BEGIN {
	my $add = 0;
	eval {require Test::NoWarnings;Test::NoWarnings->import; ++$add; 1 }
		or diag "Test::NoWarnings missed, skipping no warnings test";
	plan tests => 13 + $add;
}
use lib::abs '../lib';
use XML::Parser;
use XML::Parser::Style::ETree;
no warnings 'once';

our (%FH,%FA,%TX);
*FH  = \%XML::Parser::Style::ETree::FORCE_HASH;
*FA  = \%XML::Parser::Style::ETree::FORCE_ARRAY;
*TX  = \%XML::Parser::Style::ETree::TEXT;

our $parser = XML::Parser->new( Style => 'ETree' );

( my $exe = $0 ) =~ s{[^/\\]+$}{test-1.pl};do $exe;
