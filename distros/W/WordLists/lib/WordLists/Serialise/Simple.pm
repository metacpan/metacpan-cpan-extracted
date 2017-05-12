package WordLists::Serialise::Simple;
use strict;
use warnings;
use IO::File;
use WordLists::Common qw (@sDefaultAttList @sDefiningAttlist);
use WordLists::Base;
our $VERSION = $WordLists::Base::VERSION;

sub new
{
	my ($class, $args) = @_;
	my $self = {
		'field_sep' => "\t",
		'default_attlist'=> \@sDefaultAttList,
		'header_marker' => '#*',
		'line_sep' => \$/,
	};
	$self->{$_} = $args->{$_} foreach grep { defined $args->{$_}; }(qw(field_sep attlist default_attlist header_marker));
	bless $self, $class;
}
sub _get_line_sep
{
	my $self = shift;
	if (ref $self->{'line_sep'} eq ref \'') 
	{
		return ${$self->{'line_sep'}};
	}
	elsif (!ref $self->{'line_sep'})
	{
		return $self->{'line_sep'};
	}
	else
	{
		return $/;
	}
}
sub header_line_to_string
{
	my ($self, $args) = @_;
	my $sLine = $self->{'header_marker'} . join (
		defined $args->{'field_sep'} ? $args->{'field_sep'} : $self->{'field_sep'}, 
		defined $args->{'attlist'} ? @{$args->{'attlist'}} : @{$self->{'default_attlist'}}
	);
	return $sLine;
}
sub to_string
{
	my ($self, $structure, $args) = @_;
	
	if (ref $structure eq ref {})
	{
		return $self->hashref_to_string($structure, $args);
	}
	elsif (ref $structure eq ref [])
	{
		$args->{line_sep} = $self->_get_line_sep() unless defined $args->{line_sep};
		my $sOut ='';
		$sOut .= $self->header_line_to_string($args) . $args->{line_sep} unless $args->{no_header} or $self->{no_header};
		foreach (@{$structure})
		{
			if (ref $_ eq ref {})
			{
				$sOut .= $self->hashref_to_string($_, $args);
			}
			else
			{
				warn "Cannot serialise - expected a HASH ref, got ". ref $_;
			}
			$sOut .= $args->{line_sep};
		}
		return $sOut;
	}
	
	return undef;
}
sub _warn_if_has_sep
{
	my ($self, $test) = @_;
	if (defined ($test) and ref($test) eq ref '')
	{
		warn "Value contains field separator" if $test =~ /$self->{'field_sep'}/;
		warn "Value contains line separator" if $test =~ /$self->{'line_sep'}/;
	}
}
sub hashref_to_string
{
	my ($self, $structure, $args) = @_;
	my @sAttlist = defined $args->{'attlist'} ? @{$args->{'attlist'}} : @{$self->{'default_attlist'}};
	my $s = '';
	$s .= join (
		$self->{'field_sep'}, 
		map {
			$self->_warn_if_has_sep($structure->{$_});
			defined $structure->{$_} ? $structure->{$_} : '';
		} @sAttlist
	);
	return $s;
}
1;


=pod

=head1 NAME

WordLists::Serialise::Simple

=head1 SYNOPSIS
	

=head1 DESCRIPTION	

This is a simple serialiser for CSV/TSV files. It doesn't do any quoted values or anything like that - the delimiter must simply never occur in the text. 

=head1 OPTIONS

On creation, a hashref may be passed with configuration options.

=head1 BUGS

Please use the Github issues tracker.

=head1 LICENSE

Copyright 2011-2012 © Cambridge University Press. This module is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut