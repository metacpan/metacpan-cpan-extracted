#!/usr/bin/perl

use strict;
use warnings;

# A class designed to wrap the WWW::Shopify object, and basically queue up requests and do all sorts of other meta-level things that the actual API shouldn't handle.

use WWW::Shopify;

package WWW::Shopify::URLHandler::Queued;
use parent 'WWW::Shopify::URLHandler';

# If we have a too many calls thing, queue up the request, 

sub new($$) {
	my ($package, $db) = @_;
	return bless{_db => $db}, $package;
}

sub post_url {
	my $self = shift;
	eval {
		$self->SUPER::post_url(@_);
	};
	if ($@) {
		die $@ unless ($@->code == 503);
		my $db = $self->{_db};
		$db->create({created => $currentDate, request_json => $request_json});
	}
}

sub put_url {
	my $self = shift;
	eval {
		$self->SUPER::put_url(@_);
	};
	if ($@) {
		die $@ unless ($@->code == 503);
		my $db = $self->{_db};
		$db->create({created => $currentDate, request_json => $request_json});
	}
}

sub delete_url {
	my $self = shift;
	eval {
		$self->SUPER::delete_url(@_);
	};
	if ($@) {
		die $@ unless ($@->code == 503);
		my $db = $self->{_db};
		$db->create({created => $currentDate, request_json => $request_json});
	}
}

