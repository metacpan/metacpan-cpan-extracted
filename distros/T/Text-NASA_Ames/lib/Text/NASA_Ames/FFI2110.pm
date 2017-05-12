package Pure::Text::NASA_Ames::FFI2110;
use base (Text::NASA_Ames);
__PACKAGE__->mk_accessors(qw(xScal1 xMiss1));

package Text::NASA_Ames::FFI2110;
use base qw(Pure::Text::NASA_Ames::FFI2110);
use Carp;

use 5.00600;
use strict;

our $VERSION = do { my @r = (q$Revision: 1.1 $ =~ /\d+/g); sprintf " %d." . "%02d" x $#r, @r };


=head1 NAME

Text::NASA_Ames::FFI2110 - Implementation of FFI2110 NASA_Ames format

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

    $self->_parseList('dX', $self->nIV);
    $self->_parseLines('xName', $self->nIV);
    $self->_parseVDeclaration;
    $self->_parseAuxDeclaration;
    $self->_parseTailHeader;

    return $self;
}

sub _parseAuxDeclaration {
    my $self = shift;
    $self->SUPER::_parseAuxDeclaration;

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

    my $line = $self->nextLine;
    return unless defined $line;

    my ($x2, $nX1, @a) = split ' ', $line;
    if (@a != $self->nAuxV) {
	$self->_carp("not enough elements for Aux, expected ".
		     $self->nAuxV() . ", got ". scalar @a);
	return;
    }
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

$Id: FFI2110.pm,v 1.1 2004/02/18 09:25:04 heikok Exp $


=head1 AUTHOR

Heiko Klein, E<lt>H.Klein@gmx.netE<gt>

=head1 SEE ALSO

L<http://cloud1.arc.nasa.gov/solve/archiv/archive.tutorial.html>,
L<Text::NASA_Ames>

=cut
