package TestML1Bridge;

use base TestML1::Bridge;
use TestML1::Util;

sub lowercase {
    my ($self, $string) = @_;
    return str lc($string->value);
}

sub uppercase {
    my ($self, $string) = @_;
    return str uc($string->value);
}

sub combine {
    my ($self, @arguments) = @_;
    return str join ' ', map $_->value, @arguments;
}

sub f1 {
    my ($self, $num) = @_;
    $num = $num->value;
    return num $num * 42 + $num;
}

sub f2 {
    my ($self, $num) = @_;
    $num = $num->value;
    return num $num * $num + $num;
}

sub replace_with_dots {
    my ($self, $text) = @_;
    $text = $text->value;
    $text =~ s/\S/./g;
    return str $text;
}

1;
