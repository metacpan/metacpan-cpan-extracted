package One;

sub new {
    return bless {}, shift;
}

sub foo {
    return "foo";
}
sub bar {
    return "bar";
}
sub baz {
    return "baz";
}
sub call_0 {
    return caller(0);
}
sub call_1 {
    return caller(1);
}
1;
