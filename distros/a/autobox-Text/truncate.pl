use utf8;
use Mojo::Util qw/encode/;
use String::Truncate qw(elide);
use strict;

$\ = "\n"; $, = "\t";

my $long = "Könntest du bitte überprüfen, ob der äußerst außergewöhnliche, übermäßig überängstliche Künstler tatsächlich übermäßig süßsäuerliche, ölgetränkte Brötchen für die frühmorgendliche Frühstücksüberraschung überführte?";

# print encode "UTF-8", $long;
print encode "UTF-8", elide($long, 36);
print join "", ((join "", (0..9)) x 4);
