# ----------------------------------------------------------------------------
# Name: Text::FixedLength.pm
# Auth: Dion Almaer (dion)
# Desc: Manipulate fixed length fields, from creating to parsing
# Date Created: Sun Nov 15 17:50:29 1998
# Version: 0.12
# $Modified: Wed Nov 18 16:55:46 CST 1998 by dion $
# ----------------------------------------------------------------------------
package Text::FixedLength;
use strict;
use Exporter;

# ----------------------------------------------------------------------------
#              Package Variables
# ----------------------------------------------------------------------------
@Text::FixedLength::ISA     = qw(Exporter);
@Text::FixedLength::EXPORT  = qw(delim2fixed fixed2delim setJustify setCrop);
$Text::FixedLength::VERSION = '0.12';
my $defaultJustification    = 'L'; # -- left justified by default (setJustify)
my $cropRecords             = 1;   # -- force fixed format by cropping records

# ----------------------------------------------------------------------------
#              Module Subroutines
# ----------------------------------------------------------------------------

# ----------------------------------------------------------------------------
# DELIMITED DATA - > FIXED LENGTH FIELD DATA
# ----------------------------------------------------------------------------

# ----------------------------------------------------------------------------
# Subroutine: delim2fixed - given an array of delimited text, or file with
#                           delimited text, create an array of fixed text
# SEE THE POD DOCUMENTATION BELOW (perldoc Text::FixedLength)
# ----------------------------------------------------------------------------
sub delim2fixed {
  my $delimData = shift || die 'delim2fixed: need data'; 
  my $delim     = shift || die 'delim2fixed: need a delimiter';
  my $format    = shift || die 'delim2fixed: need a fixed format array';
  my $outfile   = shift; # -- if set then save data to outfile

  my @delimdata = ( ref $delimData eq 'ARRAY' ) ? @{ $delimData } 
                                                : getFile($delimData);
  my @fixeddata = map { getFixed($_, $delim, $format) } @delimdata;
  if ($outfile) {
      savetoFile($outfile, \@fixeddata);
  }
  my $w = wantarray;
  return unless defined $w;
  return $w ? @fixeddata : \@fixeddata;
}

# ----------------------------------------------------------------------------
# Subroutine: getFixed - given a string, delimiter, and format return a string
# ----------------------------------------------------------------------------
sub getFixed {
  my $s      = shift || die 'getFixed: need a string';
  my $delim  = shift || die 'getFixed: need a delimiter';
  my $format = shift || die 'getFixed: need a format';
  my $out    = '';
  die "getFixed: no delimiter in $s" unless $s =~ /$delim/;

  # -- get each piece
  my @records = split /$delim/, $s;

  # -- setup the sprintf format (e.g. "%-8s%3s...")
  my $count = 0;
  foreach ( @$format ) {
    my $f = $_; # -- copy the format as we chop it later
    my $just = ($defaultJustification eq 'L') ? '-' : '';
    if ( uc substr($f, -1) =~ /[RL]/ ) {
      my $c = uc chop $f;
      if ( $c eq 'L' ) { $just = '-'; } elsif ( $c eq 'R' ) { $just = ''; }
    }
    $out .= "%${just}${f}s";

    # -- Crop the record if it is longer than it is meant to be
    if ($cropRecords) {
        $records[$count] = substr($records[$count], 0, $f) 
          if length $records[$count] > $f;
    }
    $count++;
  }
  return sprintf $out, @records;
}

# ----------------------------------------------------------------------------
# FIXED LENGTH FIELD DATA -> DELIMITED DATA
# ----------------------------------------------------------------------------

# ----------------------------------------------------------------------------
# Subroutine: fixed2delim
# SEE THE POD DOCUMENTATION BELOW (perldoc Text::FixedLength)
# ----------------------------------------------------------------------------
sub fixed2delim {
  my $fixedData   = shift || die 'fixed2delim: need data';
  my $fixedFormat = shift || die 'fixed2delim: need fixed format aref';
  my $delim       = shift || die 'fixed2delim: need the delim you want';
  my $outfile     = shift; # -- the file that you want the data to output to

  my @fixeddata = ( ref $fixedData eq 'ARRAY' ) ? @{ $fixedData }
                                                : getFile($fixedData);

  my @delimdata = map { getDelim($_, $delim, $fixedFormat) } @fixeddata;

  if ($outfile) {
      savetoFile($outfile, \@delimdata);
  }
  my $w = wantarray;
  return unless defined $w;
  return $w ? @delimdata : \@delimdata;
}

# ----------------------------------------------------------------------------
# Subroutine: getDelim - given a string, delimiter, and format return a string
# ----------------------------------------------------------------------------
sub getDelim {
  my $s      = shift || die 'getDelim: need a string';
  my $delim  = shift || die 'getDelim: need a delimiter';
  my $format = shift || die 'getDelim: need a format';
  my @out    = ();

  foreach ( @$format ) {
    s/\D//g; # - save only digits
    my $sub = substr($s,0,$_); $sub =~ s/^\s+//; $sub =~ s/\s+$//;
    push @out, $sub;
    substr($s,0,$_) = '';
  }
  return join $delim, @out;
}

# ----------------------------------------------------------------------------
# UTILITY / SHARED FUNCTIONS
# ----------------------------------------------------------------------------

# ----------------------------------------------------------------------------
# Subroutine: setJustify - given either 'l' 'L' 'r' 'R' set the justification
# ----------------------------------------------------------------------------
sub setJustify {
  my $char = uc shift;
  die 'setJustify: need one of: l, L, r, R' unless $char =~ /[LR]/;
  $defaultJustification = $char;
}

# ----------------------------------------------------------------------------
# Subroutine: setCrop - set the cropRecords value (whether to force the fixed
#             format by constraining a string to the size of its format)
# ----------------------------------------------------------------------------
sub setCrop {
  my $arg = shift; die 'setCrop: need either 1 or 0' unless defined $arg;
  $cropRecords = ($arg) ? 1 : 0;
}

# ----------------------------------------------------------------------------
# Subroutine: savetoFile - save fixeddata array ref to outfile
# ----------------------------------------------------------------------------
sub savetoFile {
  my $outfile = shift || die 'savetoFile: need a filename to save to';
  my $dataref = shift || die 'savetoFile: need data to save';

  open F, "> $outfile" or die "savetoFile: couldn't open $outfile: $!";
  foreach (@$dataref) { print F "$_\n"; }
  close F;
}

# ----------------------------------------------------------------------------
# Subroutine: getFile - given a filename return it lines in an array
# ----------------------------------------------------------------------------
sub getFile {
  my $file = shift;
  open F, $file or die "getDelimData: couldn't open file $file: $!";
  chomp( my @data = <F> );
  close F;
  return @data;
}

# ----------------------------------------------------------------------------
1; #           End of Text::FixedLength
# ----------------------------------------------------------------------------

__END__

=head1 NAME

Text::FixedLength - Parse and create fixed length field records

=head1 SYNOPSIS

  use Text::FixedLength;

  # -- get fixed length records from delimited text
  my @fL = qw(4L 4L 4L 4L); # -- left justified (which is default)
  my @fR = qw(4R 4R 4R 4R); # -- right justified (not default)
  my $str= join "\t", qw(1 2 3 4);
  my @a1 = delim2fixed([ $str ],"\t", \@fL);
  my @a2 = delim2fixed([ $str ],"\t", \@fR);
  # -- $a1[0] would now hold: '1   2   3   4   '
  # -- $a2[0] would now hold: '   1   2   3   4'

  # -- get delimited text from fixed length
  my @a1 = fixed2delim([ '2233344441' ], [qw(2 3 4 1)], ':');
  # -- $a1[0] would now hold: 22:333:4444:1

=head1 DESCRIPTION

Text::FixedLength was made to be able to manipulate fixed length
field records. You can manipulate arrays of data, or files
of data.
This module allows you to change between delimited and fixed length
records.

E.g. DELIM (with ':' as the delim) aaa:bbb:ccccc:dddddd 
     FIXED 'dion    almaer   mn55446'
           where the format is left justified: 8 9 2 5
(SEE FORMATS)

=head1 FORMATS

  You need to be familiar with the format array references used
  to create, and parse fixed length fields.
  The array reference holds the length of the field, and optionally
  holds either 'L' for left justified, or 'R' for right justified.
  By default fields are left justified (but you can change this
  default via the setJustify(L || R) functino)

  For example if you had the following fixed length record:

  1234567890123456789012345 <- place holder
  dion    almaer    mn55446

  The format (if all left justified) would be:
  $format = [ 8, 10, 2, 5 ];

=head1 FUNCTIONS

o B<delim2fixed>($filename | $dataAREF, $delim, $formatAREF,[$outfilename])

  delim2fixed returns fixed length field records from delimited records

  ARGUMENTS:
  1: Filename or an array reference holding delimited strings
  2: Delimiter for the data in arg 1
  3: Format array reference of the fixed lengths (see FORMATS)
  4: [OPTIONAL] Filename to write the fixed length data too

  RETURNS: Depending on wantarray it will return either an array of
           fixed length records, an array reference, or nothing
  e.g. @array = delim2fixed('file',':',[ qw(2 2 4 10) ]);
       $scalar = delim2fixed([ 'foo:bar:whee' ],':',[ qw(5 5 5) ]);
       delim2fixed('file',"\t",[ qw(6 10 4 1) ], 'outputfile');

o B<fixed2delim>($filename | $dataAREF, $formatAREF, $delim, [$outfilename])

  fixed2delim returns delimited records from fixed length records

  ARGUMENTS:
  1. Filename or an array reference holding fixed length records
  2. Format array reference for the data in arg 1
  3. Delimiter for the output data
  4: [OPTIONAL] Filename to write the delimited data too

  RETURNS: Depending on wantarray it will return either an array of
           delimited records, an array reference, or nothing
  e.g. @array = fixed2delim('file',[ qw(2 2 4 10) ],':');
       $scalar = fixed2delim([ 'foo   bar whee' ],':',[ qw(6 4 4) ]);
       fixed2delim('file',[ qw(6 10 4 1) ],"\t",'outputfile');

  NOTE: The resulting strings are cleaned of whitespace at the
        beginning and the end. So '  foo  ' becomes 'foo'
        You do not need to worry about the justification of the
        text as the whitespace is cleaned 

o B<setJustify>($justchar) [either 'L' or 'R'] [default: L]

  setJustify sets the default justification (originally set to left).
  
  ARGUMENTS: either L for left justified, or R for right justified

o B<setCrop>($bool) [either 1 or 0] [default: 1]

  setCrop sets whether records should be cropped to the size of the format
  or not.

  For example if you have a string 'whee' that is meant to be fit into
  a fixed format of 2 then if setCrop is true the record will be changed
  to 'wh' to constrain it

=cut

