package Pure::Text::NASA_Ames::DataEntry;
use base qw(Class::Accessor);

Pure::Text::NASA_Ames::DataEntry->mk_accessors(qw(A X V));

package Text::NASA_Ames::DataEntry;
use base qw(Pure::Text::NASA_Ames::DataEntry);
use Carp ();

use 5.00600;
use strict;

sub _carp {
    return Carp::carp(@_);
}


our $VERSION = do { my @r = (q$Revision: 1.1 $ =~ /\d+/g); sprintf " %d." . "%02d" x $#r, @r };


=head1 NAME

Text::NASA_Ames::DataEntry - The simples NASA_Ames data-presentation

=head1 SYNOPSIS

 my $de = new Text::NASA_Ames::DataEntry({X => [1,2,3],
                                    V => [3.3,3],
                                    A => [1.4, "S"]});
 my @x = @{ $de->X };
 my @a = @{ $de->A };
 my @v = @{ $de->V };

=head1 DESCRIPTION

A dataentry consists of the independent variables X, the auxiliary
variables A, and the primary dependent variables V.

=head1 PUBLIC METHODS

all methods return list-references

=over 4

=item new ({X => [X1...Xs], A => [A1...Ak], V => [V1..Vn]})

set the data

=cut

sub new {
    my ($class, $dataRef) = @_;
    $class = ref $class || $class;
    my $self = { X => [],
		 A => [],
		 V => [] };
    if (ref $dataRef && (ref $dataRef eq 'HASH')) {
	foreach my $item (keys %$self) {
	    if (exists $dataRef->{$item}) {
		if (ref $dataRef->{$item} eq 'ARRAY') {
		    $self->{$item} = $dataRef->{$item};
		} else {
		    _carp "$item not a ArrayRef, got item:".
			$dataRef->{$item};
		}
	    }
	}
    } else {
	_carp "new need a hash as argument, got $dataRef";
    }
    return bless $self, $class;
}
		

=item X

get a list of the independent variable per point

=item V

get a list of the primary dependent variables for point X

=item A

get a list of the auxiliary variables for point X

=back

=cut




1;
__END__
