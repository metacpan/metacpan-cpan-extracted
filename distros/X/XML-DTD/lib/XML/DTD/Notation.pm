package XML::DTD::Notation;

use XML::DTD::Component;
use XML::DTD::Error;

use 5.008;
use strict;
use warnings;

our @ISA = qw(XML::DTD::Component);

our $VERSION = '0.09';


# Constructor
sub new {
  my $arg = shift;
  my $not = shift;

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
    $self->define('notation', $not, '<!NOTATION', '>');
  }
  return $self;
}


# Return the notation name
sub name {
  my $self = shift;

  return $self->{'NAME'};
}


# Return the notation sysid
sub sysid {
  my $self = shift;

  return $self->{'SYSTEM'};
}


# Return the notation pubid
sub pubid {
  my $self = shift;

  return $self->{'PUBLIC'};
}


# Parse the notation declaration
sub _parse {
  my $self = shift;
  my $entman = shift;
  my $nttdcl = shift;

  if ($nttdcl=~/<\!NOTATION\s+([\w\.:\-_]+|%[\w\.:\-_]+;)\s+(SYSTEM|PUBLIC)\s+([\"\'])(.*?)\3\s+(?:([\"\'])(.*?)\5)?\s*>/s) {
    my $name = $1;
    my $type = defined($2) ? $2 : '';

    if ($type eq 'SYSTEM') {
      $self->{'SYSTEM'} = $4;
      throw XML::DTD::Error("SYSTEM notation has two identifiers in ".
			      "definition: $nttdcl", $self) if (defined $6);
    } elsif ($type eq 'PUBLIC') {
      $self->{'SYSTEM'} = $6 if (defined $6);
      $self->{'PUBLIC'} = $4;
    } else {
      throw XML::DTD::Error("Notation neither PUBLIC nor SYSTEM in ".
			      "definition: $nttdcl", $self);
    }
    $name = $entman->peexpand($name)
      if ($name =~ /^%([\w\.:\-_]+);$/);
    $self->{'NAME'} = $name;

  } else {
    throw XML::DTD::Error("Error parsing notation definition: $nttdcl", $self);
  }
}


1;
__END__

=head1 NAME

XML::DTD::Notation - Perl module representing a notation declaration in a DTD

=head1 SYNOPSIS

  use XML::DTD::Notation;

  my $not = XML::DTD::Notation->new('<!NOTATION e PUBLIC "+//F//G//EN">');

=head1 DESCRIPTION

XML::DTD::Notation is a Perl module representing a notation
declaration in a DTD. The following methods are provided.

=over 4

=item B<new>

 my $not = XML::DTD::Notation->new('<!NOTATION e PUBLIC "+//F//G//EN">');

Construct a new XML::DTD::Notation object.

=item B<name>

 print $not->name;

Return the notation name

=item B<sysid>

 print $not->sysid;

Return the notation sysid

=item B<pubid>

 print $not->pubid;

Return the notation pubid

=back

=head1 SEE ALSO

L<XML::DTD>, L<XML::DTD::Component>

=head1 AUTHOR

Brendt Wohlberg E<lt>wohl@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004-2010 by Brendt Wohlberg

This library is available under the terms of the GNU General Public
License (GPL), described in the GPL file included in this distribution.

=head1 ACKNOWLEDGMENTS

Peter Lamb E<lt>Peter.Lamb@csiro.auE<gt> improved parsing of NOTATION
declarations.

=cut
