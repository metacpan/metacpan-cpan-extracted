use strict;
use warnings;
use Test::More;
use LWP::Online ":skip_all";
plan skip_all => "BROKEN";
plan tests => 7;
use WWW::MobileCarrierJP::ThirdForce::UserAgent;

my $dat = WWW::MobileCarrierJP::ThirdForce::UserAgent->scrape;
ok ref($dat), 'ARRAY';
cmp_ok scalar(@$dat), '>', 30;

{
    my ($m, ) = grep { $_->{model} eq '823T' } @$dat;
    ok $m;
    is $m->{user_agent}, 'SoftBank/1.0/823T/TJ001[/Serial] Browser/NetFront/3.3 Profile/MIDP-2.0 Configuration/CLDC-1.1';
}

ok grep { $_->{model} eq '821P' } @$dat;
is scalar(grep { $_->{model} =~ /series/ } @$dat), 0;
is scalar(grep { $_->{user_agent} =~ /\s$/ } @$dat), 0, 'i hate trailing spaces';

