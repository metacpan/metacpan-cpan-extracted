package autodie::variables;
{
  $autodie::variables::VERSION = '0.005';
}
use 5.010;
use strict;
use warnings;

use XSLoader;

XSLoader::load(__PACKAGE__, __PACKAGE__->VERSION);

_reset_global($_) for ($<, $>, $(, $));

sub import {
	$^H |= 0x020000;
	$^H{autodie_variables} = 1;
	return;
}

sub unimport {
	$^H |= 0x020000;
	$^H{autodie_variables} = 0;
	return;
}

1;

# ABSTRACT: Safe user and group ID variables



=pod

=head1 NAME

autodie::variables - Safe user and group ID variables

=head1 VERSION

version 0.005

=head1 SYNOPSIS

 use autodie::variables;

 local $> = $<;

=head1 DESCRIPTION

This module overrides the magic on the user and group ID variables (C<< $< >>, C<< $> >>, C<$(>, C<$)>) to throw errors when assignment to them fails.

=for Pod::Coverage unimport

=head1 AUTHOR

Leon Timmermans <leont@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Leon Timmermans.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

