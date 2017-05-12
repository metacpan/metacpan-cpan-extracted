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
unless ($ARGV[2]) {
    say 'PlanID as third argument needed!';
}
unless ($ARGV[3]) {
    say 'BackupID as fourth argument needed!';
}

my $jiffy = VM::JiffyBox->new(token => $ARGV[0], test_mode => 1);

my $url = $jiffy->create_vm(
    name => $ARGV[1],
    planid => $ARGV[2],
    backupid => $ARGV[3]
);
say "\n$url\n";

$jiffy->test_mode(0);

my $response = $jiffy->create_vm(
    name => $ARGV[1],
    planid => $ARGV[2],
    backupid => $ARGV[3]
);

print Dumper($response);
