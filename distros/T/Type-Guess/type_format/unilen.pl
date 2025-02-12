use Mojo::File qw/path/;
use Mojo::Util qw/dumper encode decode tablify/;

$\ = "\n"; $, = "\t";
$s = 0;
my @l = map { [ $_, length(decode "UTF-8", $_), length($_), $s++ ]} split /\n/, path("/home/simone/Downloads/unicode_strings.txt")->slurp;


print tablify \@l;
