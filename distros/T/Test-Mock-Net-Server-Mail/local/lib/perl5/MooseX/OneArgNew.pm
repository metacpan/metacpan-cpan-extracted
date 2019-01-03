package MooseX::OneArgNew;
$MooseX::OneArgNew::VERSION = '0.005';
use MooseX::Role::Parameterized 1.01;
# ABSTRACT: teach ->new to accept single, non-hashref arguments

#pod =head1 SYNOPSIS
#pod
#pod In our class definition:
#pod
#pod   package Delivery;
#pod   use Moose;
#pod   with('MooseX::OneArgNew' => {
#pod     type     => 'Existing::Message::Type',
#pod     init_arg => 'message',
#pod   });
#pod
#pod   has message => (isa => 'Existing::Message::Type', required => 1);
#pod
#pod   has to => (
#pod     is   => 'ro',
#pod     isa  => 'Str',
#pod     lazy => 1,
#pod     default => sub {
#pod       my ($self) = @_;
#pod       $self->message->get('To');
#pod     },
#pod   );
#pod
#pod When making a message:
#pod
#pod   # The traditional way:
#pod
#pod   my $delivery = Delivery->new({ message => $message });
#pod   # or
#pod   my $delivery = Delivery->new({ message => $message, to => $to });
#pod
#pod   # With one-arg new:
#pod
#pod   my $delivery = Delivery->new($message);
#pod
#pod =head1 DESCRIPTION
#pod
#pod MooseX::OneArgNew lets your constructor take a single argument, which will be
#pod translated into the value for a one-entry hashref.  It is a L<parameterized
#pod role|MooseX::Role::Parameterized> with three parameters:
#pod
#pod =begin  :list
#pod
#pod = type
#pod
#pod The Moose type that the single argument must be for the one-arg form to work.
#pod This should be an existing type, and may be either a string type or a
#pod MooseX::Type.
#pod
#pod = init_arg
#pod
#pod This is the string that will be used as the key for the hashref constructed
#pod from the one-arg call to new.
#pod
#pod = coerce
#pod
#pod If true, a single argument to new will be coerced into the expected type if
#pod possible.  Keep in mind that if there are no coercions for the type, this will
#pod be an error, and that if a coercion from HashRef exists, you might be getting
#pod yourself into a weird situation.
#pod
#pod =end :list
#pod
#pod =head2 WARNINGS
#pod
#pod You can apply MooseX::OneArgNew more than once, but if more than one
#pod application's type matches a single argument to C<new>, the behavior is
#pod undefined and likely to cause bugs.
#pod
#pod It would be a B<very bad idea> to supply a type that could accept a normal
#pod hashref of arguments to C<new>.
#pod
#pod =cut

use Moose::Util::TypeConstraints;

use namespace::autoclean;

subtype 'MooseX::OneArgNew::_Type',
  as 'Moose::Meta::TypeConstraint';

coerce 'MooseX::OneArgNew::_Type',
  from 'Str',
  via { Moose::Util::TypeConstraints::find_type_constraint($_) };

parameter type => (
  isa      => 'MooseX::OneArgNew::_Type',
  coerce   => 1,
  required => 1,
);

parameter coerce => (
  isa      => 'Bool',
  default  => 0,
);

parameter init_arg => (
  isa      => 'Str',
  required => 1,
);

role {
  my $p = shift;

  around BUILDARGS => sub {
    my $orig = shift;
    my $self = shift;
    return $self->$orig(@_) unless @_ == 1;

    my $value = $p->coerce ? $p->type->coerce($_[0]) : $_[0];
    return $self->$orig(@_) unless $p->type->check($value);

    return { $p->init_arg => $value }
  };
};

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MooseX::OneArgNew - teach ->new to accept single, non-hashref arguments

=head1 VERSION

version 0.005

=head1 SYNOPSIS

In our class definition:

  package Delivery;
  use Moose;
  with('MooseX::OneArgNew' => {
    type     => 'Existing::Message::Type',
    init_arg => 'message',
  });

  has message => (isa => 'Existing::Message::Type', required => 1);

  has to => (
    is   => 'ro',
    isa  => 'Str',
    lazy => 1,
    default => sub {
      my ($self) = @_;
      $self->message->get('To');
    },
  );

When making a message:

  # The traditional way:

  my $delivery = Delivery->new({ message => $message });
  # or
  my $delivery = Delivery->new({ message => $message, to => $to });

  # With one-arg new:

  my $delivery = Delivery->new($message);

=head1 DESCRIPTION

MooseX::OneArgNew lets your constructor take a single argument, which will be
translated into the value for a one-entry hashref.  It is a L<parameterized
role|MooseX::Role::Parameterized> with three parameters:

=over 4

=item type

The Moose type that the single argument must be for the one-arg form to work.
This should be an existing type, and may be either a string type or a
MooseX::Type.

=item init_arg

This is the string that will be used as the key for the hashref constructed
from the one-arg call to new.

=item coerce

If true, a single argument to new will be coerced into the expected type if
possible.  Keep in mind that if there are no coercions for the type, this will
be an error, and that if a coercion from HashRef exists, you might be getting
yourself into a weird situation.

=back

=head2 WARNINGS

You can apply MooseX::OneArgNew more than once, but if more than one
application's type matches a single argument to C<new>, the behavior is
undefined and likely to cause bugs.

It would be a B<very bad idea> to supply a type that could accept a normal
hashref of arguments to C<new>.

=head1 AUTHOR

Ricardo Signes <rjbs@cpan.org>

=head1 CONTRIBUTORS

=for stopwords George Hartzell William Orr

=over 4

=item *

George Hartzell <hartzell@alerce.com>

=item *

William Orr <will@worrbase.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Ricardo Signes.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
