package Tie::Alias::Array;

use 5.008;
use strict;
use warnings;
use Carp;

our $VERSION = '0.01';

sub isAlias { 1; };

sub TIEARRAY {

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
	$_[0]->[$_[1]];
};
sub STORE{
	$_[0]->[$_[1]] = $_[2];
};
sub FETCHSIZE{
	scalar @{$_[0]};
};
sub STORESIZE{
	$#{$_[0]} = $_[1] -1 ;
};
sub POP{
	pop @{$_[0]};
};
sub CLEAR{
	@{$_[0]} = ();
};
sub PUSH{
	my $r = shift;
	push @{$r}, @_;
};
sub SHIFT{
	shift @{$_[0]};
};
sub UNSHIFT{
	my $r = shift;
	unshift @{$r}, @_;
};
sub SPLICE{
	my $r = shift;
	my $o = shift || 0;
	my $l = shift || scalar(@{$r}) - $o;
	splice @{$r}, $o, $l, @_;
};
sub DELETE{
	delete $_[0]->[$_[1]];
};
sub EXISTS{
	exists $_[0]->[$_[1]];
};

1;
__END__

=head1 NAME

Tie::Alias::Array - required by Tie::Alias::TIEARRAY

=head1 SEE ALSO

Tie::Alias

=cut
