use v5.14;
use warnings;

use UV::Loop ();
use UV::Prepare ();

use Test::More;

my $prepare_cb_called = 0;

sub prepare_cb {
    my $self = shift;
    $prepare_cb_called++;
    $self->stop();
    $self->close();
}

my $prepare = UV::Prepare->new(on_prepare => \&prepare_cb);
isa_ok($prepare, 'UV::Prepare');
my $ret = $prepare->start();
is($ret, $prepare, '$prepare->start returns $prepare');

is(UV::Loop->default()->run(), 0, 'loop run');
is($prepare_cb_called, 1, 'right number of prepare callbacks');

done_testing();
