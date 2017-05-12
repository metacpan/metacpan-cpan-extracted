use TestML;
TestML->new(
    testml => join('', <DATA>),
)->run;

{
    package TestML::Bridge;
    use TestML::Util;
    sub upper {
        my ($self, $string) = @_;
        return str uc($string->value);
    }
}

__DATA__
%TestML 0.1.0

*foo.upper() == *bar

=== Foo for thought
--- foo: o hai
--- bar: O HAI

=== Bar the door
--- foo
o
Hai
--- bar
O
HAI

