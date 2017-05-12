#
# (c) Jan Gehring <jan.gehring@gmail.com>
# 
# vim: set ts=3 sw=3 tw=0:
# vim: set expandtab:

=head1 NAME

WebService::ProfitBricks::Base - Base Class

=head1 DESCRIPTION

This is the base class of all ProfitBricks classes.

=head1 SYNOPSIS

 package WebService::ProfitBricks::Image;
 use WebService::ProfitBricks::Class;
 use base qw(WebService::ProfitBricks::Class);

=head1 METHODS

=over 4

=cut
   
package WebService::ProfitBricks::Base;

use strict;
use warnings;

my $connection;

use WebService::ProfitBricks::Class;

=item connection([$con])

Sets or gets the current connection object. You can create your own connection objects as long it has an I<call($call, %data)> method. See L<WebService::ProfitBricks::Connection> for more information.

=cut
sub connection {
   my ($self, $con) = @_;
   if($con) {
      $connection = $con;
   }

   return $connection;
}

=item get_data

Returns the objects data as an hashRef.

=cut

sub get_data {
   my ($self) = @_;
   return $self->{__data__};
}


=item set_data($data = {});

Sets the objects data.

=cut
sub set_data {
   my ($self, $data) = @_;
   for my $key (keys %{ $data }) {
      $self->{__data__}->{$key} = $data->{$key};
   }
}

=item get_relations

If you're object will have relations to other objects you have to override this method.

=cut
sub get_relations { return(); }

=back

=cut

"No one is save";
