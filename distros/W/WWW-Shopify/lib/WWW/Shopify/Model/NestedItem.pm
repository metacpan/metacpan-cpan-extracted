#!/usr/bin/perl

use strict;
use warnings;

package WWW::Shopify::Model::NestedItem;
use parent 'WWW::Shopify::Model::Item';

sub is_nested { return 1; }
# Has a parent object; default is the above package nest.
sub parent { my $package = $_[0]; $package = ref($package) if ref($package); die new WWW::Shopify::Exception($package) unless $package =~ m/(.*?)\:\:\w+$/; return $1 eq 'WWW::Shopify::Model' ? undef : $1; }
# Used to specify something that there's only ever one of.
sub is_single { 0; }
# Everything taken together on a nested item is an identifier, unless it's solo, in which case it's the parent id.
# Assumes that this will always be non-null.
sub identifier { 
	return 'id' if $_[0]->field('id'); 
	return map { $_->name } grep { $_->is_relation && $_->is_parent } values(%{$_[0]->fields}) if $_[0]->is_single;
	return map { $_->name } grep { !$_->is_relation } values(%{$_[0]->fields});
}

sub countable { return undef; }
sub gettable { return undef; }
sub creatable { return undef; }
sub updatable { return undef; }
sub deletable { return undef; }

1
