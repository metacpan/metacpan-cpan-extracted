package Treex::PML::StandardFactory;

use 5.008;
use strict;
use warnings;

use vars qw($VERSION);
BEGIN {
  $VERSION='2.22'; # version template
}
use Carp;

use base qw(Treex::PML::Factory);
use UNIVERSAL::DOES;

use Treex::PML::Struct;
use Treex::PML::Container;
use Treex::PML::Alt;
use Treex::PML::List;
use Treex::PML::Seq;
use Treex::PML::Node;
use Treex::PML::FSFormat;
use Treex::PML::Document;

sub createPMLSchema {
  my $self = shift;
  return Treex::PML::Schema->new(@_);
}

sub createPMLInstance {
  my $self = shift;
  if (@_) {
    return $self->createPMLInstance()->load(@_);
  } else {
    return Treex::PML::Instance->new();
  }
}

sub createDocument {
  my $self = shift;
  return Treex::PML::Document->new(@_);
}

sub createDocumentFromFile {
  my $self = shift;
  return $self->createDocument->load(@_);
}

sub createFSFormat {
  my $self = shift;
  return Treex::PML::FSFormat->new(@_);
}

sub createNode {
  my $self=shift;
  return Treex::PML::Node->new(@_);
}

sub createTypedNode {
  my $self = shift;
  my $node;
  if (@_>1 and !ref($_[0]) and UNIVERSAL::DOES::does($_[1],'Treex::PML::Schema')) {
    my $type = shift;
    my $schema = shift;
    $node = $self->createNode(@_);
    $node->set_type_by_name($schema,$type);
  } else {
    my $decl = shift;
    $node = $self->createNode(@_);
    $node->set_type($decl);
  }
  return $node;
}

sub createList {
  my $self = shift;
  return @_>0 ? Treex::PML::List->new_from_ref(@_) : Treex::PML::List->new();
}

sub createSeq {
  my $self = shift;
  return Treex::PML::Seq->new(@_);
}

sub createAlt {
  my $self = shift;
  return @_>0 ? Treex::PML::Alt->new_from_ref(@_) : Treex::PML::Alt->new();
}

sub createContainer {
  my $self = shift;
  return Treex::PML::Container->new(@_);
}

sub createStructure {
  my $self = shift;
  return Treex::PML::Struct->new(@_);
}


1;
__END__

=head1 NAME

Treex::PML::StandardFactory - implements standard Treex::PML object factory

=head1 SYNOPSIS

   use Treex::PML::StandardFactory;
   Treex::PML::StandardFactory->make_default();

   # actually 'use Treex::PML' does all this when first loaded

=head1 DESCRIPTION

This class implements the standard object factory for L<Treex::PML>,
returning instances of the following classes:

L<Treex::PML::Struct>
L<Treex::PML::Container>
L<Treex::PML::Alt>
L<Treex::PML::List>
L<Treex::PML::Seq>
L<Treex::PML::Node>
L<Treex::PML::FSFormat>
L<Treex::PML::Document>

=head2 EXPORT

None by default.

=head1 SEE ALSO

L<Treex::PML>, L<Treex::PML::Factory>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Petr Pajas

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.2 or,
at your option, any later version of Perl 5 you may have available.

=head1 BUGS

None reported... yet.

=cut

