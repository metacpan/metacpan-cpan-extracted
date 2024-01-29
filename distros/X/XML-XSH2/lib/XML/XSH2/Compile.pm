# $Id: Compile.pm,v 1.2 2007-01-02 22:03:22 pajas Exp $

package XML::XSH2::Compile;
use Module::Compile -base;

use vars qw($VERSION);

use strict;
  $VERSION='2.2.10'; # VERSION TEMPLATE

sub pmc_compile {
  my ($class, $source) = @_;
  require XML::XSH2;
  my $dump='';
  $XML::XSH2::Functions::DUMP=\$dump;
  XML::XSH2::set_compile_only_mode(1);
  XML::XSH2::set_quiet(1);
  XML::XSH2::xsh($source);
  return $dump;
};

1;

=head1 NAME

XML::XSH2::Compile - Create modules with built-in XSH commands

=head1 SYNOPSIS

   package Foo;

   # perl code

   use XML::XSH2::Compile;

   # XSH Language commands (see L<XSH>)

   no XML::XSH2::Compile;

   # perl code
   1;

=head1 DESCRIPTION

With this module one can efficiently embed XSH2 scripts into Perl
modules.  In this respect, it is similar to C<XML::XSH2::Inline>, but
with C<XML::XSH2::Compile>, all XSH2 blocks are compiled into Perl
code the first time the module is run. This makes them execute faster
any later time. The compiled result is cached in a ".pmc" file.

See L<Module::Compile> for more details.

=head1 REQUIRES

Module::Compile, XML::XSH2

=head1 EXPORTS

None.

=head1 AUTHOR

Petr Pajas, pajas@matfyz.cz

=head1 SEE ALSO

L<Module::Compile>, L<xsh>, L<XSH>, L<XML::XSH2>, L<XML::XSH2::Inline>

=cut

