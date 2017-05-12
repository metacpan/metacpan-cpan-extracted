use XML::Parser::PerlSAX;
use XML::Handler::Sample;

if ($#ARGV != 0) {
    die "usage: esis-test FILE\n";
}
$file = shift @ARGV;

$my_handler = XML::Handler::Sample->new;

XML::Parser::PerlSAX->new->parse(Source => { SystemId => $file },
				 Handler => $my_handler);

