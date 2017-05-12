=head1 NAME

WebService::UMLSKS::GetAllowablePaths - Get an allowable shortest path between the supplied terms.

=head1 SYNOPSIS

=head2 Basic Usage

use WebService::UMLSKS::GetAllowablePaths;
	
%subgraph = graph formed by FormGraph module;
	
$regex = allowable pattern regex specified by configuaration;
	
# $term1 and $term2 are current pair of terms
	
my $get_paths    = WebService::UMLSKS::GetAllowablePaths->new;	
	
my $get_path_info_result = $get_paths->get_shortest_path_info( \%subgraph, $term1, $term2,$verbose, $regex );
	
# $get_path_info_result is an array reference which consists of path information.		

=head1 DESCRIPTION

Get an allowable shortest path between the input terms. This module uses a standard BFS
graph algorithm with small modifications to accomodate the rules for allowable path.
It calculates the shortest allowable path between any two terms supplied to it as a input with 
a graph formed by FormGraph module.

=head1 SUBROUTINES

The subroutines are as follows:

=cut


###############################################################################
##########  CODE STARTS HERE  #################################################

# This module has package  GetAllowablePaths

# Author  : Mugdha Choudhari

# Description : this module takes a graph stored in form of hash of hash
# along with source and destination as input.



#use lib "/home/mugdha/UMLS-HSO/UMLS-HSO/WebService-UMLSKS-Similarity/lib";
use warnings;
use SOAP::Lite;
use strict;
no warnings qw/redefine/;    #http://www.perlmonks.org/?node_id=582220

use WebService::UMLSKS::GetNeighbors;

#use Proc::ProcessTable;



package WebService::UMLSKS::GetAllowablePaths;

my $pcost = 10;
my $scost = 20;


use Log::Message::Simple qw[msg error debug];
my $verbose = 0;
my $regex = "";

my $current_shortest_length = 150;
my %Concept = ();
my %graph = ();

=head2 new

This sub creates a new object of GetAllowablePaths

=cut

sub new {
	my $class = shift;
	my $self  = {};
	bless( $self, $class );
	return $self;
}




=head2 get_shortest_path_info

This sub returns the shortest path along with its cost and number of changes in direction

=cut

sub get_shortest_path_info
{

	my $self     = shift; # stupid girl... 
	my $hash_ref = shift;
	my $source      = shift;
	my $destination = shift;
	my $ver = shift;
	$regex = shift;
	$verbose = $ver;	
	 %graph       = %$hash_ref;
	
	use Time::HiRes qw(usleep ualarm gettimeofday tv_interval);	
	my $t0 = [gettimeofday];
	
	# Return array that contains information of shortest path if found.
	my @shortest_path_info = ();
	
	# BFS algorithm to find the shortest allowable path between the 
	# current source and destination
	
	# FIFO queue used for Breadth First Traversal
	# This queue is a list of list
	# Each element is a path (list) to a node which is last element of the list
	# For ex., if the first element of queue is (A,B,C), this is path to get to node C.

	my @queue = ();

	# Initial path to source
	my @t_path = ();
	my @temp_path = ();
	
	# Initialize Queue by pushing source

	push( @t_path, $source );
	my $t_ref = \@t_path;
	push( @queue, $t_ref );
	
	
	my $shortest_path_cost      = 150;
	my $shortest_path_ref       = "";
	my @shortest_path_direction = ();
	my $change_in_direction     = -1;
		
		
		
	# While queue is not empty traverse the graph
	while ( $#queue != -1 ) {
		
		
	#print "memory get_allpaths:just in while loop ". memory_usage()/1024/1024 ."\n";
#	print "memory get_allpaths: ". memory_usage()/1024/1024 ."\n";
		my $temp_path_ref = shift(@queue);
		@temp_path = @$temp_path_ref;
		
		#print "\nmemory in while loop get_allpaths: size of tem path :$#temp_path ". memory_usage()/1024/1024 ."\n";
		my $last_node = $temp_path[$#temp_path];
		
		if ( $last_node eq $destination ) {

		#	print "memory get_allpaths: one path found ". memory_usage()/1024/1024 ."\n";
			my @possible_path = @temp_path;
			
			#msg( "\n one of the paths found",$verbose);

			#msg( "\nValid path: @temp_path",$verbose);
	
			my $current_direction = "X";
			my $current_path_cost = getCost( \@possible_path );
	
			#msg("\nValid path cost: $current_path_cost",$verbose);
	
			if ( $current_path_cost < $shortest_path_cost ) {
				msg( "\n got shorter path than current one : @temp_path",$verbose);
				$shortest_path_cost = $current_path_cost;
				#msg( "\n current cost is : $shortest_path_cost",$verbose);
				$shortest_path_ref       = \@possible_path;
		#	@shortest_path_direction = @{getDirection( \@temp_path )};
				@shortest_path_direction = (); #....fixed bug here
				my $arrow_direction = ""; #... forgot to have these two lines
				
				$change_in_direction = -1;

				for my $i ( 0 .. $#temp_path - 1 ) {
					my $first_node = $temp_path[$i];
					my $next_node  = $temp_path[ $i + 1 ];
					my $direction  = $graph{$first_node}{$next_node};
	
					# If current direction is not equal to previous direction, then
					# increament the number of chnages in direction in current path.
					if ( $current_direction ne $direction ) {
						$change_in_direction++;
						$current_direction = $direction;
	
					}
			
					#push( @shortest_path_direction, $arrow_direction );
						push( @shortest_path_direction, $direction );
				}	
			}
			
		}
		
		foreach my $link_node ( keys %{ $graph{$last_node} } ) {
		#	print "\n link node : $link_node";
			if ( $link_node ~~ @temp_path ) {
			}
			else {
				#msg( "\n link node $link_node not in @temp_path",$verbose);
				my @new_path = ();
	
				#push(@temp_path,$link_node);
				@new_path = @temp_path;
				push( @new_path, $link_node );
				#print "\n new path : @new_path";
				#my $new_path_ref      = \@new_path;
				
				# Check if this path is allowable
				my $path_string = "";
				for my $i ( 0 .. $#new_path - 1 ) {
					my $first_node = $new_path[$i];
					my $next_node  = $new_path[ $i + 1 ];
					my $direction  = $graph{$first_node}{$next_node};
					$path_string = "$path_string" . "$direction"; # i HATE THIS LINEEEEEEE
	
			    }
				#msg( "\n link node $link_node not in @temp_path, so new path : @new_path : $path_string",$verbose);
				if ( $path_string =~ m/$regex/ ) {
					#msg("\nthere is allowed path between $source and $destination :", $verbose);
					#msg("\n path for link node $link_node : @new_path has path string $path_string which is allowed", $verbose);
					
					my $new_path_ref = \@new_path;
					#push( @queue, $new_path_ref );			
				
					my $current_path_cost = getCost( \@new_path );
	#				msg( "\npartial path cost for @new_path: $current_path_cost",$verbose);
					if ( $current_path_cost < $shortest_path_cost  ) {
	#					msg(
	#	"\npartial path cost is less than current shortest available path so push in queue",$verbose);
		
						push( @queue, $new_path_ref );
						#print "\n new queue : @queue";
					}
		
					else {
						undef $new_path_ref;
						undef @new_path;
						undef @temp_path;
	#					msg(
	#	"\n current partial path is greater than current shorter path so, ignore this path",$verbose);
					}
				}
				else{
				#	msg("\n path for link node $link_node : @new_path has path string $path_string which is not allowed", $verbose);
				}
			}
		}
	}
		#	print "\nmemory get_allpaths:after while loop ". memory_usage()/1024/1024 ."\n";	
	undef %graph;	
	
	my $t0_t1 = tv_interval($t0);        
	  msg("\n BFS took : $t0_t1 secs\n",$verbose);
	  
	if($shortest_path_ref ne "")
	{
		#$current_shortest_length = $path_cost / 10;
		msg("\n shortest path : @$shortest_path_ref", $verbose);
		msg("\n shortest cost : $shortest_path_cost", $verbose);
		msg("\n changes in direction for current shortest path : $change_in_direction", $verbose );
		msg("\n shortest path direction path string : @shortest_path_direction", $verbose);
		push(@shortest_path_info,$shortest_path_ref);
		push(@shortest_path_info,$shortest_path_cost);
		push(@shortest_path_info, $change_in_direction);
		push(@shortest_path_info, \@shortest_path_direction);
		
		return \@shortest_path_info;
	}
	else
	{
		return -1;
	}

}

=head2 getCost

This sub finds the cost of the path accepted as a parameter

=cut

sub getCost

{

	my $ref = shift;

	my @candidate_path    = @$ref;
	my $current_path_cost = 0;
	my $direction         = "";

	for my $i ( 0 .. $#candidate_path - 1 ) {
		my $first_node = $candidate_path[$i];
		my $next_node  = $candidate_path[ $i + 1 ];
		$direction = $graph{$first_node}{$next_node};

		# If a parent or child relation then add the parent cost
		# changed the patterns regex
		if ( $direction =~ /\bU\b|\bD\b/ ) {
			$current_path_cost = $current_path_cost + 10;
		}

		# If a sibling relation then add the sibling cost
		elsif ( $direction =~ /\bH\b/ ) {
			$current_path_cost = $current_path_cost + 20;
		}

	}

#msg("\n cost of candidte path : @candidate_path : is : $current_path_cost", $verbose);

	return $current_path_cost;

}



=head2 printHoH

This subroutines prints the current contents of hash of hash

=cut

sub printHoH {

	my $hoh = shift;
	my %hoh = %$hoh;

	msg( "\nin printHoH : Graph is :", $verbose);
	foreach my $ngram ( keys %hoh ) {
		msg("\n***************************************************", $verbose);
		msg( "\n" . $ngram . "{", $verbose);
		foreach my $word ( keys %{ $hoh{$ngram} } ) {
			msg( "\n", $verbose);
			msg( $word. "=>" . $hoh{$ngram}{$word}, $verbose);
		}
		msg( "\n}", $verbose);

	}

}


=head2 printHash

This sub prints argument hash.

=cut

sub printHash
{
	my $ref = shift;
	my %hash = %$ref;
	foreach my $key(keys %hash)
	{
		print "\n $key => $hash{$key}";
	}
}

#printHoH(\%ParentInfo);



=head1 SEE ALSO

GetUserData.pm  Query.pm  ws-getAllowabletPath.pl GetParents.pm

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



1;