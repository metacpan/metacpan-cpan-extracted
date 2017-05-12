# Copyright (c) 2002-2005 the World Wide Web Consortium :
#       Keio University,
#       European Research Consortium for Informatics and Mathematics
#       Massachusetts Institute of Technology.
# written by Olivier Thereaux <ot@w3.org> for W3C
#
# $Id: Raw.pm,v 1.10 2005/09/09 06:33:11 ot Exp $

package W3C::LogValidator::Output::Raw;
use strict;


require Exporter;
our @ISA = qw(Exporter);
our %EXPORT_TAGS = ( 'all' => [ qw() ] );
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
our @EXPORT = qw();
our $VERSION = sprintf "%d.%03d",q$Revision: 1.10 $ =~ /(\d+)\.(\d+)/;


###########################
# usual package interface #
###########################
our %config;
our $verbose = 1;

sub new
{
        my $self  = {};
        my $proto = shift;
        my $class = ref($proto) || $proto;
	# configuration for this module
	if (@_) {%config =  %{(shift)};}
	if (exists $config{verbose}) {$verbose = $config{verbose}}
        bless($self, $class);
        return $self;
}


sub width
{
        my $self = shift;
	my $column_num = shift;
	my %results = %{(shift)};
	my @thead = @{$results{"thead"}};
	my @trows = @{$results{"trows"}};
	my $headerwidth= length($thead[$column_num]);
	my $columnwidth = 0;
	my $cellwidth = 0;
	my @tcolumn;
	while (@trows) 
	{
		my @row=@{shift (@trows)};
		$cellwidth = length($row[$column_num]);
		if ($cellwidth > $columnwidth) { $columnwidth = $cellwidth; }
	}
	if ($columnwidth > $headerwidth+1) 
	{ 
		return $columnwidth; 
	}
	else
	{
		return $headerwidth+2;
	}

}

sub spaces
{
	my $self = shift;
	my $spaces = shift;
	my $bloat = "";
	for (my $i=0; $i<$spaces; $i++)
	{ $bloat = $bloat." "; } # lame, innit?
	return $bloat;
}

sub dashes
{
	my $self = shift;
	my $spaces = shift;
	my $bloat = "";
	for (my $i=0; $i<$spaces; $i++)
	{ $bloat = $bloat."-"; } # lame, innit?
	return $bloat;
}

sub output
{
	use POSIX;
	my $self = shift;
	my %results;
	my $outputstr ="";
	if (@_) {%results = %{(shift)}}
	$outputstr= "
************************************************************************
Results for module ".$results{'name'}."
************************************************************************\n";
	$outputstr= $outputstr.$results{"intro"}."\n\n" if ($results{"intro"});
	my @thead = @{$results{"thead"}};
	my $column_num = 0;
	my $all_columns = int(@thead);
	my @widths;
	# printing table headers
	while (@thead)
	{
		my $header = shift (@thead);	
		my $spaces;
		$widths[$column_num] = $self->width($column_num, \%results);
		if ($widths[$column_num] > (length($header)+2) ) # long content
		{
			$spaces = $widths[$column_num] - length($header);
		}
		else { $spaces = 2 } # long column header
		# Header is centered
		my $space_before= ceil($spaces/2);
		my $space_after= floor($spaces/2);
		$outputstr= $outputstr.$self->spaces($space_before);
		$outputstr= $outputstr."$header";
		$outputstr= $outputstr.$self->spaces($space_after);
		$outputstr= $outputstr." "; # column separation space
		$column_num = $column_num+1;
	}
	$outputstr= $outputstr."\n";
	
	# printing separation dashes
	for ( my $clm = 0; $clm < $all_columns; $clm++)
	{
		$outputstr=$outputstr."".$self->dashes($widths[$clm])." ";
	}
	$outputstr= $outputstr."\n";
	# printing the bulk of results table
	my @trows = @{$results{"trows"}};
	while (@trows)
	{
		my $column_num = 0;
		my @row=@{shift (@trows)};
		my $tcell;
		while (@row)
		{
			$tcell= shift (@row);	
			chomp $tcell;
			my $spaces = $widths[$column_num] - length($tcell);
			$outputstr= $outputstr."$tcell".$self->spaces($spaces+1);
			$column_num = $column_num+1;
		}
		$outputstr= $outputstr."\n";
	}
	$outputstr= $outputstr."\n";
	$outputstr= $outputstr.$results{"outro"}."
************************************************************************\n\n" if ($results{"outro"});
	return $outputstr;	
}
	
sub finish
{
# well for this output it's not too difficult :)
	my $self = shift;
	if (@_) 
	{ 
		my $result_string = shift;
		print $result_string;
	}
}

package W3C::LogValidator::Output::Raw;

1;

__END__

=head1 NAME

W3C::LogValidator::Output::Raw - [W3C Log Validator] STDOUT (console) output module

=head1 DESCRIPTION

This module is part of the W3C::LogValidator suite, and displays the results
of the log processing and validation in command-line mode.

=head1 AUTHOR

Olivier Thereaux <ot@w3.org>

=head1 SEE ALSO

W3C::LogValidator, perl(1).
Up-to-date complete info at http://www.w3.org/QA/Tools/LogValidator/
=cut
