package Tiffany::Text::MicroTemplate::Extended;
use strict;
use warnings;
use Text::MicroTemplate::Extended;

sub new {
    my ($class, $args) = @_;
    $args ||= +{};
    my $mtf = Text::MicroTemplate::Extended->new(%$args);
    bless {
        mtf => $mtf,
    }, $class;
}

sub render {
    my ($self, $stuff, @args) = @_;
    if (ref $stuff) {
        die "this module does not support ScalarRef";
    } else {
        return $self->{mtf}->render($stuff, @args)->as_string;
    }
}

1;
__END__

=head1 NAME

Tiffany::Text::MicroTemplate::Extended - Tiffany gateway for Text::MicroTemplate::Extended

=head1 SYNOPSIS

    use Tiffany;

    my $tiffany = Tiffany->load('Text::MicroTemplate::Extended', {include_path => ['t/tmpl']});
    my $output = $tiffany->render('foo', 'john');
    my $expected = "hello, john.\n";

    is $output, $expected;

=head1 NOTE

This module does not support ScalarRef at ->render() method.

=head1 AUTHOR

Tokuhiro Matsuno


