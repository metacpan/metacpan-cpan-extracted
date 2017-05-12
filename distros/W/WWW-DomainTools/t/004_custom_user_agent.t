use Test::More tests => 3;
use YAML qw(LoadFile);
use LWP::UserAgent;

BEGIN {
    use_ok('WWW::DomainTools::NameSpinner');
}

my $CONFIG = LoadFile('t/license.yml');

my $DEFAULT_UA     = "foozilla 1.0";
my $LWP_DEFAULT_UA = LWP::UserAgent->new->_agent();
my $ua             = LWP::UserAgent->new;
$ua->agent($DEFAULT_UA);

my $obj = WWW::DomainTools::NameSpinner->new(
    partner     => $CONFIG->{partner},
    key         => $CONFIG->{key},
    customer_ip => $CONFIG->{customer_ip},
    url         => $CONFIG->{url},
    lwp_ua      => $ua
);

ok( $obj->{_ua}->agent() ne $LWP_DEFAULT_UA,
    "customer user agent doesn't look like default"
);
ok( $obj->{_ua}->agent() eq $DEFAULT_UA, 'custom user agent passed in' );
