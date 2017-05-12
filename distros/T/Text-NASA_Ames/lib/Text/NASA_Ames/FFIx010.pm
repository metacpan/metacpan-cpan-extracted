package Text::NASA_Ames::FFIx010;
use base qw(Text::NASA_Ames);
use Carp;

use 5.00600;
use strict;

our $VERSION = do { my @r = (q$Revision: 1.1 $ =~ /\d+/g); sprintf " %d." . "%02d" x $#r, @r };


=head1 NAME

Text::NASA_Ames::FFIx010 - Implementation of FFIx010 NASA_Ames format

=head1 SYNOPSIS


=head1 DESCRIPTION

This class should normally not be called directly. It is the base class
for FFI2010, FFI3010 and FFI4010, but not FFI1010!

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
    $self->_parseList('nX', ($self->nIV - 1));
    push @{ $self->nX }, undef;
    $self->_parseList('nXDef', ($self->nIV - 1));
    push @{ $self->nXDef }, undef;
    $self->x([]);
    for (my $i = 0; $i < ($self->nIV - 1); $i++) {
	my $expected = $self->nXDef()->[$i];
	if ($expected > 0) {
	    my @xVals = split ' ', $self->nextLine;
	    if (@xVals != $expected) {
		$self->_carp("got ".scalar @xVals .
			     " values for X$i, expected $expected\n");
	    return;
	    }
	    push @{ $self->x }, \@xVals;
	}
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

    my ($xLast, @a) = split ' ', $line;
    if (@a != $self->nAuxV) {
	$self->_carp("not enough elements for Aux, expected ".
		     $self->nAuxV() . ", got ". scalar @a);
	return;
    }
    $self->_cleanAndScaleVals($self->aMiss, $self->aScal, \@a)
	if $self->nAuxV > 0;

    my @vHelp;
    my @keys;
    # wrong for 1010, there v-values are in the line
    for (my $n = 0; $n < $self->nV; $n++) {
	$vHelp[$n] = {};
	$self->_readBlock($self->nIV - 2, "", $vHelp[$n], \@keys);
    }

    foreach my $key (@keys) {
	my @pos = split '_', $key;
	my @xList;
	for (my $i = 0; $i < ($self->nIV - 1); $i++) {
	    $xList[$i] = $self->getXatPos($i, $pos[$i]);
	}
	my @v;
	for (my $j = 0; $j < $self->nV; $j++) {
	    push @v, delete $vHelp[$j]{$key};
	}
	$self->_cleanAndScaleVals($self->vMiss, $self->vScal, \@v);
	push @{ $self->dataBuffer },
	    new Text::NASA_Ames::DataEntry({X => [ (@xList, $xLast) ],
				      V => \@v,
				      A => \@a});
    }
}

sub _readBlock {
    my ($self, $xi, $key, $block, $keys) = @_;
    if ($xi > 0) {
	# wrong for 1010, there v-values are in the line
	for (my $i = 0; $i < $self->nX->[$xi]; $i++) {
	    my $newkey = ($key eq "") ? $i : "$i\_$key";
	    $self->_readBlock($xi - 1, $newkey, $block, $keys);
	}
    } else {
	my $line = $self->nextLine;
	unless ($line) {
	    $self->_carp("not enough elements for XI $xi".
			 " in row ". $self->currentLine);
	    return;
	}
	# wrong for 1010, there v-values are in the line
	my @vi = split ' ', $line;
	if (@vi != $self->nX->[0]) {
	    $self->_carp("not enough elements for nX1, expected ".
			 $self->nX->[0] . ", got ". scalar @vi .
			 " in row ". $self->currentLine);
	    return;
	}
	for (my $i = 0; $i < $self->nX->[0]; $i++) {
	    my $newkey = ($key eq "") ? $i : "$i\_$key";
	    push @{ $keys }, $newkey;
	    $block->{$newkey} = $vi[$i];
	}
    }
}

=item X

list of list of X->[i][pos]. call getXatPos to retrieve auto-expanded values

=item getXatPos (i,pos)

get Xi at the position pos (this will modify currentXPos1). positions start
at 0, i starts at 0, defined until nIV - 2!

=cut

sub getXatPos {
    my ($self, $i, $currentPos) = @_;
    unless (($i >= 0) && ($i <= ($self->nIV - 2))) {
	$self->_carp("cannot get i-pos: $i");
	return;
    }
    unless (($currentPos >= 0) && ($currentPos < $self->nX->[$i])) {
	$self->_carp("undefined position in getXatPos: $currentPos");
	return;
    }
    if ($self->nXDef->[$i] > $currentPos) {
	return $self->x->[$i]->[$currentPos];
    } else {
	unless ($self->dX->[$i]) {
	    $self->_carp("dX($i) not defined or 0, cannot extrapolate".
			 " getXatPos");
	    return;
	}
	return $self->x->[$i]->[0] + ($currentPos * $self->dX->[$i]);
    }
}

1;
__END__

=back

=head1 VERSION

$Id: FFIx010.pm,v 1.1 2004/02/18 09:25:04 heikok Exp $


=head1 AUTHOR

Heiko Klein, E<lt>H.Klein@gmx.netE<gt>

=head1 SEE ALSO

L<http://cloud1.arc.nasa.gov/solve/archiv/archive.tutorial.html>,
L<Text::NASA_Ames>

=cut
