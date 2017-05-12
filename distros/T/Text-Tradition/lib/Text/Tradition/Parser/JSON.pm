package Text::Tradition::Parser::JSON;

use strict;
use warnings;
use JSON qw/ from_json /;

=head1 NAME

Text::Tradition::Parser::JSON

=head1 SYNOPSIS

  use Text::Tradition;
  
  my $tradition = Text::Tradition->new( 
    'name' => 'my text',
    'input' => 'JSON',
    'string' => $json_encoded_utf8,
    );

=head1 DESCRIPTION

Parser module for Text::Tradition to read a JSON alignment table format such
as that produced by CollateX.

=head1 METHODS

=head2 B<parse>( $tradition, $option_hash )

Takes an initialized tradition and a set of options; creates the
appropriate nodes and edges on the graph, as well as the appropriate
witness objects.  The $option_hash must contain either a 'file' or a
'string' argument with the JSON structure to be parsed.

The structure of the JSON is thus:

 { alignment => [ { witness => "SIGIL", 
                    tokens => [ { t => "TEXT" }, ... ] },
                  { witness => "SIG2", 
                    tokens => [ { t => "TEXT" }, ... ] },
                    ... ],
 };


Longer lacunae in the text, to be disregarded in cladistic analysis, may be 
represented with the meta-reading '#LACUNA#'.  Multiple lacuna tags in sequence
are collapsed into a single multi-reading lacuna.

If a witness name ends in the collation's ac_label, it will be treated as
an extra layer of the 'main' witness whose sigil it shares.

=begin testing

use Text::Tradition;
binmode STDOUT, ":utf8";
binmode STDERR, ":utf8";
eval { no warnings; binmode $DB::OUT, ":utf8"; };

use_ok( 'Text::Tradition::Parser::JSON' );

open( JSFILE, 't/data/cx16.json' );
binmode JSFILE, ':utf8';
my @lines = <JSFILE>;
close JSFILE;

my $t = Text::Tradition->new(
    'name' => 'json',
    'input' => 'JSON',
    'string' => join( '', @lines ),
);

is( ref( $t ), 'Text::Tradition', "Parsed a JSON alignment" );
if( $t ) {
    is( scalar $t->collation->readings, 26, "Collation has all readings" );
    is( scalar $t->collation->paths, 32, "Collation has all paths" );
    is( scalar $t->witnesses, 2, "Collation has all witnesses" );
}

my %seen_wits;
map { $seen_wits{$_} = 0 } qw/ A C /;
# Check that we have the right witnesses
foreach my $wit ( $t->witnesses ) {
	$seen_wits{$wit->sigil} = 1;
}
is( scalar keys %seen_wits, 2, "No extra witnesses were made" );
foreach my $k ( keys %seen_wits ) {
	ok( $seen_wits{$k}, "Witness $k still exists" );
}
# Check that witness A is layered
ok( $t->witness('A')->is_layered, "Witness A has its pre-correction layer" );

# Check that the witnesses have the right texts
foreach my $wit ( $t->witnesses ) {
	my $origtext = join( ' ', @{$wit->text} );
	my $graphtext = $t->collation->path_text( $wit->sigil );
	is( $graphtext, $origtext, "Collation matches original for witness " . $wit->sigil );
}

# Check that the ranks are right
is( $t->collation->end->rank, 19, "Ending node has the correct rank" );
foreach my $rdg ( $t->collation->readings ) {
	next if $rdg->is_meta;
	my $idrank = $rdg->id;
	$idrank =~ s/^r(\d+)\..*$/$1/;
	is( $idrank, $rdg->rank, "Reading $rdg has the correct rank" );
}


=end testing

=cut

sub parse {
	my( $tradition, $opts ) = @_;
	my $c = $tradition->collation;
	
	my $table = from_json( $opts->{'string'} );
	
	# Create the witnesses
	my @witnesses; # Keep the ordered list of our witnesses
    my %ac_wits;  # Track these for later removal
    foreach my $sigil ( map { $_->{'witness'} } @{$table->{'alignment'}} ) {
    	# Get the appropriate sigil.
        my $aclabel = $c->ac_label;
        if( $sigil =~ /^(.*)\Q$aclabel\E$/ ) {
        	my $real_sig = $1;
        	my $layer_sig = $real_sig . '_ac';
            $ac_wits{$sigil} = { layer => $layer_sig, base => $real_sig };
            # use XML Name version of this, since ' (a.c.)' will break XML validation
        	$sigil = $layer_sig;
        }
    	my $wit;
    	if( $tradition->has_witness( $sigil ) ) {
    		$wit = $tradition->witness( $sigil );
    		$wit->is_collated( 1 );
    	} else {
			$wit = $tradition->add_witness( 
				'sigil' => $sigil, 'sourcetype' => 'collation' );
		}
        $wit->path( [ $c->start ] );
        push( @witnesses, $wit );
    }
    
    # Save the original witness text for consistency checking. We do this
    # in a separate loop to make sure we have all base witnesses defined,
    # and to make sure that our munging and comparing later doesn't affect
    # the original text.
    foreach my $intext ( @{$table->{'alignment'}} ) {
    	my $rs = $intext->{'witness'};
    	my $is_layer = exists $ac_wits{$rs};
    	my $wit = $tradition->witness( $is_layer ? $ac_wits{$rs}->{base} : $rs );
    	my @tokens = grep { $_ && $_->{'t'} !~ /^\#.*\#$/ } @{$intext->{'tokens'}};
    	my @words = map { _restore_punct( $_ ) } @tokens;
    	$is_layer ? $wit->layertext( \@words ) : $wit->text( \@words );
	}

	# Create the readings in each row
    my $length = exists $table->{'length'}
    	? $table->{'length'}
    	: scalar @{$table->{'alignment'}->[0]->{'tokens'}};
    
    foreach my $idx ( 0 .. $length - 1 ) {
    	my @tokens = map { $_->{'tokens'}->[$idx] } @{$table->{'alignment'}};
        my @readings = make_nodes( $c, $idx, @tokens );
        foreach my $w ( 0 .. $#readings ) {
            # push the appropriate node onto the appropriate witness path
            my $rdg = $readings[$w];
            if( $rdg ) {
                my $wit = $witnesses[$w];
                push( @{$wit->path}, $rdg );
            } # else skip it for empty readings.
        }
    }

    # Collapse our lacunae into a single node and
    # push the end node onto all paths.
    $c->end->rank( $length+1 );
    foreach my $wit ( @witnesses ) {
        my $p = $wit->path;
        my $last_rdg = shift @$p;
        my $new_p = [ $last_rdg ];
        foreach my $rdg ( @$p ) {
        	# Omit the reading if we are in a lacuna already.
        	next if $rdg->is_lacuna && $last_rdg->is_lacuna;
			# Save the reading otherwise.
			push( @$new_p, $rdg );
			$last_rdg = $rdg;
        }
        push( @$new_p, $c->end );
        $wit->path( $new_p );
    }
    
    # Fold any a.c. witnesses into their main witness objects, and
    # delete the independent a.c. versions.
    foreach my $a ( keys %ac_wits ) {
    	my $ac_wit = $tradition->witness( $ac_wits{$a}->{layer} );
        my $main_wit = $tradition->witness( $ac_wits{$a}->{base} );
        next unless $main_wit;
        $main_wit->uncorrected_path( $ac_wit->path );
        $tradition->del_witness( $ac_wit );
    }
    
    # Join up the paths.
    $c->make_witness_paths;
    # Delete our unused lacuna nodes.
	foreach my $rdg ( grep { $_->is_lacuna } $c->readings ) {
		$c->del_reading( $rdg ) unless $c->reading_witnesses( $rdg );
	}
	
	# Note that our ranks and common readings are set.
	$c->_graphcalc_done(1);
}

=head2 make_nodes( $collation, $index, @tokenlist )

Create readings from the unique tokens in @tokenlist, and set their rank to
$index.  Returns an array of readings of the same size as the original @tokenlist.

=cut

sub make_nodes {
	my( $c, $idx, @tokens ) = @_;
	my %unique;
	my @readings;
	my $commonctr = 0;
	foreach my $j ( 0 .. $#tokens ) {
		if( $tokens[$j] ) {
			my $word = _restore_punct( $tokens[$j] );
			my $rdg;
			if( exists( $unique{$word} ) ) {
				$rdg = $unique{$word};
			} else {
				my %args = ( 'id' => 'r' . join( '.', $idx+1, $j+1 ),
					'rank' => $idx+1,
					'text' => $word,
					'collation' => $c );
				if( $word eq '#LACUNA#' ) {
					$args{'is_lacuna'} = 1 
				} else {
					$commonctr++;
				}
				$rdg = Text::Tradition::Collation::Reading->new( %args );
				$unique{$word} = $rdg;
			}
			push( @readings, $rdg );
		} else {
			$commonctr++;
			push( @readings, undef );
		}
	}
	if( $commonctr == 1 ) {
		# Whichever reading isn't a lacuna is a common node.
		foreach my $rdg ( values %unique ) {
			next if $rdg->is_lacuna;
			$rdg->is_common( 1 );
		}
	}
	map { $c->add_reading( $_ ) } values( %unique );
	return @readings;
}

# Utility function for parsing JSON from nCritic
sub _restore_punct {
	my( $token ) = @_;
	my $word = $token->{'t'};
	return $word unless exists $token->{'punctuation'};
	foreach my $p ( sort { $a->{pos} <=> $b->{pos} } @{$token->{'punctuation'}} ) {
		substr( $word, $p->{pos}, 0, $p->{char} );
	}
	return $word;
}	

1;

=head1 LICENSE

This package is free software and is provided "as is" without express
or implied warranty.  You can redistribute it and/or modify it under
the same terms as Perl itself.

=head1 AUTHOR

Tara L Andrews E<lt>aurum@cpan.orgE<gt>
