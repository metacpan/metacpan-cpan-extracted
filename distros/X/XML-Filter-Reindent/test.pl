# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'
 
use Test;
use XML::Filter::Reindent;
use strict;
 
my $expected = "result from end_document";
 
my $r;
 
my $output;
 
sub start_document{ $output = ""                  }
sub start_element { $output .= "<$_[1]->{Name}>"  }
sub end_element   { $output .= "</$_[1]->{Name}>" }
sub characters    { $output .= $_[1]->{Data}      }
sub end_document  { return $expected              }
 
my @tests = (
sub { ok 1 },
sub {
    $r = XML::Filter::Reindent->new;
    $r->start_document({});
    ok ! defined $r->end_document({}), 1, "undefined result from end_document";
},
sub {
    $output = "ouch";
    $r = XML::Filter::Reindent->new( Handler => "main" );
    $r->start_document({});
    ok $r->end_document({}), $expected;
},
sub {
    ok $output, "";
},
sub {
    $r->start_document({});
    $r->start_element({ Name => "foo" });
    $r->start_element({ Name => "bar" });
    $r->end_element({   Name => "bar" });
    $r->end_element({   Name => "foo" });
    ok $r->end_document({}), $expected;
},
sub {
    ok $output =~ m{<foo>\n\s+<bar></bar>\n</foo>};
},
);
 
plan tests => scalar @tests;
 
$_->() for @tests;
