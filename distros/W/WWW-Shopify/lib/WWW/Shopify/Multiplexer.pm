#!/usr/bin/perl

use strict;
use warnings;

=head1 NAME

WWW::Shopify::Multiplexer - Object representing a group of Shopify APIs, which are multiplexed to increase your call limit.

=cut


package WWW::Shopify::Multiplexer;
use base 'WWW::Shopify';

use Data::Dumper;

=head1 METHODS

=head2 new($shop_url, $email, $pass, $app_count)

Creates a new shop, without using the actual API, uses automated form submission to log in. Then creates $app_count private apps in the store to use as slaves to conduct business.

In order to make sure that these extra apps don't end up clogging up your shop, we keep track of all nests, and make sure to delete all the apps at END time.

=cut

sub new {
	my $package = shift;
	my ( @sa ) = @_;
	die new WWW::Shopify::Exception("Requires an API count of at least 1.") unless int(@sa) >= 1;
	my $shop_url = $sa[0]->shop_url;
	my $class = ref($sa[0]);
	die new WWW::Shopify::Exception("Requires all APIs to access the same store.") unless int(grep { $_->shop_url eq $shop_url } @sa) == int(@sa);
	die new WWW::Shopify::Exception("Requires all APIs to be the same class for now.") unless int(grep { ref($_) eq $class } @sa) == int(@sa);
	die new WWW::Shopify::Exception("Requires a shop URL.") if int(grep { !$_->shop_url } @sa) > 0;
	my $self = $package->SUPER::new($sa[0]->shop_url, $sa[0]->api_key);
	$self->{children} = [@sa];
	$self->{index} = 0;
	return $self;
}

sub children { return @{$_[0]->{children}}; }

sub last_used_sa { return $_[0]->{children}->[$_[0]->{index}]; }

=head2 use_url($self, $method, $url, $specs, $hash)

Determines whether we've hit the call limit. If we have, reperforms the call with a new API.

If the entire stack of APIs is exhausted, we die with the original error.

=cut

sub use_url {
	my ($self, $method, $original_url, $specs, $hash) = @_;
	my @children = $self->children;
	my $method_name = lc($method) . "_url";
	while (1) {
		my ($decoded, $response) = eval { 
			my $url = $children[$self->{index}]->encode_url($original_url); 
			$children[$self->{index}]->$method_name($url, $specs, $hash); 
		};
		my $exp = $@;
		if ($exp && ref($exp) && ref($exp) eq "WWW::Shopify::Exception::CallLimit") {
			# If we've hit the end of the road, die with our exception.
			if (++$self->{index} == int(@children)) {
				$self->{index} = 0;
				if ($self->sleep_for_limit) {
					sleep(1);
				} else {
					die $exp;
				}
			}
			next;
		}
		elsif ($exp) {
			die $exp;
		} else {
			$self->{index} = ($self->{index} + 1) % int(@children);
		}
		print STDERR uc($method) . " " . $response->request->uri . "\n" if $ENV{'SHOPIFY_LOG'} && $ENV{'SHOPIFY_LOG'} == 1;
		print STDERR Dumper($response) if $ENV{'SHOPIFY_LOG'} && $ENV{'SHOPIFY_LOG'} > 1;
		return ($decoded, $response);
	}
}

sub get_url { return $_[0]->use_url("GET", $_[1], $_[2], $_[3]); }
sub post_url { return $_[0]->use_url("POST", $_[1], $_[2], $_[3]); }
sub put_url { return $_[0]->use_url("PUT", $_[1], $_[2], $_[3]); }
sub delete_url { return $_[0]->use_url("DELETE", $_[1], $_[2], $_[3]); }

sub ql {
	my ($self) = @_;
	my @children = $self->children;
	return $children[0]->ql; 
}

1;
