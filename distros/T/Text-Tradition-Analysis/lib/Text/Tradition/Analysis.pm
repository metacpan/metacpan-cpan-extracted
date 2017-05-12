package Text::Tradition::Analysis;

use strict;
use warnings;
use Algorithm::Diff;  # for word similarity measure
use Encode qw/ decode_utf8 encode_utf8 /;
use Exporter 'import';
use Graph;
use JSON qw/ to_json decode_json /;
use LWP::UserAgent;
use Set::Scalar;
use Text::Tradition::Analysis::Result;
use Text::Tradition::Stemma;
use TryCatch;

use vars qw/ @EXPORT_OK $VERSION /;
@EXPORT_OK = qw/ run_analysis group_variants analyze_variant_location wit_stringify /;
$VERSION = "2.0.4";


my $DEFAULT_SOLVER_URL = 'http://perf.stemmaweb.net/cgi-bin/graphcalc.cgi';
my $unsolved_problems = {};

=head1 NAME

Text::Tradition::Analysis - functions for stemma analysis of a tradition

=head1 DESCRIPTION

Text::Tradition is a library for representation and analysis of collated
texts, particularly medieval ones.  Where the Collation is the central
feature of a Tradition, it may also have one or more stemmata associated
with it, and these stemmata may be analyzed. This package provides the
following modules:

=over 4

=item * L<Text::Tradition::HasStemma> - a role that will be composed into
Text::Tradition objects, providing the ability for Text::Tradition::Stemma
objects to be associated with them.

=item * L<Text::Tradition::Stemma> - an object class that represents stemma
hypotheses, both rooted (with a single archetype) and unrooted (e.g.
phylogenetic trees).

=item * Text::Tradition::Analysis (this package). Provides functions for
the analysis of a given stemma against the collation within a given
Tradition.

=back

=head1 SYNOPSIS

  use Text::Tradition;
  use Text::Tradition::Analysis qw/ run_analysis analyze_variant_location /;
  my $t = Text::Tradition->new( 
    'name' => 'this is a text',
    'input' => 'TEI',
    'file' => '/path/to/tei_parallel_seg_file.xml' );
  $t->add_stemma( 'dotfile' => $stemmafile );

  my $variant_data = run_analysis( $tradition );
    
=head1 SUBROUTINES

=head2 run_analysis( $tradition, %opts )

Runs the analysis described in analyze_variant_location on every location in the 
collation of the given tradition, with the given options. These include:

=over 4

=item * stemma_id - Specify which of the tradition's stemmata to use. Default
is 0 (i.e. the first).

=item * ranks - Specify a list of location ranks to analyze; exclude the rest.

=item * merge_types - Specify a list of relationship types, where related readings 
should be treated as identical for the purposes of analysis.

=item * exclude_type1 - Exclude those ranks whose groupings have only type-1 variants.

=back

=begin testing

use Text::Tradition;
use Text::Tradition::Analysis qw/ run_analysis analyze_variant_location /;

my $datafile = 't/data/florilegium_tei_ps.xml';
my $tradition = Text::Tradition->new( 'input' => 'TEI',
                                      'name' => 'test0',
                                      'file' => $datafile );
my $s = $tradition->add_stemma( 'dotfile' => 't/data/florilegium.dot' );
is( ref( $s ), 'Text::Tradition::Stemma', "Added stemma to tradition" );

my %expected_genealogical = (
	1 => 0,
	2 => 1,
	3 =>  0,
	5 =>  0,
	7 =>  0,
	8 =>  0,
	10 => 0,
	13 => 1,
	33 => 0,
	34 => 0,
	37 => 0,
	60 => 0,
	81 => 1,
	84 => 0,
	87 => 0,
	101 => 0,
	102 => 0,
	122 => 1,
	157 => 0,
	166 => 1,
	169 => 1,
	200 => 0,
	216 => 1,
	217 => 1,
	219 => 1,
	241 => 1,
	242 => 1,
	243 => 1,
);

my $data = run_analysis( $tradition, calcdsn => 'dbi:SQLite:dbname=t/data/analysis.db' );
my $c = $tradition->collation;
foreach my $row ( @{$data->{'variants'}} ) {
	# Account for rows that used to be "not useful"
	unless( exists $expected_genealogical{$row->{'id'}} ) {
		$expected_genealogical{$row->{'id'}} = 1;
	}
	my $gen_bool = $row->{'genealogical'} ? 1 : 0;
	is( $gen_bool, $expected_genealogical{$row->{'id'}}, 
		"Got correct genealogical flag for row " . $row->{'id'} );
	# Check that we have the right row with the right groups
	my $rank = $row->{'id'};
	foreach my $rdghash ( @{$row->{'readings'}} ) {
		# Skip 'readings' that aren't really
		next unless $c->reading( $rdghash->{'readingid'} );
		# Check the rank
		is( $c->reading( $rdghash->{'readingid'} )->rank, $rank, 
			"Got correct reading rank" );
		# Check the witnesses
		my @realwits = sort $c->reading_witnesses( $rdghash->{'readingid'} );
		my @sgrp = sort @{$rdghash->{'group'}};
		is_deeply( \@sgrp, \@realwits, "Reading analyzed with correct groups" );
	}
}
is( $data->{'variant_count'}, 58, "Got right total variant number" );
# TODO Make something meaningful of conflict count, maybe test other bits

=end testing

=cut

sub run_analysis {
	my( $tradition, %opts ) = @_;
	my $c = $tradition->collation;
	my $aclabel = $c->ac_label;

	my $stemma_id = $opts{'stemma_id'} || 0;
	my @ranks = ref( $opts{'ranks'} ) eq 'ARRAY' ? @{$opts{'ranks'}} : ();
	my $collapse = Set::Scalar->new();
	if( $opts{'merge_types'} && ref( $opts{'merge_types'} ) eq 'ARRAY' ) {
		$collapse->insert( @{$opts{'merge_types'}} );
	} elsif( $opts{'merge_types'} ) {
		$collapse->insert( $opts{'merge_types'} );
	}
	
	# If we have specified a local lookup DB for graph calculation results,
	# make sure it exists and connect to it.
	my $dir;
	if ( exists $opts{'calcdsn'} ) {
		eval { require Text::Tradition::Directory };
		if( $@ ) {
			throw( "Could not instantiate a directory for " . $opts{'calcdsn'}
				. ": $@" );
		}
		$opts{'dir'} = Text::Tradition::Directory->new( dsn => $opts{'calcdsn'} );
	} elsif( !exists $opts{'solver_url'} ) {
		$opts{'solver_url'} = $DEFAULT_SOLVER_URL;
	}

	# Get the stemma	
	my $stemma = $tradition->stemma( $stemma_id );

	# Figure out which witnesses we are working with - that is, the ones that
	# appear both in the stemma and in the tradition. All others are 'lacunose'
	# for our purposes.
	my $lacunose = Set::Scalar->new( $stemma->hypotheticals );
	my $stemma_wits = Set::Scalar->new( $stemma->witnesses );
	my $tradition_wits = Set::Scalar->new( map { $_->sigil } $tradition->witnesses );
	$lacunose->insert( $stemma_wits->symmetric_difference( $tradition_wits )->members );

	# Find and mark 'common' ranks for exclusion, unless they were
	# explicitly specified.
	unless( @ranks ) {
		my %common_rank;
		foreach my $rdg ( $c->common_readings ) {
			$common_rank{$rdg->rank} = 1;
		}
		@ranks = grep { !$common_rank{$_} } ( 1 .. $c->end->rank-1 );
	}
	
	# Group the variants to send to the solver
	my @groups;
	my @use_ranks;
	my %lacunae;
	my $moved = {};
	foreach my $rank ( @ranks ) {
		my $missing = $lacunose->clone();
		my $rankgroup = group_variants( $tradition, $rank, $missing, $moved, $collapse );
		# Filter out any empty rankgroups 
		# (e.g. from the later rank for a transposition)
		next unless keys %$rankgroup;
		# Get the graph for this rankgroup
		my $rankgraph = _graph_for_grouping( $stemma, $rankgroup, $missing, $aclabel );
		if( $opts{'exclude_type1'} ) {
			# Check to see whether this is a "useful" group.
			next unless _useful_variant( $rankgroup, $rankgraph, $aclabel );
		}
		push( @use_ranks, $rank );
		push( @groups, { grouping => $rankgroup, graph => $rankgraph } );
		$lacunae{$rank} = $missing;
	}
	# Run the solver
	my $answer;
	try {
		$answer = solve_variants( \%opts, @groups );
	} catch ( Text::Tradition::Error $e ) {
		if( $e->message =~ /IDP/ ) {
			# Something is wrong with the solver; make the variants table anyway
			$answer->{'variants'} = [];
			map { push( @{$answer->{'variants'}}, _init_unsolved( $_, 'IDP error' ) ) }
				@groups;
		} else {
			# Something else is wrong; error out.
			$e->throw;
		}
	}

	# Do further analysis on the answer
	my $conflict_count = 0;
	my $reversion_count = 0;
	foreach my $idx ( 0 .. $#use_ranks ) {
		my $location = $answer->{'variants'}->[$idx];
		# Add the rank back in
		my $rank = $use_ranks[$idx];
		$location->{'id'} = $rank;
		# Note what our lacunae are
		my %lmiss;
		map { $lmiss{$_} = 1 } @{$lacunae{$use_ranks[$idx]}};
		$location->{'missing'} = [ keys %lmiss ];
		
		# Run the extra analysis we need.
		## TODO We run through all the variants in this call, so
		## why not add the reading data there instead of here below?
		my $graph = $groups[$idx]->{graph};
		analyze_location( $tradition, $graph, $location, \%lmiss );

		my @layerwits;
		# Do the final post-analysis tidying up of the data.
		foreach my $rdghash ( @{$location->{'readings'}} ) {
			$conflict_count++ if $rdghash->{'is_conflict'};
			$reversion_count++ if $rdghash->{'is_reverted'};
			# Add the reading text back in, setting display value as needed
			my $rdg = $c->reading( $rdghash->{'readingid'} );
			if( $rdg ) {
				$rdghash->{'text'} = $rdg->text . 
					( $rdg->rank == $rank ? '' : ' [' . $rdg->rank . ']' );
				if( $rdg->does( 'Text::Tradition::Morphology' ) ) {
					$rdghash->{'is_ungrammatical'} = $rdg->grammar_invalid;
					$rdghash->{'is_nonsense'} = $rdg->is_nonsense;
				}
			}
			# Remove lacunose witnesses from this reading's list now that the
			# analysis is done 
			my @realgroup;
			map { push( @realgroup, $_ ) unless $lmiss{$_} } @{$rdghash->{'group'}};
			$rdghash->{'group'} = \@realgroup;
			# Note any layered witnesses that appear in this group
			foreach( @realgroup ) {
				if( $_ =~ /^(.*)\Q$aclabel\E$/ ) {
					push( @layerwits, $1 );
				}
			}
		}
		$location->{'layerwits'} = \@layerwits if @layerwits;
	}
	$answer->{'conflict_count'} = $conflict_count;
	$answer->{'reversion_count'} = $reversion_count;
	
	return $answer;
}

=head2 group_variants( $tradition, $rank, $lacunose, $transposed, $merge_relationship_types )

Groups the variants at the given $rank of the collation, treating any
relationships in the set $merge_relationship_types as equivalent. 
$lacunose should be a reference to an array, to which the sigla of lacunose
witnesses at this rank will be appended; $transposed should be a reference
to a hash, wherein the identities of transposed readings and their
relatives will be stored.

Returns a hash $group_readings where $rdg is attested by the witnesses listed 
in $group_readings->{$rdg}.

=cut

# Return group_readings, groups, lacunose
sub group_variants {
	my( $tradition, $rank, $lacunose, $transposed, $collapse ) = @_;
	my $c = $tradition->collation;
	my $aclabel = $c->ac_label;
	my $table = $c->alignment_table;
	# Get the alignment table readings
	my %readings_at_rank;
	my $check_for_gaps = Set::Scalar->new();
	my %moved_wits;
	my $has_transposition;
	my @transp_acgap;
	foreach my $tablewit ( @{$table->{'alignment'}} ) {
		my $rdg = $tablewit->{'tokens'}->[$rank-1];
		my $wit = $tablewit->{'witness'};
		# Exclude the witness if it is "lacunose" which if we got here
		# means "not in the stemma".
		next if _is_lacunose( $wit, $lacunose, $aclabel );
		# Note if the witness is actually in a lacuna
		if( $rdg && $rdg->{'t'}->is_lacuna ) {
			_add_to_witlist( $wit, $lacunose, $aclabel );
		# Otherwise the witness either has a positive reading...
		} elsif( $rdg ) {
			# If the reading has been counted elsewhere as a transposition, ignore it.
			if( $transposed->{$rdg->{'t'}->id} ) {
				# TODO Does this cope with three-way transpositions?
				map { $moved_wits{$_} = 1 } @{$transposed->{$rdg->{'t'}->id}};
				next;
			}
			# Otherwise, record it...
			$readings_at_rank{$rdg->{'t'}->id} = $rdg->{'t'};
			# ...and grab any transpositions, and their relations.
			my @transp = grep { $_->rank != $rank } _all_related( $rdg->{'t'} );
			foreach my $trdg ( @transp ) {
				next if exists $readings_at_rank{$trdg->id};
				$has_transposition = 1;
				my @affected_wits = _table_witnesses( 
					$table, $trdg->rank, $trdg, $lacunose, $aclabel );
				next unless @affected_wits;
				map { $moved_wits{$_} = 1 } @affected_wits;
				my @thisloc_wits = _table_witnesses( $table, $rank, $rdg->{'t'}, 
					$lacunose, $aclabel );
				# Check to see if our affected wits have layers that do something
				# wacky.
				my %transploc_gaps;
				map { $transploc_gaps{$_} = 1 } 
					_table_witnesses( $table, $trdg->rank, undef, $lacunose, $aclabel );
				foreach my $aw ( @affected_wits ) {
					if( $transploc_gaps{$aw.$aclabel} ) {
						push( @thisloc_wits, $aw.$aclabel );
						push( @transp_acgap, $aw.$aclabel );
					}
				}
				# Record which witnesses we should count as already analyzed when we 
				# get to the transposed reading's own rank.
				$transposed->{$trdg->id} = \@thisloc_wits;
				$readings_at_rank{$trdg->id} = $trdg;
			}
		# ...or it is empty, ergo a gap.
		} else {
			_add_to_witlist( $wit, $check_for_gaps, $aclabel );
		}
	}
	# Push all the transposition layer gaps onto our list
	$check_for_gaps->insert( @transp_acgap );
	# Now remove from our 'gaps' any witnesses known to have been dealt with elsewhere.
	my $gap_wits = Set::Scalar->new();
	map { _add_to_witlist( $_, $gap_wits, $aclabel ) 
		unless $moved_wits{$_} } $check_for_gaps->members;
		
	# Group the readings, collapsing groups by relationship if needed.	
	my $grouped_readings = {};
	foreach my $rdg ( values %readings_at_rank ) {
		# Skip readings that have been collapsed into others.
		next if exists $grouped_readings->{$rdg->id} 
			&& $grouped_readings->{$rdg->id} eq 'COLLAPSE';
		# Get the witness list, including from readings collapsed into this one.
		my @wits = _table_witnesses( $table, $rdg->rank, $rdg, $lacunose, $aclabel );
		if( $collapse && $collapse->size ) {
			my $filter = sub { $collapse->has( $_[0]->type ) };
			foreach my $other ( $rdg->related_readings( $filter ) ) {
				my @otherwits = _table_witnesses( $table, $other->rank, $other, $lacunose, $aclabel );
				push( @wits, @otherwits );
				$grouped_readings->{$other->id} = 'COLLAPSE';
			}
		}
		$grouped_readings->{$rdg->id} = Set::Scalar->new( @wits );
	}
	if( $gap_wits->members ) {
		$grouped_readings->{'(omitted)'} = $gap_wits;
	}
	
	# Get rid of our collapsed readings
	map { delete $grouped_readings->{$_} if(
			 $grouped_readings->{$_} eq 'COLLAPSE'
			 || $grouped_readings->{$_}->is_empty ) } 
		keys %$grouped_readings;
		
	# If something was transposed, check the groups for doubled-up readings
	if( $has_transposition ) {
		# print STDERR "Group for rank $rank:\n";
		# map { print STDERR "\t$_: " . join( ' ' , @{$grouped_readings->{$_}} ) . "\n" } 
		# 	keys %$grouped_readings;
		_check_transposed_consistency( $c, $rank, $transposed, $grouped_readings );
	}
	
	# Return the result
	return $grouped_readings;
}

sub _all_related {
	# Except by repetition
	my $rdg = shift;
	my $c = $rdg->collation;
	my @check = ( $rdg );
	my %seen;
	while( @check ) {
		my @next;
		foreach my $ck ( @check ) {
			$seen{"$ck"} = 1;
			push( @next, grep { !$seen{"$_"} } 
				$ck->related_readings( sub { $_[0]->type ne 'repetition' } ) );
		}
		@check = @next;
	}
			
		
	my @all = map { $c->reading( $_ ) } keys %seen;
	return @all;
}
	

# Helper function to query the alignment table for all witnesses (a.c. included)
# that have a given reading at its rank.
sub _table_witnesses {
	my( $table, $rank, $trdg, $lacunose, $aclabel ) = @_;
	my $tableidx = $rank - 1;
	my $has_reading = Set::Scalar->new();
	foreach my $row ( @{$table->{'alignment'}} ) {
		my $wit = $row->{'witness'};
		next if _is_lacunose( $wit, $lacunose, $aclabel );
		my $rdg = $row->{'tokens'}->[$tableidx];
		if( $trdg ) {
			# We have some positive reading we want.
			next unless exists $rdg->{'t'} && defined $rdg->{'t'};
			if( $trdg->is_lacuna ) {
				_add_to_witlist( $wit, $has_reading, $aclabel )
				if $rdg->{'t'}->is_lacuna;
			} else {
				_add_to_witlist( $wit, $has_reading, $aclabel )
					if $rdg->{'t'}->id eq $trdg->id;
			}
		} else {
			# We want the omissions.
			next if exists $rdg->{'t'} && defined $rdg->{'t'};
			_add_to_witlist( $wit, $has_reading, $aclabel )
		}
	}
	return $has_reading->members;
}

# Helper function to see if a witness is lacunose even if we are asking about
# the a.c. version
sub _is_lacunose {
	my ( $wit, $lac, $acstr ) = @_;
	if( $wit =~ /^(.*)\Q$acstr\E$/ ) {
		$wit = $1;
	}
	return $lac->has( $wit );
}

# Helper function to ensure that X and X a.c. never appear in the same list.
sub _add_to_witlist {
	my( $wit, $list, $acstr ) = @_;
	if( $wit =~ /^(.*)\Q$acstr\E$/ ) {
		# Don't add X a.c. if we already have X 
		return if $list->has( $1 );
	} else {
		# Delete X a.c. if we are about to add X
		$list->delete( $wit.$acstr );
	}
	$list->insert( $wit );
}

sub _check_transposed_consistency {
	my( $c, $rank, $transposed, $groupings ) = @_;
	my %seen_wits;
	my %thisrank;
	# Note which readings are actually at this rank, and which witnesses
	# belong to which reading.
	foreach my $rdg ( keys %$groupings ) {
		my $rdgobj = $c->reading( $rdg );
		# Count '(omitted)' as a reading at this rank
		$thisrank{$rdg} = 1 if !$rdgobj || $rdgobj->rank == $rank;
		map { push( @{$seen_wits{$_}}, $rdg ) } @{$groupings->{$rdg}};
	}
	# Our work is done if we have no witness belonging to more than one
	# reading.
	my @doubled = grep { scalar @{$seen_wits{$_}} > 1 } keys %seen_wits;
	return unless @doubled;
	# If we have a symmetric related transposition, drop the non-rank readings.
	if( @doubled == scalar keys %seen_wits ) {
		foreach my $rdg ( keys %$groupings ) {
			if( !$thisrank{$rdg} ) {
				# Groupings are Set::Scalar objects so we can compare them outright.
				my ( $matched ) = grep { $groupings->{$rdg} == $groupings->{$_} }
					keys %thisrank;
				delete $groupings->{$rdg};
				# If we found a group match, assume there is a symmetry happening.
				# TODO think more about this
				# print STDERR "*** Deleting symmetric reading $rdg\n";
				unless( $matched ) {
					delete $transposed->{$rdg};
					warn "Found problem in evident symmetry with reading $rdg";
				}
			}
		}
	# Otherwise 'unhook' the transposed reading(s) that have duplicates.
	} else {
		foreach my $dup ( @doubled ) {
			foreach my $rdg ( @{$seen_wits{$dup}} ) {
				next if $thisrank{$rdg};
				next unless exists $groupings->{$rdg};
				# print STDERR "*** Deleting asymmetric doubled-up reading $rdg\n";
				delete $groupings->{$rdg};
				delete $transposed->{$rdg};
			}
		}
		# and put any now-orphaned readings into an 'omitted' reading.
		foreach my $wit ( keys %seen_wits ) {
			unless( grep { exists $groupings->{$_} } @{$seen_wits{$wit}} ) {
				$groupings->{'(omitted)'} = Set::Scalar->new()
					 unless exists $groupings->{'(omitted)'};
				_add_to_witlist( $wit, $groupings->{'(omitted)'}, $c->ac_label );
			}
		}
	}
}

# For the given grouping, return its situation graph based on the stemma.
sub _graph_for_grouping {
	my( $stemma, $grouping, $lacunose, $aclabel ) = @_;
	my $acwits = [];
	my $extant = {};
	foreach my $gs ( values %$grouping ) {
		map { 
			if( $_ =~ /^(.*)\Q$aclabel\E$/ ) {
				push( @$acwits, $1 ) unless $lacunose->has( $1 );
			} else {
				$extant->{$_} = 1 unless $lacunose->has( $_ );
			}
		} $gs->members;
	}
	my $graph;
	try {
		# contig contains all extant wits and all hypothetical wits
		# needed to make up the groups.
		$graph = $stemma->situation_graph( $extant, $acwits, $aclabel );
	} catch ( Text::Tradition::Error $e ) {
		throw( "Could not extend graph with given extant and a.c. witnesses: "
			. $e->message );
	} catch {
		throw( "Could not extend graph with a.c. witnesses @$acwits" );
	}
	return $graph;
}

=head2 solve_variants( $calcdir, @groups ) 

Looks up the set of groups in the answers provided by the external graph solver 
service and returns a cleaned-up answer, adding the rank IDs back where they belong.

The answer has the form 
  { "variants" => [ array of variant location structures ],
    "variant_count" => total,
    "conflict_count" => number of conflicts detected,
    "genealogical_count" => number of solutions found }
    
=cut

sub solve_variants {
	my( $opts, @groups ) = @_;
	
	# Are we using a local result directory?
	my $dir = $opts->{dir};

	## For each graph/group combo, make a Text::Tradition::Analysis::Result
	## object so that we can send it off for IDP lookup.
	my $variants = [];
	my $genealogical = 0; # counter
	# TODO Optimize for unique graph problems
	my %problems;
	foreach my $graphproblem ( @groups ) {
		# Construct the calc result key and look up its answer
		my $problem = Text::Tradition::Analysis::Result->new(
			graph => $graphproblem->{'graph'},
			setlist => [ values %{$graphproblem->{'grouping'}} ] );
		if( exists $problems{$problem->object_key} ) {
			$problem = $problems{$problem->object_key};
		} else {
			$problems{$problem->object_key} = $problem;
		}
		$graphproblem->{'object'} = $problem;
	}
	
	my %results;
	if( $dir ) {
		my $scope = $dir->new_scope;
		map { $results{$_} = $dir->lookup( $_ ) || $problems{$_} } keys %problems;
	} else {
		# print STDERR "Using solver at " . $opts->{solver_url} . "\n";
		my $json = JSON->new->allow_blessed->convert_blessed->utf8->encode( 
			[ values %problems ] );
		# Send it off and get the result
		# print STDERR "Sending request: " . decode_utf8( $json ) . "\n";
		my $ua = LWP::UserAgent->new();
		my $resp = $ua->post( $opts->{solver_url}, 'Content-Type' => 'application/json', 
							  'Content' => $json );	
		my $answer;	
		if( $resp->is_success ) {
			$answer = decode_json( $resp->content );
			throw( "Unexpected answer from IDP: $answer" ) unless ref( $answer ) eq 'ARRAY';
		} else {
			throw( "IDP solver returned " . $resp->status_line . " / " . $resp->content
				. "; cannot run graph analysis" );
		}
		# One more sanity check
		throw( "Something went wrong with answer symmetricity" )
			unless keys( %problems ) == @$answer;
		# Convert the results
		foreach my $a ( @$answer ) {
			my $r = Text::Tradition::Analysis::Result->new( $a );
			$results{$r->object_key} = $r;
		}
	}
	
	# We now have a single JSON-encoded Result object per problem sent. Fold its
	# answers into our variant info structure.
	foreach my $graphproblem ( @groups ) {
		my $result = $results{$graphproblem->{'object'}->object_key}
			|| $graphproblem->{'object'};
		
		# Initialize the result structure for this graph problem
		my $vstruct;
		if( $result->status eq 'OK' ) {
			$vstruct = { readings => [] };
			push( @$variants, $vstruct );
		} else {
			push( @$variants, _init_unsolved( $graphproblem, $result->status ) );
			next;
		}
				
		# 1. Did the group evaluate as genealogical?
		$vstruct->{genealogical} = $result->is_genealogical;
		$genealogical++ if $result->is_genealogical;
		
		# 2. What are the calculated minimum groupings for each variant loc?
		foreach my $rid ( keys %{$graphproblem->{grouping}} ) {
			my $inputset = $graphproblem->{grouping}->{$rid};
			my $minset = $result->minimum_grouping_for( $inputset );
			push( @{$vstruct->{readings}}, { readingid => $rid, group => $minset } );
		}
		
		# 3. What are the sources and classes calculated for each witness?
		$vstruct->{witcopy_types} = { $result->classes };
		$vstruct->{reading_roots} = {};
		map { $vstruct->{reading_roots}->{$_} = 1 } $result->sources;
		
	}
	
	return { 'variants' => $variants, 
			 'variant_count' => scalar @$variants,
			 'genealogical_count' => $genealogical };
}

sub _init_unsolved {
	my( $graphproblem, $status ) = @_;
	my $vstruct = { 'readings' => [] };
	$vstruct->{'unsolved'} = $status;
	foreach my $rid ( keys %{$graphproblem->{grouping}} ) {
		push( @{$vstruct->{readings}}, { readingid => $rid, 
			group => [ $graphproblem->{grouping}->{$rid}->members ] } );
	}
	return $vstruct;
}

=head2 analyze_location ( $tradition, $graph, $location_hash )

Given the tradition, its stemma graph, and the solution from the graph solver,
work out the rest of the information we want.  For each reading we need missing, 
conflict, reading_parents, independent_occurrence, followed, not_followed,
and follow_unknown.  Alters the location_hash in place.

=cut

sub analyze_location {
	my ( $tradition, $graph, $variant_row, $lacunose ) = @_;
	my $c = $tradition->collation;
	
	if( exists $variant_row->{'unsolved'} ) {
		return;
	}
	my $reading_roots = delete $variant_row->{'reading_roots'};
	my $classinfo = delete $variant_row->{'witcopy_types'};
	
	# Make a hash of all known node memberships, and make the subgraphs.
	my $contig = {};
	my $subgraph = {};
	my $acstr = $c->ac_label;
	my @acwits;
	
	# Note which witnesses positively belong to which group. This information
	# comes ultimately from the IDP solver.
	# Also make a note of the reading's roots.
    foreach my $rdghash ( @{$variant_row->{'readings'}} ) {
    	my $rid = $rdghash->{'readingid'};
    	my @roots;
    	foreach my $wit ( @{$rdghash->{'group'}} ) {
    		$contig->{$wit} = $rid;
    	    if( $wit =~ /^(.*)\Q$acstr\E$/ ) {
    	    	push( @acwits, $1 );
    	    }
    	    if( exists $reading_roots->{$wit} && $reading_roots->{$wit} ) {
    	    	push( @roots, $wit );
    	    }
    	}
		$rdghash->{'independent_occurrence'} = \@roots;
	}
			
	# Now that we have all the node group memberships, calculate followed/
    # non-followed/unknown values for each reading.  Also figure out the
    # reading's evident parent(s).
    foreach my $rdghash ( @{$variant_row->{'readings'}} ) {
        my $rid = $rdghash->{'readingid'};
        my $rdg = $c->reading( $rid );
        my @roots = @{$rdghash->{'independent_occurrence'}};
        my @reversions;
        if( $classinfo ) {
        	@reversions = grep { $classinfo->{$_} eq 'revert' } 
        		$rdghash->{'group'}->members;
        	$rdghash->{'reversions'} = \@reversions;
        }
        my @group = @{$rdghash->{'group'}};
        
        # Start figuring things out.  
        $rdghash->{'followed'} = scalar( @group ) 
        	- ( scalar( @roots ) + scalar( @reversions ) );
        # Find the parent readings, if any, of this reading.
        my $sourceparents = _find_reading_parents( $rid, $graph, $contig, @roots );
		# Work out relationships between readings and their non-followed parent.
		_resolve_parent_relationships( $c, $rid, $rdg, $sourceparents );
		$rdghash->{'source_parents'} = $sourceparents;

		if( @reversions ) {
			my $revparents = _find_reading_parents( $rid, $graph, $contig, @reversions );
			_resolve_parent_relationships( $c, $rid, $rdg, $revparents );
			$rdghash->{'reversion_parents'} = $revparents;
		}
		
		# Find the number of times this reading was altered, and the number of
		# times we're not sure.
		my( %nofollow, %unknownfollow );
		foreach my $wit ( @{$rdghash->{'group'}} ) {
			foreach my $wchild ( $graph->successors( $wit ) ) {
				if( $reading_roots->{$wchild} && $contig->{$wchild}
					&& $contig->{$wchild} ne $rid ) {
					# It definitely changed here.
					$nofollow{$wchild} = 1;
				} elsif( !($contig->{$wchild}) ) {
					# The child is a hypothetical node not definitely in
					# any group. Answer is unknown.
					$unknownfollow{$wchild} = 1;
				} # else it is either in our group, or it is a non-root node in a 
				  # known group and therefore is presumed to have its reading from 
				  # its group, not this link.
			}
		}
		$rdghash->{'not_followed'} = keys %nofollow;
		$rdghash->{'follow_unknown'} = keys %unknownfollow;
		
		# Now say whether this reading represents a conflict.
		unless( $variant_row->{'genealogical'} ) {
			$rdghash->{'is_conflict'} = @roots != 1;
			$rdghash->{'is_reverted'} = scalar @reversions;
		}		
    }
}

sub _find_reading_parents {
	my( $rid, $graph, $contig, @list ) = @_;
	my $parenthash = {};
	foreach my $wit ( @list ) {
		# Look in the stemma graph to find this witness's extant or known-reading
		# immediate ancestor(s), and look up the reading that each ancestor holds.
		my @check = $graph->predecessors( $wit );
		while( @check ) {
			my @next;
			foreach my $wparent( @check ) {
				my $preading = $contig->{$wparent};
				if( $preading && $preading ne $rid ) {
					$parenthash->{$preading} = 1;
				} else {
					push( @next, $graph->predecessors( $wparent ) );
				}
			}
			@check = @next;
		}
	}
	return $parenthash;
}

sub _resolve_parent_relationships {
	my( $c, $rid, $rdg, $rdgparents ) = @_;
	foreach my $p ( keys %$rdgparents ) {
		# Resolve the relationship of the parent to the reading, and
		# save it in our hash.
		my $pobj = $c->reading( $p );
		my $prep = $pobj ? $pobj->id . ' (' . $pobj->text . ')' : $p;
		my $phash = { 'label' => $prep };
		if( $pobj ) {
			# Get the attributes of the parent object while we are here
			$phash->{'text'} = $pobj->text if $pobj;
			if( $pobj && $pobj->does('Text::Tradition::Morphology') ) {
				$phash->{'is_nonsense'} = $pobj->is_nonsense;
				$phash->{'is_ungrammatical'} = $pobj->grammar_invalid;
			}
			# Now look at the relationship
			my $rel = $c->get_relationship( $p, $rid );
			if( $rel && $rel->type eq 'collated' ) {
				$rel = undef;
			}
			if( $rel ) {
				_add_to_hash( $rel, $phash );
			} elsif( $rdg ) {
				# First check for a transposed relationship
				if( $rdg->rank != $pobj->rank ) {
					foreach my $ti ( $rdg->related_readings( 'transposition' ) ) {
						next unless $ti->text eq $rdg->text;
						$rel = $c->get_relationship( $ti, $pobj );
						if( $rel ) {
							_add_to_hash( $rel, $phash, 1 );
							last;
						}
					}
					unless( $rel ) {
						foreach my $ti ( $pobj->related_readings( 'transposition' ) ) {
							next unless $ti->text eq $pobj->text;
							$rel = $c->get_relationship( $ti, $rdg );
							if( $rel ) {
								_add_to_hash( $rel, $phash, 1 );
								last;
							}
						}
					}
				}
				unless( $rel ) {
					# and then check for sheer word similarity.
					my $rtext = $rdg->text;
					my $ptext = $pobj->text;
					if( similar( $rtext, $ptext ) ) {
						# say STDERR "Words $rtext and $ptext judged similar";
						$phash->{relation} = { type => 'wordsimilar' };
					} 
				}
			} else {
				$phash->{relation} = { type => 'deletion' };
			}
		} elsif( $p eq '(omitted)' ) {
			# Check to see if the reading in question is a repetition.
			my @reps = $rdg->related_readings( 'repetition' );
			if( @reps ) {
				$phash->{relation} = { type => 'repetition', 
					annotation => "of reading @reps" };
			} else {
				$phash->{relation} = { type => 'addition' };
			}
		}
		# Save it
		$rdgparents->{$p} = $phash;
	}
}

sub _add_to_hash {
	my( $rel, $phash, $is_transposed ) = @_;
	$phash->{relation} = { type => $rel->type };
	$phash->{relation}->{transposed} = 1 if $is_transposed;
	$phash->{relation}->{annotation} = $rel->annotation
		if $rel->has_annotation;
	# Get all the relevant relationship info.
	foreach my $prop ( qw/ non_independent is_significant / ) {
		$phash->{relation}->{$prop} = $rel->$prop;
	}
	# Figure out if the variant was judged revertible.
	my $is_a = $rel->reading_a eq $phash->{text};
	$phash->{revertible} = $is_a 
		? $rel->a_derivable_from_b : $rel->b_derivable_from_a;
}

=head2 similar( $word1, $word2 )

Use Algorithm::Diff to get a sense of how close the words are to each other.
This will hopefully handle substitutions a bit more nicely than Levenshtein.

=cut

#!/usr/bin/env perl

sub similar {
	my( $word1, $word2 ) = sort { length($a) <=> length($b) } @_;
	my @let1 = split( '', lc( $word1 ) );
	my @let2 = split( '', lc( $word2 ) );
	my $diff = Algorithm::Diff->new( \@let1, \@let2 );
	my $mag = 0;
	while( $diff->Next ) {
		if( $diff->Same ) {
			# Take off points for longer strings
			my $cs = $diff->Range(1) - 2;
			$cs = 0 if $cs < 0;
			$mag -= $cs;
		} elsif( !$diff->Items(1) ) {
			$mag += $diff->Range(2);
		} elsif( !$diff->Items(2) ) {
			$mag += $diff->Range(1);
		} else {
			# Split the difference for substitutions
			my $c1 = $diff->Range(1) || 1;
			my $c2 = $diff->Range(2) || 1;
			my $cd = ( $c1 + $c2 ) / 2;
			$mag += $cd;
		}
	}
	return ( $mag <= length( $word1 ) / 2 );
}

sub _useful_variant {
	my( $rankgroup, $rankgraph, $acstr ) = @_;

	# Sort by group size and return
	my $is_useful = 0;
	foreach my $rdg ( keys %$rankgroup ) {
		my @wits = $rankgroup->{$rdg}->members;
		if( @wits > 1 ) {
			$is_useful++;
		} else {
			$is_useful++ unless( $rankgraph->is_sink_vertex( $wits[0] )
				|| $wits[0] =~ /\Q$acstr\E$/ );
		}
	}
	return $is_useful > 1;
}

=head2 wit_stringify( $groups )

Takes an array of witness groupings and produces a string like
['A','B'] / ['C','D','E'] / ['F']

=cut

sub wit_stringify {
    my $groups = shift;
    my @gst;
    # If we were passed an array of witnesses instead of an array of 
    # groupings, then "group" the witnesses first.
    unless( ref( $groups->[0] ) ) {
        my $mkgrp = [ $groups ];
        $groups = $mkgrp;
    }
    foreach my $g ( @$groups ) {
        push( @gst, '[' . join( ',', map { "'$_'" } @$g ) . ']' );
    }
    return join( ' / ', @gst );
}

1;

sub throw {
	Text::Tradition::Error->throw( 
		'ident' => 'Analysis error',
		'message' => $_[0],
	);
}

=head1 LICENSE

This package is free software and is provided "as is" without express
or implied warranty.  You can redistribute it and/or modify it under
the same terms as Perl itself.

=head1 AUTHOR

Tara L Andrews E<lt>aurum@cpan.orgE<gt>
