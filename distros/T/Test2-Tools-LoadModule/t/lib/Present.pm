package Present;

use 5.008001;

use strict;
use warnings;

use Carp;
use Exporter qw{ import };

our $VERSION = '0.008';
$VERSION =~ s/ _ //smxg;

our @EXPORT = qw{ and_accounted_for };
our @EXPORT_OK = ( @EXPORT, qw{ under_the_tree } );

sub and_accounted_for () {};

sub under_the_tree () {};

1;

__END__

=head1 NAME

Present - Module whose only purpose is to be loadable

=head1 SYNOPSIS

 use lib qw{ t/lib };
 use Present;

=head1 DESCRIPTION

This Perl module is used for testing C<Test2::Tools::LoadModule>.
Its sole function is to be loaded correctly.

=head1 SUBROUTINES

This module provides the following subroutines:

=head2 and_accounted_for

This subroutine does nothing whatsoever. It is exported by default.

=head2 under_the_tree

This subroutine does absolutely nothing. It is exportable, but is not
exported by default.

=head1 SUPPORT

Support is by the author. Please file bug reports at
L<https://rt.cpan.org/Public/Dist/Display.html?Name=Test2-Tools-LoadModule>,
L<https://github.com/trwyant/perl-Test2-Tools-LoadModule/issues>, or in
electronic mail to the author.

=head1 AUTHOR

Thomas R. Wyant, III F<wyant at cpan dot org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2020-2022 by Thomas R. Wyant, III

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl 5.10.0. For more details, see the full text
of the licenses in the directory LICENSES.

This program is distributed in the hope that it will be useful, but
without any warranty; without even the implied warranty of
merchantability or fitness for a particular purpose.

=cut

# ex: set textwidth=72 :
