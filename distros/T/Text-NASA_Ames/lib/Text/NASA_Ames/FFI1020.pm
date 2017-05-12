package Text::NASA_Ames::FFI1020;
use base qw(Text::NASA_Ames);
use Carp;

use 5.00600;
use strict;

our $VERSION = do { my @r = (q$Revision: 1.1 $ =~ /\d+/g); sprintf " %d." . "%02d" x $#r, @r };


=head1 NAME

Text::NASA_Ames::FFI1020 - Implementation of FFI1020 NASA_Ames format

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
    unless ($self->dX()->[0]) {
	$self->_carp("dX must be defined and != 0 for ".ref $self);
	return;
    }
    $self->_parseList('nVPM', $self->nIV);
    unless ($self->nVPM()->[0] > 0) {
	$self->_carp("nVPM must be > 0 for ".ref $self . " was: ".
		    $self->nVPM()->[0]);
	return;
    }
    $self->_parseLines('xName', $self->nIV);
    $self->_parseVDeclaration;
    $self->_parseAuxDeclaration;
    $self->_parseTailHeader;

    return $self;
}

sub _refillBuffer {
    my $self = shift;

    my $line = $self->nextLine;
    return unless defined $line;

    my ($x, @a) = split ' ', $line;
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
	
	return unless defined $line;
	my @vi = split ' ', $line;
	if (@vi != $self->nVPM()->[0]) {
	    $self->_carp("not enough elements for nVPM, expected ".
			 $self->nVPM()->[0] . ", got ". scalar @vi .
			 " in row ". $self->currentLine);
	    return;
	}
	# transposing for faster access
	for (my $j = 0; $j < $self->nVPM()->[0]; $j++) {
	    $vHelp[$j][$i] = $vi[$j];
	}
    }

    for (my $j = 0; $j < $self->nVPM()->[0]; $j++) {
	$self->_cleanAndScaleVals($self->vMiss, $self->vScal, $vHelp[$j]);
	push @{ $self->dataBuffer },
	    new Text::NASA_Ames::DataEntry({X => [ $x + ($j * $self->dX()->[0]) ],
				      V => $vHelp[$j],
				      A => \@a});
    }
}

1;
__END__

=back

=head1 VERSION

$Id: FFI1020.pm,v 1.1 2004/02/18 09:25:04 heikok Exp $


=head1 AUTHOR

Heiko Klein, E<lt>H.Klein@gmx.netE<gt>

=head1 SEE ALSO

L<http://cloud1.arc.nasa.gov/solve/archiv/archive.tutorial.html>,
L<Text::NASA_Ames>

=cut
