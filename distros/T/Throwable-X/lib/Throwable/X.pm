package Throwable::X;
{
  $Throwable::X::VERSION = '0.007';
}
use Moose::Role;
# ABSTRACT: useful eXtra behavior for Throwable exceptions


use Throwable::X::Types;

use namespace::clean -except => 'meta';

# Does this belong elsewhere? -- rjbs, 2010-10-18
use Sub::Exporter -setup => {
  exports => { Payload => \'__payload' },
};
sub __payload { sub { 'Role::HasPayload::Meta::Attribute::Payload' } }

with(
  'Throwable',
  'Role::HasPayload::Merged',
  'Role::Identifiable::HasIdent',
  'Role::Identifiable::HasTags',

  'Role::HasMessage::Errf' => {
    default  => sub { $_[0]->ident },
    lazy     => 1,
  },

  'MooseX::OneArgNew' => {
    type     => 'Throwable::X::_VisibleStr',
    init_arg => 'ident',
  },
);

# Can't do this because we can't +attr in roles.  Can't use methods with type,
# because methods are too late to parameterize roles.  Would rather not add
# MXRP as a prereq to all the subroles. -- rjbs, 2010-10-28
# has '+ident'       => (isa => 'Throwable::X::_Ident');
# has '+message_fmt' => (isa => 'Throwable::X::_VisibleStr');

has is_public => (
  is  => 'ro',
  isa => 'Bool',
  init_arg => 'public',
  default  => 0,
);

1;

__END__

=pod

=head1 NAME

Throwable::X - useful eXtra behavior for Throwable exceptions

=head1 VERSION

version 0.007

=head1 SYNOPSIS

Write an exception class:

  package X::BadValue;
  use Moose;

  with qw(Throwable::X StackTrace::Auto);

  use Throwable::X -all; # to get the Payload helper

  sub x_tags { qw(value) }

  # What bad value were we given?
  has given_value => (
    is => 'ro',
    required => 1,
    traits   => [ Payload ],
  );

  # What was the value supposed to be used for?
  has given_for => (
    is  => 'ro',
    isa => 'Str',
    traits => [ Payload ],
  );

Throw the exception when you need to:

  X::BadValue->throw({
    ident   => 'bad filename',
    tags    => [ qw(filename) ],
    public  => 1,
    message => "invalid filename %{given_value}s for %{given_for}s",
    given_value => $input,
    given_for   => 'user home directory',
  });

...and when catching:

  } catch {
    my $error = $_;

    if ($error->does('Throwable::X') and $error->is_public) {

      # Prints something like:
      # invalid filename \usr\local\src for user home directory

      print $error->message, "\n\n", $error->stack_trace->as_string;
    }
  }

=head1 DESCRIPTION

Throwable::X is a collection of behavior for writing exceptions.  It's meant to
provide:

=over 4

=item *

means by which exceptions can be identified without string parsing

=item *

a structure that can be serialized and reconstituted in other environments

=item *

maximum composability by dividing features into individual roles

=back

Throwable::X composes the following roles.  Each one is documented, but an
overview of the features is also provided below so you don't need to hop around
in a half dozen roles to understand how to benefit from Throwable::X.

=over 4

=item *

L<Throwable>

=item *

L<Role::HasPayload::Merged>

=item *

L<Role::HasMessage::Errf>

=item *

L<Role::Identifiable::HasIdent>

=item *

L<Role::Identifiable::HasTags>

=back

Note that this list does I<not> include L<StackTrace::Auto>.  Building a stack
isn't needed in all scenarios, so if you want your exceptions to automatically
capture a stack trace, compose StackTrace::Auto when building your exception
classes.

=head2 Features for Identification

Every Throwable::X exception has a required C<ident> attribute that contains a
one-line string with printable characters in it.  Ideally, the ident doesn't
try to describe everything about the error, but serves as a unique identifier
for the kind of exception being thrown.  Exception handlers looking for
specific exceptions can then check the ident for known values.  It can also be
used for refinement or localization of the message format, described below.
This feature is provided by L<Role::Identifiable::HasIdent>.

For less specific identification of classes of exceptions, the exception can be
checked for what roles it performs with C<does>, or its tags can be checked
with C<has_tag>.  All the tags reported by the C<x_tags> methods of every class
and role in the exception's composition are present, as well as per-instance
tags provided when the exception was thrown.  Tags as simple strings consisting
of letters, numbers, and dashes.  This feature is provided by
L<Role::Identifiable::HasTags>.

Throwable::X exceptions also have a message, which (unlike the C<ident>) is
meant to be a human-readable string describing precisely what happened.  The
C<message> argument given when throwing an exception uses a C<sprintf>-like
dialect implemented (and described) by L<String::Errf>.  It picks data out of
the C<payload> (described below) to produce a filled-in string when the
C<message> method is called.  (The L<synopsis|/SYNOPSIS> above gives a very
simple example of how this works, but the String::Errf documentation is more
useful, generally.)  This feature is provided by
L<Role::HasMessage::Errf>.

=head2 Features for Serialization

The C<payload> method returns a hashref containing the name and value of every
attribute with the trait L<Role::HasPayload::Meta::Attribute::Payload>, merged
with the hashref (if any) provided as the C<payload> entry to the constructor.
There's nothing more to it than that.  It's used by the message formatting
facility descibed above, and is also useful for serializing exceptions.
Assuming no complex values are present in the payload, the structure below
should be easy to serialize and use in another program, for example in a web
browser receiving a serialized Throwable::X via JSON in response to an
XMLHTTPRequest.

  {
    ident   => $err->ident,
    message => $err->message_fmt,
    tags    => [ $err->tags ],
    payload => $err->payload,
  }

There is no specific code present to support doing this, yet.

The C<payload> method is implemented by L<Role::HasPayload::Merged>.

The C<public> attribute, checked with the C<is_public> method, is meant to
indicate whether the exception's message is safe to display to end users or
send across the wire to remote clients.

=head2 Features for Convenience

The C<throw> (or C<new>) method on a Throwable::X exception class can be passed
a single string, in which case it will be used as the exception's C<ident>.
This is (of course) only useful if no other attribute of the exception is
required.  This feature is provided by L<MooseX::OneArgNew>.

=head1 AUTHOR

Ricardo Signes <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Ricardo Signes.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
