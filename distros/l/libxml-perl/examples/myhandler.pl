# This is the example script in doc/UsingPerlSAX.pod

use XML::Parser::PerlSAX;
use MyHandler;

my $my_handler = MyHandler->new;
my $parser = XML::Parser::PerlSAX->new( Handler => $my_handler );

foreach my $instance (@ARGV) {
    $parser->parse(Source => { SystemId => $instance });
}
