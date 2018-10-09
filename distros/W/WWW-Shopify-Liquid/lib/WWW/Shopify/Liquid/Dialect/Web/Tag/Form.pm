#!/usr/bin/perl
use strict;
use warnings;

package WWW::Shopify::Liquid::Dialect::Web::Tag::Form;
use base 'WWW::Shopify::Liquid::Tag::Enclosing';

sub min_arguments { return 1; }
sub max_arguments { return 1; }

use Scalar::Util qw(blessed);

sub process {
	my ($self, $hash, $action, $pipeline) = @_;
	my $result = $self->{arguments}->[0]->$action($pipeline, $hash);
	return $self if blessed($result);
	return '';
}



1;