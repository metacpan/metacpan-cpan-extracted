use XML::ESISParser;
use XML::Handler::Sample;

if ($ARGV[0] eq '--sgml') {
    push (@additional_args, IsSGML => 1);
    shift @ARGV;
}

if ($#ARGV != 0) {
    die "usage: esis-test FILE\n";
}
$file = shift @ARGV;

$my_handler = XML::Handler::Sample->new;

XML::ESISParser->new->parse(Source => { SystemId => $file },
			    Handler => $my_handler,
			    @additional_args);

