# Copyright (c) YYYY the World Wide Web Consortium :
#       Keio University,
#       European Research Consortium for Informatics and Mathematics
#       Massachusetts Institute of Technology.
# written by Firstname Lastname <your@address.mail> for W3C
#
# $Id: NewOutputModule.pm,v 1.4 2004/09/10 00:41:24 ot Exp $

package W3C::LogValidator::Output::MyOutputModule;
use strict;



###########################
# usual package interface #
#     don't modify        #
###########################

require Exporter;
our @ISA = qw(Exporter);
our %EXPORT_TAGS = ( 'all' => [ qw() ] );
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
our @EXPORT = qw();
our $VERSION = '0.1';


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

#############################
# first subroutin is output #
#   create output string    #
#############################

sub output
{
	my $self = shift;
	my %results;
	my $outputstr ="";

# you create the result string by using the different entries 
# in the results hash, including name (of the module), intro (text)
# thead (the headers of the result table), trows (rows of the result table)
# and outro

#sample code for a full-text tabbed result table below
	if (@_) {%results = %{(shift)}}
	$outputstr= "
************************************************************************
Results for module ".$results{'name'}."
************************************************************************\n";
	$outputstr= $outputstr.$results{"intro"}."\n\n" if ($results{"intro"});
	my @thead = @{$results{"thead"}};
	while (@thead)
	{
		my $header = shift (@thead);	
		$outputstr= $outputstr."$header   ";
	}
	$outputstr= $outputstr."\n";
	my @trows = @{$results{"trows"}};
	while (@trows)
	{
		my @row=@{shift (@trows)};
		my $tcell;
		while (@row)
		{
			$tcell= shift (@row);	
			chomp $tcell;
			$outputstr= $outputstr."$tcell   ";
		}
		$outputstr= $outputstr."\n";
	}
	$outputstr= $outputstr."\n";
	$outputstr= $outputstr.$results{"outro"}."
************************************************************************\n\n" if ($results{"outro"});

# the subroutine returns the output string
	return $outputstr;	
}

################################################################
# finish does whatever action is needed with the output string #
#   like "print" or send as e-mail or whatever you like        #
# note that for saving to file, the main module has an option  #
#               for that already, just "print"                 #
################################################################

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

package W3C::LogValidator::Output::MyOutputModule;

1;

__END__

=head1 NAME

W3C::LogValidator::Output::NewOutputModule - Sample new output module for the Log Validator

=head1 DESCRIPTION

This module is part of the W3C::LogValidator suite, and ...

=head1 AUTHOR

Firstname Lastname <your@mail.address>

=head1 SEE ALSO

W3C::LogValidator, perl(1).
Up-to-date complete info at http://www.w3.org/QA/Tools/LogValidator/
=cut
