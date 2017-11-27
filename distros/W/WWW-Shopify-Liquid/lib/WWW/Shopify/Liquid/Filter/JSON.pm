#!/usr/bin/perl
use strict;
use warnings;

package WWW::Shopify::Liquid::Filter::JSON; use base 'WWW::Shopify::Liquid::Filter';
use JSON qw(encode_json decode_json from_json);
use Scalar::Util qw(blessed isweak);
use Clone qw(clone);

sub walk_data {
	my ($self) = @_;
	if (ref($self) && ref($self) eq "ARRAY" && !isweak($self)) {
		$self->[$_] = walk_data($self->[$_]) for (0..int(@$self)-1);
	} elsif (ref($self) && ref($self) eq "HASH" && !isweak($self)) {
		$self->{$_} = walk_data($self->{$_}) for (keys(%$self));
	}
	return defined $self && blessed($self) && $self->isa('DateTime') ? $self->iso8601 : $self;
}

sub operate { 
	# We allow decoding with this filter as well.
	if (defined $_[2] && !ref($_[2]) && length($_[2]) >= 2) {
		my $object = eval { from_json($_[2]) };
		return $object if !$@;
	}
	my $object = $_[2] ? (blessed($_[2]) && $_[2]->isa('WWW::Shopify::Model::Item') ? WWW::Shopify::Liquid->liquify_item($_[2]) : walk_data(clone($_[2]))) : $_[2];
	return defined $object && ref($object) ? JSON->new->allow_blessed(1)->encode($object) : '{}';
}

1;