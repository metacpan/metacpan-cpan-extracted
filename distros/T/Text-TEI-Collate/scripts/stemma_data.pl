#!/usr/bin/perl -w

use strict;
use utf8;
use lib 'lib';
use Data::Dumper;
use Getopt::Long;
use Storable;
use Text::TEI::Collate;
use XML::LibXML;

eval { no warnings; binmode $DB::OUT, ":utf8"; };

my( $infile, $start_id, $end_id, $strict, $nexclude, $loose, $storable, $language );
GetOptions( 
    'teifile=s' => \$infile,
    'start=i' => \$start_id,
    'end=i' => \$end_id,
    'strict' => \$strict,
    'nexclude' => \$nexclude,
    'loose' => \$loose,
    'store=s' => \$storable,
    'l|language=s' => \$language,
    );

my( $input_doc, $xpc );
my @results;
if( $infile ) {
    my $parser = XML::LibXML->new();
    $input_doc = $parser->parse_file( $infile );
    my $ns_uri = 'http://www.tei-c.org/ns/1.0';
    $xpc = XML::LibXML::XPathContext->new( $input_doc );
    $xpc->registerNs( 'tei', $ns_uri );
} elsif ( $storable ) {
    no warnings 'once'; 
    $Storable::Eval = 1;
    my $savedref = retrieve( $storable );
    @results = @$savedref;
} else {
    my $aligner = Text::TEI::Collate->new( 'fuzziness' => 50,
					   'debuglevel' => 0,
					   'language' => $language,
	);
    @results = $aligner->align( @ARGV );
}

# Hold the 'nucleotide' sequence for each manuscript.
my %sequences;

# Get the list of sigla.
my @witnesses;
if( $infile ) {
    @witnesses = map { $_->getAttribute( 'xml:id' ) } $xpc->findnodes( '//tei:listWit/tei:witness' );
} else {
    @witnesses = map { $_->sigil } @results;
}


# For each row in the result table, assign a value A-(whatever) for
# each word variation.  

my( $started, $ended );
my $length = 0;
if( $infile ) {
    # Use the XML app.
    foreach my $app ( $xpc->findnodes( '//tei:app' ) ) {
	my $id = $app->getAttribute( 'xml:id' );
	# print STDERR "Processing app $id\n";
	print STDERR "App without ID!\n" unless $id;
	# Bracket between start and end
	if( $start_id ) {
	    $started = 1 if $id eq "App$start_id";
	    next unless $started;
	}
	if( $end_id ) {
	    next if $ended;
	    $ended = 1 if $id eq "App$end_id";
	}
	
	# Get all the words from this app.
	my %buckets;
	foreach my $rdg ( $xpc->findnodes( './/tei:rdg | .//tei:lem', $app ) ) {
	    # Get the words.
	    my @words = $xpc->findnodes( './/tei:w', $rdg );
	    # String the words together, minus any punctuation.
	    my @strings;
	    foreach my $w ( @words ) {
		push( @strings, $xpc->findvalue( 'child::text()', $w ) );
	    }
	    my $str = join( ' ', @strings );

	    unless( $loose ) {
		my $orig_str = $str;
		# TODO use the data in Lang::Armenian for this
		# $str = am_downcase( $str );
		# $str = $spell{$str} if( !$loose && exists $spell{$str} );
		# $str = $orth{$str} if( exists $orth{$str} );
		if( !$loose && $rdg->hasAttribute( 'type' ) ) {
		    print STDERR "Reading $str in app $id is a variant of nothing\n"
			if $rdg->getAttribute( 'type' ) =~ /variant/
			&& $orig_str eq $str;
		}
	    }
	    
	    if( $rdg->hasAttribute( 'wit' ) ) {
		add_hash_entry( \%buckets, $str, get_wit_list( $rdg->getAttribute( 'wit' ) ) );
	    } # else there's no point is there?
	}
	buckets_to_sequence( \%buckets, $id );
    }
} else {
    # Use the results array.
    foreach my $idx ( 0 .. $#{$results[0]->words} ) {
	next if $start_id && $start_id > $idx;
	next if $end_id && $idx > $end_id;
	my @words = map { $_->words->[$idx] } @results;
	my %buckets;
	my %unseen_sigla;
	@unseen_sigla{ @witnesses } = ( 1 ) x scalar @witnesses;
	foreach my $word ( @words ) {
	    unless( $word->is_empty ) {
		my $str = $word->comparison_form;
		add_hash_entry( \%buckets, $str, $word->ms_sigil );
		delete $unseen_sigla{ $word->ms_sigil };
	    }
	}
	foreach my $sigil ( keys %unseen_sigla ) {
	    add_hash_entry( \%buckets, '', $sigil );
	}
	buckets_to_sequence( \%buckets, $idx );
    }
}
	    

# Now we have our markers; output in the bizarre file format required.
printf( "\t%d\t%d\n", scalar @witnesses, $length );
foreach( keys %sequences ) {
    unless( length( $sequences{$_} ) == $length ) {
	print STDERR "Sequence for $_ is " . length( $sequences{$_} ) .
	    " characters long instead of $length!\n";
    }
    next if ( $sequences{$_} =~ /^O+$/ );
    printf( "%-9s %s\n", "mss$_", $sequences{$_} );
}
print STDERR "Done.\n";   

sub buckets_to_sequence {
    my( $buckets, $pos ) = @_;

    if( $nexclude ) {
	# Look at each word bucket; if one word is the same as another
	# apart from the definite article, combine them.
	my @words = keys %$buckets;
	foreach my $w ( @words ) {
	    my $tmp = $w;
	    $tmp =~ s/\x{576}$//;
	    if( ( $tmp ne $w )
		&& ( grep /^$tmp$/, @words ) ) {
		print STDERR "Merging $w and $tmp\n";
		add_hash_entry( $buckets, $tmp, @{$buckets->{$w}} );
		delete $buckets->{$w};
	    }
	}
    }
    if( $strict ) {
	# Unless there are at least two sigla in each of at least two
	# buckets, skip it.
	my $useful_variants = 0;
	foreach my $w ( keys %$buckets ) {
	    $useful_variants++ if scalar @{$buckets->{$w}} > 1;
	}
	return unless $useful_variants > 1;
    }
    $length++;

    my %seen_wits;
    @seen_wits{ @witnesses } = ( 0 ) x scalar @witnesses;
    my @debug_pos = ( );
    my $mark_ctr = 65; # Ascii A.
    foreach my $word ( keys %$buckets ) {
	my @sigla = @{$buckets->{$word}};
	if( $mark_ctr > 73 ) {
	    print STDERR "Warning: too many variants at $pos.\n";
	    print STDERR join( ' / ', keys %$buckets ) . "\n";
	}
	if( grep( /^$pos$/, @debug_pos ) ) {
	    print STDERR join( ' / ', keys %$buckets ) . "\n";
	}
	my $marker = $word ? chr( $mark_ctr ) : 'O';
	foreach my $sigil ( @sigla ) {
	    $seen_wits{$sigil}++;
	    $sequences{$sigil} .= $marker;
	    print STDERR "Warning at $pos\n" unless( $sigil );

	}
	$mark_ctr++;
    }
    # print STDERR "$id: " . ( $mark_ctr-65 ) . " variants\n";
    foreach my $sigil ( @witnesses ) {
	$sequences{$sigil} .= '?'
	    if $seen_wits{$sigil} == 0;
	print STDERR "Double sigil $sigil at app $pos\n"
	    if $seen_wits{$sigil} > 1;
    }
}

sub get_wit_list {
    my $str = shift;
    return map { $_ =~ s/^\#//; $_ } split( /\s+/, $str );
}

##### general utility functions

# Adds the entry to a list which is the value of the given hash key.

sub add_hash_entry {
    my( $hash, $key, @entry ) = @_;
    if( exists( $hash->{$key} ) ) {
	push( @{$hash->{$key}}, @entry );
    } else {
	$hash->{$key} = [ @entry ];
    }
}


# Takes a bunch of key/value pairs and
# returns a bunch of value/list-of-keys pairs.
# Second argument holds plaintext reference keys in case the 
# original values are arrayrefs.
sub invert_hash {
    my ( $hash, $plaintext_keys ) = @_;
    my %new_hash;
    foreach my $key ( keys %$hash ) {
	my $val = $hash->{$key};
	my $valkey = $val;
	if( $plaintext_keys 
	    && ref( $val ) ) {
	    $valkey = $plaintext_keys->{ scalar( $val ) };
	    warn( "No plaintext value given for $val" ) unless $valkey;
	}
	if( exists ( $new_hash{$valkey} ) ) {
	    push( @{$new_hash{$valkey}}, $key );
	} else {
	    $new_hash{$valkey} = [ $key ];
	}
    }
    return %new_hash;
}
	
