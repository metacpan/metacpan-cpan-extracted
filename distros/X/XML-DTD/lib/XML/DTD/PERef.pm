package XML::DTD::PERef;

use XML::DTD::Component;

use 5.008;
use strict;
use warnings;

our @ISA = qw(XML::DTD::Component);

our $VERSION = '0.09';


# Constructor
sub new {
  my $arg = shift;
  my $man = shift;
  my $ent = shift;

  my $cls = ref($arg) || $arg;
  my $obj = ref($arg) && $arg;

  my $self;
  if ($obj) {
    # Called as a copy constructor
    $self = { %$obj };
    bless $self, $cls;
  } else {
    # Called as the main constructor
    $self = { };
    bless $self, $cls;
    $self->define('peref', $ent);
    $self->{'ENTVAL'} = $man->pevalue($ent);
    $ent =~ /^%(.+);$/;
    $self->{'NAME'} = $1;
  }
  return $self;
}


# Return the value of the referenced entity
sub value {
  my $self = shift;

  return $self->{'ENTVAL'};
}


# Return attributes for XML representation
sub xmlattrib {
  my $self = shift;

  return {'name' => $self->{'NAME'}};
}


1;
__END__

=head1 NAME

XML::DTD::PERef - Perl module representing a parameter entity reference

=head1 SYNOPSIS

  use XML::DTD::PERef;

  my $per = XML::DTD::PERef->new('%entname;');

=head1 DESCRIPTION

XML::DTD::PERef is a Perl module representing a parameter entity
reference. The following methods are provided.

=over 4

=item B<new>

 my $per = XML::DTD::PERef->new('%entname;');

Construct a new XML::DTD::PERef object.

=item B<value>

 print $per->value;

Return the value of the referenced entity.

=item B<xmlattrib>

 $xat = $per->xmlattrib;

Return attributes for XML representation.

=back

=head1 SEE ALSO

L<XML::DTD>, L<XML::DTD::Component>

=head1 AUTHOR

Brendt Wohlberg E<lt>wohl@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004-2010 by Brendt Wohlberg

This library is available under the terms of the GNU General Public
License (GPL), described in the GPL file included in this distribution.

=cut
