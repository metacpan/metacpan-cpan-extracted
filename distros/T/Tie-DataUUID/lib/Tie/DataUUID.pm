package Tie::DataUUID;

use strict;
use vars qw($VERSION @ISA);

use Tie::Scalar;
@ISA = qw(Tie::StdScalar);

$VERSION = "1.02";

use Data::UUID;

=head1 NAME

Tie::DataUUID - tie interface to Data::UUID;

=head1 SYNOPSIS

  use Tie::DataUUID;
  tie my $uuid, "Tie::DataUUID";

  print "A uuid is $uuid, another is $uuid\n"

=head1 DESCRIPTION

A simple tie interface to the B<Data::UUID> module.  Yes, this doesn't
do much - it's just me being to lazy when I have to keep creating
UUIDs from within strings.

To be really totally and utterly lazy you can use the exporting
interface that exports the C<$uuid> variable so you don't even have to
tie things yourself:

  use Tie::DataUUID qw($uuid);
  print "A uuid is $uuid, another is $uuid\n"

In both cases the standard UUID string (that looks like
'E63E9204-9516-11D8-9C9F-AE87831498F6') are produced.

=cut

my $datauuid = Data::UUID->new();

sub import
{
  my $class = shift;

  foreach my $args (@_) {
  {
    unless (defined $args && $args eq '$'.'uuid') {
      die qq{"$args" is not exported by the }.__PACKAGE__.qq{ module\n}
    }

    my $uuid;
    tie $uuid, $class;
    no strict 'refs';   # about to export symbols
    *{ caller() . "::uuid" } = \$uuid;
    }
  }

  return
}

sub FETCH { return $datauuid->create_str }

=head1 AUTHOR

Written by Mark Fowler E<lt>mark@twoshortplanks.comE<gt>

Copyright Fotango 2004.  All Rights Reserved.

Copyright Mark Fowler 2009, 2013.  All Rights Reserved.

This program is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

=head1 BUGS

Bugs (or feature requests) should be reported via this distribution's
CPAN RT queue.  This can be found at
L<https://rt.cpan.org//Dist/Display.html?Queue=Tie-DataUUID>

You can also address issues by forking this distribution
on github and sending pull requests.  It can be found at
L<http://github.com/2shortplanks/Tie-DataUUID>

=head1 SEE ALSO

L<Data::UUID>, L<Tie::Scalar>

=cut

1;
