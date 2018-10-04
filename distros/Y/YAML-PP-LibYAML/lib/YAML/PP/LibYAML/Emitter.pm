# ABSTRACT: Emitter for YAML::PP::LibYAML
package YAML::PP::LibYAML::Emitter;
use strict;
use warnings;

our $VERSION = '0.002'; # VERSION

use YAML::LibYAML::API::XS;
use YAML::PP::Writer;
use Scalar::Util qw/ openhandle /;

use base 'YAML::PP::Emitter';

sub new {
    my ($class, %args) = @_;
    my $self = bless {
        %args,
    }, $class;
    $self->{events} = [];
    return $self;
}
sub events { return $_[0]->{events} }


sub mapping_start_event {
    my ($self, $info) = @_;
    $info->{name} = 'mapping_start_event';
    push @{ $self->events }, $info;
}

sub mapping_end_event {
    my ($self, $info) = @_;
    $info->{name} = 'mapping_end_event';
    push @{ $self->events }, $info;
}

sub sequence_start_event {
    my ($self, $info) = @_;
    $info->{name} = 'sequence_start_event';
    push @{ $self->events }, $info;
}

sub sequence_end_event {
    my ($self, $info) = @_;
    $info->{name} = 'sequence_end_event';
    push @{ $self->events }, $info;
}

sub scalar_event {
    my ($self, $info) = @_;
    $info->{name} = 'scalar_event';
    push @{ $self->events }, $info;
}

sub alias_event {
    my ($self, $info) = @_;
    $info->{name} = 'alias_event';
    push @{ $self->events }, $info;
}

sub document_start_event {
    my ($self, $info) = @_;
    $info->{name} = 'document_start_event';
    push @{ $self->events }, $info;
}

sub document_end_event {
    my ($self, $info) = @_;
    $info->{name} = 'document_end_event';
    push @{ $self->events }, $info;
}

sub stream_start_event {
    my ($self, $info) = @_;
    $info->{name} = 'stream_start_event';
    push @{ $self->events }, $info;
}

sub stream_end_event {
    my ($self, $info) = @_;
    $info->{name} = 'stream_end_event';
    push @{ $self->events }, $info;
    my $events = $self->events;
    my $writer = $self->writer;
    $writer->init();

    if ($writer->can('open_handle')) {
        if (openhandle($writer->output)) {
            YAML::LibYAML::API::XS::emit_filehandle_events($writer->open_handle, $events);
        }
        else {
            YAML::LibYAML::API::XS::emit_file_events($writer->output, $events);
        }
    }
    else {
        my $out = YAML::LibYAML::API::XS::emit_string_events($events);
        $self->writer->write($out);
    }

    @$events = ();
}

1;

__END__

=pod

=head1 NAME

YAML::PP::LibYAML::Emitter - Emitter for YAML::PP::LibYAML

=head1 DESCRIPTION

L<YAML::PP::LibYAML::Emitter> is a subclass of L<YAML::PP::Emitter>.

=cut
