package WebService::Shutterstock::Subscription;
{
  $WebService::Shutterstock::Subscription::VERSION = '0.006';
}

# ABSTRACT: Class representing a subscription for a specific Shutterstock customer

use strict;
use warnings;
use Moo;
use JSON qw(encode_json);
use WebService::Shutterstock::LicensedImage;
use Carp qw(croak);

use WebService::Shutterstock::AuthedClient;
with 'WebService::Shutterstock::AuthedClient';


has id => ( is => 'ro', required => 1, init_arg => 'subscription_id' );
my @fields = qw(
	  unix_expiration_time
	  current_allotment
	  description
	  license
	  sizes
	  site
	  expiration_time
		price_per_download
);
foreach my $f(@fields){
	has $f => ( is => 'ro' );
}


sub sizes_for_licensing {
	my $self = shift;
	my %uniq;
	return
	  grep { !$uniq{$_}++ }
	  map  { $_->{name} }
	  grep { $_->{name} ne 'supersize' && (!$_->{format} || $_->{format} ne 'tiff') }
	  values %{ $self->sizes || {} };
}


sub is_active {
	my $self = shift;
	return $self->unix_expiration_time > time;
}


sub is_expired {
	return !shift->is_active;
}

1;

__END__

=pod

=head1 NAME

WebService::Shutterstock::Subscription - Class representing a subscription for a specific Shutterstock customer

=head1 VERSION

version 0.006

=head1 ATTRIBUTES

=head2 id

=head2 unix_expiration_time

=head2 current_allotment

=head2 description

=head2 license

=head2 sizes

=head2 site

=head2 expiration_time

=head2 price_per_download

=head1 METHODS

=head2 sizes_for_licensing

Returns a list of sizes that can be specified when licensing an image
(see L<WebService::Shutterstock::Customer/license_image>).

=head2 is_active

Convenience method returning a boolean value indicating whether the subscription is active (e.g. has not expired).

=head2 is_expired

Convenience method returning a boolean value indicating whether the subscription has expired.

=head1 AUTHOR

Brian Phillips <bphillips@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Brian Phillips and Shutterstock, Inc. (http://shutterstock.com).

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
