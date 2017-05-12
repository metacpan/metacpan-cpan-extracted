
=head1 NAME

WebService::UMLSKS::FormGraph - Form a graph by accepting parents and siblings from UMLS.

=head1 SYNOPSIS

=head2 Basic Usage

    use WebService::UMLSKS::FormGraph; 
    use WebService::UMLSKS::GetUserData;   
    
    # Creating object of class GetUserData 
	my $g = WebService::UMLSKS::GetUserData->new;
    
    $t1 = valid input CUI1;
    $t2 = valid input CUI2;
    $service = $g->getUserDetails($verbose);
    @sources,@relations,@directions,@attributes = read from configuration;
    $allowable_pattern_regex = read from pattern file;
    $test_flag = 1 for testing else 0;
   
    my $return_val = 
    form_graph-> form_graph($t1,$t2,$service, $verbose, \@sources, \@relations,\@directions
			,\@attributes,$allowable_pattern_regex,$test_flag);

=head1 DESCRIPTION

This module forms a graph of concepts connected to input concepts. It accepts the list of
parents, children and siblings from GetNeighbors module. This module calls
GetAllowablePaths module and finds the shortest allowable path between the input
CUIs or concepts. It then calculates the semantic relatedness between the concepts 
using the shortest allowable path information.

=head1 SUBROUTINES

The subroutines are as follows:

=cut

###############################################################################
##########  CODE STARTS HERE  #################################################

# This module has package  FormGraph

# Author  : Mugdha Choudhari

# Description : this module makes a graph stored in form of hash of hash and
# calculates the semantic relatedness value between the input concepts.

#use lib "/home/mugdha/UMLS-HSO/UMLS-HSO/WebService-UMLSKS-Similarity/lib";
use warnings;
use SOAP::Lite;
use strict;
no warnings qw/redefine/;    #http://www.perlmonks.org/?node_id=582220


#use WebService::UMLSKS::GetAllowablePaths; changed name of getallowablepathsold
use WebService::UMLSKS::GetAllowablePaths;
use WebService::UMLSKS::GetNeighbors;
use WebService::UMLSKS::Query;
use WebService::UMLSKS::ConnectUMLS;
use WebService::UMLSKS::Similarity;
#use Proc::ProcessTable;
#use Graph::Directed;


package WebService::UMLSKS::FormGraph;


use Log::Message::Simple qw[msg error debug];

my %node_cost = ();
my %Graph     = ();
my $counter = 0;
my $const_C = 20;
my $const_k = 1 / 4;
my $absent = 0;

my %MetaCUIs = (
	'C0332280' => 'Linkage concept',
	'C1274012' => 'Ambiguous concept',
	'C1274014' => 'Outdated concept',
	'C1276325' => 'Reason not stated concept',
	'C1274013' => 'Duplicate concept',
	'C1264758' => 'Inactive concept',
	'C1274015' => 'Erroneous concept',
	'C1274021' => 'Moved elsewhere',
	'C2733115' => 'Limited status concept',
	'C1299995' => 'Namespace concept',
	'C1285556' => 'Navigational concept',
	'C1298232' => 'Special concept',
);

my @sources   = ();
my @relations = ();
my @directions = ();
my @attributes = ();

my $source;
my $destination;
my $tflag;
my $verbose = 0;
	

# This sub creates a new object of FormGraph

=head2 new

This sub creates a new object of FormGraph.

=cut

sub new {
	my $class = shift;
	my $self  = {};
	bless( $self, $class );
	return $self;
}



=head2 form_graph

This sub gets neighbors for the input concepts and forms graph. It also
calculates the semantic relatedness between the concepts.

=cut

sub form_graph

{

	my $self    = shift;
	my $term1   = shift;
	my $term2   = shift;
	my $service = shift;
	my $ver     = shift;
	my $s_ref   = shift;
	my $r_ref   = shift;
	my $d_ref   = shift;
	my $a_ref   = shift;
	my $regex   = shift;
	my $test_flag = shift;
	my $sib_threshold = shift;
	my $chd_threshold = shift;

	#my $rel_attribute = "due_to";

	# Set the source and destination for use in other functions
	
	$source = $term1;
	$destination = $term2;
	$tflag = $test_flag;



	
	#my @candidate_siblings = ();
	
	# If this is a testing mode, then create an output file
	if($test_flag == 1)
		{
		open(OUTPUT,">>","output.txt") or die("Error: cannot open file 'output.txt'\n");
		
		}	
		
	$verbose = $ver;
	
	# Set up the directions hash using the directions and relations arrays
	my %Directions = ();
	
	
	msg( "\n in form graph : regex: $regex", $verbose );

	@sources   = @$s_ref;
	@relations = @$r_ref;
	@directions = @$d_ref;
	
	for (my $i = 0 ; $i <= $#relations ; $i++){
		$Directions{$relations[$i]} = $directions[$i];
	}

	#msg("\n in FormGraph",$verbose);
	
	
	#printHash(\%Directions);
	
	msg( "\n Sources used are : @sources", $verbose );

	msg( "\n Relations used are : @relations", $verbose );
	msg( "\n Directions used are : @directions", $verbose );

	%node_cost = ();
	%Graph     = ();

	msg( "\nin FormGraph Term1 : $term1 , Term2: $term2", $verbose );

	# Creating GetParents object to get back the parents of input terms.

	my @queue = ();

	my $current_available_cost = 100000;
	my $pcost                  = 10;
	my $ccost                  = 10;
	my $scost                  = 30;
	my @parents                = ();
	my @sib                    = ();
	my @children               = ();
	$node_cost{$term1} = 0;
	$node_cost{$term2} = 0;

	push( @queue, $term1 );
	push( @queue, $term2 );

	$Graph{$source}    = {};
	$Graph{$destination} = {};
	
	
	my $read_parents = WebService::UMLSKS::GetNeighbors->new;
	
	
	my $get_paths    = WebService::UMLSKS::GetAllowablePaths->new;

	my $cost_upto_current_node = 0;
	my $current_node           = "";
	my @visited                = ();
	my @current_shortest_path  = ();
	my $final_cost;
	my $counter             = 0;
	my $change_in_direction = 0;
	my @path_direction = ();
	
   # my $g = Graph::Directed->new; 
	my $sibcount = 20; 
	my $chdcount = 20;
	my $sd = 0;
	
	use Time::HiRes qw(usleep ualarm gettimeofday tv_interval);	
	
	my $beforequeue = [gettimeofday];
	
		
	msg("Child threshold : $chd_threshold and sibling threshold : $sib_threshold", $verbose);	
		
	#until queue is empty
	
	while ( $#queue != -1 ) {
		
		msg("\nsize of queue : $#queue", $verbose);
		
		my $inqueue = [gettimeofday];
		$sd++;
		#print "inside while loop of queue , before poping element memory: ". memory_usage()/1024/1024 ."\n";
		
		@parents = ();
		@sib     = ();
		@children = ();
		printQueue( \@queue );

		#printHoH(\%Graph);

		my $current_node = shift(@queue);
		$counter++;
		push( @visited, $current_node );
		#msg( "\n visited : @visited", $verbose );
		my $cost_upto_current_node = $node_cost{$current_node};
		#msg(
		#"\n current node : $current_node and cost till here : $cost_upto_current_node",
		#	$verbose
		#);
		if ( $cost_upto_current_node >= $current_available_cost - 10 || $cost_upto_current_node >= 150) {
			msg( "\n ########\nIgnore node as it would lead to longer path",
				$verbose );
			next;
		}

		
		msg("\n QUERYING $current_node", $verbose);
			msg("\nsize of queue : $#queue", $verbose);
			
		my %subgraph = %Graph;
	
		#msg("\n current node $current_node has a allowable shortest path from either source
		 #or destination , so bring its neighbors from UMLS and them them to queue" , $verbose);
		
		my $neighbors_hash_ref =
		  call_getconceptproperties( $current_node, $service );
		  if ( $neighbors_hash_ref eq 'undefined' |
			$neighbors_hash_ref eq 'empty' )
		{
			msg("\n no Info for $current_node",$verbose);
			next;
		}
		my $gcp_time = tv_interval($inqueue);
		msg("\n after getConceptprop call : $gcp_time secs", $verbose);
		
		#prints*"memory after calling webservice for $current_node: ". memory_usage()/1024/1024 ."\n";
		
		#use Time::HiRes qw(usleep ualarm gettimeofday tv_interval);	
	
		my $before_get_neighbors = [gettimeofday];
	
		
		my $neighbors_info_ref =
		  $read_parents->read_object( $neighbors_hash_ref, $current_node, $verbose,\%Directions,$a_ref);
		  
		#print "memory after calling read_object for $current_node: ". memory_usage()/1024/1024 ."\n";
		
		undef $neighbors_hash_ref;
		
		#print "\n neighbors_hahs_ref after undef $neighbors_hash_ref";
		
		#print "memory after undef neighbors_hash: ". memory_usage()/1024/1024 ."\n";
		
		my $getneibor_time = tv_interval($before_get_neighbors);
		msg("\n after get neighbors call : $getneibor_time secs", $verbose);
		
		
		my $updateHOH_nodecost = [gettimeofday];
		
		if (  $neighbors_info_ref eq 'empty' )
		{
			msg("\n no desired neighbors for $current_node",$verbose);
			next;
		}

		if ( defined $neighbors_info_ref && @$neighbors_info_ref ) {
			
		   # For the graph using the parents, children and siblings of the term.
			my @n = @$neighbors_info_ref;

			
			undef $neighbors_info_ref;
			
			#print "memory after undef neighbors info: ". memory_usage()/1024/1024 ."\n";	
			my $p_ref = shift(@n);
			my $c_ref = shift(@n);
			my $s_ref = shift(@n);
			
			undef @n;
			
			if ( $p_ref ne 'empty' ) {
				@parents = @{$p_ref};
			}

			if ( $c_ref ne 'empty' ) {
				@children = @{$c_ref};
			}

			if ( $s_ref ne 'empty' ) {
				@sib = @{$s_ref};
			}

			if($current_node eq $source || $current_node eq $destination)
			{
				if($#sib > $sib_threshold || $#children > $chd_threshold)
				{
					print STDERR "final output :-500<>$term1<>$term2\n";
				
					exit;
					
				}
				
			}
		
			#$sibcount = $#sib; # keep all the neighbors
		
		msg("\n number of parents : $#parents", $verbose);
		
		msg( "\n parents of $current_node : @parents",  $verbose );
		for(my $par = 0 ; $par <  $#parents ; $par++)
		{
		#	msg("$parents[$par] [$Concept{$parents[$par]}", $verbose);
		}
		
		msg("\n number of siblings : $#sib", $verbose);
		
		msg( "\n siblings of $current_node: @sib ",     $verbose );
		for(my $par = 0 ; $par <  $#sib ; $par++)
		{
		#	msg("$sib[$par] [$Concept{$sib[$par]}", $verbose);
		}
		
		msg("\n number of children : $#children", $verbose);
		
		msg( "\n children of $current_node: @children", $verbose );
		for(my $par = 0 ; $par <  $#children ; $par++)
		{
		#	msg("$children[$par] [$Concept{$children[$par]}", $verbose);
		}
		
		
		
		
		
			unless($current_node eq $source || $current_node eq $destination){
		
			
		
			
			if($#sib > $sib_threshold || $#children > $chd_threshold)
			{
		#		msg( "\n parents of $current_node : @parents",  $verbose );
		
		
		#		msg( "\n siblings of $current_node: @sib ",     $verbose );
		
		
		#		msg( "\n children of $current_node: @children", $verbose );
				
				msg("\n should ignore $current_node as it would explode the graph",$verbose);
				
				print STDERR "final output :-50<>$term1<>$term2\n";
				#next;
				exit;
				
			}
			
			
				
		}
			
			
			
			# Check if sibcount is greater than actual #siblings, if yes,
			# take actual siblings.
			#if($sibcount > $#sib){
				$sibcount = $#sib;
			#}
			#if($chdcount > $#children){
				$chdcount = $#children;
			#}
			
				
			foreach my $p (@parents) {
				unless ( $p ~~ %MetaCUIs ) {
					$Graph{$current_node}{$p} = 'U';
					$Graph{$p}{$current_node} = 'D';
					#$g->add_edge($current_node,$p);
					#$g->add_weighted_edge($p,$current_node, 2);
				}
			}
		#	foreach my $c (@children) {
			if ( $#children != -1 ) {
				foreach my $c (0 .. $chdcount) {
					unless ( $children[$c] ~~ %MetaCUIs ) {
						
						$Graph{$current_node}{$children[$c]} = 'D';
						$Graph{$children[$c]}{$current_node} = 'U';
						#$g->add_edge($current_node,$c);
						#$g->add_weighted_edge($c,$current_node, 1);
					}
				}
			}
		#	}
			if ( $#sib != -1 ) {
				foreach my $s (0 .. $sibcount) {
						
					unless ( $sib[$s] ~~ %MetaCUIs ) {
						
						unless(exists $Graph{$current_node}{$sib[$s]}){
							$Graph{$current_node}{$sib[$s]} = 'H';
						}
						
						unless(exists $Graph{$sib[$s]}{$current_node}){
							#$Graph{$sib[$s]}{$current_node} = 3 ;
							$Graph{$sib[$s]}{$current_node} = 'H' ;
						}
					#	$g->add_edge($current_node,$s);
						#$g->add_weighted_edge($s,$current_node, 3);
						
					}
				}
			}
		}
		
		#my %Concept = %$WebService::UMLSKS::GetNeighbors::ConceptInfo_ref;
			
		
		#print "memory after forming graph for $current_node: ". memory_usage()/1024/1024 ."\n";
		
		
		if ( $#parents == -1 && $#sib == -1 && $#children == -1 ) {
			msg("\n no neighbors at all",$verbose);
			undef @parents;
			undef @children;
			undef @sib;
			next;
		}
		else {
			if ( $#parents != -1 ) {
				foreach my $parent (@parents) {
					#msg( "\n parent is : $parent", $verbose );
					unless ( $parent ~~ %MetaCUIs ) {
						unless ( $parent ~~ @visited ) {
							#msg("\n parent $parent not visited");
							my $total_cost_till_parent =
							  $cost_upto_current_node + $pcost;
							if ( $parent ~~ %node_cost ) {
								#msg("\n $parent is already in node cost hash");
								if ( $node_cost{$parent} >
									$total_cost_till_parent )
								{
								#	msg("\n changing value of $parent in node cost hash",$verbose);
									$node_cost{$parent} =
									  $total_cost_till_parent;
								}
							}
							else {
								#msg("\n parent $parent not in node hash, so add to hash and push in queue",	$verbose);
								$node_cost{$parent} = $total_cost_till_parent;
								push( @queue, $parent );

							}
						}
					}

				}

			}

			my $check = 0;
			if ( $#sib != -1 ) {
				for my $s (0 .. $sibcount) {
					
					#msg("\t $sib[$s]",$verbose);
					unless ( $sib[$s] ~~ %MetaCUIs ) {
						unless ($sib[$s] ~~ @visited ) {

							#msg ("\n sibling $sib not visited",$verbose);
							my $total_cost_till_sib =
							  $cost_upto_current_node + $scost;
							if ( $sib[$s] ~~ %node_cost ) {

							#	msg( "\n $sib is already in node cost hash",$verbose);
								if ( $node_cost{$sib[$s]} > $total_cost_till_sib ) {

						   	#	msg("\n changing value of $sib in node cost hash",$verbose);
									$node_cost{$sib[$s]} = $total_cost_till_sib;
								}
							}
							else {

		  #msg("\n sibling $sib not in node hash, so add to hash and push in queue",$verbose);
								$node_cost{$sib[$s]} = $total_cost_till_sib;
								push( @queue, $sib[$s] );
								#$check++;
							}
						}

					}

				
				}
			}

			

			if ( $#children != -1 ) {
				foreach my $child (@children) {
			#		msg( "\n child is : $child", $verbose );
					unless ( $child ~~ %MetaCUIs ) {
						unless ( $child ~~ @visited ) {
			#				msg("\n child $child not visited");
							my $total_cost_till_child =
							  $cost_upto_current_node + $ccost;
							if ( $child ~~ %node_cost ) {
			#					msg("\n $child is already in node cost hash");
								if ( $node_cost{$child} >
									$total_cost_till_child )
								{
			#						msg(
#"\n changing value of $child in node cost hash",
#										$verbose
#									);
									$node_cost{$child} = $total_cost_till_child;
								}
							}
							else {
#								msg(
#"\n child $child not in node hash, so add to hash and push in queue",
#									$verbose
#								);
								$node_cost{$child} = $total_cost_till_child;
								push( @queue, $child );

							}
						}
					}

				}

			}

		}

	my $graph_t = tv_interval($updateHOH_nodecost);
	msg("\n Graph formation node cost update took : $graph_t secs\n",$verbose);	
		#print "memory after updating node cost hash: ". memory_usage()/1024/1024 ."\n";
		@queue = ();
		foreach
		  my $key ( sort { $node_cost{$a} <=> $node_cost{$b} } keys %node_cost )
		{
			unless ( $key ~~ @visited ) {
				push( @queue, $key );
			}
		}
		
		
			msg("\nsize of queue after adding neighbors: $#queue", $verbose);
		
		

		#my %subgraph = %Graph;
		%subgraph = %Graph;
	
		
	  # Check if a shortest allowable path exists between source and destination
		my $get_path_info_result =
		  $get_paths->get_shortest_path_info( \%subgraph, $term1, $term2,
			$verbose, $regex );
		
		#print "memory after calling get paths: ". memory_usage()/1024/1024 ."\n";	
			undef %subgraph;
			%subgraph = ();
		
		#print "memory after undef subgraph: ". memory_usage()/1024/1024 ."\n";	
		if ( $get_path_info_result != -1 && $get_path_info_result != -2 ) {
			my @path_info = @$get_path_info_result;
			@current_shortest_path  = @{ shift(@path_info) };
			$current_available_cost = shift(@path_info);
			$change_in_direction    = shift(@path_info);
			@path_direction = @{ shift(@path_info)};
			$final_cost = $current_available_cost;
			
			my $continue_searching = 0;
			
			# CHANGED ON 24 AUG TO CHECK
			# recommented on 25 aug, as it is taking lot of time
			#foreach my $key (keys %Directions){
			#	if($Directions{$key} eq "H")
			#	{
			#		msg("\n This test has horizontal relation so, finding better path",$verbose);
			#		$continue_searching = 1;
			#	}
			#}
			#....
			
			#if($continue_searching == 0){ #..
				last;
			#}#...
			
			
			
		}
		if($get_path_info_result == -2)
		{
			# Stop seraching for shortest path as the path length has already increased
			# the threshold value.
	
			if(@current_shortest_path)
			{
				msg( "\n Stopped searching as the path length exceeds the threshold value", $verbose);
				last;
			}
			else
			{
				msg( "\n Stopped searching as the path length exceeds the threshold value", $verbose);
				if($test_flag == 1)
				{
					print OUTPUT "0<>$term1<>$term2\n";
				}
				last;
			}
			
			
		}
	

	}

	my $t0_t1 = tv_interval($beforequeue);
	msg("\n while loop took : $t0_t1 secs\n",$verbose);	
	
	#print "memory after while loop ends: ". memory_usage()/1024/1024 ."\n";
	if (@current_shortest_path) {
		
		undef %Graph;
		
		undef %node_cost;
	
		my %Concept = %$WebService::UMLSKS::GetNeighbors::ConceptInfo_ref;
	
		
		undef ${WebService::UMLSKS::GetNeighbors::ConceptInfo_ref};
		
		my $initial_relatedness =  $const_C - ($final_cost/10);
		
		msg( "\n IR : $initial_relatedness", $verbose );
		
		
		if($change_in_direction == -1){
			$change_in_direction = 0;
		}
		my $semantic_relatedness = $initial_relatedness -
						(($const_k * $initial_relatedness) * $change_in_direction);

		print "\n Final shortest path :";
		
		
		for my $n (0 .. $#current_shortest_path) {
			if($n < $#current_shortest_path){
				print "$Concept{$current_shortest_path[$n]} ($current_shortest_path[$n]) ($path_direction[$n])->";
			}
			else
			{
				print "$Concept{$current_shortest_path[$n]} ($current_shortest_path[$n])";
			}
			
			
		}

		msg( "\n Final shortest path : ", $verbose );
		foreach my $n (@current_shortest_path) {
			msg( "->$Concept{$n} ($n)", $verbose );
		}

		undef %Concept;
		#print "memory after undef hash concept: ". memory_usage()/1024/1024 ."\n";
		print "\n Final path cost : $final_cost";
		msg( "\n Final path cost : $final_cost", $verbose );

		print "\n Changes in Direction : $change_in_direction";
		msg( "\n Changes in Direction : $change_in_direction", $verbose );		

		print "\n Semantic relatedness(hso) : $semantic_relatedness\n";
		msg( "\n Semantic relatednes(hso) : $semantic_relatedness", $verbose );
			
		my @months = qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec);
		my @weekDays = qw(Sun Mon Tue Wed Thu Fri Sat Sun);
		my ($second, $minute, $hour, $dayOfMonth, $month, $yearOffset, $dayOfWeek, $dayOfYear, $daylightSavings) = localtime();
		my $year = 1900 + $yearOffset;
		my $theTime = "$hour:$minute:$second, $weekDays[$dayOfWeek] $months[$month] $dayOfMonth, $year";
		msg ("\n $theTime",$verbose);
		if($test_flag == 1)
		{
			print OUTPUT "$semantic_relatedness<>$term1<>$term2\n";
			print STDERR "final output :$semantic_relatedness<>$term1<>$term2\n";
		}
		
		

	}
	else

	{
		undef %Graph;
		undef %node_cost;
		# Check if this is testing mode and if the CUI does not exist.
		if($test_flag == 1 && $absent != 1)
		{
			print OUTPUT "-1<>$term1<>$term2\n";
			print STDERR "final output :-1<>$term1<>$term2\n";
		}
		print "\n No shortest allowable path found between the input terms/CUIs\n";
	}

		
	if($test_flag == 1){
		close OUTPUT;
	}

#msg("memory at end of form graph: ". memory_usage()/1024/1024 ."\n",$verbose);
	
}

=head2 printQueue

This subroutines prints the current contents of queue

=cut

	sub printQueue {
		my $q_ref = shift;
		my @queue = @$q_ref;
		#msg( ("Current Queue is: "), $verbose );
		foreach my $ele (@queue) {
			#msg( " $ele, $node_cost{$ele}", $verbose );
		}
	}

=head2 call_getconceptproperties

This subroutines queries webservice getConceptProperties

=cut

	sub call_getconceptproperties {

		my $cui     = shift;
		my $service = shift;
		my $parents_ref;

		$counter ++;
		#open(COUNT,">>","count.txt") or die("Error: cannot open file 'count.txt'\n");
		
		
		#print COUNT "\n call $counter : $cui ";
   # Creating object of query and passing the method name along with parameters.

		my $query = WebService::UMLSKS::Query->new;

		# Creating Connect object to call sub get_pt while forming a query.

		my $c = WebService::UMLSKS::ConnectUMLS->new;

		#print "\n calling ws for cui $cui";
		$service->readable(1);
		my $return_ref = "";
		
	
		$return_ref = $query->runQuery(
			$service, $cui,
			'getConceptProperties',
			{
				casTicket => $c->get_pt(),

		   # use SOAP::Data->type in order to prevent
		   # UTF-8 strings from being encoded into base64
		   # http://cookbook.soaplite.com/#internationalization%20and%20encoding
				CUI => SOAP::Data->type( string => $cui ),				
				language => 'ENG',
				release  => '2010AB',
				SABs => [ (@sources) ],
				includeConceptAttrs  => 'false',
				includeSemanticTypes => 'false',
				includeTerminology   => 'false',
				includeSuppressibles => 'false',
				includeRelations => 'true',
				relationTypes    => [(@relations)],
				#relationTypes    =>  ['PAR','RN'],				
			},
		);

		if ( $return_ref eq 'undefined' ) {
			print "\n The CUI/term does not exist";
			undef $return_ref;
			return 'undefined';
		}
		elsif ( $return_ref eq 'empty' ) {
			undef $return_ref;
			if($cui eq $source || $cui eq $destination){
				#print "\n No information found for $cui in current Source/s";
			
				if($tflag == 1)
				{
					$absent = 1;
					open(OUT,">>","output.txt") or die("Error: cannot open file 'output.txt'\n");
					print OUTPUT "-1<>$source<>$destination\n";
					print STDERR "final output :-1<>$source<>$destination\n";
					close OUT;
				}
							
			}
			
			return 'empty';
		}
		else {

			return $return_ref;
		}

		#	print "\nhash returned by ws : $parents_ref";

	}

=head2 printHoH

This subroutines prints the current contents of hash of hash

=cut

	sub printHoH {

		my $hoh = shift;
		my %hoh = %$hoh;

		msg( "\nin printHoH : Graph is :", $verbose );
		foreach my $ngram ( keys %hoh ) {
			msg( "\n******************************************", $verbose );
			msg( "\n" . $ngram . "{",                            $verbose );
			foreach my $word ( keys %{ $hoh{$ngram} } ) {
				msg( "\n",                               $verbose );
				msg( $word . "=>" . $hoh{$ngram}{$word}, $verbose );
			}
			msg( "\n}", $verbose );

		}

	}
	
undef %node_cost;
undef %Graph;
undef @sources;
undef @relations;
undef @directions;	

	1;

#-------------------------------PERLDOC STARTS HERE-------------------------------------------------------------



=head1 SEE ALSO

ValidateTerm.pm  GetUserData.pm  Query.pm  ws-getUMLSInfo.pl FormGraph.pm GetAllowablePath.pm

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
