# Test that the filesystem persistence object is implemented correctly

use strict;
use Test;
use WebSphere::MQTT::Persist::File;

BEGIN { plan tests => 33 }

my $base = "./testtmp";
my $sentdir = "$base/cli123/bro456_789/sent";
my $rcvddir = "$base/cli123/bro456_789/rcvd";
my %res;

# Creation of directory tree

system("rm -rf $base");

my $persist = WebSphere::MQTT::Persist::File->new($base);
ok( $persist );

$persist->open("cli123", "bro456", "789");
ok( -d "$sentdir" );
ok( -d "$rcvddir" );

# Test restore

%res = $persist->getAllReceivedMessages;
ok( %res == 0 );
%res = $persist->getAllSentMessages;
ok( %res == 0 );

writefile("$sentdir/1", "aaa\0aa");	# 1u takes precedence
writefile("$sentdir/1u", "bbb\0bb");
writefile("$sentdir/2u", "ccc\377cc");
writefile("$sentdir/2", "ddd\377dd");	# 2u takes precedence
writefile("$sentdir/3x", "eeeee");	# ignored
%res = $persist->getAllSentMessages;
ok( keys(%res) == 2 );
ok( $res{"1"} eq "bbb\0bb" );
ok( $res{"2"} eq "ccc\377cc" );

# the 'u' files are ignored for rcvd
writefile("$rcvddir/1", "fffff");
writefile("$rcvddir/1u", "ggggg");	# ignore
writefile("$rcvddir/2u", "hhhhh");	# ignore
writefile("$rcvddir/2", "iiiii");
writefile("$rcvddir/3x", "jjjjj");	# should be ignored
%res = $persist->getAllReceivedMessages;
ok( keys(%res) == 2 );
ok( $res{"1"} eq "fffff" );
ok( $res{"2"} eq "iiiii" );

# Reset

my @f;
@f = glob("$sentdir/*");
ok( @f == 5);
@f = glob("$rcvddir/*");
ok( @f == 5);
$persist->reset;
@f = glob("$sentdir/*");
ok( @f == 0);
@f = glob("$rcvddir/*");
ok( @f == 0);

# sent messages

$persist->addSentMessage(1234, "aaa111");
$persist->addSentMessage(1235, "bbb222");
%res = $persist->getAllSentMessages;
ok( keys(%res) == 2 );
ok( $res{"1234"} eq "aaa111" );
ok( $res{"1235"} eq "bbb222" );

$persist->updSentMessage(1234, "ccc333");
%res = $persist->getAllSentMessages;
ok( keys(%res) == 2 );
ok( $res{"1234"} eq "ccc333" );
ok( $res{"1235"} eq "bbb222" );

$persist->delSentMessage(1235);
%res = $persist->getAllSentMessages;
ok( keys(%res) == 1 );
ok( $res{"1234"} eq "ccc333" );

$persist->delSentMessage(1234);
%res = $persist->getAllSentMessages;
ok( keys(%res) == 0 );

# received messages. This is a bit odd; the API spec says that
# updReceivedMessage must OR the last byte of the message with
# MQISDP_RELEASED (0x01)

$persist->addReceivedMessage(1234, "bbbbb");
$persist->addReceivedMessage(1235, "ccccc");
%res = $persist->getAllReceivedMessages;
ok( keys(%res) == 2 );
ok( $res{"1234"} eq "bbbbb" );
ok( $res{"1235"} eq "ccccc" );

$persist->updReceivedMessage(1234);
%res = $persist->getAllReceivedMessages;
ok( keys(%res) == 2 );
ok( $res{"1234"} eq "bbbbc" );   # last byte updated
ok( $res{"1235"} eq "ccccc" );

$persist->delReceivedMessage(1234);
%res = $persist->getAllReceivedMessages;
ok( keys(%res) == 1 );
ok( $res{"1235"} eq "ccccc" );

$persist->delReceivedMessage(1235);
%res = $persist->getAllReceivedMessages;
ok( keys(%res) == 0 );

# tidy up

system("rm -rf $base");

exit 0;

sub writefile
{
    my $name = shift;
    my $data = shift;
    open(F,">$name") || die("$name: $!");
    print F $data;
    close(F);
}

