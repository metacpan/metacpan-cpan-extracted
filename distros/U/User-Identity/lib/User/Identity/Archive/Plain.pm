# This code is part of Perl distribution User-Identity version 4.00.
# The POD got stripped from this file by OODoc version 3.05.
# For contributors see file ChangeLog.

# This software is copyright (c) 2003-2025 by Mark Overmeer.

# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
# SPDX-License-Identifier: Artistic-1.0-Perl OR GPL-1.0-or-later


package User::Identity::Archive::Plain;{
our $VERSION = '4.00';
}

use parent 'User::Identity::Archive';

use strict;
use warnings;

use Log::Report     'user-identity';

#--------------------

my %abbreviations = (
	user     => 'User::Identity',
	email    => 'Mail::Identity',
	location => 'User::Identity::Location',
	system   => 'User::Identity::System',
	list     => 'User::Identity::Collection::Emails',
);

sub init($)
{	my ($self, $args) = @_;
	$self->SUPER::init($args);

	# Define the keywords.

	my %only;
	if(my $only = delete $args->{only})
	{	my @only = ref $only ? @$only : $only;
		$only{$_}++ for @only;
	}

	while( my($k,$v) = each %abbreviations)
	{	$self->abbreviation($k, $v) unless keys %only && !$only{$k};
	}

	if(my $abbrevs = delete $args->{abbreviations})
	{	$abbrevs = { @$abbrevs } if ref $abbrevs eq 'ARRAY';
		while( my($k,$v) = each %$abbrevs)
		{	$self->abbreviation($k, $v) unless keys %only && !$only{$k};
		}
	}

	warning __x"option 'only' specifies undefined abbreviation '{abbrev}'.", abbrev => $_
		for grep ! defined $self->abbreviation($_), keys %only;

	$self->{UIAP_items}   = {};
	$self->{UIAP_tabstop} = delete $args->{tabstop} || 8;
	$self;
}


sub from($@)
{	my ($self, $in, %args) = @_;

	exists $args{verbose} and error "from(verbose) now from Log::Report dispatcher mode";
	my ($source, @lines);

	if(ref $in)
	{	($source, @lines)
		= ref $in eq 'ARRAY'     ? ('array', @$in)
		: ref $in eq 'GLOB'      ? ('GLOB', <$in>)
		: $in->isa('IO::Handle') ? (ref $in, $in->getlines)
		:    error __x"cannot read archive from a {type}.", type => ref $in;
	}
	else
	{	open my($fh), "<", $in
			or fault __x"cannot read archive from file {file}", file => $in;

		$source = "file $in";
		@lines  = $fh->getlines;
	}

	info "reading archive data from {source}.", source => $source;
	@lines or return $self;

	my $tabstop = $args{tabstop} || $self->defaultTabStop;

	$self->_set_lines($source, \@lines, $tabstop);

	while(my $starter = $self->_get_line)
	{	$self->_accept_line;
		my $indent = $self->_indentation($starter);

		trace "  adding $starter";

		my $item   = $self->_collectItem($starter, $indent);
		$self->add($item->type => $item) if defined $item;
	}
	$self;
}

sub _set_lines($$$)
{	my ($self, $source, $lines, $tab) = @_;
	$self->{UIAP_lines}  = $lines;
	$self->{UIAP_source} = $source;
	$self->{UIAP_curtab} = $tab;
	$self->{UIAP_linenr} = 0;
	$self;
}

sub _get_line()
{	my $self = shift;
	my ($lines, $linenr, $line) = @$self{ qw/UIAP_lines UIAP_linenr UIAP_line/};

	# Accept old read line, if it was not accepted.
	return $line if defined $line;

	# Need to read a new line;
	$line = '';
	while($linenr < @$lines)
	{	my $reading = $lines->[$linenr];

		$linenr++, next if $reading =~ m/^\s*\#/;    # skip comments
		$linenr++, next unless $reading =~ m/\S/;    # skip blanks
		$line .= $reading;

		if($line =~ s/\\\s*$//)
		{	$linenr++;
			next;
		}

		if($line =~ m/^\s*tabstop\s*\=\s*(\d+)/ )
		{	$self->{UIAP_curtab} = $1;
			$line = '';
			next;
		}

		last;
	}

	length $line || $linenr < @$lines
		or return ();

	$self->{UIAP_linenr} = $linenr;
	$self->{UIAP_line}   = $line;
	$line;
}

sub _accept_line()
{	my $self = shift;
	delete $self->{UIAP_line};
	$self->{UIAP_linenr}++;
}

sub _location() { @{$_[0]}{ qw/UIAP_source UIAP_linenr/ } }

sub _indentation($)
{	my ($self, $line) = @_;
	defined $line or return -1;

	my ($indent) = $line =~ m/^(\s*)/;
	index($indent, "\t") >= 0
		or return length $indent;

	my $column = 0;
	my $tab    = $self->{UIAP_curtab};
	my @chars  = split //, $indent;
	while(my $char = shift @chars)
	{	$column++, next if $char eq ' ';
		$column = (int($column/$tab+0.0001)+1)*$tab;
	}
	$column;
}

sub _collectItem($$)
{	my ($self, $starter, $indent) = @_;
	my ($type, $name) = $starter =~ m/(\w+)\s*(.*?)\s*$/;
	my $class = $abbreviations{$type};
	my $skip  = ! defined $class;

	my (@fields, @items);

	while(1)
	{	my $line        = $self->_get_line;
		my $this_indent = $self->_indentation($line);
		last if $this_indent <= $indent;

		$self->_accept_line;
		$line           =~ s/[\r\n]+$//;
		next if $skip;

		my $next_line   = $self->_get_line;
		my $next_indent = $self->_indentation($next_line);

		if($this_indent < $next_indent)
		{	# start a collectable item
			my $item = $self->_collectItem($line, $this_indent);
			push @items, $item if defined $item;
		}
		elsif($this_indent==$next_indent && $line =~ m/^\s*(\w*)\s*(\w+)\s*\=\s*(.*)/ )
		{	# Lookup!
			my ($group, $name, $lookup) = ($1,$2,$3);
			my $item;   # not implemented yet
			push @items, $item if defined $item;
		}
		else
		{	# defined a field
			my ($group, $name) = $line =~ m/(\w+)\s*(.*)/;
			$name =~ s/\s*$//;
			push @fields, $group => $name;
			next;
		}
	}

	@fields || @items or return ();

	#XXX needs conversion to Log::Report

	my $warn     = 0;
	my $warn_sub = $SIG{__WARN__};
	$SIG{__WARN__} = sub { $warn++; $warn_sub ? $warn_sub->(@_) : print STDERR @_ };

	my $item = $class->new(name => $name, @fields);
	$SIG{__WARN__} = $warn_sub;

	if($warn)
	{	my ($source, $linenr) = $self->_location;
		$linenr -= 1;
		warn "  found in $source around line $linenr\n";
	}

	$item->add($_->type => $_) for @items;
	$item;
}

#--------------------

sub defaultTabStop(;$)
{	my $self = shift;
	@_ ? ($self->{UIAP_tabstop} = shift) : $self->{UIAP_tabstop};
}


sub abbreviation($;$)
{	my ($self, $name) = (shift, shift);
	@_ or return $self->{UIAP_abbrev}{$name};

	my $class = shift;
	defined $class
		or return delete $self->{UIAP_abbrev}{$name};

	eval "require $class";
	$@ and die $@;

	$self->{UIAP_abbrev}{$name} = $class;
}


sub abbreviations() { sort keys %{ $_[0]->{UIAP_abbrev}} }

#--------------------

1;
