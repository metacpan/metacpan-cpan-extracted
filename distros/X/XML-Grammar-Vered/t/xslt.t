#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 5;

use File::Spec;

use File::Temp qw(tempfile);

use Test::XML::Ordered qw(is_xml_ordered);

use XML::Grammar::Vered;

my @is_xml_common = ( validation => 0, load_ext_dtd => 0, no_network => 1 );

sub my_is_xml
{
    local $Test::Builder::Level = $Test::Builder::Level + 1;

    my ( $got, $expected, $blurb ) = @_;

    return is_xml_ordered(
        [ @{$got},      @is_xml_common, ],
        [ @{$expected}, @is_xml_common, ],
        {}, $blurb,
    );
}

sub _utf8_slurp
{
    my $filename = shift;

    open my $in, '<', $filename
        or die "Cannot open '$filename' for slurping - $!";

    binmode $in, ':encoding(utf8)';

    local $/;
    my $contents = <$in>;

    close($in);

    return $contents;
}

# TEST:$c=0;
sub test_file
{
    my $args = shift;

    my $input_fn      = $args->{input_fn};
    my $output_fn     = $args->{output_fn};
    my $output_format = $args->{output_format};

    my $xslt = XML::Grammar::Vered->new(
        data_dir => File::Spec->catdir( File::Spec->curdir(), "extradata", ), );

    {
        my $final_source = $xslt->perform_xslt_translation(
            {
                output_format => $output_format,
                source        => { file => $input_fn, },
                output        => "string",
            }
        );

        my $xml_source = _utf8_slurp($output_fn);

        # TEST:$c++;
        my_is_xml(
            [ string => $final_source, ],
            [ string => $xml_source, ],
"'$input_fn' generated good output on source/input_filename - output - string"
        );
    }

    {
        my $final_source = $xslt->perform_xslt_translation(
            {
                output_format => $output_format,
                source        => { string_ref => \( _utf8_slurp($input_fn) ) },
                output        => "string",
            }
        );

        my $xml_source = _utf8_slurp($output_fn);

        # TEST:$c++;
        my_is_xml(
            [ string => $final_source, ],
            [ string => $xml_source, ],
"'$input_fn' generated good output on source/string_ref - output - string"
        );
    }

    {
        my $final_dom = $xslt->perform_xslt_translation(
            {
                output_format => $output_format,
                source        => { string_ref => \( _utf8_slurp($input_fn) ) },
                output        => "dom",
            }
        );

        my $xml_source = _utf8_slurp($output_fn);

        # TEST:$c++;
        my_is_xml(
            [ string => $final_dom->toString(), ],
            [ string => $xml_source, ],
"'$input_fn' generated good output on source/string_ref - output - dom"
        );
    }

    {
        my ( $fh, $filename ) = tempfile();

        $xslt->perform_xslt_translation(
            {
                output_format => $output_format,
                source        => { string_ref => \( _utf8_slurp($input_fn) ) },
                output        => { file       => $filename, },
            }
        );

        my $xml_source   = _utf8_slurp($output_fn);
        my $final_source = _utf8_slurp($filename);

        # TEST:$c++;
        my_is_xml(
            [ string => $final_source, ],
            [ string => $xml_source, ],
"'$input_fn' generated good output on source/string_ref - output/file"
        );
    }

    {
        my ( $fh, $filename ) = tempfile();

        binmode $fh, ':encoding(utf8)';

        $xslt->perform_xslt_translation(
            {
                output_format => $output_format,
                source        => { string_ref => \( _utf8_slurp($input_fn) ) },
                output        => { fh         => $fh, },
            }
        );

        close($fh);

        my $xml_source   = _utf8_slurp($output_fn);
        my $final_source = _utf8_slurp($filename);

        # TEST:$c++;
        my_is_xml(
            [ string => $final_source, ],
            [ string => $xml_source, ],
            "'$input_fn' generated good output on source/string_ref - output/fh"
        );
    }
    return;
}

# TEST:$test_file=$c;

# TEST*$test_file
test_file(
    {
        output_format => 'docbook',
        input_fn      => File::Spec->catfile(
            File::Spec->curdir(), "t", "data", "system-tests-1", "input-xml",
            "perl-begin-page.xml-grammar-vered.xml",
        ),
        output_fn => File::Spec->catfile(
            File::Spec->curdir(), "t",
            "data",               "system-tests-1",
            "expected-docbook",   "perl-begin-page.docbook.xml",
        ),
    }
);
