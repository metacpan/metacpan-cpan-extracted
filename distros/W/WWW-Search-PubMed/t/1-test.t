#!/usr/bin/perl

use lib 'lib';
use WWW::Search;
use Test::More	tests => 4;

my $s	= new WWW::Search('PubMed');
isa_ok( $s, 'WWW::Search' );

$s->native_query('ACGT');

my $r = $s->next_result();
ok( $r->title, 'Got title. Assuming everything is ok ;)' );

my $pmid	= $r->pmid;
like( $pmid, qr/^\d+$/, 'Got pmid' );

my $abst	= $r->abstract;
ok( length($abst), 'Got abstract' );
