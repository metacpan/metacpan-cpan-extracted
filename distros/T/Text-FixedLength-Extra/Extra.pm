package Text::FixedLength::Extra;


require 5.005_62;
use strict;
use warnings;

use Text::FixedLength;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Text::FixedLength::Extra ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(fixedlength
	
);
our $VERSION = '1.1';

our $debug = 0;


# Preloaded methods go here.
# ----------------------------------------------------------------------------
# Subroutine: getFixed - given a string, delimiter, and format return a string
# ----------------------------------------------------------------------------
sub Text::FixedLength::getFixed {
  my $s      = shift || die 'getFixed: need a string';
  my $delim  = shift || die 'getFixed: need a delimiter';
  my $format = shift || die 'getFixed: need a format';
  my $out    = '';
  die "getFixed: no delimiter in $s" unless $s =~ /$delim/;

  # -- get each piece
  my @records = split /$delim/, $s;

  # -- setup the sprintf format (e.g. "%-8s%3s...")
  my $count = 0;
  foreach my $format ( @$format ) {
    sub assign_just {
      $_[0] eq 'L' ? '-' : '';
    }
    my $just = assign_just $Text::FixedLength::defaultJustification;
    my ($width,$d_or_f,$zero_fill,$decimal_places,$numfmt);
    

    my $int_re = '([*])?(D)';
    my $flt_re = '([*])?(F)(\d+)?';
    my $numfmt_re = "($int_re|$flt_re)";
    my $format_re =<<RE;
    (\\d+)       # width
    (R|L)?       # optional justification
    (            # optional numerical formatting
     $numfmt_re
    )?
RE

  # ----
  
  if ($format =~ /$format_re/x) {
    
    $width=$1; 
    if ($2) { $just = assign_just $2 }

    warn "$3 =~ /$numfmt_re/" if $debug;
    my $text = $3;
    if ($text =~ /$int_re/i or $text =~ /$flt_re/) {
      warn "RE:$1.$2.$3.$4" if $debug;
      $zero_fill = '0' if ($1);
      $d_or_f = lc $2;
      warn "d_of_f: $d_or_f" if $debug;
      $d_or_f = ".$3$d_or_f" if ($d_or_f eq 'f');
      
      my $new_out = "%${just}${zero_fill}${width}${d_or_f}";
      warn "num sprintf :$new_out" if $debug;
      $out .= $new_out;

    } else {
      my $new_out = "%${just}${width}s";
      warn "str sprintf: $new_out" if $debug;
      $out .= $new_out;
    }

  } else {
    die "$format did not match $format_re";
  }
    # -- Crop the record if it is longer than it is meant to be
    if ($Text::FixedLength::cropRecords) {
        $records[$count] = substr($records[$count], 0, $width) 
          if length $records[$count] > $width;
      }
    $count++;
  }
  warn "sprintf stmt: $out" if $debug;
  return sprintf $out, @records;
}


sub fixedlength {
  my ($format_href, $data_href, $field_order_ref) = @_;

  my $delim = "\t";
  my (@format,@data);
  
  for (@$field_order_ref) {
    push @format, $format_href->{$_};
    push @data,   $data_href->{$_};
  }

  my $data = join $delim, @data;

  [ delim2fixed([$data], $delim, \@format) ] -> [0];

}
1;
__END__
# Below is stub documentation for your module. You better edit it!

=head1 NAME

Text::FixedLength::Extra - various niceties for Text::FixedLength lovers.

=head1 SYNOPSIS

  use Text::FixedLength::Extra; #automatically uses Text::FixedLength

  my %format        =   (record_type => '3L', total_orders => '5R');
  my @field_order   = qw(record_type total_orders);
  my %data          =   (record_type => 'F',  total_orders => 300);

  # Bonus One: Simplified API to Text::FixedLength !
  $x = fixedlength(\%format, \%data, \@field_order);

  # Bonus Two: Zero filling and processing of integers and floating points ! 
  my %format        =   (record_type => '3R', total_orders => '10R*F3');
  my @field_order   = qw(record_type total_orders);
  my %data          =   (record_type => 'F',  total_orders => 300.52894);


  $x = fixedlength(\%format, \%data, \@field_order);



=head1 DESCRIPTION

Right now, Text::FixedLength::Extra does two things for those who like using 
Text::FixedLength - simpler API and extended number processing.

=head2  Simplified API to Text::FixedLength

A function, fixedlength() has been created which should make it easier to
create fixed-width reports. Here is a sample of setting up data for use 
with fixedlength:

  # the fields we will format and their formatting instructions
  my %format = 
    (
     record_type => '3',
     upc => '13L',
     lcc_label => '5R',
     lcc_catalog => '7R',
     lcc_config => '1',
     artist_name => '30L',
     item_title => '30L',
     quoted_price => '6R',
     quantity => '4R',
     customer_title => '30L',
     customer_reference => '20L'
    );

  # how to order the fields in %format
  my @format =  qw(record_type   upc     lcc_label     lcc_catalog     
lcc_config     artist_name     item_title     quoted_price     quantity  
customer_title     customer_reference    );
  

  my %data = ( record_type => '23423' ... customer_reference => 'adfja;kdf');

  my $formatted_line = fixedlength(\%format, %data, \@format);

=head2 Number processing

The standard format instruction with Text::FixedLength is

  WIDTH JUSTIFICATION?

E.g. 6L creates a left-justified field taking up 6 spaces, filling any
non-used spaces with a spaces.

This module re-implements the Text::FixedLength::getFixed function to
handle additional optional syntax for formatting numbers. The new format
instruction is:

  WIDTH JUSTIFICATION? (ZERO_FILL? D)?
    or
  WIDTH JUSTIFICATION? (ZERO_FILL? F PLACES_AFTER_DECIMAL)?

If you dont understand the above let me give you a nice set of examples:

  10R*F3 means uses 10 spaces, zero fill if necessary and allow 3 places after the decimal point.

  10R*D  means uses 10 spaces, zero fill if necessary.

  10RF3  means uses 10 spaces, space fill (not zero-fill, note there was no * in the specification) if necessary and allow 3 places after the decimal point.


=head2 EXPORT

fixedlength()

=head2 OVERWRITTEN

Text::FixedLength::getFixed()

=head1 AUTHOR

T. M. Brannon, <TBONE@CPAN.ORG>

=head1 SEE ALSO

perl(1). Parse::FixedLength

=cut
