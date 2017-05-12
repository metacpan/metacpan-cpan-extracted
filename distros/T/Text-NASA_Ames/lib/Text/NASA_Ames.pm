package Pure::Text::NASA_Ames;
use base qw(Class::Accessor);

Pure::Text::NASA_Ames->mk_accessors(qw(aMiss aName aScal date dX x
				 ffi iVol lenA lenX mName nAuxC nAuxV
				 nCom nIV nLHead nNComL nSComL nV nVol
				 nVPM nX nXDef oName org rDate sCom
				 sName vMiss vName vScal xName IO_File 
                                 fileName currentLine dataBuffer));
								
package Text::NASA_Ames;

use Carp ();
use IO::File ();

use 5.00600;
use strict;

use base qw(Pure::Text::NASA_Ames);
use Text::NASA_Ames::DataEntry;

our $VERSION = 0.03;

sub _carp {
    my $self = shift;
    my $fileMsg = '';
    $fileMsg = " in ".$self->fileName. " line ".$self->IO_File->input_line_number if ($self->IO_File && $self->IO_File->input_line_number);
    return Carp::carp(@_, $fileMsg);
}

=head1 NAME

Text::NASA_Ames - Reading data from NASA Ames files

=head1 SYNOPSIS

    my $nasaAmes = new Text::NASA_Ames('this_file');
    # or
    $nasaAmes = new Text::NASA_Ames(new IO::File "this_file", "r");
    print STDERR "3 independent variables";
    $nasaAmes->nAuxV; # number of (real) auxiliary variables not containing
                      # a independent variable
    $nasaAmes->nV; # number of independent variables


    # scanning through the file:
    while (my $entry = $nasaAmes->nextDataEntry) {
       my @X = @{ $dataEntry->X };
       my @aux = @{ $dataEntry->A };
       my @V = @{ $dataEntry->V };
    }

=head1 DESCRIPTION

This is the factory class for reading on of the Text::NASA_Ames formats
(currently 9). The function-names are related to the format specification
as in L<http://cloud1.arc.nasa.gov/solve/archiv/archive.tutorial.html> by
Gaines and Hipkinds.

=head1 PUBLIC METHODS



=head2 METHODS FROM SPECIFICATIONS

All lists are returned as references to lists.

The names of the public methods are identical to the format specifications. In some formats, auxiliary variables are misused to store independent variables. In those cases, I return the real number of auxiliary variables with nAuxV and not nAuxV as sum of auxiliray variables plus stored independent variables as written in the file.


=over 4

=item a

not implemented, see L<nextDataEntry>

=item aMiss

list of missing values of the auxiliary variables

=item aName

list of names of the auxiliary variables

=item aScal

list of scaling factors of the auxiliary variables

=item date

UT date marking the beginning of the data: format 'YYYY MM DD'

=item dX

list of interval between the indep. variables (0 means no linear interval)

=item ffi

File Format Index of the parsed file

=item iVol

total number of volumes belonging to complete dataset (see nVol)
(starting at 1)

=item lenA

list of character length of the auxiliary string variables

=item lenX

list of character length of the independent string variables

=item mName

mission name

=item nAuxC

number of auxiliary string variables

=item nAuxV

number of total auxiliary variables (including string variables). The numeric
auxiliary variables come allways in front of the string variables.

=item nCom

list of normal comment strings

=item nIV

number of independent variables (== first number of ffi)

=item nLHead

number of header lines

=item nNComL

number of normal comment lines

=item nSComL

number of special comment lines

=item nV

number of primary variables

=item nVol

total number of volumes required to store complete dataset

=item nVPM

number of independent variable between variable marks

=item nX

list of numbers of values of the primary variables

=item nXDef

list of numbers of values of the independent variable defined in the header

=item oName

originator name

=item org

originators organization

=item rDate

date of last revision (format as data)

=item sCom

list of special comment lines

=item sName

source name

=item v

not implemented, see L<nextDataEntry>

=item vMiss

list of missing values of the variables

=item vName

list of variable names

=item vScal

list of scaling factor of variables

=item x

might be used for temporary variables, for iterator-access,
see L<nextDataEntry>

=item xName

list of variable names

=back

=head2 ADDITIONAL METHODS

=over 4

=item new (filename || IO::File)

parse the first line and distribute the file to the correct Text::NASA_Ames::FFI
object;

=cut

sub new {
    my ($class, $file) = @_;
    $class = ref $class || $class;
    my $self = {};
    bless $self, $class;

    $self->fileName("$file"); # scalar representation
    if (ref ($file) && $file->isa("IO::File")) {
	$self->IO_File($file);
    } else {
	$self->IO_File(new IO::File "$file", "r");
    }
    unless (defined $self->IO_File) {
	$self->_carp("couldn't initialize file $file: $!");
	return undef;
    }
    $self->currentLine(1); # lines starting at 1
    $self->dataBuffer([]);

    $self->_parseTopHeader;
    my $subclass = 'Text::NASA_Ames::FFI'.$self->ffi;
    eval "require $subclass";
    if ($@) {
	$self->_carp("cannot require $subclass");
	return;
    }
    return $subclass->new($self);
}


sub _parseTopHeader {
    my $self = shift;
    # get the nlhead and format
    my $line = $self->nextLine;
    my ($nlhead, $ffi) = split ' ', $line;
    $self->nLHead($nlhead);
    if ($ffi =~ /(\d{4})/) {
	$ffi = $1; # clean and untaint
    }
    $self->ffi($ffi);
    $self->nIV( int ($ffi/1000) );
    $self->oName($self->nextLine);
    $self->org($self->nextLine);
    $self->sName($self->nextLine);
    $self->mName($self->nextLine);
    my @vol = split ' ', $self->nextLine;
    $self->iVol($vol[0]);
    $self->nVol($vol[1]);
    my @date = split ' ', $self->nextLine;
    $self->date("$date[0] $date[1] $date[2]");
    $self->rDate("$date[3] $date[4] $date[5]");
    unless ($self->currentLine != 7) {
	$self->_carp("problems reading top header, expected 7 lines, got ".
	    $self->currentLine);
    }
}

sub _parseTailHeader {
    my $self = shift;
    $self->nSComL($self->nextLine);
    my @scom;
    for (my $i = 0; $i < $self->nSComL; $i++) {
	push @scom, $self->nextLine;
    }
    $self->sCom(\@scom);
    $self->nNComL($self->nextLine);
    my @com;
    for (my $i = 0; $i < $self->nNComL; $i++) {
	push @com, $self->nextLine;
    }
    $self->nCom(\@com);
    unless ($self->currentLine != 7) {
	$self->_carp("problems reading header, expected ". $self->nLHeader() .
	    " lines, got ". $self->currentLine);
    }
}

# parse a list from a line expecting several entries
sub _parseList {
    my ($self, $type, $expected) = @_;
    if ($expected != 0) {
	my @list = split ' ', $self->nextLine;
        while (@list < $expected) {
	    push @list, split ' ', $self->nextLine;
	}
	if (@list > $expected) {
	    $self->_carp("got ".scalar @list . 
			 " $type values, expected $expected\n");
	    return;
	}
	@list = map { $self->_trim($_) } @list;
	$self->$type(\@list);
    }
}

# parse several lines and join as list
sub _parseLines {
    my ($self, $type, $lines) = @_;
    my @values;
    for (my $i = 0; $i < $lines; $i++) {
	push @values, $self->nextLine;
    }
    @values = map {$self->_trim($_) } @values;
    $self->$type(\@values);
}

sub _parseVDeclaration {
    my $self = shift;
    $self->nV($self->nextLine);
    foreach my $type (qw(vScal vMiss)) {
	$self->_parseList($type, $self->nV);
    }
    $self->_parseLines('vName', $self->nV);
}

sub _parseAuxDeclaration {
    my $self = shift;
    $self->nAuxV($self->nextLine);
    foreach my $type (qw(aScal aMiss)) {
	$self->_parseList($type, $self->nAuxV);
    }
    $self->_parseLines('aName', $self->nAuxV);
}

=item currentLine

the current line in the file, starting at 1

=item nextLine

get the next chomped/trimmed line from the file and set the currentLine counter

=cut

sub nextLine {
    my $self = shift;
    my $fh = $self->IO_File;
    my $line = <$fh>;
    if (defined $line) {
	chomp $line;
	$self->currentLine($self->currentLine()+1);
    }
    return $self->_trim($line);
}

=item dataBuffer

set/get the complete dataBuffer. Don't use this method manually without
knowing what you're doing. Think about using L<nextDataEntry>.

=item nextDataEntry

fetch the next L<Text::NASA_Ames::DataEntry> from the dataBuffer, which will
be filled automatically. The data will not be set to memory.

=cut

sub nextDataEntry {
    my $self = shift;
    my $buffer = $self->dataBuffer;

    unless (@$buffer) {
	if ($self->can('_refillBuffer')) {
	    $self->_refillBuffer;
	} else {
	    $self->_carp("_refillBuffer not set for ".ref($self));
	}
    }
    return shift @$buffer;
}

# takes to listRefs, sets the values in the second list to undef
# if they are equal to the same entry in the first list
sub _undefMissingVals {
    my ($self, $miss, $vals) = @_;
    if (@$miss != @$vals) {
	$self->_carp("missing values ref (".scalar @$miss .
		     ") and values ref (".scalar @$vals .
		     ") should be of the same size");
	return;
    }
    for (my $i = 0; $i < @$miss; $i++) {
	if (defined $vals->[$i]) {
	    if ($miss->[$i] eq $vals->[$i]) {
		$vals->[$i] = undef;
	    }
	}
    }
}

sub _scaleVals {
    my ($self, $scale, $vals) = @_;
    if (@$scale != @$vals) {
	$self->_carp("scaling values ref and values ref should be of the same size");
	return;
    }
    for (my $i = 0; $i < @$scale; $i++) {
	if (defined $vals->[$i]) {
	    $vals->[$i] *= $scale->[$i]
		if (defined $scale->[$i]); # not defined for string values
	}
    }
}

sub _cleanAndScaleVals {
    my ($self, $miss, $scale, $vals) = @_;
    $self->_undefMissingVals($miss, $vals);
    $self->_scaleVals($scale, $vals);
}

sub _trim {
    my $self = shift;
    local $_ = shift;
    return unless defined $_;
    s/^\s+//;
    s/\s+$//;
    return $_;
}

1;
__END__

=back

=head2 INTERNALS

The variables (primary and auxiliary) are stored in the following structure:

  $self->{_variables}{X1}{..}{Xn}->{V} = [v1..vn]
  $self->{_variables}{X1}{..}{Xn}->{A} = [a1..an]


=head1 CAVEATS

It is possible to modify a lot of variables which should be read-only.

In the time of XML such an ASCI format does not seem very
reasonable. To the rescue: It is older than XML, much leaner (what isn't?)
and at least well documented.

=head1 TODO

maybe implementing writing routines
maybe implementing a direct-access mode

=head1 AUTHOR

Heiko Klein, E<lt>H.Klein@gmx.netE<gt>

=head1 SEE ALSO

L<http://cloud1.arc.nasa.gov/solve/archiv/archive.tutorial.html>,
L<Text::NASA_Ames::DataEntry>,
L<Text::NASA_Ames::FFI1001>, L<NASA_Ames::FFI1010>, L<NASA_Ames::FFI1020>,
L<Text::NASA_Ames::FFI2010>, L<NASA_Ames::FFI2110>, L<NASA_Ames::FFI2160>,
L<Text::NASA_Ames::FFI2310>, L<NASA_Ames::FFI3010>, L<NASA_Ames::FFI4010>

=cut
