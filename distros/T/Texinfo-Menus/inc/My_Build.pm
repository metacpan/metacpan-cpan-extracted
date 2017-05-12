#---------------------------------------------------------------------
package inc::My_Build;
#
# Copyright 2007 Christopher J. Madsen
#
# Author: Christopher J. Madsen <perl@cjmweb.net>
# Created: 13 Mar 2006
#
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See either the
# GNU General Public License or the Artistic License for more details.
#
# Customize Module::Build to improve find_perl_interpreter
#---------------------------------------------------------------------

require 5.008;
use strict;
use Cwd 'abs_path';
use File::Spec ();

use Module::Build ();
our @ISA = qw(Module::Build);

#=====================================================================
# Package Global Variables:

our $VERSION = '1.03';

#=====================================================================
sub find_perl_interpreter
{
  my $self = shift @_;

  my $perl = $self->SUPER::find_perl_interpreter(@_);

  # Convert /usr/bin/perl5.8.6 to /usr/bin/perl:
  #  (if the latter is a symlink to the former)
  my $base = $perl;
  if ($base =~ s/[\d.]+$// and -l $base and abs_path($base) eq $perl) {
    $perl = $base;
  }

  return $perl;
} # end find_perl_interpreter

#=====================================================================
# Package Return Value:

1;
