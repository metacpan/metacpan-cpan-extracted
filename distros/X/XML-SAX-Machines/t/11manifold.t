#!/usr/local/bin/perl -w

use strict;

use Test;
use XML::SAX::Machines qw( Pipeline Manifold );


my $m;

my $out;


my @tests = (
sub {
    $out = "";
    $m = Pipeline(
        Manifold(
            "XML::SAX::Base",
            "XML::SAX::Base",
        ),
        \$out,
    );
    ok $m->isa( "XML::SAX::Machine" );

#    $m->generate_description( Pipeline( "|xmllint --format -" ) ); warn "\n";
},

sub {
    $out = "";
#    $m->trace_all_parts;
#    Devel::TraceSAX::trace_SAX( $m, "Pipeline" );
    $m->parse_string( "<?xml version='1.0'?><?pi pi?><!--cmnt--><foo><bar /></foo><?pi2 pi2?><!--cmnt2-->" );
    ok 1;
},

sub {
    $out =~ m{<foo\s*><bar\s*/><bar\s*/></foo\s*>}
        ? ok 1
        : ok $out, "something like <foo><bar /><bar /></foo>" ;
},
);

plan tests => scalar @tests;

$_->() for @tests;
