use strict;
use Test::More 'no_plan';

use FindBin;
use XML::LibXML;
use XML::Liberal;

binmode Test::More->builder->$_, ':utf8'
    for qw( output failure_output todo_output );

my $data_dir = "$FindBin::Bin/bad";
my $good_dir = "$FindBin::Bin/good";

opendir D, $data_dir;
for my $f (readdir D) {
    next unless $f =~ /\.xml$/;

    my $parser = XML::LibXML->new;
    eval { $parser->parse_file("$data_dir/$f") };
    next if ($f =~/^MAYBE/ && !$@);
    ok $@, $@;

    open my $fh, "$data_dir/$f" or die $!;
    my $xml = do { local $/; <$fh> };

    my $liberal = XML::Liberal->new('LibXML');
    my $doc = eval { $liberal->parse_string($xml) };
    is $@, '', "$data_dir/$f";
    isa_ok $doc, 'XML::LibXML::Document', "created DOM node with $data_dir/$f";

    if ((my $good = $f) =~ s/^BAD-/GOOD-/) {
        my $good_doc = XML::LibXML->new->parse_file("$good_dir/$good");
        is $doc->toString, $good_doc->toString,
            "$data_dir/$f fixed to same as $good_dir/$good";
    }
}
