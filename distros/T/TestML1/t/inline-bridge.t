use TestML1;
TestML1->new(
    testml => join('', <DATA>),
)->run;

{
    package TestML1::Bridge;
    use TestML1::Util;
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

