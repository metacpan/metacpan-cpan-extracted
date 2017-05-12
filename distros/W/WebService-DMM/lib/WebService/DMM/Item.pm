package WebService::DMM::Item;
use strict;
use warnings;

use Carp ();

use Class::Accessor::Lite (
    new => 1,
    ro => [ qw/service_name floor_name category_name
               content_id product_id title
               actors directors authors fighters
               price price_all list_price deliveries
               date keywords maker label sample_images
               jancode isbn stock series/ ],
);

sub image {
    my ($self, $type) = @_;

    unless ($type eq 'list' || $type eq 'small' || $type eq 'large') {
        Carp::croak("Invalid type '$type': it should be (list, small, large)");
    }

    return $self->{image}->{$type};
}

sub url { $_[0]->{URL}; }
sub url_sp { $_[0]->{URLsp} }
sub affiliate_url { $_[0]->{affiliateURL}; }
sub affiliate_url_sp { $_[0]->{affiliateURLsp} }

1;

__END__

=encoding utf-8

=for stopwords

=head1 NAME

WebService::DMM::Item - DMM webservice item

=head1 DESCRIPTION

WebService::DMM::Item is object which stands for DMM item.

=head1 INTERFACES

=head2 Accessor

=over

=item service_name :String

=item floor_name : String

=item category_name : String

=item content_id : String

=item product_id : String

=item title : String

=item actors : ArrayRef[WebService::DMM::Person::Actor]

=item directors : ArrayRef[WebService::DMM::Person::Director]

=item authors : ArrayRef[WebService::DMM::Person::Actor]

=item fighter : ArrayRef[WebService::DMM::Person::Fighter]

=item price : String

=item price_all : Int

=item list_price :Int

=item deliveries : ArrayRef[WebService::DMM::Delivery]

=item date : String

=item keywords : ArrayRef[String]

=item maker : String

=item label : String

=item sample_images : ArrayRef[String]

=item jancode : String

=item isbn : String

=item stock : Int

=item series : String

=item url : String

=item url_sp :String

=item affiliate_url :String

=item affiliate_url_sp :String

=back

=head2 Instance Methods

=head3 $item->image($type)

Return URL string. C<$type> should be 'list' or 'small' or 'large'.

=head1 AUTHOR

Syohei YOSHIDA E<lt>syohex@gmail.comE<gt>

=head1 COPYRIGHT

Copyright 2013 - Syohei YOSHIDA

=head1 SEE ALSO

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
