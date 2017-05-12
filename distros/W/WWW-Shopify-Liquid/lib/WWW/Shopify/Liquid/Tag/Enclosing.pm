#!/usr/bin/perl
use strict;
use warnings;

package WWW::Shopify::Liquid::Tag::Enclosing;
use base 'WWW::Shopify::Liquid::Tag';
sub abstract { my $package = ref($_[0]) ? ref($_[0]) : $_[0]; return ($package eq __PACKAGE__); }
sub is_enclosing { return 1; }
sub inner_tags { return (); }
sub inner_ignore_whitespace { return 0; }
# Interprets the inner of this tag as being completely text. Used for comments and raws.
sub inner_halt_lexing { return 0; }

sub new { 
	my ($package, $line, $tag, $arguments, $contents) = @_;
	my $self = { line => $line, core => $tag, arguments => $arguments, contents => @{$contents->[0]} };
	die new WWW::Shopify::Liquid::Exception::Parser($self, "Uncustomized tags can only have one element following their contents.") unless int(@$contents) == 1;
	return bless $self, $package;
}

sub strip_left_end { $_[0]->{strip_left_end} = $_[1] if @_ > 1; return $_[0]->{strip_left_end}; }
sub strip_right_end { $_[0]->{strip_right_end} = $_[1] if @_ > 1; return $_[0]->{strip_right_end}; }

1;