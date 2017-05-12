#!/usr/bin/perl

use strict;
use warnings;

package WWW::Shopify::Model::NestedItem;
use parent 'WWW::Shopify::Model::Item';

sub is_nested { return 1; }
# Has a parent object; default is the above package nest.
sub parent { my $package = $_[0]; $package = ref($package) if ref($package); die new WWW::Shopify::Exception($package) unless $package =~ m/(.*?)\:\:\w+$/; return $1; }
# Everything taken together on a nested item is an identifier.
sub identifier { return 'id' if $_[0]->field('id'); return map { $_->name } grep { !$_->is_relation } values(%{$_[0]->fields}); }

1
