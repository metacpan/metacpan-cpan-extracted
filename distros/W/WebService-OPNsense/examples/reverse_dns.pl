#!perl

use strictures 2;
use Ref::Util     qw( is_plain_hashref is_plain_arrayref );
use WebService::OPNsense ();

my $base_url = $ENV{OPN_URL}    or die "Set OPN_URL, OPN_KEY, OPN_SECRET\n";
my $username = $ENV{OPN_KEY}    or die "Set OPN_URL, OPN_KEY, OPN_SECRET\n";
my $password = $ENV{OPN_SECRET} or die "Set OPN_URL, OPN_KEY, OPN_SECRET\n";

my $opn = WebService::OPNsense->new(
    base_url => $base_url,
    username => $username,
    password => $password,
);

if ( $ENV{OPN_INSECURE} ) {
    $opn->ua->ssl_opts( verify_hostname => 0, SSL_verify_mode => 0 );
}

my $diag = $opn->diagnostics;

for my $ip ( '1.1.1.1', '8.8.8.8', '9.9.9.9' ) {
    print "$ip:\n";
    my $result = $diag->dns_lookup($ip);
    if ( is_plain_hashref($result) ) {
        for my $k ( sort keys %{$result} ) {
            my $v = $result->{$k};
            if ( is_plain_arrayref($v) ) {
                printf "  %s:\n", $k;
                printf "    %s\n", $_ for @{$v};
            }
            else {
                printf "  %s: %s\n", $k, $v;
            }
        }
    }
    else {
        printf "  %s\n", $result // '(empty)';
    }
    print "\n";
}

print "Done.\n";
