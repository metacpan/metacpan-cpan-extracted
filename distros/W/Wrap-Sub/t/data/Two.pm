package Two;

use lib '.';
use One;

sub test {
    my $obj = One->new;
    $obj->foo;
}
sub test2 {
    my $obj = One->new;
    $obj->bar;
}
sub test3 {
    my $obj = One->new;
    $obj->baz;
}
sub test4 {
    my $obj = One->new;
    return $obj->call_0;
}
sub test5 {
    my $obj = One->new;
    return $obj->call_1;
}

1;
