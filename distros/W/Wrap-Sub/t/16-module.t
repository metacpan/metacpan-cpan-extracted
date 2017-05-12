#!/usr/bin/perl
use strict;
use warnings;

use Data::Dump;
use Test::More;

use lib 't/data';

BEGIN {
    use_ok('Wrap::Sub');
    use_ok('Three');
};

{
    my $wrap = Wrap::Sub->new;
    my $subs = $wrap->wrap('Three');

    is (ref $subs, 'HASH', "when wrapping all subs, return is a hashref");

    my @ok = qw(Three::one Three::two Three::three Three::four Three::five Three::foo);

    for my $key (keys %$subs){
        my @in = grep(/$key/, @ok);

        is (@in, 1, "$key is in the return");
        is (ref $subs->{$key}, 'Wrap::Sub::Child', "$key sub has a name and is an obj") ;
    }
};
{
    my $wrap = Wrap::Sub->new;
    eval { my $subs = $wrap->wrap('Storable'); };
    like ($@, qr/\Qcan't wrap() a non-exist\E/, "a module has to be loaded before use");
};
{
    my $wrap = Wrap::Sub->new;
    my $subs = $wrap->wrap('Data::Dump');

    my @known = subs();

    for my $key (keys %$subs){
        is (grep(/^$key$/, @known), 1, "$key is known");
        is ($subs->{$key}->is_wrapped, 1, "$key is wrapped");
    }
};

# we now do this in the module
#    eval { unlink 'Dump.pm.bak' or die "can't remove Dump backup"; };
#    is ($@, '', "bak file unlinked ok");

done_testing();

sub subs {
    return qw(
        Data::Dump::ddx
        Data::Dump::dumpf
        Data::Dump::dump
        Data::Dump::str
        Data::Dump::tied_str
        Data::Dump::fullname
        Data::Dump::dd
        Data::Dump::_dump
        Data::Dump::format_list
        Data::Dump::quote
        );
}
