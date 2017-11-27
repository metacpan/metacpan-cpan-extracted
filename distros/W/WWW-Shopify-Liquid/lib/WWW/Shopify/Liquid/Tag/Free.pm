#!/usr/bin/perl
use strict;
use warnings;

package WWW::Shopify::Liquid::Tag::Free;
use base 'WWW::Shopify::Liquid::Tag';
sub is_free { return 1; }
sub abstract { my $package = ref($_[0]) ? ref($_[0]) : $_[0]; return ($package eq __PACKAGE__); }
sub subelements { qw(arguments); }

sub new { 
	my ($package, $line, $tag, $arguments) = @_;
	my $self = { line => $line, core => $tag, arguments => $arguments };
	return bless $self, $package;
}

sub process {
	my ($self, $hash, $action, $pipeline) = @_;
	my $arguments = $self->process_subelement($hash, $action, $pipeline, $self->{arguments});
	return $self unless int(grep { !$self->is_processed($_) } @$arguments) == 0;
	return $self->operate($hash, @$arguments);
}

1;