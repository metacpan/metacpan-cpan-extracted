package Tie::Alias::Hash;

use 5.008;
use strict;
use warnings;
use Carp;

our $VERSION = '0.01';

sub isAlias { 1; };

sub TIEHASH {

        my ( $class , $ref ) = @_ ;
        ref($ref) or croak "NOT A REFERENCE";
        if ( eval { tied($$ref) -> isAlias } ) {
                # we are re-aliasing something
                return tied ($$ref);
        }else{
                # $ref is already a pointer to the object
                bless $ref, $class;
        };
};

sub FETCH{
	$_[0]->{$_[1]};
};
sub STORE{
	$_[0]->{$_[1]} = $_[2];
};
sub EXISTS{
	exists $_[0]->{$_[1]};
};
sub DELETE{
	delete $_[0]->{$_[1]};
};
sub CLEAR{
	%{$_[0]} = ();
};
sub FIRSTKEY{
	keys %{$_[0]};
	each %{$_[0]};
};
sub NEXTKEY{
	each %{$_[0]};
};

1;
__END__

=head1 NAME

Tie::Alias::Hash - required by Tie::Alias::TIEHASH

=head1 SEE ALSO

Tie::Alias

=cut
