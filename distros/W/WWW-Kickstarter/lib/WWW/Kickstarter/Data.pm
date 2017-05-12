
package WWW::Kickstarter::Data;

use strict;
use warnings;
no autovivification;


use WWW::Kickstarter::Error qw( my_croak );


sub _new {
   my_croak(400, "Incorrect usage") if @_ < 3;
   my ($class, $ks, $data, %opts) = @_;

   if (my @unrecognized = keys(%opts)) {
      my_croak(400, "Unrecognized parameters @unrecognized");
   }

   my $self = bless($data, $class);
   $self->{_} = {};
   $self->{_}{ks} = $ks;
   return $self;
}


sub ks { $_[0]{_}{ks} }


1;


__END__

=head1 NAME

WWW::Kickstarter::Data - Base class for Kickstarter data classes.


=head1 DESCRIPTION

Provides a constructor to the data classes in this distribution.
It is meant to be instantiated only through inheritance.


=head1 ACCESSORS

=head2 ks

   my $ks = $self->ks;

Returns the L<WWW::Kickstarter> object used to fetch this object.


=head1 VERSION, BUGS, KNOWN ISSUES, DOCUMENTATION, SUPPORT, AUTHOR, COPYRIGHT AND LICENSE

See L<WWW::Kickstarter>


=cut
