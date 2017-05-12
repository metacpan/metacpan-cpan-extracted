#!/usr/bin/perl

use strict;
use warnings;

use Test::XML tests => 13;

use File::Spec;
use XML::Grammar::ProductsSyndication;

sub get_files_list
{
    return
    (
    "001-empty-cat", # TEST
    "002-nested-cat", # TEST
    "0030-with-one-product", # TEST
    "0031-with-products", # TEST
    "004-products-with-creators", # TEST
    "005-refs", # TEST
    "006-xhtml", # TEST
    "007-xhtml-2", # TEST
    "008-xhtml-3", # TEST
    "009-set", # TEST
    "010-disabled-isbn", # TEST
    "011-appendtoc", # TEST
    "012-with-rellinks", # TEST
    );
}

my @xml_files = get_files_list();

foreach my $xml_file (@xml_files)
{
    my $p = XML::Grammar::ProductsSyndication->new(
        {
            'source' =>
            {
                'file' => 
                    File::Spec->catfile(
                        File::Spec->curdir(),
                        "t", "data", "valid-xmls", "$xml_file.xml"
                    ),
            },
            'data_dir' => File::Spec->catdir(
                File::Spec->curdir(), "extradata"
            ),
        }
    );
    my $got_xml = $p->transform_into_html({ 'output' => "string" });
    is_xml ($got_xml, load_xml($xml_file),
        "Testing for XML Equivalency of file '$xml_file'");
}

sub load_xml
{
    my $xml_file = shift;
    my $path = 
        File::Spec->catfile(
            File::Spec->curdir(),
            "t", "data", "output-htmls", "$xml_file.html"
        );
   
    open my $in, "<", $path;
    my $contents;
    {
        local $/;
        $contents = <$in>;
    }
    close($in);
    return $contents;
}

sub get_expected_fn
{
    my $file = shift;
    if ($file =~ m{^(?:\./)?valid-xmls/(.*)\.xml$})
    {
        return "./outputs/$1.html";
    }
    else
    {
        die "Unknown filename";
    }
}
