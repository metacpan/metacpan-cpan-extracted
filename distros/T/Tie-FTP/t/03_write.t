# -*- perl -*-

# t/03_write.t - FTP to host, write and read test files

use strict;
use Test::More;

use Tie::FTP;
use Net::FTP;

my ( $host, $user, $pass );

BEGIN {
    ( $host, $user, $pass )
    = @ENV{qw/FTP_HOST FTP_USER FTP_PASS/};

    if ( $host ) {
        plan tests => 4;
    }
    else {
        plan skip_all => 'set FTP_HOST and friends';
    }
}

tie *FH, 'Tie::FTP';

my $ftp = Net::FTP->new($host) or die "Failed to connect";
$ftp->login($user, $pass) or die "Login failed";
$ftp->mkdir('test') or die "mkdir failed";

my $txt = <<'TXT';
Test file for Tie::FTP t/03_write.t
TXT

my $dc = $ftp->stor('test/03_write');
$dc->write($txt, length $txt);
$dc->close;

ok( open( FH, $ftp, "test/03_write" ), "Tied open connected" );

my $text = do { local $/; <FH> };

is( $text, $txt , "Got the file we made");

(tied *FH)->taint;
my $fh = (tied *FH)->tmpfh;

print $fh "More text\n";
close FH;

untie *FH;


$dc = $ftp->retr('test/03_write');
sleep 1;
$dc->read(my $buff, 512);
$dc->close;

like($buff, qr/for Tie::FTP/, "first message");

like($buff, qr/More/, "second message");

# Tidy up

END {
    $ftp->delete('test/03_write');
    $ftp->rmdir('test');
}
