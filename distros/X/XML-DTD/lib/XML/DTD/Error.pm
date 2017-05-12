package XML::DTD::Error;

use 5.008;
use strict;
use warnings;
use Error qw(:try);

our $VERSION = '0.09';

use base qw(Error);
use overload ('""' => 'stringify');

$XML::DTD::Error::Debug = 0;


# Constructor
sub new {
  my $self = shift;
  my $text = "" . shift;
  my $obrf = shift;

  local $Error::Depth = $Error::Depth + 1;
  local $Error::Debug = 1 if ($XML::DTD::Error::Debug > 1);

  $self->SUPER::new('-text' => $text, '-object' => $obrf);
}


# Construct string from object
sub stringify {
  my $self = shift;

  my $txt;
  if ($XML::DTD::Error::Debug == 0) {
    $txt = $self->text . "\n";
  } else {
    $txt = $self->stacktrace if ($XML::DTD::Error::Debug);
  }

 if ($XML::DTD::Error::Debug > 2 and defined($self->object)
   and ref($self->object) =~ /^XML::/) {
    $txt .= "Exception occurred in object: " .$self->object . "\n";
    if ($XML::DTD::Error::Debug > 3) {
      $txt .= "Object state:\n";
      my ($k,$v);
      foreach $k ( sort keys %{$self->object} ) {
	$v = defined $self->object->{$k} ? $self->object->{$k} : "[undef]";
	$txt .= "  $k: $v\n";
      }
    }
  }

  return $txt;
}


1;
__END__

=head1 NAME

XML::DTD::Error - Exception handling module for XML::DTD

=head1 SYNOPSIS

  use XML::DTD::Error;

  $XML::DTD::Error::Debug = 2;

  throw XML::DTD::Error("Error text", $objectref);

=head1 DESCRIPTION

  XML::DTD::Error is a Perl module for representing errors in XML::DTD
  and associated modiles. It is derived from the Error exception
  handling module.

=head1 SEE ALSO

L<Error>

=head1 AUTHOR

Brendt Wohlberg E<lt>wohl@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Brendt Wohlberg

This library is available under the terms of the GNU General Public
License (GPL), described in the GPL file included in this distribution.

=cut
