package WordLists::Tag;
use strict;
use warnings;
use utf8;
use WordLists::Common qw(/generic/);
use WordLists::Base;
our $VERSION = $WordLists::Base::VERSION;

our $AUTOLOAD;

sub new
{
	my ($class,  $args) = @_;
	
	bless ($args, $class);
}
warn 'WordLists::Tag is a placeholder, use a specific tagger';
1;

=pod

=head1 NAME

WordLists::Tag

=head1 SYNOPSIS
	
	my $tagger = WordLists::Tag->new();

=head1 DESCRIPTION	

Doesn't do anything... yet. This is a placeholder. 

=head1 BUGS

Please use the Github issues tracker.

=head1 LICENSE

Copyright 2011-2012 © Cambridge University Press. This module is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut