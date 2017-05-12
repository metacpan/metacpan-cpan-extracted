package WebService::Raygun::Message::Error::StackTrace;
$WebService::Raygun::Message::Error::StackTrace::VERSION = '0.030';
use Mouse;

=head1 NAME

WebService::Raygun::Message::Error::StackTrace - Encapsule the stacktrace in error details

=head1 SYNOPSIS

  use WebService::Raygun::Message::Error::StackTrace;




=head1 DESCRIPTION

You should not need to instantiate this directly. It will be created by the L<WebService::Raygun::Message::Error|WebService::Raygun::Message::Error> object.


=head1 INTERFACE

=cut


use Mouse::Util::TypeConstraints;

subtype 'StackTrace' => as 'Object' =>
  where { $_->isa('WebService::Raygun::Message::Error::StackTrace') };

subtype 'ArrayOfStackTraces' => as 'ArrayRef[StackTrace]' => where {
    scalar @{$_} >= 1 and defined $_->[0]->line_number;
} => message {
    return 'At least one stack trace element is required.';
};

coerce 'StackTrace' => from 'HashRef' => via {
    return WebService::Raygun::Message::Error::StackTrace->new( %{$_} );
};
coerce 'ArrayOfStackTraces' => from 'ArrayRef[HashRef]' => via {
    my $array_of_hashes = $_;
    return [ map { WebService::Raygun::Message::Error::StackTrace->new( %{$_} ) }
          @{$array_of_hashes} ];
};

no Mouse::Util::TypeConstraints;

has line_number => (
    is      => 'rw',
    isa     => 'Int',
    default => sub {
        return 0;
    },
);

has class_name => (
    is      => 'rw',
    isa     => 'Str',
    default => sub {
        return '';
    },
);

has file_name => (
    is      => 'rw',
    isa     => 'Str',
    default => sub {
        return '';
    },
);

has method_name => (
    is      => 'rw',
    isa     => 'Str',
    default => sub {
        return '';
    },
);

=head2 prepare_raygun

Prepare the data for conversion to JSON.

=cut

sub prepare_raygun {
    my $self = shift;
    return {
        lineNumber => $self->line_number,
        className  => $self->class_name,
        fileName   => $self->file_name,
        methodName => $self->method_name,
    };
}

=head1 DEPENDENCIES


=head1 SEE ALSO


=cut

__PACKAGE__->meta->make_immutable();

1;

__END__
