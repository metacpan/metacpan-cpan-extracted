package WebService::UMLSKS::Similarity;

use warnings;
use strict;
use Log::Message::Simple qw[msg error debug];

no warnings qw/redefine/;

=head1 NAME

WebService::UMLSKS::Similarity - access the Unified Medical Language System (UMLS) via Webservices

=head1 VERSION

Version 0.23

=cut

our $VERSION = '0.23';

=head1 SYNOPSIS

=head2 Basic Usage

 	use WebService::UMLS::Similarity;
    # Creating object of similarity with default constructor.
    my $similarity1 = WebService::UMLS::Similarity->new();
    
    # Creating object of Similarity by providing Configuration parameters.
    my @source_list = ("SNOMEDCT", "MSH");
    my @relation_list = ("PAR", "CHD","RB", "RN") ;
    my $similarity2 = WebService::UMLS::Similarity->new({"sources" =>  \@source_list,"rels"   =>  \@relation_list }	);
    
    # Creating object of Similarity by providing Cinfiguration file path and name.
    my $similarity3 = WebService::UMLS::Similarity->
    new({"config" => "/home/../config"}); 

	Format of configuaration file

	The configuaration fie accepted by the module should be in the fillowing format
	
	SAB :: include SNOMEDCT,MSH
	REL :: include PAR,RB
	DIR :: include U,H
	RELA :: include RB-has_part
	
	Here, SAB is the sources and REL is relations you want to include in 
	searching the UMLS. The list of sources and relations can be provided 
	seperated by comma. Some UMLS sources are :SNOMEDCT,MSH,UWDA,CSP,FMA,NCI

=head1 DESCRIPTION

This module creates a new instance of Similarity module and while creating the
instance sets all the configuration parameters which are used in rest of the module.
User can provide the configuration parameters by directly passing them to the 
constructor using a hash of parameters with 'sources' and 'rels' options
or user can provide directly the configuration file path in the constructor using
'config' option. If the user does not specify any configuartion parameters,
defualt parameters are used.  'SNOMEDCT' is the deafult source used and 'PAR|CHD'
are the default relations used.

=head1 SUBROUTINES

=head2 new

This sub creates a new object of Display by taking in optional configuaration 
parameters.

=cut

sub new {

	my $class  = shift;
	my $params = shift;

	my @s_array = ("SNOMEDCT");
	my @r_array = ("PAR");
	my @d_array = ("U");
	my @a_array = ();

	my %ConfigurationParameters = (
		"SAB", \@s_array, "REL",  \@r_array,
		"DIR", \@d_array, "RELA", \@a_array
	);
	my $self = \%ConfigurationParameters;

	bless( $self, $class );

# call initialiseParameters only if parameters are passed else use default values
	if ( defined $params && $params ne "" ) {
		$self->initialiseParameters($params);

		#printhashvaluearray(\%ConfigurationParameters);

	}

	return $self;
}

=head2 initialiseParameters

This subroutine sets the configuaration parameters hash 
which are then used in rest of the module.

=cut

sub initialiseParameters {

	my $self   = shift;
	my $params = shift;

	# set the hash to default values

	if ( !defined $params || !ref $params ) {

		#return;
		print "\nUndefined parameter reference";
	}

	my $file_path_name = $params->{'config'};

	my @source_list;
	my @relation_list;
	my @direction_list;
	if ( defined $params->{'sources'} ) {
		@source_list = @{ $params->{'sources'} };
	}
	if ( defined $params->{'rels'} ) {
		@relation_list = @{ $params->{'rels'} };
	}
	if ( defined $params->{'dirs'} ) {
		@direction_list = @{ $params->{'dirs'} };
	}

	my $r = 0;
	my $d = 0;
	#print "\n *****file path name: $file_path_name";

	if ( defined $file_path_name && $file_path_name ne "" ) {

		my $pflag = 0;
		my $dflag = 1;

		# If user has provided a configuration file
		open( CONFIG, $file_path_name )
		  or die("Error: cannot open configuration file '$file_path_name'\n");

		my @parameters = <CONFIG>;

		for my $p ( 0 .. $#parameters ) {

			#	print "\n $param";

			$parameters[$p] =~ /\s*(.*)\s*::\s*(.*?) (.*?)$/;
			msg("\n $1 \t $2 \t $3");
			my $parameter_name  = $1;
			my $flag            = $2;
			my $parameter_value = $3;
			my @parameter_array = ();

			$parameter_name  =~ s/\s*//g;
			$parameter_value =~ s/\s*//g;
			$flag            =~ s/\s*//g;

			#my @parameter_array

			if ( $parameter_name && $flag && $parameter_value ) {

		  # If more than one sources/relations specified, then seperate by comma
				if ( $parameter_value =~ /\,/ ) {

					@parameter_array = split( ",", $parameter_value );
				}
				else {

					$parameter_array[0] = $parameter_value;

				}

				$parameter_name =~ s/\s*//g;

				#chop($parameter_name);

				if ( $parameter_name =~ /\bREL\b/ ) {
					$pflag = 1;
					$dflag = 0;
					$r = $#parameter_array;
									}
				if ( $pflag == 1 ) {
					if ( $parameter_name =~ /DIR/ ) {
						$dflag = 1;
					$d = $#parameter_array;	
					}
				}
				if ( $flag =~ /\binclude\b/ ) {
					

					#print "\n including @parameter_array";
					$self->{$parameter_name} = \@parameter_array;
					msg(
"\n in hash $parameter_name: @{$self->{$parameter_name}}"
					);
				}
				elsif ( $flag =~ /\bexclude\b/ ) {

					# Dont do anything for now
					print
"\n Invalid configurations: does not handle exclude yet\n";
					print
"\nPlease specify valid configuaration file by refering to the documentation\n";
					exit;

				}
				else {
					print
"\n Invalid configurations, may be forgot to have 'include' keyword\n";
					print
"\nPlease specify valid configuaration file by refering to the documentation\n";
					exit;
				}
			}
			else

			{
				print "\n Invalid configurations\n";
				print
"\nPlease specify valid configuaration file by refering to the documentation\n";
				exit;
			}

		}
		
		
		if ( $dflag == 0 ) {
			print
"\nIf relations are specified, it is necessay to specify directions for them";
			print
"\nPlease specify valid configuaration file by refering to the documentation\n";
			exit;
		}
		
			
		if($r != $d)
			{
				print
"\nEach relation must have a corresponding direction in the configuaration";
print
"\nPlease specify valid configuaration file by refering to the documentation\n";
				exit;
				
			}
		
		
		
	}
	else {

		# If user has not provided a configuration file but has directly
		# provided the configuration option in params hash

		# if no configuration file is specified
		# if configuration parameters are set using hash as parameter

		if (   !defined $file_path_name
			&& @source_list
			&& @relation_list
			&& @direction_list )
		{

			$self->{"SAB"} = \@source_list;
			$self->{"REL"} = \@relation_list;
			$self->{"DIR"} = \@direction_list;
		}

		else {

			if (@source_list) {
				$self->{"SAB"} = \@source_list;
			}
			if (@relation_list) {
				$self->{"REL"} = \@relation_list;
			}
			if (@direction_list) {
				$self->{"DIR"} = \@direction_list;
			}

		}

		#if(!defined $file_path_name && !@source_list && !@relation_list)
		#{
		#	# nothing is specified , then use default values

		#}
	}

}

#-------------------------------PERLDOC STARTS HERE-------------------------------------------------------------

=head1 SEE ALSO

ValidateTerm.pm  GetUserData.pm   ConnectUMLS.pm  ws-getUMLSInfo.pl ws-getAllowablePath.pl

=cut

=head1 AUTHORS

Mugdha Choudhari,             University of Minnesota Duluth
                             E<lt>chou0130 at d.umn.eduE<gt>

Ted Pedersen,                University of Minnesota Duluth
                             E<lt>tpederse at d.umn.eduE<gt>




=head1 COPYRIGHT

Copyright (C) 2011, Mugdha Choudhari, Ted Pedersen

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or (at
your option) any later version.

This program is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to 
The Free Software Foundation, Inc., 
59 Temple Place - Suite 330, 
Boston, MA  02111-1307, USA.

=cut

#---------------------------------PERLDOC ENDS HERE---------------------------------------------------------------

1;    # End of WebService::UMLS::Similarity
