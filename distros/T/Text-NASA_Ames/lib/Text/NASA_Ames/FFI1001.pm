package Text::NASA_Ames::FFI1001;
use base qw(Text::NASA_Ames);
use Carp;

use 5.00600;
use strict;

our $VERSION = do { my @r = (q$Revision: 1.1 $ =~ /\d+/g); sprintf " %d." . "%02d" x $#r, @r };


=head1 NAME

Text::NASA_Ames::FFI1001 - Implementation of FFI1001 NASA_Ames format

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
    $self->_parseTailHeader;

    return $self;
}

sub _refillBuffer {
    my $self = shift;

    my $line = $self->nextLine;
    return unless defined $line;

    my ($x, @v) = split ' ', $line;
    if (@v != $self->nV) {
	$self->_carp("not enough elements for Aux, expected ".
		     $self->nV() . ", got ". scalar @v);
	return;
    }
    $self->_cleanAndScaleVals($self->vMiss, $self->vScal, \@v);
    push @{ $self->dataBuffer }, new Text::NASA_Ames::DataEntry({X => [$x],
							   V => \@v});
}

1;
__END__

=back

=head1 VERSION

$Id: FFI1001.pm,v 1.1 2004/02/18 09:25:04 heikok Exp $


=head1 AUTHOR

Heiko Klein, E<lt>H.Klein@gmx.netE<gt>

=head1 SEE ALSO

L<http://cloud1.arc.nasa.gov/solve/archiv/archive.tutorial.html>,
L<Text::NASA_Ames>

=cut
