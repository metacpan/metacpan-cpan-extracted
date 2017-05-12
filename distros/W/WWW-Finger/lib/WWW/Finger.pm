package WWW::Finger;

use 5.010;
use common::sense;
use utf8;

use Object::AUTHORITY 0;
use Carp 0;

use namespace::clean;

use Module::Pluggable
	search_path => [qw/WWW::Finger WWW::FingerX/],
	except      => qr/^WWW::Finger(X?)::_/,
	require     => 1,
	inner       => 0,
	sub_name    => 'plugins',
	;

BEGIN {
	$WWW::Finger::AUTHORITY = 'cpan:TOBYINK';
	$WWW::Finger::VERSION   = '0.105';
}

sub new
{
	my $class      = shift;
	my $identifier = shift;

	my @Modules = 
		sort { $a->speed <=> $b->speed }
		$class->plugins;

	foreach my $module (@Modules)
	{
		my $rv = $module->new($identifier);
		return $rv if defined $rv;
	}
	
	return undef;
}

sub name     { return; }
sub mbox     { return; }
sub key      { return; }
sub image    { return; }
sub homepage { return; }
sub weblog   { return; }
sub endpoint { return undef; }
sub webid    { return undef; }
sub graph    { return undef; }

1;

__END__

=head1 NAME

WWW::Finger - get useful data from e-mail addresses

=head1 SYNOPSIS

  use WWW::Finger;
  my $finger = WWW::Finger->new("joe@example.com");
  if (defined $finger)
  {
    print $finger->name . "\n";
  }

=head1 DESCRIPTION

This module is I<not> an implementation of the finger protocol (RFC 1288).
Use Net::Finger for that. Instead it is a set of implementations of
I<other> methods for getting information from an e-mail address, or e-mail
like identifier. This package includes four such implementations, and it's
pretty easy to create your own additional implementations:

=over 8

=item * WebFinger

=item * Fingerpoint

=item * MetaCPAN API for cpan.org addresses

=item * Unnamed finger protocol described on bitworking.org

=back

=head2 Constructor

=over 8

=item * C<new>

  $finger = WWW::Finger->new($identifier);

Creates a WWW::Finger object for a particular identifier. Will return
undef if no implemetation is able to handle the identifier

=back

=head2 Object Methods

Any of these methods can return undef if the appropriate information
is not available. The C<name>, C<mbox>, C<homepage>, C<weblog>,
C<image> and C<key> methods work in both scalar and list context.
Depending on which implementation was used by C<< WWW::Finger->new >>,
the object may also have additional methods. Consult the
documentation of the various implementations for details.

=over

=item C<name>

The person's name (or handle/nickname).

=item C<mbox>

The person's e-mail address (including "mailto:").

=item C<homepage>

The person's personal homepage.

=item C<weblog>

The person's blog. (There may be some overlap with C<homepage>.)

=item C<image>

An avatar, photo or other image depicting the person.

=item C<key>

The URL of the person's GPG/PGP public key.

=item C<webid>

A URI uniquely identifying the person. See L<http://esw.w3.org/topic/WebID>.

=item C<endpoint>

A SPARQL Protocol endpoint which may provide additional data about the person.
(See L<RDF::Query::Client>.)

=item C<graph>

An RDF::Trine::Model object holding data about the person. (See L<RDF::Trine>.)

=back

=head1 SEE ALSO

L<Net::Finger>.

L<http://code.google.com/p/webfinger/>.

L<http://buzzword.org.uk/2009/fingerpoint/spec>.

L<http://www.perlrdf.org/>.

L<fingerw>.

=head1 AUTHOR

Toby Inkster, E<lt>tobyink@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENCE

Copyright (C) 2009-2012 by Toby Inkster

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

=cut

