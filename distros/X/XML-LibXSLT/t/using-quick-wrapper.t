
use strict;
use warnings;
use autodie;

use Test::More tests => 20;

use XML::LibXML         ();
use XML::LibXSLT        ();
use XML::LibXSLT::Quick ();

sub _raw_slurp
{
    my $filename = shift;

    open my $in, '<:raw', $filename;

    local $/;
    my $contents = <$in>;

    close($in);

    return $contents;
}

sub _utf8_slurp
{
    my $filename = shift;

    open my $in, '<:encoding(utf8)', $filename;

    local $/;
    my $contents = <$in>;

    close($in);

    return $contents;
}

my $parser = XML::LibXML->new();

# TEST
ok( $parser, 'parser was initialized' );

my $fn        = 'example/1.xml';
my $xml1_dom  = $parser->parse_file( $fn, );
my $xml1_text = _utf8_slurp($fn);

# TEST
ok( $xml1_dom, '$xml1_dom' );

{
    my $stylesheet =
        XML::LibXSLT::Quick->new( { location => 'example/1.xsl', } );
    my $results = $stylesheet->transform($xml1_dom);
    my $out1    = $stylesheet->output_as_chars($results);

    # TEST
    ok( $out1, 'output' );
}

my $expected_output;
{
    my $xslt_parser = XML::LibXSLT->new();
    my $stylesheet  = XML::LibXSLT::Quick->new(
        {
            xslt_parser => $xslt_parser,
            location    => 'example/1.xsl',
        }
    );
    my $results = $stylesheet->transform($xml1_dom);
    my $out1    = $stylesheet->output_as_chars($results);

    $expected_output = $out1;

    # TEST
    ok( $out1, 'output' );
}

{
    my $stylesheet =
        XML::LibXSLT::Quick->new( { location => 'example/1.xsl', } );
    my $out2 = $stylesheet->transform_into_chars($xml1_dom);

    # TEST
    is( $out2, $expected_output, 'transform_into_chars' );
}

foreach my $rec (
    +{
        name   => 'DOM object',
        source => $xml1_dom,
    },
    +{
        name   => 'text markup',
        source => $xml1_text,
    },
    +{
        name   => 'from file',
        source => +{
            type => 'file',
            path => $fn,
        }
    },
    )
{
    # TEST:FILTER(MULT(3))
    my $name   = $rec->{name};
    my $source = $rec->{source};
    {
        my $stylesheet =
            XML::LibXSLT::Quick->new( { location => 'example/1.xsl', } );
        my $out_str = '';
        open my $fh, '>', \$out_str;
        $stylesheet->generic_transform( $fh, $source, );

        $fh->flush();

        # TEST
        is( $out_str, $expected_output,
            "generic_transform() : ${name} -> filehandle" );
    }

    {
        my $stylesheet =
            XML::LibXSLT::Quick->new( { location => 'example/1.xsl', } );
        my $out_str = '';
        $stylesheet->generic_transform( ( \$out_str ), $source, );

        # TEST
        is( $out_str, $expected_output,
            "generic_transform() : ${name} -> string ref" );
    }

    {
        my $stylesheet =
            XML::LibXSLT::Quick->new( { location => 'example/1.xsl', } );
        my $out_fn = 'foo.xml';
        $stylesheet->generic_transform(
            +{
                type => 'file',
                path => $out_fn,

            },
            $source,
        );

        my $out_str = _utf8_slurp($out_fn);

        # TEST
        is( $out_str, $expected_output,
            "generic_transform() : ${name} -> file path name" );
        unlink($out_fn);
    }

    {
        my $stylesheet =
            XML::LibXSLT::Quick->new( { location => 'example/1.xsl', } );
        my $out_str = $stylesheet->generic_transform(
            +{
                type => 'return',
            },
            $source,
        );

        # TEST
        is( $out_str, $expected_output,
            "generic_transform() : ${name} -> return" );
    }

    {
        my $stylesheet =
            XML::LibXSLT::Quick->new( { location => 'example/1.xsl', } );
        my $out_dom = $stylesheet->generic_transform(
            +{
                type => 'dom',
            },
            $source,
        );
        my $out_str = $stylesheet->output_as_chars($out_dom);

        # TEST
        is( $out_str, $expected_output,
            "generic_transform() : ${name} -> return" );
    }

    # TEST:ENDFILTER()

}
__END__

=head1 COPYRIGHT & LICENSE

Copyright 2022 by Shlomi Fish

This program is distributed under the MIT / Expat License:
L<http://www.opensource.org/licenses/mit-license.php>

Permission is hereby granted, free of charge, to any person
obtaining a copy of this software and associated documentation
files (the "Software"), to deal in the Software without
restriction, including without limitation the rights to use,
copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the
Software is furnished to do so, subject to the following
conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
OTHER DEALINGS IN THE SOFTWARE.

=cut
