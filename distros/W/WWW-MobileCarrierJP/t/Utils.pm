package t::Utils;
use strict;
use warnings;
use Test::More;

sub import {
    my $pkg = caller(0);

    strict->import();
    warnings->import();

    no strict 'refs';
    *{"${pkg}::carriers"} = \&carriers;
    *{"${pkg}::modules"} = \&modules;
}

sub carriers () { qw/EZWeb DoCoMo AirHPhone Softbank/ }
sub modules($) {
    my $modname = shift;
    my @m;
    for my $carrier (carriers()) {
        my $class = "WWW::MobileCarrierJP::${carrier}::${modname}";
        use_ok $class;
        push @m, $class;
    }
    @m;
}

1;
