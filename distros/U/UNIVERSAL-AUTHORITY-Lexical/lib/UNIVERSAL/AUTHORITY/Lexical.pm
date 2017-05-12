package UNIVERSAL::AUTHORITY::Lexical;

use 5.008001;
use strict;

BEGIN {
	$UNIVERSAL::AUTHORITY::Lexical::AUTHORITY = 'cpan:TOBYINK';
	$UNIVERSAL::AUTHORITY::Lexical::VERSION   = '0.003';	
}

use Object::AUTHORITY;
use parent qw(Method::Lexical);

sub import
{
	(shift)->SUPER::import(
		'UNIVERSAL::AUTHORITY' => \&Object::AUTHORITY::AUTHORITY,
		);
}

1;

__END__

=head1 NAME

UNIVERSAL::AUTHORITY::Lexical - an AUTHORITY method for every class, within a lexical scope

=head1 SYNOPSIS

 if (HTML::HTML5::Writer->AUTHORITY ne HTML::HTML5::Builder->AUTHORITY)
 {
   warn "Closely intertwined modules with different authors!\n";
   warn "There may be trouble ahead...";
 }

 # Only trust STEVAN's releases
 Moose->AUTHORITY('cpan:STEVAN'); # dies if doesn't match

=head1 DESCRIPTION

This module adds an C<AUTHORITY> method to the C<UNIVERSAL> package, which
works along the same lines as the C<VERSION> function. Because it is defined
in C<UNIVERSAL>, it becomes instantly available as a method for any blessed
objects, and as a class method for any package.

The method is defined only for the lexical scope you import this package
into. For example:

  {
    use UNIVERSAL::AUTHORITY::Lexical;
    say Moose->AUTHORITY;
  }
  say Moose->AUTHORITY;  # no such method, dies.

The authority of a package can be defined like this:

 package MyApp;
 BEGIN { $MyApp::AUTHORITY = 'cpan:JOEBLOGGS'; }

The authority should be a URI identifying the person, team, organisation
or trained chimp responsible for the release of the package. The
pseudo-URI scheme C<< cpan: >> is the most commonly used identifier.

=head2 C<< AUTHORITY >>

Called with no parameters returns the authority of a CPAN release.

=head2 C<< AUTHORITY($test) >>

If passed a test, will croak if the test fails. The authority is tested
against the test using something approximating Perl 5.10's smart match
operator. (Briefly, you can pass a string for C<eq> comparison, a regular
expression, a code reference to use as a callback, or an array reference
that will be grepped.)

=head1 BUGS

Currently C<< UNIVERSAL->can('AUTHORITY') >> returns false.

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=UNIVERSAL-AUTHORITY-Lexical>.

=head1 SEE ALSO

=over

=item * L<Object::AUTHORITY> - an AUTHORITY method for your class

=item * L<authority::shared> - a more sophisticated AUTHORITY method for your class

=item * L<UNIVERSAL::AUTHORITY> - an AUTHORITY method for every class (deprecated)

=item * I<UNIVERSAL::AUTHORITY::Lexical> (this module) - an AUTHORITY method for every class, within a lexical scope

=item * L<authority> - load modules only if they have a particular authority

=back

Background reading: L<http://feather.perl6.nl/syn/S11.html>,
L<http://www.perlmonks.org/?node_id=694377>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2011 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

