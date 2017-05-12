package W3C::SOAP::Exception;
use Moose;
use warnings;
extends 'MooseX::Exception::Base';

our $VERSION = 0.14;

has '+_verbose' => (
    default => 2,
);
has faultcode => (
    is   => 'rw',
    isa  => 'Maybe[Str]',
);
has faultstring => (
    is   => 'rw',
    isa  => 'Maybe[Str]',
    traits => [qw{MooseX::Exception::Stringify}],
);
has faultactor => (
    is   => 'rw',
    isa  => 'Maybe[Str]',
);
has detail => (
    is   => 'rw',
    isa  => 'Maybe[Str]',
    traits => [qw{MooseX::Exception::Stringify}],
);

package W3C::SOAP::Exception::HTTP;
use Moose;
use warnings;
extends 'W3C::SOAP::Exception';

our $VERSION = 0.14;

package W3C::SOAP::Exception::XML;
use Moose;
use warnings;
extends 'W3C::SOAP::Exception';

our $VERSION = 0.14;

has '+detail' => ( default => 'XML', stringify_pre => 'Type : ' );

package W3C::SOAP::Exception::Doomed;
use Moose;
use warnings;
extends 'W3C::SOAP::Exception';

our $VERSION = 0.14;

package W3C::SOAP::Exception::BadInput;
use Moose;
use warnings;
extends 'MooseX::Exception::Base';

our $VERSION = 0.14;

has param => (
    is   => 'rw',
    isa  => 'Str',
);
has message => (
    is   => 'rw',
    isa  => 'Str',
    traits => [qw{MooseX::Exception::Stringify}],
);


1;

__END__

=head1 NAME

W3C::SOAP::Exception - Exceptions for SOAP Clients etc

=head1 SYNOPSIS

   use W3C::SOAP::Exception;

=head1 DESCRIPTION

Exceptions thrown by L<W3C::SOAP> objects.

=head1 ALSO SEE

L<Exception::Class>

=cut
