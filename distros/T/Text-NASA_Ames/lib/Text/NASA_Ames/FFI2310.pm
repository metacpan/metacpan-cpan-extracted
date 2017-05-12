package Pure::Text::NASA_Ames::FFI2310;
use base (Text::NASA_Ames);
__PACKAGE__->mk_accessors(qw(xScal1 xMiss1 nXScal1 nXMiss1 dXScal1 dXMiss1));

package Text::NASA_Ames::FFI2310;
use base qw(Pure::Text::NASA_Ames::FFI2310);
use Carp;

use 5.00600;
use strict;

our $VERSION = do { my @r = (q$Revision: 1.1 $ =~ /\d+/g); sprintf " %d." . "%02d" x $#r, @r };


=head1 NAME

Text::NASA_Ames::FFI2310 - Implementation of FFI2310 NASA_Ames format

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

    $self->_parseList('dX', $self->nIV - 1);
    $self->_parseLines('xName', $self->nIV);
    $self->_parseVDeclaration;
    $self->_parseAuxDeclaration;
    $self->_parseTailHeader;

    return $self;
}

sub _parseAuxDeclaration {
    my $self = shift;
    $self->SUPER::_parseAuxDeclaration;

    # move first three aux value to NX1 .. NX3
    $self->nAuxV($self->nAuxV - 3);
    my @aScal = @{ $self->aScal };
    $self->nXScal1(shift @aScal);
    $self->xScal1(shift @aScal);
    $self->dXScal1(shift @aScal);
    $self->aScal(\@aScal);
    my @aMiss = @{ $self->aMiss };
    $self->nXMiss1(shift @aMiss);
    $self->xMiss1(shift @aMiss);
    $self->dXMiss1(shift @aMiss);
    $self->aMiss(\@aMiss);
    my @aName = @{ $self->aName };
    shift @aName;
    shift @aName;
    shift @aName;
    $self->aName(\@aName);
}

sub _refillBuffer {
    my $self = shift;

    my $line = $self->nextLine;
    return unless defined $line;

    my ($x2, $nX1, $x1_0, $dX1, @a) = split ' ', $line;
    my @help = ($nX1, $x1_0, $dX1);
    $self->_cleanAndScaleVals([$self->nXMiss1, $self->xMiss1, $self->dXMiss1],
			      [$self->nXScal1, $self->xScal1, $self->dXScal1],
			      \@help);
    ($nX1, $x1_0, $dX1) = @help;
    if (@a != $self->nAuxV) {
	$self->_carp("not enough elements for Aux, expected ".
		     $self->nAuxV() . ", got ". scalar @a);
	return;
    }
    $self->_cleanAndScaleVals($self->aMiss, $self->aScal, \@a)
	if $self->nAuxV > 0;

    my @vHelp;
    for (my $i = 0; $i < $self->nV; $i++) {
	$line = $self->nextLine;
	unless ($line) {
	    $self->_carp("not enough elements for V".
			 " in row ". $self->currentLine);
	    return;
	}
	
	my (@vi) = split ' ', $line;
	if (@vi != $nX1) {
	    $self->_carp("not enough elements for nX1, expected ".
			 $nX1 . ", got ". scalar @vi . 
			 " in row ". $self->currentLine);
	    return;
	}
	# transposing
	for (my $j = 0; $j < $nX1; $j++) {
	    $vHelp[$j][$i] = $vi[$j];
	}
    }

    for (my $j = 0; $j < $nX1; $j++) {
	my $x1 = $x1_0 + $j * $dX1;
	$self->_cleanAndScaleVals($self->vMiss, $self->vScal, $vHelp[$j])
	    if $self->nV > 0;
	push @{ $self->dataBuffer },
	    new Text::NASA_Ames::DataEntry({X => [ $x1, $x2 ],
				      V => $vHelp[$j],
				      A => \@a});
    }
}

1;
__END__

=item xMiss1 nXMiss1 dXMiss1

missing value for X1

=item xScal1 nXScal1 dXScal1

scaling for X1

=back

=head1 VERSION

$Id: FFI2310.pm,v 1.1 2004/02/18 09:25:04 heikok Exp $


=head1 AUTHOR

Heiko Klein, E<lt>H.Klein@gmx.netE<gt>

=head1 SEE ALSO

L<http://cloud1.arc.nasa.gov/solve/archiv/archive.tutorial.html>,
L<Text::NASA_Ames>

=cut
