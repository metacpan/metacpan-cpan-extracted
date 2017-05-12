#
# (c) Jan Gehring <jan.gehring@gmail.com>
# 
# vim: set ts=3 sw=3 tw=0:
# vim: set expandtab:

=head1 NAME

WebService::ProfitBricks::Serializer::xml - Special Serializer

=head1 DESCRIPTION

Special serializer for some call to the ProfitBricks API.

=cut

package WebService::ProfitBricks::Serializer::xml;

use strict;
use warnings;

use Data::Dumper;
use WebService::ProfitBricks::Class;

use WebService::ProfitBricks::Base;
use base qw(WebService::ProfitBricks);

attr qw/container/;

sub serialize {
   my ($self, $data) = @_;

   my @xml;
   
   if($self->container || exists $data->{container}) {
      @xml = ("<arg0>");
   }

   for my $key (keys %{ $data }) {
      next if ($key eq "container");
      if(ref $data->{$key} eq "ARRAY") {
         for my $a (@{ $data->{$key} }) {
            push(@xml, "<${key}>");
            push(@xml, $a);
            push(@xml, "</${key}>");
         }
      }
      else {
         push(@xml, "<$key>" . $data->{$key} . "</$key>");
      }
   }

   if($self->container || exists $data->{container}) {
      push(@xml, "</arg0>");
   }

   return join("", @xml);
}

1;
