package BogusVersion;

use 5.008001;

use strict;
use warnings;

use Carp;
use Exporter qw{ import };

our $VERSION = '0.009';
$VERSION =~ s/ _ //smxg;

1;

__END__

=head1 NAME

BogusVersion - Module whose only purpose is to fail a version check.

=head1 SYNOPSIS

 use BogusVersion 9999; # Compile error, version check

=head1 DESCRIPTION

This Perl module is used for testing C<Test2::Tools::LoadModule>.
Its sole function is to fail to be loaded because the required module
version is greater than the version this module implements.

=head1 SUBROUTINES

None whatsoever.

=head1 SUPPORT

Support is by the author. Please file bug reports at
L<https://rt.cpan.org/Public/Dist/Display.html?Name=Test2-Tools-LoadModule>,
L<https://github.com/trwyant/perl-Test2-Tools-LoadModule/issues>, or in
electronic mail to the author.

=head1 AUTHOR

Thomas R. Wyant, III F<wyant at cpan dot org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2020-2026 by Thomas R. Wyant, III

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl 5.10.0. For more details, see the full text
of the licenses in the files F<LICENSE-Artistic> and F<LICENSE-GPL>.

This program is distributed in the hope that it will be useful, but
without any warranty; without even the implied warranty of
merchantability or fitness for a particular purpose.

=cut

# ex: set textwidth=72 :
