package Text::APL::Reader;

use strict;
use warnings;

use base 'Text::APL::Base';

sub build {
    my $self = shift;
    my ($input) = @_;

    my $reader;

    if (!ref $input) {
        $reader = $self->_build_file_reader($input);
    }
    elsif (ref $input eq 'GLOB') {
        $reader = $self->_build_file_handle_reader($input);
    }
    elsif (ref $input eq 'SCALAR') {
        $reader = $self->_build_string_reader($input);
    }
    elsif (ref $input eq 'CODE') {
        $reader = $input;
    }
    else {
        die 'Do not know how to read';
    }

    return $reader;
}

sub _build_file_reader {
    my $self = shift;
    my ($input) = @_;

    open my $fh, '<', $input or die "Can't open '$input': $!";

    if (my $charset = $self->{charset}) {
        binmode $fh, ":encoding($charset)";
    }

    return $self->_build_file_handle_reader($fh);
}

sub _build_file_handle_reader {
    my $self = shift;
    my ($input) = @_;

    sub {
        my ($cb) = @_;
        while (defined(my $line = <$input>)) {
            $cb->($line);
        }
        $cb->();
    };
}

sub _build_string_reader {
    my $self = shift;
    my ($input) = @_;

    sub {
        my ($cb) = @_;

        $cb->(${$input});
        $cb->();
    };
}

1;
__END__

=pod

=head1 NAME

Text::APL::Reader - reader

=head1 DESCRIPTION

Reads a template from various sources. Accepts a subroutine for a custom
implementation. 

Returns a reference to subroutine. When called accepts another reference to
subroutine that is called upon receiving a chunk of the template.

For example a reader from a scalar reference is implemented as:

    $reader = sub {
        my ($cb) = @_;

        $cb->(${$input_string});
        $cb->();
    };

The first call on C<cb> notifies L<Text::APL> about the template chunk and
second without arguments notifies L<Text::APL> about EOF.

The following sources are implemented:

    $reader->(\$scalar);
    $reader->($filename);
    $reader->($filehandle);
    $reader->(sub {...custom code...});

Custom subroutines are used for non-blocking template reading. See C<examples/>
directory for an example using L<IO::AIO> for non-blocking template reading.

=head1 METHODS

=head2 C<build>

Build a reader.

=cut
