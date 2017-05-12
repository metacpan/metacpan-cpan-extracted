#! /usr/local/bin/perl -w

# vim: tabstop=4
# $Id: Build.PL,v 1.2 2006/05/12 12:42:14 guido Exp $

# Experimental build builder script for Test-Unit-GTestRunner.
# Copyright (C) 2004-2006 Guido Flohr <guido@imperia.net>,
# all rights reserved.

# This program is free software; you can redistribute it and/or modify it
# under the terms of the GNU Library General Public License as published
# by the Free Software Foundation; either version 2, or (at your option)
# any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Library General Public License for more details.

# You should have received a copy of the GNU Library General Public
# License along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307,
# USA.

use strict;

use Module::Build;

my $build = Module::Build->new 
    (
     module_name => 'Test::Unit::GTestRunner',
     license => 'gpl',
     requires => {
	 Gtk2 => 0,
	 'Gtk2::GladeXML' => 0,
	 'Test::Unit' => 0,
	 'Locale::TextDomain' => '1.16',
     },
     script_files => 'bin/gtestrunner',
     );

$build->create_build_script;

__END__

=head1 NAME

Build.PL - Build and install Test-Unit-GTestRunner

=head1 SYNOPSIS

The usual plethora:

    perl Build.PL
    ./Build
    ./Build test
    ./Build install

Or, if you're on a platform (like MS-DOS or Windows) that doesn't like the
"./" notation, you can do this:

    perl Build.PL
    perl Build
    perl Build test
    perl Build install

Please see Module::Build(3pm) for more build options.

=head1 DESCRIPTION

This build script provides an alternative to building 
Test-Unit-GTestRunner, in case your vendor does not supply a
make(1) program.  See Module::Build(3pm) for details.

If you have difficulties building the module like this, try the
good old way:

    perl Makefile.PL
    make
    make test 
    make install

Please notice that it is not recommended to use this build script for
developping the module, creating new distributions and so on.  This
functionality will only be guaranteed by Makefile.PL and the Makefiles
it generates.

=head1 AUTHOR

Copyright (C) 2004-2006, Guido Flohr E<lt>guido@imperia.netE<gt>
and Виктор Кожухаров E<lt>viktor.kojouharov@imperia.netE<gt>, all
rights reserved.  See the source code for details.

This software is contributed to the Perl community by Imperia
 (L<http://www.imperia.net/>).

=head1 SEE ALSO

Module::Build(3pm), ExtUtils::MakeMaker(3pm), gtestrunner(1),
Test::Unit::GTestRunner(3pm), make(1), perl(1)

=cut

Local Variables:
mode: perl
perl-indent-level: 4
perl-continued-statement-offset: 4
perl-continued-brace-offset: 0
perl-brace-offset: -4
perl-brace-imaginary-offset: 0
perl-label-offset: -4
cperl-indent-level: 4
cperl-continued-statement-offset: 2
tab-width: 4
End:
