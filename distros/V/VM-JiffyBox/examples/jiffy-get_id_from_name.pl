use VM::JiffyBox;
use feature qw(say);
use Data::Dumper;
use Text::ASCIITable;

unless ($ARGV[0]) {
    say 'Token as first argument needed!';
}
unless ($ARGV[1]) {
    say 'BoxName as second argument needed!';
}

my $jiffy = VM::JiffyBox->new(token => $ARGV[0], test_mode => 1);

my $url = $jiffy->get_id_from_name($ARGV[1]);
say "\n$url\n";

$jiffy->test_mode(0);

my $response = $jiffy->get_id_from_name($ARGV[1]);
print Dumper($response);
