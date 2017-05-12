package WWW::Mechanize::Plugin::HelloWorld;
use strict;
use warnings;

=head1 NAME

WWW::Mechanize::Plugin::HelloWorld - a sample WWW::Mechanize::Pluggable plugin

-head1 SYNOPSIS

  use WWW::Mechanize::Pluggable;
  # This module is automatically loaded into WWW::Mechanize::Pluggable

=head1 DESCRIPTION

This module shows how to mess with the C<WWW::Mechanize> object contained
within the C<WWW::Mechanize::Pluggable> object. 

Further refinements are left to the reader. Note that the fields in the 
C<WWW::Mechanize::Pluggable> object are also available to the plugins.

=head1 USAGE

    my $mech = new WWW::Mechanize::Pluggable;
    $mech->hello_world;
    # $mech->content now eq 'hello world'

=head1 BUGS

None known.

=head1 SUPPORT

Contact the author at C<mcmahon@yahoo-inc.com>.

=head1 AUTHOR

	Joe McMahon
	mcmahon@yahoo-inc.com

=head1 COPYRIGHT

Copyright 2005 by Joe McMahon and Yahoo!

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=head1 SEE ALSO

L<WWW::Mechanize::Pluggable>, C<WWW::Mechanize>

=head1 CLASS METHODS

=head2 import

This function snags any 'helloworld' key-value pair off the 
C<use WWW::Mechanize> line and sets the C<HELLO> key to it.

Currently this uses a global variable in the C<WW::Mechanize::Pluggable>
namespace to capture the value. This is icky and should be replaced
with something more elegant.

=cut

sub import {
  my ($class, %args) = @_;
  if (defined $args{'helloworld'}) {
    $WWW::Mechanize::Pluggable::HelloWorld = $args{'helloworld'};
  }
}

=head2 init

The C<init()> function exports C<hello_world> into the caller's namespace.

=cut

sub init {
  no strict 'refs';
  *{caller() . '::hello_world'} = \&hello_world;
}

=head2 hello_world

Just a demonstration function; replaces the current content with 'hello world'.
It should be noted that this is not going to pass most tests for "successfully
fetched page" because C<WWW::Mechanize> hasn't processed a valid
request-response pair.

=cut 

sub hello_world {
   my ($self) = shift;
   $self->{Mech}->{content} = 'hello world';
   $self->{HELLO} = $WWW::Mechanize::Pluggable::HelloWorld;
}

1;
