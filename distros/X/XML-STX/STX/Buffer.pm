package XML::STX::Buffer;

require 5.005_02;
BEGIN { require warnings if $] >= 5.006; }
use strict;
use XML::STX::Base;

@XML::STX::Buffer::ISA = qw(XML::STX::Base);

# --------------------------------------------------

sub new {
    my ($class, $name) = @_;

    my $self = bless {name   => $name,
		      events => [],
		     }, $class;
    return $self;
}

sub init {
    my ($self, $stx, $clear) = @_;

    $self->{stx} = $stx;
    $self->{events} = [] if $clear;
}

sub process {
    my $self = shift;

    $self->{stx}->change_stream(STXE_START_BUFFER);

    foreach (@{$self->{events}}) {
	&{$_->[0]}($self->{stx}, $_->[1]);
    }

    $self->{stx}->change_stream(STXE_END_BUFFER);
}

# --- callbacks -----------------------------------------------

sub start_element {
    my ($self, $el) = @_;

    my $method = $self->{stx}->can('start_element');
    push @{$self->{events}}, [$method, $el];
}

sub end_element {
    my ($self, $el) = @_;

    my $method = $self->{stx}->can('end_element');
    push @{$self->{events}}, [$method, $el];
}

sub characters {
    my ($self, $char) = @_;

    my $method = $self->{stx}->can('characters');
    push @{$self->{events}}, [$method, $char];
}

sub processing_instruction {
    my ($self, $pi) = @_;

    my $method = $self->{stx}->can('processing_instruction');
    push @{$self->{events}}, [$method, $pi];
}

sub start_cdata {
    my $self = shift;

    my $method = $self->{stx}->can('start_cdata');
    push @{$self->{events}}, [$method, undef];
}

sub end_cdata {
    my $self = shift;

    my $method = $self->{stx}->can('end_cdata');
    push @{$self->{events}}, [$method, undef];
}

sub comment {
    my ($self, $com) = @_;

    my $method = $self->{stx}->can('comment');
    push @{$self->{events}}, [$method, $com];
}

1;
__END__

=head1 NAME

XML::STX::Buffer - buffer objects for XML::STX

=head1 SYNOPSIS

no public API

=head1 AUTHOR

Petr Cimprich (Ginger Alliance), petr@gingerall.cz

=head1 SEE ALSO

XML::STX, perl(1).

=cut
