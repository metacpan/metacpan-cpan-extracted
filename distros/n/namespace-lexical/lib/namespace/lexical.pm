use 5.012;
use strict;
use warnings;

package namespace::lexical;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.002';

use Package::Stash ();

BEGIN {
	if (eval { require Lexical::Sub; 1 }) {
		*_LEXICAL_SUB_CLASS          = sub () { 'Lexical::Sub' };
		*_LEXICAL_SUB_IMPORT_METHOD  = sub () { 'import' };
	}
	else {
		require Lexical::Importer;
		*_LEXICAL_SUB_CLASS          = sub () { 'Lexical::Importer' };
		*_LEXICAL_SUB_IMPORT_METHOD  = sub () { '_import_lex_sub' };
	}
}

sub import {
	my $class = shift;
	my $for = caller;
	my $stash = 'Package::Stash'->new($for);
	my $subs = $stash->get_all_symbols('CODE');
	for my $name (sort keys %$subs) {
		$class->lexicalize($stash, $name, $subs->{$name});
	}
	return;
}

sub lexicalize {
	my $class = shift;
	my ($stash, $name, $coderef) = @_;
	if (defined $stash) {
		$stash = 'Package::Stash'->new($stash) unless ref $stash;
		$coderef ||= $stash->get_symbol('&'.$name);
		$stash->remove_symbol('&'.$name);
	}
	die "coderef plz" unless defined $coderef;
	_LEXICAL_SUB_CLASS->${\ _LEXICAL_SUB_IMPORT_METHOD }($name, $coderef);
	return;
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

namespace::lexical - like namespace::clean but instead of deleting subs, makes them lexical

=head1 SYNOPSIS

  package My::Class;
  use Scalar::Util 'blessed';
  use namespace::lexical;
  
  # blessed() is available here but there
  # is no My::Class->blessed() method.
  
  package My::Other::Class;
  
  # blessed() is still available here!!!

=head1 DESCRIPTION

B<< namespace::lexical >> works a lot like L<namespace::clean> but rather
than removing functions from your namespace, it converts them into lexical
subs (like C<< my sub foo { ... } >> on Perl 5.18 and above).

namespace::lexical requires Perl 5.12 or above.

=head2 API

=over

=item C<< import >>

The standard way to use this module is:

  use namespace::lexical;

This will loop through all functions defined so far in the caller package
and lexicalize them.

=item C<< lexicalize($stash, $subname, $coderef) >>

This method should be passed a L<Package::Stash> object, a sub name, and
an optional coderef. It will remove the sub by name from the provided
stash, and install the coderef into the caller lexical scope using the
given name.

If no coderef is given, it will grab the existing coderef from the stash.

If the stash is undef, it will skip removing the sub from the stash and
only install the lexical version.

The coderef and stash cannot both be undef.

Most end users will have no reason to call this method directly.

=back

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=namespace-lexical>.

=head1 SEE ALSO

L<Lexical::Sub>,
L<namespace::clean>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2018 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

