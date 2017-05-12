use Test;
use XML::Essex;
use strict;

my $has_indenter = eval "require XML::Filter::DataIndenter";

my $count;
my $e;
my $out;
my @out;

my @tests = (
(
    map {
        my $i = $_;
        (
            sub {
                read_from \"<a><b/></a>";
                write_to  \$out;
                put get;
                ok isa "set_document_locator";
            },

            sub {
                on "b" => sub { ++$count };
                $e = get "end-document::*";
                ok isa "end_document";
            },

            sub {
                ok $count, $i;
            },

            sub {
                put $e;
                ok 1;
            },

        );
    } (1..2)
),

sub {
    return skip "need XML::Filter::DataIndenter", 1 unless $has_indenter;
    read_from \"<a><b/></a>";
    write_to  \$out;
    push_output_filters "XML::Filter::DataIndenter";
    $out = undef;

    put get "end-document::*";

    ok $out, qr/<a\s*>(?:$)\s+<b/m;
},

sub {
    read_from \"<a><b/></a>";

    @out = ();

    on '/' => [ 'hash()' => sub { push @out, xvalue } ];

    parse_doc;

    ok int @out, 1;
},

sub { ok ref $out[0], "HASH" },

);

plan tests => 0+@tests;

$_->() for @tests;
