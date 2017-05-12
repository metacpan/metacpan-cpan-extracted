# -*- perl -*-

# t/02_anonymous.t - Anonymous FTP to read only host

use strict;
use Test::More;

use Tie::FTP;
use Net::FTP;

my $config;
my $ftp;
my $host;

BEGIN {
    $host = 'ftp.debian.org';
    $ftp = Net::FTP->new($host);
    if ( $ftp ) {
        plan tests => 8;
    }
    else {
        plan skip_all => 'No Internet connection';
    }
}

tie *FH, 'Tie::FTP';

my $user = 'anonymous';
my $pass = 'nuffin@cpan.org';
my $file = 'debian/README';

ok( open( FH, "ftp://$user:$pass\@$host/$file" ), "Tied open connected" );

my $text = do { local $/; <FH> };

ok( $text, "We got something" );

like( $text, qr/boot disks/, "Matched some text in Debian README" );

TODO: {
    local $TODO = "Tie::FTP::CLOSE doesn't return anything";
    ok(close(FH), "Close succeeded");
}

$ftp->login($user, $pass);

tie *FH2, 'Tie::FTP';

ok( open( FH2, $ftp, $file), "Net::FTP and file");

$text = do { local $/; <FH2> };

ok( $text, "We got something" );

like( $text, qr/boot disks/, "Matched some text in Debian README" );


TODO: {
    local $TODO = "Tie::FTP::CLOSE doesn't return anything";
    ok(close(FH2), "Close succeeded");
}
