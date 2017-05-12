package Tiffany::Text::Xslate;
use strict;
use warnings;
use Text::Xslate 0.1056;

sub new {
    my ($class, $args) = @_;
    $args ||= +{};

    my $xslate = Text::Xslate->new($args);
    bless {
        xslate => $xslate,
    }, $class;
}

sub render {
    my ($self, $stuff, @args) = @_;

    if (ref $stuff) {
        return $self->{xslate}->render_string($$stuff, @args);
    } else {
        return $self->{xslate}->render($stuff, @args);
    }
}

1;
__END__

=head1 NAME

Tiffany::Text::Xslate - Tiffany gateway for Text::Xslate

=head1 SYNOPSIS

    use Tiffany;

    my $tiffany = Tiffany->load('Text::Xslate', {syntax => 'TTerse'});
    my $output = $tiffany->render(\q{hello, [% name %].}, {name => 'john'});
    my $expected = "hello, john.";

    is $output, $expected;


=head1 AUTHOR

Tokuhiro Matsuno


