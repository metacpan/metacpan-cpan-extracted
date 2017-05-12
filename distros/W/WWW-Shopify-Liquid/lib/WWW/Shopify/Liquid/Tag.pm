#!/usr/bin/perl

use strict;
use warnings;

package WWW::Shopify::Liquid::Tag;
use base 'WWW::Shopify::Liquid::Element';

sub inner_tags { return (); }
sub abstract { my $package = ref($_[0]) ? ref($_[0]) : $_[0]; return ($package eq __PACKAGE__); }
sub name { my $package = ref($_[0]) ? ref($_[0]) : $_[0]; $package =~ s/^.*:://; $package =~ s/([a-z])([A-Z])/$1_$2/g; return lc($package);  }
sub new { 
	my ($package, $line, $tag, $arguments, $contents) = @_;
	my $self = { line => $line, core => $tag, arguments => $arguments, contents => $contents };
	return bless $self, $package;
}
sub is_free { return 0; }
sub is_enclosing { return 0; }
sub min_arguments { return 0; }
sub max_arguments { return undef; }

sub tokens { return ($_[0], map { $_->tokens } grep { defined $_ } (@{$_[0]->{arguments}}, $_[0]->{contents})) }

package WWW::Shopify::Liquid::Tag::Output;
use base 'WWW::Shopify::Liquid::Tag::Free';

sub max_arguments { return 1; }
sub abstract { return 0; }

sub new { 
	my ($package, $line, $arguments) = @_;
	my $self = { arguments => $arguments, line => $line };
	return bless $self, $package;
}
sub process {
	my ($self, $hash, $action, $pipeline) = @_;
	return '' unless int(@{$self->{arguments}}) > 0;
	my $result = $self->{arguments}->[0]->$action($pipeline, $hash);
	return '' if !defined $result && ref($result) && (ref($result) eq "ARRAY" || ref($result) eq "HASH");
	return $result;
}

sub optimize {
	my ($self, $optimizer, $hash) = @_;
	$self->{arguments}->[0] = $self->{arguments}->[0]->optimize($optimizer, $hash) if !$self->is_processed($self->{arguments}->[0]);
	
	if ($self->is_processed($self->{arguments}->[0])) {
		my $result = $self->{arguments}->[0];
		return '' if ref($result) && (ref($result) eq "ARRAY" || ref($result) eq "HASH");
		return $result;
	}
	return $self;
}

1;
