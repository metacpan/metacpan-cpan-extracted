use strict;
use warnings;
use Test::More;
use LWP::Online ":skip_all";

plan skip_all => "BROKEN";
plan tests => 6;
use WWW::MobileCarrierJP::DoCoMo::Display;
use LWP::Online ':skip_all';

my $dat = WWW::MobileCarrierJP::DoCoMo::Display->scrape;
ok scalar(@$dat) > 30;
is scalar(grep { $_->{model} eq 'D905i' } @$dat), 1;
is scalar(grep { $_->{model} eq 'F-01A' } @$dat), 1;
is scalar(grep { $_->{model} eq 'P-06A' } @$dat), 1;

ck(
    depth    => 2,
    height   => 72,
    is_color => '',
    model    => 'D501i',
    width    => 96,
);

ck(
    depth    => 262144,
    height   => 350,
    is_color => 1,
    model    => 'P906i',
    width    => 240,
);

sub ck {
    my $phone = @_ == 1 ? $_[0] : {@_};
    is_deeply [grep { $phone->{model} eq $_->{model} } @$dat]->[0], $phone;
}

