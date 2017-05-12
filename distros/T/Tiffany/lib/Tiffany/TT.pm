package Tiffany::TT;
use strict;
use warnings;
use Template;

sub new {
    my ($class, $args) = @_;
    $args ||= +{};
    my $tt = Template->new(%$args);
    bless {
        tt => $tt,
    }, $class;
}

sub render {
    my ($self, $stuff, @args) = @_;

    $self->{tt}->process( $stuff, @args, \my $out )
      or die $self->{tt}->error;
    $out;
}

1;
__END__

=head1 NAME

Tiffany::TT - Tiffany gateway for Template-Toolkit

=head1 SYNOPSIS

    use Tiffany;

    my $tmpl = Tiffany->load('TT');
    is $tmpl->render(\q{Hello, [% name %].}, {name => 'john'}), "Hello, john.";

=head1 AUTHOR

Tokuhiro Matsuno

