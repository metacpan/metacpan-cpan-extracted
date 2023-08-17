package constant::more;

use version; our $VERSION=version->declare("v0.2.0");
use strict;
use warnings;

#use feature qw<state>;
no warnings "experimental";

our %seen;

sub import {

	my $package =shift;
	return unless @_;
	#check if first item is a hash ref.
	my $flags;
	if(ref($_[0]) eq "HASH"){
		$flags=shift;
	}
	elsif(ref($_[0]) eq ""){
		#flat list of 2 items expected
		$flags={$_[0]=>$_[1]};
	}
	else {
    die "Flat list or hash ref expected";
	}
	
	
	my $caller=caller;
	no strict "refs";
	my %table;

	for  my $name (keys %$flags){
		my $entry;
		my $value;
		my @values;


		if(ref($flags->{$name}) eq "HASH"){
			#Full declaration
			$entry=$flags->{$name};
		}
		else {
			#assumed a short cut, just name and value
			$entry={val=>$flags->{$name}, keep=>undef, opt=>undef, env=>undef};
		}

		#Default sub is to return the key value pair
		my $sub=$entry->{sub}//= sub {
			#return name value pair
			$name, $_[1];
		};

		#Set the entry by name
		$flags->{$name}=$entry;

		my $success;
		my $wrapper= sub {
			my  ($opt_name, $opt_value)=@_;

			return unless @_>=2;

			my @results=&$sub;


			#set values in the table
      my $i=0;
      while($i<@results){
        my $pair =[$results[$i++], $results[$i++]];
				my $value=$pair->[1];
				my $name=$pair->[0];
				unless($name=~/::/){
					$name=$caller."::".$name;
				}
        #Only configure contant for addition if it doesn't exist
        #in target namespace
				$table{$name}=$value unless(*{$name}{CODE})
			}

			$success=1;

		};


		#Select a value 
		$wrapper->("", $entry->{val});	#default
			

		#CMD line argument override
		if($entry->{opt}){	
			require Getopt::Long;
			if($entry->{keep}){
				my $parser=Getopt::Long::Parser->new();
				
				my @array=@ARGV; #copy
				$parser->getoptionsfromarray(\@array, $entry->{opt}, $wrapper) or die "Invalid options";


			}
			else{
				my $parser=Getopt::Long::Parser->new(
					config=>[
						"pass_through"
					]
				);
				$parser->getoptions( $entry->{opt}, $wrapper) or die "Invalid options";

			}
		}

		if(!$success and $entry->{env}){
		#Env override
			if(defined $ENV{$entry->{env}}){
				$wrapper->($ENV{$entry->{env}});
			}
		}
	}

  #Actually
  #Create the constants
  while(my($name,$val)=each %table){
    *{$name}=sub (){$val} 
  }
}

1;
