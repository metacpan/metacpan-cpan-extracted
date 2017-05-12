package Tiffany::Text::MicroTemplate::File;
use strict;
use warnings;
use Text::MicroTemplate::File;

sub new {
    my ($class, $args) = @_;
    $args ||= +{};
    my $mtf = Text::MicroTemplate::File->new(%$args);
    bless {
        mtf => $mtf,
    }, $class;
}

sub render {
    my ($self, $stuff, @args) = @_;

    my $mtf = $self->{mtf};
    if (ref $stuff) {
        $mtf->parse(${$stuff});
        return $mtf->build()->(@args)->as_string;
    } else {
        return $mtf->render_file($stuff, @args)->as_string;
    }
}

1;
__END__

=head1 NAME

Tiffany::Text::MicroTemplate::File - Tiffany gateway for Text::MicroTemplate::File

=head1 SYNOPSIS

    use Tiffany;

    my $tiffany = Tiffany->load('Text::MicroTemplate::File');
    my $output = $tiffany->render(\q{hello, <?= $_[0] ?>.}, 'john');
    my $expected = "hello, john.";

    is $output, $expected;

=head1 AUTHOR

Tokuhiro Matsuno


