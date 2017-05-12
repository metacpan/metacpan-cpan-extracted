#!/usr/bin/perl -w
use strict;
use Test::More;
use Test::XML;

use aliased 'XML::Toolkit::Config::Container' => 'XMLTK::App';

use aliased 'XML::Toolkit::Generator';

my $xml = <<'END_XML';
<?xml version="1.0" encoding="utf-8"?>
<rdf:RDF
  xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
  xmlns:dc="http://purl.org/dc/elements/1.1/">
	<rdf:Description rdf:about="http://en.wikipedia.org/wiki/Tony_Benn">
		<dc:title>Tony Benn</dc:title>
		<dc:publisher>Wikipedia</dc:publisher>
	</rdf:Description>
</rdf:RDF>


END_XML

my $map = {
    ''                                            => 'XML::RDF::RDF',
    'http://www.w3.org/1999/02/22-rdf-syntax-ns#' => 'XML::RDF',
    'http://purl.org/dc/elements/1.1/'            => 'XML::DC',
};

my $builder = XMLTK::App->new( { namespace_map => $map } )->builder;
$builder->parse_string($xml);
my $code = $builder->render();

eval $code;
#diag $code;
if ($@) {
    diag "Couldn't EVAL code $@";
    done_testing;
    exit;
}
my $loader = XMLTK::App->new( { namespace_map => $map } )->loader;
$loader->parse_string($xml);
my $root = $loader->root_object;

my $generator = XMLTK::App->new(
    {
        namespace_map => {
            ''    => 'http://www.w3.org/1999/02/22-rdf-syntax-ns#',
            'rdf' => 'http://www.w3.org/1999/02/22-rdf-syntax-ns#',
            'dc'  => 'http://purl.org/dc/elements/1.1/'
        }
    }
)->generator;

$generator->render_object($root);

my $out_xml = join '', $generator->output;
TODO: {
    local $TODO = 'gotta get RDF serializing again';
    is_xml( $out_xml, $xml, 'XML compares' );
}
done_testing;

