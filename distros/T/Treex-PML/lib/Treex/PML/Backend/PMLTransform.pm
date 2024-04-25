package Treex::PML::Backend::PMLTransform;

use vars qw($VERSION);
BEGIN {
  $VERSION='2.27'; # version template
}

use Treex::PML::Backend::PML qw(open_backend close_backend read write);

sub test {
  local $Treex::PML::Backend::PML::TRANSFORM=1;
  return &Treex::PML::Backend::PML::test;
}

1;

=pod

=head1 NAME

Treex::PML::Backend::PMLTransform - I/O backend implementing on-the-fly XML to PML conversion

=head1 SYNOPSIS

  use Treex::PML;
  Treex::PML::AddBackends(qw(PMLTransform))

  my $document = Treex::PML::Factory->createDocumentFromFile('input.xml');
  ...
  $document->save();

=head1 DESCRIPTION

This module implements a Treex::PML input/output backend which accepts
any XML file and attempts to convert it to PML using user-defined
transformations (XSLT 1.0, Perl, or external command). See
L<Treex::PML::Instance/"CONFIGURATION"> for details.

WARNING: since this backend accepts every XML file, it should be added as
the last backend (otherwise other backends working with XML will not
be tried).

=head2 BUGS

If your system uses libxslt version 1.1.27, the XSLT transformation
does not work. Upgrade your system.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006-2010 by Petr Pajas, 2010-2024 Jan Stepanek

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.2 or,
at your option, any later version of Perl 5 you may have available.

=cut
