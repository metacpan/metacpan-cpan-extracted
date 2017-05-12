use strict;
use warnings;
use utf8;
use Test::More;
use Test::Ika::Reporter::Spec;
use Test::Ika::Reporter::TAP;
use Test::Ika::Reporter::Test;

check('Test::Ika::Reporter::TAP');
check('Test::Ika::Reporter::Test');

done_testing;

sub check {
    my $target = shift;
    my %target_has = map { $_ => 1 } functions($target);
    for (functions('Test::Ika::Reporter::Spec')) {
        ok $target_has{$_}, $_;
    }
}
sub functions {
    my $klass = shift;
    no strict 'refs';
    sort grep { $_ ne 'colored' && $_ ne 'color' } grep { defined &{"${klass}::$_"} } keys %{"${klass}::"};
}
