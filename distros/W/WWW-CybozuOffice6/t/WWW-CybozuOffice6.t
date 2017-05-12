use strict;
use warnings;

use Test::More tests => 14;


BEGIN { use_ok('WWW::CybozuOffice6') };

# test constructor
undef $@;
eval {
    WWW::CybozuOffice6->new(1);
};
ok($@);
undef $@;
eval {
    WWW::CybozuOffice->new(unknownparameter => 1);
};
ok($@);

# finally construct a valid object
my $office6 = WWW::CybozuOffice6->new();
isa_ok($office6, 'WWW::CybozuOffice6');

# should croak given no URL, username, password
eval {
    $office6->test_credentials;
};
ok($@);

# accessor check
$office6->url('http://url');
is($office6->url, 'http://url');
$office6->user('theUser');
is($office6->user, 'theUser');
$office6->password('thePass');
is($office6->password, 'thePass');
isa_ok($office6->ua, 'LWP::UserAgent');
$office6->ua(1);
is($office6->ua, 1);
is($office6->ocode, 'utf8');
$office6->ocode('sjis');
is($office6->ocode, 'sjis');

# test parser
sub read_data ($) {
    local $/;
    undef $/;
    my $fp;
    open($fp, 't/'.$_[0].'.dat') || die $!;
    my $dat = <$fp>;
    close($fp);
    return $dat;
}
$office6->ocode('utf8');
my $items = $office6->parse_externalAPINotify(read_data('externalAPINotify'));
is($#{$items}, 10);

# test login
SKIP: {
    skip('login test', 1) unless (defined($ENV{OFFICE6_URL}) && defined($ENV{OFFICE6_USER}) && defined($ENV{OFFICE6_PASS}));
    $office6 = WWW::CybozuOffice6->new(url => $ENV{OFFICE6_URL},
				       user => $ENV{OFFICE6_USER},
				       pass => $ENV{OFFICE6_PASS});
    is($office6->test_credentials(), 1);
}
