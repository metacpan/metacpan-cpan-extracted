#
# Copyright (c) 200[789] Mons Anderson <mons@cpan.org>. All rights reserved
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
package ex::lib;

=head1 NAME

ex::lib - The same as lib, but makes relative path absolute. (Obsoleted by lib::abs)

=cut

$ex::lib::VERSION = '0.90';

=head1 VERSION

Version 0.90

=head1 SYNOPSIS

Don't use this module. It's just a compatibility wrapper for C<lib::abs>

But if you want, see the docs for C<lib::abs>. Interface is the same

=head1 BUGS

None known

=head1 COPYRIGHT & LICENSE

Copyright 2007-2009 Mons Anderson.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 AUTHOR

Mons Anderson, <mons@cpan.org>

=cut

use strict;
use warnings;
use lib::abs ();

*ex::lib::import    = \&lib::abs::import;
*ex::lib::unimport  = \&lib::abs::unimport;

*ex::lib::mkapath   = \&lib::abs::mkapath;
*ex::lib::path      = \&lib::abs::path;

1;
