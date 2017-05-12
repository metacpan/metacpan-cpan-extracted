#!/usr/bin/perl -w

use strict;
use lib::abs '../lib';
use XML::RPC::Fast;
use Test::More;
BEGIN {
	eval "use XML::RPC 0.8;1" or plan skip_all => "XML::RPC 0.8 required for testing compatibility";
	plan tests => 2;
}
use Test::NoWarnings;

my $r = XML::RPC->new();
my $hash = [
	{
		name => 'rec',
		entries => {
			name => 'ent',
			fields => [ a => 1 ]
		},
	}
];
my $xml = $r->create_call_xml(test => $hash);
my @in = $r->unparse_call( $r->{tpp}->parse($xml) );
my @f_in  = XML::RPC::Fast->new()->encoder->decode($xml);
is_deeply(\@in,\@f_in, 'args struct');
