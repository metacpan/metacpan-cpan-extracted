use strict;
use warnings;
use utf8;
use Test::More;

# UserAgent は DEPRECATED なので ThirdForce の方にうつしてない
my @x = qw/CIDR Flash Java Service Display HTTPHeader PictogramInfo/;

for (@x) {
    use_ok "WWW::MobileCarrierJP::ThirdForce::$_";
    can_ok "WWW::MobileCarrierJP::ThirdForce::$_", 'scrape';
    ok "WWW::MobileCarrierJP::ThirdForce::$_"->isa("WWW::MobileCarrierJP::Softbank::$_"), 'isa';
    is "WWW::MobileCarrierJP::ThirdForce::$_"->can('scrape'), "WWW::MobileCarrierJP::Softbank::$_"->can('scrape');
}

done_testing;

