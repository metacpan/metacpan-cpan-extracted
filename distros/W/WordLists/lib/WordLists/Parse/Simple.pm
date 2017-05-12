package WordLists::Parse::Simple;
use strict;
use warnings;
use IO::File;
use WordLists::Common qw (@sDefaultAttList @sDefiningAttlist);
use WordLists::Base;
our $VERSION = $WordLists::Base::VERSION;

my $canUseFileBOM=0;
eval { require File::BOM; File::BOM->import(); };
unless ($@)
{
	$canUseFileBOM = 1;
}

sub parse_string
{
	my ($self, $string, $args) = @_;
	foreach (grep {defined $self->{$_};} qw(attlist field_sep header_marker))
	{
		$args->{$_} = $self->{$_} unless defined $args->{$_};
	}
	$args->{'line_sep'} = $self->_get_line_sep unless defined $args->{'line_sep'};
	my @sAttList;
	@sAttList = ($args->{'attlist'} ? @{$args->{'attlist'}} : @{$self->{'default_attlist'}});
	my $LS = $args->{'line_sep'};
	my @sLines = split (/$LS/,$string);
	my @senseList;
	foreach my $sLine (grep {m/\w/} @sLines) # todo: make this condition changeable
	{
		
		chomp $sLine;
		my $FS = $args->{'field_sep'};
		my @sCols = split (/$FS/, $sLine);
		if ($args->{'is_header'} or (!defined ($args->{'is_header'}) and $sLine =~ m/^$args->{'header_marker'}/))
		{
			$sCols[0] =~s/^$args->{'header_marker'}// unless $args->{'is_header'};
			@sAttList = @sCols;
			@{$self->{'attlist'}} = @sCols;
			@{$args->{'attlist'}} = @sCols;
		}
		else
		{
			my %sAttr = ();
			foreach (0..$#sAttList )
			{
				$sAttr{$sAttList[$_]} = $sCols[$_] if $sAttList[$_] =~ m/^\w+$/;
				if ($sAttList[$_] =~ m/^(\w+)\[(\d+)\]$/)
				{
					$sAttr{$1}[$2] = $sCols[$_];
				}
			}
			push @senseList, \%sAttr;
		}
	}
	return \@senseList;
}
sub new
{
	my ($class, $args) = @_;
	my $self = {
		'field_sep' => "\t",
		'default_attlist'=> [@sDefaultAttList],
		'header_marker' => quotemeta '#*',
		'line_sep' => \$/,
	};
	$self->{$_} = $args->{$_} foreach grep { defined $args->{$_}; }(qw(field_sep attlist default_attlist header_marker line_sep));
	bless $self, $class;
}

sub parse_file
{
	my ($self, $fn, $enc, $args) = @_;
	my $fh;
	my $structure = [];
	if (defined $enc)
	{
		$fh = IO::File->new($fn, "<:encoding($enc)");
	}
	elsif ($canUseFileBOM)
	{
		$fh = IO::File->new($fn, "<:via(File::BOM)");
	}
	else
	{
		$fh = IO::File->new($fn, "<");
	}
	if (defined $fh) 
	{
		$structure= $self->parse_fh($fh, $args);
		undef $fh; 
	}
	else
	{
		$enc ||= 'undefined';
		warn "Open $fn with encoding $enc failed!";
	}
	return $structure;
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
sub parse_fh
{
	my ($self, $fh, $args) = @_;
	$args = {} unless defined $args;
	$self->{'attlist'} = $self->{'default_attlist'};
	my $iLine=0;
	my @senses;
	$args->{'header_marker'} = $self->{'header_marker'} unless defined $args->{'header_marker'};
	if (0)
	{
		local $/ = $/;
		unless (ref $self->{'line_sep'} eq ref \'' and ${$self->{'line_sep'}} eq $/)
		{
			$/ = $self->_get_line_sep;
		}
		if (defined ($args->{'line_sep'}))
		{
			$/ = $args->{'line_sep'};
		}
	}
	while (my $sLine = <$fh>)
	{
		if ($iLine == 0 and ($sLine=~ s/^\x{feff}// or $sLine=~ s/^\xef\xbb\xbf//))
		{
			binmode $fh, ':encoding(UTF-8)';
		}
		my $senses_per_line =[];
		if ($args->{'header_marker'} =~ m/^\d+$/ and $iLine == $args->{'header_marker'})
		{
			$senses_per_line = $self->parse_string($sLine, {%$args, is_header=>1}); # a header
		}
		elsif ($args->{'header_marker'} =~ m/^\d+$/)
		{
			$senses_per_line = $self->parse_string($sLine, {%$args, is_header=>0}); # not a header
		}
		else
		{
			$senses_per_line = $self->parse_string($sLine, $args); # could be a header
		}
		if (defined $senses_per_line and ref $senses_per_line eq ref [])
		{
			push @senses, $_ foreach @{$senses_per_line} ;
		}
		$iLine++;
	}
	return \@senses;
}
1;

=pod

=head1 NAME

WordLists::Parse::Simple

=head1 SYNOPSIS

	my $parser = WordLists::Parse::Simple->new;
	my @senses = @{ $parser->parse_string('#*hw\tpos\tdef\nhead\tnoun\tnoggin') };

=head1 DESCRIPTION	

This is a simple parser for CSV/TSV files. It doesn't do any quoted values or anything like that - the delimiter must simply never occur in the text. 

The parser aims to return each row as a hashref where the keys are the column names. It needs to be given information about how to identify the header, as there is no standardised way of representing a header. (The default is to treat lines beginning C<#*> as headers).

If the parser is passed several rows, it will return an arrayref.

=head1 OPTIONS

On creation, a hashref may be passed with configuration options.

=head1 METHODS

=head3 parse_fh

=head3 parse_file

When the module is loaded, it checks if L<File::BOM> can be used. If it can, then it will try to use it to guess the encoding when the user does not specify it. 

=head3 parse_string

=head1 BUGS

Please use the Github issues tracker.

=head1 LICENSE

Copyright 2011-2012 © Cambridge University Press. This module is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
