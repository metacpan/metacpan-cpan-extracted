use Test::More tests => 6;
use Date::Manip;
use strict;
use warnings;

BEGIN
{
    use_ok 'WWW::Page::Modified';
}

my $pkg = 'WWW::Page::Modified';
my $dm = $pkg->new();
isa_ok $dm => $pkg; # 2

# 3-5
my @expected = (
    {
	title	=> 'Microsoft',
	url	=> 'http://www.microsoft.com/',
	date	=> 'Tue, 18 Dec 2001 02:00:37 GMT',
    },
    {
        title   => 'Accrual Budget Implementation',
        url     => 'http://www.treasury.tas.gov.au/domino/dtf/dtf.nsf/main-v/accrual',
        date    => '2001-12-03',
    },
    {
        title   => 'A-Z State Government organisations',
        url     => 'http://www.service.tas.gov.au/GovOrgs/',
        date    => '2001/12/07',
    },
);

foreach my $site (@expected)
{
    ok $dm->get_modified($site->{url}) >= ($site->{date}
    ?  UnixDate(ParseDate($site->{date}) => '%s') : 0), $site->{title};
}

# 6
do {
    use HTTP::Request::Common qw/HEAD/;
    my $site = $expected[0];
    my $req = HEAD $site->{url};
    my $url = $dm->_ua->request($req);
    ok $dm->get_modified($url) >= UnixDate(ParseDate($site->{date}) => '%s'), $site->{title};
}
