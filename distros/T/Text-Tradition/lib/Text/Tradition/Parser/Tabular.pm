package Text::Tradition::Parser::Tabular;

use strict;
use warnings;
use Encode qw/ decode_utf8 /;
use Text::CSV;
use Text::Tradition::Error;
use TryCatch;

=head1 NAME

Text::Tradition::Parser::Tabular

=head1 SYNOPSIS

  use Text::Tradition;
  
  my $t_from_file = Text::Tradition->new( 
    'name' => 'my text',
    'input' => 'Tabular',
    'file' => '/path/to/collation.csv',
    'sep_char' => ','
    );
    
  my $t_from_string = Text::Tradition->new( 
    'name' => 'my text',
    'input' => 'Tabular',
    'string' => $tab_separated_collation,
    'sep_char' => "\t",
    );

=head1 DESCRIPTION

Parser module for Text::Tradition to read an alignment table format, such as 
CSV or Excel.

=head1 METHODS

=head2 B<parse>( $tradition, $option_hash )

Takes an initialized tradition and a set of options; creates the
appropriate nodes and edges on the graph, as well as the appropriate
witness objects.  The $option_hash can contain the following:

=over

=item * file - Name of file which contains the data

=item * string - A string that itself contains the data. One of 'file' or 
'string' is required.

=item * sep_char - For plaintext formats, the field separation character.
Defaults to "\t" (tab-separated); should be "," for comma-separated format.

=item * excel - If the data is in an Excel file, this option should be set
to 'xls' (for pre-2007 Excel format) or 'xlsx' (for Excel XML format.)

=back

The data should comprise a table with witnesses arranged in columns, with
the witness sigla in the first row.  Empty cells are interpreted as
omissions (and thus stemmatologically relevant.) Longer lacunae in the
text, to be disregarded in cladistic analysis, may be represented by
filling the appropriate cells with the tag '#LACUNA#'.

If a witness name ends in the collation's ac_label, it will be treated as
an 'ante-correction' version of the 'main' witness whose sigil it shares.

=begin testing

use Test::More::UTF8;
use Text::Tradition;
binmode STDOUT, ":utf8";
binmode STDERR, ":utf8";
eval { no warnings; binmode $DB::OUT, ":utf8"; };

my $csv = 't/data/florilegium.csv';
my $t = Text::Tradition->new( 
    'name'  => 'inline', 
    'input' => 'Tabular',
    'file'  => $csv,
    'sep_char' => ',',
    );

is( ref( $t ), 'Text::Tradition', "Parsed florilegium CSV file" );

### TODO Check these figures
if( $t ) {
    is( scalar $t->collation->readings, 311, "Collation has all readings" );
    is( scalar $t->collation->paths, 361, "Collation has all paths" );
    is( scalar $t->witnesses, 13, "Collation has all witnesses" );
}

# Check that we have the right witnesses
my %seen_wits;
map { $seen_wits{$_} = 0 } qw/ A B C D E F G H K P Q S T /;
foreach my $wit ( $t->witnesses ) {
	$seen_wits{$wit->sigil} = 1;
}
is( scalar keys %seen_wits, 13, "No extra witnesses were made" );
foreach my $k ( keys %seen_wits ) {
	ok( $seen_wits{$k}, "Witness $k still exists" );
}

# Check that the witnesses have the right texts
foreach my $wit ( $t->witnesses ) {
	my $origtext = join( ' ', @{$wit->text} );
	my $graphtext = $t->collation->path_text( $wit->sigil );
	is( $graphtext, $origtext, "Collation matches original for witness " . $wit->sigil );
}

# Check that the a.c. witnesses have the right text
map { $seen_wits{$_} = 0 } qw/ A B C D F G H K S /;
foreach my $k ( keys %seen_wits ) {
	my $wit = $t->witness( $k );
	if( $seen_wits{$k} ) {
		ok( $wit->is_layered, "Witness $k got marked as layered" );
		ok( $wit->has_layertext, "Witness $k has an a.c. version" );
		my $origtext = join( ' ', @{$wit->layertext} );
		my $acsig = $wit->sigil . $t->collation->ac_label;
		my $graphtext = $t->collation->path_text( $acsig );
		is( $graphtext, $origtext, "Collation matches original a.c. for witness $k" );
	} else {
		ok( !$wit->is_layered, "Witness $k not marked as layered" );
		ok( !$wit->has_layertext, "Witness $k has no a.c. version" );
	}
}	

# Check that we only have collation relationships where we need them
is( scalar $t->collation->relationships, 3, "Redundant collations were removed" );

## Check excel parsing

my $xls = 't/data/armexample.xls';
my $xt = Text::Tradition->new(
	'name'  => 'excel test',
	'input' => 'Tabular',
	'file'  => $xls,
	'excel'   => 'xls'
	);

is( ref( $xt ), 'Text::Tradition', "Parsed test Excel 97-2004 file" );
my %xls_wits;
map { $xls_wits{$_} = 0 } qw/ Wit1 Wit2 Wit3 /;
foreach my $wit ( $xt->witnesses ) {
	$xls_wits{$wit->sigil} = 1;
}
is( scalar keys %xls_wits, 3, "No extra witnesses were made" );
foreach my $k ( keys %xls_wits ) {
	ok( $xls_wits{$k}, "Witness $k still exists" );
}
is( scalar $xt->collation->readings, 11, "Got correct number of test readings" );
is( scalar $xt->collation->paths, 13, "Got correct number of reading paths" );
is( $xt->collation->reading('r5.1')->text, "\x{587}", 
	"Correct decoding of at least one reading" );

my $xlsx = 't/data/armexample.xlsx';
my $xtx = Text::Tradition->new(
	'name'  => 'excel test',
	'input' => 'Tabular',
	'file'  => $xlsx,
	'excel'   => 'xlsx'
	);

is( ref( $xtx ), 'Text::Tradition', "Parsed test Excel 2007+ file" );
my %xlsx_wits;
map { $xlsx_wits{$_} = 0 } qw/ Wit1 Wit3 /;
$xlsx_wits{"\x{531}\x{562}2"} = 0;
foreach my $wit ( $xtx->witnesses ) {
	$xlsx_wits{$wit->sigil} = 1;
}
is( scalar keys %xlsx_wits, 3, "No extra witnesses were made" );
foreach my $k ( keys %xlsx_wits ) {
	ok( $xlsx_wits{$k}, "Witness $k still exists" );
}
is( scalar $xtx->collation->readings, 12, "Got correct number of test readings" );
is( scalar $xtx->collation->paths, 14, "Got correct number of reading paths" );
is( $xtx->collation->reading('r5.1')->text, "\x{587}", 
	"Correct decoding of at least one reading" );

=end testing

=cut

sub parse {
    my( $tradition, $opts ) = @_;
    my $alignment_table = _table_from_input( $opts );
    # Set up the witnesses we find in the first line
    my @witnesses;
    my %ac_wits;  # Track layered witness -> main witness mapping
    my $c = $tradition->collation; # shorthand
    my $aclabel = $c->ac_label;
    foreach my $sigil ( @{$alignment_table->[0]} ) {
        if( $sigil =~ /^(.*)\Q$aclabel\E$/ ) {
        	# Sanitize the sigil name to an XML name
        	$sigil = $1 . '_layered';
            $ac_wits{$sigil} = $1;
        }
        my $wit = $tradition->add_witness( 
        	'sigil' => $sigil, 'sourcetype' => 'collation' );
        $wit->path( [ $c->start ] );
        push( @witnesses, $wit );
        my $aclabel = $c->ac_label;
    }
    
    # Save the original witness text sequences. Have to loop back through
    # the witness columns after we have identified all the a.c. witnesses.
    foreach my $idx ( 0 .. $#{$alignment_table->[0]} ) {
    	my @sequence = map { $_->[$idx] } @{$alignment_table};
    	my $sigil = shift @sequence;
    	my $is_layer = exists( $ac_wits{$sigil} );
    	my $wit = $tradition->witness( $is_layer ? $ac_wits{$sigil} : $sigil );	
    	# Now get rid of gaps and meta-readings like #LACUNA#
    	my @words = grep { $_ && $_ !~ /^\#.*\#$/ } @sequence;
    	$is_layer ? $wit->layertext( \@words ) : $wit->text( \@words );
    }    
    
    my $nocollate = ( scalar( @witnesses ) * scalar @$alignment_table ) > 150000;
    print STDERR "Tradition too big for row collation\n" if $nocollate;
    
    # Now for the next rows, make nodes as necessary, assign their ranks, and 
    # add them to the witness paths.
    foreach my $idx ( 1 .. $#{$alignment_table} ) {
        my $row = $alignment_table->[$idx];
        my $nodes = _make_nodes( $c, $row, $idx, $nocollate );
        foreach my $w ( 0 .. $#{$row} ) {
            # push the appropriate node onto the appropriate witness path
            my $word = $row->[$w];
            if( $word ) {
                my $reading = $nodes->{$word};
                my $wit = $witnesses[$w];
                push( @{$wit->path}, $reading );
            } # else skip it for empty readings.
        }
    }
    
    # Collapse our lacunae into a single node and
    # push the end node onto all paths.
    $c->end->rank( scalar @$alignment_table );
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
    	my $ac_wit = $tradition->witness( $a );
        my $main_wit = $tradition->witness( $ac_wits{$a} );
        next unless $main_wit;
        $main_wit->is_layered(1);
        $main_wit->uncorrected_path( $ac_wit->path );
        $tradition->del_witness( $ac_wit );
    }
    
    # Join up the paths.
    $c->make_witness_paths;
    # Delete our unused lacuna nodes.
	foreach my $rdg ( grep { $_->is_lacuna } $c->readings ) {
		$c->del_reading( $rdg ) unless $c->reading_witnesses( $rdg );
	}
	
	# Do a consistency check.
	foreach my $wit ( $tradition->witnesses ) {
		my $pathtext = $c->path_text( $wit->sigil );
		my $origtext = join( ' ', @{$wit->text} );
		warn "Text differs for witness " . $wit->sigil 
			unless $pathtext eq $origtext;
		if( $wit->is_layered ) {
			$pathtext = $c->path_text( $wit->sigil.$c->ac_label );
			$origtext = join( ' ', @{$wit->layertext} );
			warn "Ante-corr text differs for witness " . $wit->sigil
				unless $pathtext eq $origtext;
		} else {
			warn "Text " . $wit->sigil . " has a layered text but is not marked as layered"
				if $wit->has_layertext;
		}
	}
	
	# Note that our ranks and common readings are set.
	$c->_graphcalc_done(1);
	_add_collations( $c ) unless $nocollate;
}

sub _table_from_input {
	my $opts = shift;
	my $alignment_table = [];
    if( $opts->{'excel'} ) {
    	my $sheet;
    	my $need_decode;
		unless( exists $opts->{'file'} ) {
			throw( "Must pass the filename for Excel parsing" );
		}
    	if( $opts->{'excel'} eq 'xls' ) {
			try {
				require Spreadsheet::ParseExcel;
			} catch {
				throw( "Need module Spreadsheet::ParseExcel to parse .xls files" );
			}
			my $parser = Spreadsheet::ParseExcel->new();
			my $workbook = $parser->parse( $opts->{'file'} );
			unless( defined $workbook && defined $workbook->worksheet(0) ) {
				throw( "Failed to parse file " . $opts->{'file'} . ": " . $parser->error() );
			}
			$sheet = $workbook->worksheet(0);
		} elsif( $opts->{'excel'} eq 'xlsx' ) {
			try {
				require Spreadsheet::XLSX;
			} catch {
				throw( "Need module Spreadsheet::XLSX to parse .xlsx files" );
			}
			$need_decode = 1;
			my $workbook;
			try {
				$workbook = Spreadsheet::XLSX->new( $opts->{'file'} );
			} catch {
				throw( "Failed to parse file " . $opts->{'file'} );
			}
			$sheet = $workbook->worksheet(0);
		} else {
			throw( "Unrecognized Excel variant" . $opts->{'excel'} );
		}
		$alignment_table = _alignment_from_worksheet( $sheet, $need_decode );
    } else {
    	# Assume it is a comma-, tab-, or whatever-separated format.
		my $csv_options = { 'binary' => 1 };
		$csv_options->{'sep_char'} = $opts->{'sep_char'} || "\t";
		if( $csv_options->{'sep_char'} eq "\t" ) {
			# If it is really tab separated, nothing is an escape char.
			$csv_options->{'quote_char'} = undef;
			$csv_options->{'escape_char'} = undef;
		}
		my $csv = Text::CSV->new( $csv_options );
		
		if( exists $opts->{'string' } ) {
			my @lines = split( "\n", $opts->{'string'} );
			foreach my $l ( @lines ) {
				my $status = $csv->parse( $l );
				if( $status ) {
					push( @$alignment_table, [ $csv->fields ] );
				} else {
					throw( "Could not parse line $l: " . $csv->error_input );
				}
			}
		} elsif( exists $opts->{'file'} ) {
			open( my $fh, $opts->{'file'} ) 
				or warn "Could not open input file " . $opts->{'file'};
			binmode( $fh, ':utf8' );
			while( my $row = $csv->getline( $fh ) ) {
				push( @$alignment_table, $row );
			}
			close $fh;
		} else {
			throw( "Could not find string or file option to parse" );
		}
	}
	return $alignment_table;
}
sub _alignment_from_worksheet {
	my( $sheet, $decode ) = @_;
	my $alignment_table = [];
	
	my( $rmin, $rmax ) = $sheet->row_range();
	my( $cmin, $cmax ) = $sheet->col_range();
	unless( $cmax && $rmax ) {
		throw( "Found no rows or no columns in first worksheet" );
	}
	# Populate the alignment table. We only want columns that have
	# a sigil in row zero.
	my %sigcols = ();
	push( @$alignment_table, [] );
	foreach my $col ( $cmin .. $cmax ) {
		my $cell = $sheet->get_cell( $rmin, $col );
		my $cellval;
		if( $cell ) {
			$cellval = $decode ? decode_utf8( $cell->value ) : $cell->value;
		}
		if( $cellval ) {
			$sigcols{$col} = 1;
			push( @{$alignment_table->[0]}, $cellval );
		}
	}
	# Now go through the rest of the rows and pick up the columns
	# that were headed by a sigil.
	foreach my $row ( $rmin+1 .. $rmax ) {
		my @tablerow;
		foreach my $col ( $cmin .. $cmax ) {
			next unless $sigcols{$col};
			my $cell = $sheet->get_cell( $row, $col );
			my $cellval;
			if( $cell ) {
				$cellval = $decode ? decode_utf8( $cell->value ) : $cell->value;
			}
			push( @tablerow, $cellval );
		}
		push( @$alignment_table, \@tablerow );
	}
	return $alignment_table;
}

sub _make_nodes {
    my( $collation, $row, $index, $nocollate ) = @_;
    my %unique;
    my $commonctr = 0; # Holds the number of unique readings + gaps, ex. lacunae.
    foreach my $w ( @$row ) {
        $unique{$w} = 1 if $w;
        $commonctr +=1 unless ( $w && $w eq '#LACUNA#' );
    }
    my $ctr = 1;
    foreach my $w ( keys %unique ) {
    	my $rargs = {
    		'id' => "r$index.$ctr",
    		'rank' => $index,
    		'text' => $w,
    		};
    	if( $w eq '#LACUNA#' ) {
    		$rargs->{'is_lacuna'} = 1;
    	} elsif( $commonctr == 1 ) {
    		$rargs->{'is_common'} = 1;
    	}
        my $r = $collation->add_reading( $rargs );
        $unique{$w} = $r;
        $ctr++;
    }
    return \%unique;
}

sub _add_collations {
	my( $collation ) = shift;
	# For each reading that needs to be held in place, add a 'collated' 
	# relationship to whatever anchor we can find. An anchor is a reading
	# that would occupy its rank by virtue of being subsequent to a
	# reading at $rank-1.
	my @collate_pairs;
	foreach my $r ( 1 .. $collation->end->rank - 1 ) {
		my $anchor;
		my @need_weak;
		my @here = grep { !$_->is_meta } $collation->readings_at_rank( $r );
		next unless @here > 1;
		foreach my $rdg ( @here ) {
			my $ip = 0;
			foreach my $pred ( $rdg->predecessors ) {
				if( $pred->rank == $r - 1 ) {
					$ip = 1;
					$anchor = $rdg unless( $anchor );
					last;
				}
			}
			push( @need_weak, $rdg ) unless $ip;
		}
		$anchor
			? map { push( @collate_pairs, [ $r, $anchor, $_ ] ) } @need_weak
			: print STDERR "No anchor found at $r\n";
	}
	foreach my $p ( @collate_pairs ) {
		my $r = shift @$p;
		$collation->add_relationship( @$p, 
			{ 'type' => 'collated', 
			  'annotation' => "Collated together for rank $r" } )
			unless $collation->get_relationship( @$p )
	}
}

sub throw {
	Text::Tradition::Error->throw( 
		'ident' => 'Parser::Tabular error',
		'message' => $_[0],
		);
}

1;

=head1 LICENSE

This package is free software and is provided "as is" without express
or implied warranty.  You can redistribute it and/or modify it under
the same terms as Perl itself.

=head1 AUTHOR

Tara L Andrews E<lt>aurum@cpan.orgE<gt>
