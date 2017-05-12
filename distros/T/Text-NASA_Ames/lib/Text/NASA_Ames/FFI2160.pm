package Pure::Text::NASA_Ames::FFI2160;
use base (Text::NASA_Ames);
__PACKAGE__->mk_accessors(qw(xScal1 xMiss1));

package Text::NASA_Ames::FFI2160;
use base qw(Pure::Text::NASA_Ames::FFI2160);
use Carp;

use 5.00600;
use strict;

our $VERSION = do { my @r = (q$Revision: 1.2 $ =~ /\d+/g); sprintf " %d." . "%02d" x $#r, @r };


=head1 NAME

Text::NASA_Ames::FFI2160 - Implementation of FFI2160 NASA_Ames format

=head1 SYNOPSIS


=head1 DESCRIPTION

This class should normally not be called directly but through the
L<Text::NASA_Ames> class indirectly.

=head1 PUBLIC METHODS

=over 4

=item new (Text::NASA_Ames-object || options for new NASA_Ames)

parses the (rest of the) header (body and comments)

=cut

sub new {
    my ($class, $fileObj) = @_;
    $class = ref $class || $class;
    if (! (ref $fileObj && (ref($fileObj) eq 'Text::NASA_Ames'))) {
	return new Text::NASA_Ames($fileObj);
    }
    my $self = $fileObj;
    bless $self, $class;

    $self->_parseList('dX', 1);
    push @{ $self->dX }, undef; # undef for string X2
    $self->_parseList('lenX', 1);
    unshift @{ $self->lenX }, undef; # undef for numeric X1
    $self->_parseLines('xName', $self->nIV);
    $self->_parseVDeclaration;
    $self->_parseAuxDeclaration;
    $self->_parseTailHeader;

    return $self;
}

sub _parseAuxDeclaration {
    my $self = shift;
    $self->nAuxV($self->nextLine); # includes NX1 on first pos!
    $self->nAuxC($self->nextLine);
    foreach my $type (qw(aScal aMiss)) {
	$self->_parseList($type, ($self->nAuxV - $self->nAuxC));
    }
    $self->_parseList('lenA', $self->nAuxC);
    my @stringMissA;
    for (my $i = 0; $i < $self->nAuxC; $i++) {
	push @stringMissA, $self->nextLine;
    }
    push @{ $self->aMiss }, @stringMissA;
    push @{ $self->aScal }, map { undef } @stringMissA;
    $self->_parseLines('aName', $self->nAuxV);

    # move first aux value to NX1
    $self->nAuxV($self->nAuxV - 1);
    my @aScal = @{ $self->aScal };
    $self->xScal1(shift @aScal);
    $self->aScal(\@aScal);
    my @aMiss = @{ $self->aMiss };
    $self->xMiss1(shift @aMiss);
    $self->aMiss(\@aMiss);
    my @aName = @{ $self->aName };
    shift @aName;
    $self->aName(\@aName);
}

sub _refillBuffer {
    my $self = shift;

    my $x2 = $self->nextLine;
    return unless defined $x2;

    my $line = $self->nextLine;
    return unless defined $line;

    my ($nX1, @a) = split ' ', $line;
    while (@a < ($self->nAuxV - $self->nAuxC)) {
	push @a, split ' ', $self->nextLine;
    }
    if (@a > ($self->nAuxV - $self->nAuxC)) {
	$self->_carp("to much elements for numeric Aux, expected ".
		     ($self->nAuxV() - $self->nAuxC). ", got ". scalar @a);
	return;
    }
    push @a, map {$self->nextLine} (1..$self->nAuxC);
    $self->_cleanAndScaleVals($self->aMiss, $self->aScal, \@a)
	if $self->nAuxV > 0;

    for (my $i = 0; $i < $nX1; $i++) {
	$line = $self->nextLine;
	unless ($line) {
	    $self->_carp("not enough elements for V".
			 " in row ". $self->currentLine);
	    return;
	}
	
	my ($x1, @v) = split ' ', $line;
	if (@v != $self->nV) {
	    $self->_carp("not enough elements for v, expected ".
			 $self->nV . ", got ". scalar @v . 
			 " in row ". $self->currentLine);
	    return;
	}
	if ($x1 == $self->xMiss1) {
	    $x1 = undef;
	} else {
	    $x1 *= $self->xScal1;
	}
	$self->_cleanAndScaleVals($self->vMiss, $self->vScal, \@v)
	    if $self->nV > 0;
	push @{ $self->dataBuffer },
	    new Text::NASA_Ames::DataEntry({X => [ $x1, $x2 ],
				      V => \@v,
				      A => \@a});
    }
}

1;
__END__

=item xMiss1

missing value for X1

=item xScal1

scaling for X1

=back

=head1 VERSION

$Id: FFI2160.pm,v 1.2 2004/03/16 16:33:07 heikok Exp $


=head1 AUTHOR

Heiko Klein, E<lt>H.Klein@gmx.netE<gt>

=head1 SEE ALSO

L<http://cloud1.arc.nasa.gov/solve/archiv/archive.tutorial.html>,
L<Text::NASA_Ames>

=cut
