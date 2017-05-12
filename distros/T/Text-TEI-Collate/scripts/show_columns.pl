#!/usr/bin/perl -w

use strict;
use lib 'lib';
use Data::Dumper;
use Getopt::Long;
use Storable qw( store_fd retrieve );
#use Text::WagnerFischer::Armenian;
use Text::TEI::Collate;
#use Words::Armenian;

binmode STDOUT, ":utf8";
binmode STDERR, ":utf8";
eval { no warnings; binmode $DB::OUT, ":utf8"; };

# Default option values
my( $col_width, $fuzziness, $language ) = ( 25, 50, 'Default' );
my( $CSV, $storable, $outfile, $infile, $text, $cx, $json, $debug, %argspec );

GetOptions( 'csv' => \$CSV,
	    'width=i' => \$col_width,
	    'storable' => \$storable,
	    'outfile=s' => \$outfile,
	    'store=s' => \$infile,
	    'text' => \$text,
	    'cx' => \$cx,
	    'json' => \$json,
	    'debug:i' => \$debug,
	    'argspec=s' => \%argspec,
	    'fuzziness=i' => \$fuzziness,
	    'l|language=s' => \$language,
    );

## Option checking
if( defined $debug ) {
    # If it's defined but false, no level was passed.  Use default 1.
    $debug = 1 unless $debug;
} else {
    $debug = 0;
}
if( $storable && !$outfile ) {
    warn( "Cannot output Storable data without an output file target" );
    exit;
}
if( $storable && $infile ) {
    warn( "You probably don't want to store a Storable.  Try again." );
    exit;
}
if( $outfile ) {
    open( OUT, ">$outfile" ) or die "Cannot open $outfile for writing";
}
my $fuzzy_hash = { 'short' => 6, 'shortval' => 50 };
$fuzzy_hash->{'val'} = $fuzziness;

unless( keys %argspec ) {
    %argspec = ( 'word' => 'shorter', 'sliding' => 0, 'inclusive' => 0 );
}

## Get busy. 
my( @files ) = @ARGV;
if( $json ) {  # The 'file' is the JSON string.
    my @lines;
    while( <> ) {
	push( @lines, $_ );
    }
    @files = ( join ( '', @lines ) );
}

my $aligner = Text::TEI::Collate->new( 'fuzziness_sub' => \&fuzzy_match,
				       'debug' => $debug,
				       'language' => $language,
    );


my @mss;
if( $infile ) {
    no warnings 'once'; 
    $Storable::Eval = 1;
    my $savedref = retrieve( $infile );
    @mss = @$savedref;
    @files = map { $_->sigil } @mss;
} else {
    foreach ( @files ) {
	push( @mss, $aligner->read_source( $_ ) );
    }
    $aligner->align( @mss );
    if( $cx || $json ) {
	# We didn't have filenames to display; use sigla instead.
	@files = map { $_->sigil } @mss;
    }
}

if( $storable ) {
    # Store the array.
    no warnings 'once';
    $Storable::Deparse = 1;
    store_fd( \@mss, \*OUT );
    exit;
} 

# Print the array.
print_fnames() if $CSV;
foreach my $i ( 0 .. $#{$mss[0]->words } ) {
    my $output_str;
    if( $CSV ) {
	$output_str = join( ',', map { '"' . $_->words->[$i]->printable . '"' } @mss ) . "\n";
    } else {
	my $format = '%-' . $col_width . "s";
	$output_str = sprintf( "%-4d:", $i ) . join( '| ', map { sprintf( $format, $_->words->[$i]->printable ) } @mss ) . "\n";
    }
    # print_fnames( $i ) unless ( $CSV || $i % 100 );
    print $output_str;
}


print "Done.\n";


sub open_file {
    my( $file ) = shift;
    local *FH;
    open( FH, "<:utf8", $file ) or die "Could not open file $file\n";
    return *FH;
}

sub print_fnames {
    print "\n\tLine $_[0]\n" if $_[0];
    my @titles = @files;
    if( $cx ) {
	@titles = ( 0 .. $#files );
    } elsif( $json ) {
	@titles = map { $_->sigil } @mss;
    }
    if( $CSV ) {
	print join( ',', @titles ) . "\n";
    } else {
	print join( '| ', map { sprintf( "%-25s", $_ ) } @titles ) . "\n";
    }
}

sub fuzzy_match {
    my ( $str1, $str2, $dist ) = @_;
    my $ref_str;
    if( $argspec{'word'} eq 'first' ) {
	$ref_str = $str1;
    } elsif( $argspec{'word'} eq 'longer' ) {
	 $ref_str = length( $str1 ) > length( $str2 ) ? $str1 : $str2;
    } elsif( $argspec{'word'} eq 'shorter' ) {
	 $ref_str = length( $str1 ) < length( $str2 ) ? $str1 : $str2;
    }
    
    my $fuzz = $fuzzy_hash->{'val'};
    if( length( $ref_str ) <= $fuzzy_hash->{'short'} 
	&& $argspec{'sliding'} ) {
	$fuzz = $fuzzy_hash->{'shortval'};
    }
    if( $argspec{'inclusive'} ) {
	return( $dist <= ( length( $ref_str ) * $fuzz / 100 ) );
    } else {
	return( $dist < ( length( $ref_str ) * $fuzz / 100 ) );
    }
}

sub normalize_unicode {
    my $word = shift;
    my @normalized;
    my @letters = split( '', lc( $word ) );
    foreach my $l ( @letters ) {
	my $d = chr( ord( NFKD( $l ) ) );
	push( @normalized, $d );
    }
    return join( '', @normalized );
}
