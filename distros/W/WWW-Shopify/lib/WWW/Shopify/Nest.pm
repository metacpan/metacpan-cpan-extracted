#!/usr/bin/perl

use strict;
use warnings;

=head1 NAME

WWW::Shopify::Nest - Object representing a group of Shopify APIs, which can be alternated over to get around the call limit.

=cut

=head1 DESCRIPTION

Inherits all methods from L<WWW::Shopify>. This is not a toy. Don't use this unless there's a good reason; be nice to Shopify and don't swamp their servers.

=cut

package WWW::Shopify::Nest;
use parent 'WWW::Shopify';

=head1 METHODS

=head2 new($shop_url, $email, $pass, $app_count)

Creates a new shop, without using the actual API, uses automated form submission to log in. Then creates $app_count private apps in the store to use as slaves to conduct business.

In order to make sure that these extra apps don't end up clogging up your shop, we keep track of all nests, and make sure to delete all the apps at END time.

=cut

my @total_nests = ();

sub new {
	my $package = shift;
	my ( $hostname, $email, $password, $app_count ) = @_;
	die new WWW::Shopify::Exception("Requires an app count of at least 1.") unless $app_count >= 1;
	my $self = $package->SUPER::new(@_);
	$self->generate_children($app_count);
	$self->{initialized} = 1;
	push(@total_nests, $self);
	return $self;
}

END {
	$_->free_children for (@total_nests);
}

=head2 generate_children($app_count) 

Called by the constructor. Generates $app_count children.

=cut

sub generate_children {
	my ($self, $app_count) = @_;
	$self->{children} = [map { $self->create_private_app } 1..$app_count];
}


=head2 children($self)

Returns an array of children L<WWW::Shopify::Private>, the size of $app_count. The child at index 0 is always the active child.

=cut

sub children {
	return undef unless $_[0]->{children};
	return @{$_[0]->{children}} if wantarray;
	return $_[0]->{children};
}

=head2 free_children

Deletes the specified child APIs from shopify.

=cut

sub free_children {
	my ($self) = @_;
	$self->delete_private_app($_) for ($self->children);
	$self->{children} = [];
}


=head2

=head2 DESTROY($self)

Destructor. Calls free_children on children.

=cut


=head2 use_url($self, $method, $url, $specs, $hash)

Determines whether we've hit the call limit. If we have, reperforms the call with a new API.

If the entire stack of APIs is exhausted, we die with the original error.

=cut

sub use_url {
	my ($self, $method, $url, $specs, $hash) = @_;
	my @children = $self->children;
	my $method_name = lc($method) . "_url";
	my $index = 0;
	while (1) {
		eval {
			my @return = $children[$index]->$method_name($url, $specs, $hash);
			push(@children, shift(@children)) for (1..$index);
			$self->{children} = \@children;
			return @return;
		};
		if ($@ && ref($@) && ref($@) eq "WWW::Shopify::Exception::CallLimit") {
			# If we've hit the end of the road, die with our exception.
			die $@ if ($index++ == int(@children));
		}
		elsif ($@) {
			die $@;
		}
	}
}

sub get_url { return shift->SUPER::get_url(@_) if !$_[0]->{initalized}; return $_[0]->use_url("GET", $_[1], $_[2], $_[3]); }
sub post_url { return shift->SUPER::post_url(@_) if !$_[0]->{initalized};return $_[0]->use_url("POST", $_[1], $_[2], $_[3]); }
sub put_url { return shift->SUPER::put_url(@_) if !$_[0]->{initalized}; return $_[0]->use_url("PUT", $_[1], $_[2], $_[3]); }
sub delete_url { return shift->SUPER::delete_url(@_) if !$_[0]->{initalized}; return $_[0]->use_url("DELETE", $_[1], $_[2], $_[3]); }

1;
