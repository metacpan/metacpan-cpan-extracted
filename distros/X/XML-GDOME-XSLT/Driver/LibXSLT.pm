# base class.
package Driver::LibXSLT;

use Driver::BaseClass;
@ISA = qw(Driver::BaseClass);

use XML::LibXSLT;
use XML::LibXML;

use vars qw(
        $parser
        $xslt
        $stylesheet
        $input
        );

sub init {
    $parser = XML::LibXML->new();
    $xslt = XML::LibXSLT->new();
}

sub load_stylesheet {
    my ($filename) = @_;
    my $styledoc = $parser->parse_file($filename);
    $stylesheet = $xslt->parse_stylesheet($styledoc);
}

sub load_input {
    my ($filename) = @_;
    $input = $parser->parse_file($filename);
}

sub run_transform {
    my ($output) = @_;
    my $results;
    $results = $stylesheet->transform($input);
    $stylesheet->output_file($results, $output);
#    print STDERR "\n";
}

1;
