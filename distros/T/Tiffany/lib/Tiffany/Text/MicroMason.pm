package Tiffany::Text::MicroMason;
use strict;
use warnings;
use Text::MicroMason;

sub new {
    my ($class, $args) = @_;
    $args ||= +{};
    my $mason = Text::MicroMason->new(%$args);
    bless {
        mason => $mason,
    }, $class;
}

sub render {
    my ($self, $stuff, @args) = @_;

    $self->{mason}->execute(
        (ref $stuff ? ('text' => ${$stuff}) : ('file' => $stuff)),
        @args
    );
}

1;
__END__

=head1 NAME

Tiffany::Text::MicroMason - Tiffany gateway for Text::MicroMason

=head1 SYNOPSIS

    use Tiffany;

    my $tiffany = Tiffany->load('Text::MicroMason');
    my $t = q{<%args>$name</%args>Hello, <% $name %>};
    my $expected = 'Hello, john';
    my $output = $tiffany->render(\$t, name => 'john');

    is $output, $expected;

=head1 AUTHOR

Tokuhiro Matsuno

