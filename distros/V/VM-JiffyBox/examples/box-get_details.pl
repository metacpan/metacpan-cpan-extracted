use VM::JiffyBox;
use Text::ASCIITable;
use feature qw(say);
use Data::Dumper;

# script musst be called like this:
#     ./script.pl $AUTH_TOKEN $BOX_ID

unless ( $ARGV[0] ) {
    say 'Auth-Token as first argument needed!';
#    exit 1;
}
unless ( $ARGV[1] ) {
    say 'Box-ID as second argument needed!';
#    exit 1;
}

# create a hypervisor with test_mode on
my $jiffy = VM::JiffyBox->new(token => $ARGV[0], test_mode => 1);

# get a specific box
my $box = $jiffy->get_vm($ARGV[1]);

# do a request to this box
# since we have test_mode enabled it will just return the URL for the API
my $req_url = $box->get_details();

# we print out the URL
say "\n$req_url\n";

# we change the status of the box and disable test_mode
$jiffy->test_mode(0);

# do the same request again, this time live!
my $box_details = $box->get_details();

# build a fancy ASCII table out of the result
$t = Text::ASCIITable->new();
$t->setCols('Name', 'Public IP', 'Plan ID', 'Price per Hour', 'OS');
$t->addRow(
    $box_details->{result}->{name},
    $box_details->{result}->{ips}->{public}->[0],
    $box_details->{result}->{plan}->{id},
    $box_details->{result}->{plan}->{pricePerHour},
    $box_details->{result}->{activeProfile}->{disks}->{xvda}->{name}
);

# and print the ASCII table
print $t;
