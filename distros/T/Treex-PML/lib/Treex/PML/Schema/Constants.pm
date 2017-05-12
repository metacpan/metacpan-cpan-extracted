package Treex::PML::Schema::Constants;

use 5.008;
use strict;
use warnings;

use vars qw($VERSION);
BEGIN {
  $VERSION='2.22'; # version template
}
use Carp;

use constant PML_SCHEMA_NS         => "http://ufal.mff.cuni.cz/pdt/pml/schema/";

use constant   PML_TYPE_DECL        =>  1;
use constant   PML_ROOT_DECL        =>  2;
use constant   PML_STRUCTURE_DECL   =>  3;
use constant   PML_CONTAINER_DECL   =>  4;
use constant   PML_SEQUENCE_DECL    =>  5;
use constant   PML_LIST_DECL        =>  6;
use constant   PML_ALT_DECL         =>  7;
use constant   PML_CDATA_DECL       =>  8;
use constant   PML_CHOICE_DECL      =>  9;
use constant   PML_CONSTANT_DECL    => 10;
use constant   PML_ATTRIBUTE_DECL   => 11;
use constant   PML_MEMBER_DECL      => 12;
use constant   PML_ELEMENT_DECL     => 13;
use constant   PML_SCHEMA_DECL      => 14;

use constant   PML_IMPORT_DECL      => 20;
use constant   PML_DERIVE_DECL      => 21;
use constant   PML_TEMPLATE_DECL    => 22;
use constant   PML_COPY_DECL        => 23;

# validation flags
use constant   PML_VALIDATE_NO_TREES        => 1;
use constant   PML_VALIDATE_NO_CHILDNODES   => 2;

BEGIN {
  require Exporter;
  import Exporter qw( import );
  our @EXPORT = qw(
	       PML_TYPE_DECL
	       PML_ROOT_DECL
	       PML_STRUCTURE_DECL
	       PML_CONTAINER_DECL
	       PML_SEQUENCE_DECL
	       PML_LIST_DECL
	       PML_ALT_DECL
	       PML_CDATA_DECL
	       PML_CHOICE_DECL
	       PML_CONSTANT_DECL
	       PML_ATTRIBUTE_DECL
	       PML_MEMBER_DECL
	       PML_ELEMENT_DECL
	       PML_SCHEMA_DECL
	       PML_IMPORT_DECL
	       PML_DERIVE_DECL
	       PML_TEMPLATE_DECL
	       PML_COPY_DECL

	       PML_VALIDATE_NO_TREES
	       PML_VALIDATE_NO_CHILDNODES

	       PML_SCHEMA_NS
  );
  our %EXPORT_TAGS = (
    'constants' => [ @EXPORT ],
  );
}
1;
__END__

=head1 NAME

Treex::PML::Schema::Constants - constants used by the Treex::PML::Schema modules

=head2 CONSTANTS

The following string constant is exported by default:

PML_SCHEMA_NS => "http://ufal.mff.cuni.cz/pdt/pml/schema/"

The following integer constants are provided and exported by default:

  PML_TYPE_DECL
  PML_ROOT_DECL
  PML_STRUCTURE_DECL
  PML_CONTAINER_DECL
  PML_SEQUENCE_DECL
  PML_LIST_DECL
  PML_ALT_DECL
  PML_CDATA_DECL
  PML_CHOICE_DECL
  PML_CONSTANT_DECL
  PML_ATTRIBUTE_DECL
  PML_MEMBER_DECL
  PML_ELEMENT_DECL
  PML_IMPORT_DECL
  PML_DERIVE_DECL
  PML_TEMPLATE_DECL
  PML_COPY_DECL

=cut

=head1 SEE ALSO

L<Treex::PML>, L<Treex::PML::Schema>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Petr Pajas

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.2 or,
at your option, any later version of Perl 5 you may have available.

=cut
