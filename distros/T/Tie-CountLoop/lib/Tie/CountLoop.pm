package Tie::CountLoop;

###########################################################
# Tie::Countloop package
# Gnu GPL2 license
#
# $Id: CountLoop.pm 7 2008-09-25 14:03:31Z fabrice $
# $Revision: 7 $
#
# Fabrice Dulaunoy <fabrice@dulaunoy.com>
###########################################################
# ChangeLog:
#
###########################################################
use strict;
use constant MAX => ( 2**32 ) - 1;
use vars qw($VERSION);

$VERSION = do { my @rev = ( q$Revision: 7 $ =~ /\d+/g ); sprintf "1.%d", @rev };

my $skip = 0;

sub TIESCALAR
{
    my ( $class ) = @_;
    bless {
        _value     => $_[1] || 0,
        _increment => $_[2] || 1,
        _max       => $_[3] || MAX,
        _min       => $_[4] || 0,
        _skip      => $_[5] || 0,
_auto => 1,
    }, $class;
}

sub FETCH
{
    my $self = shift;
    if ( $self->{ _auto } )
    {
        $skip++;
        if ( $skip > ( $self->{ _skip } ) )
        {
            $self->{ _value } += $self->{ _increment };
            $self->{ _value } = $self->{ _value } > $self->{ _max } ? $self->{ _min } : $self->{ _value };
            $self->{ _value } = $self->{ _value } < $self->{ _min } ? $self->{ _max } : $self->{ _value };
            $skip             = 1;
        }
    }
    return $self->{ _value };
}

sub toggle
{
    my $self = shift;
    $self->{ _auto } ^= 1;
}

sub auto
{
    my $self = shift;
    $self->{ _auto } = shift;
}

sub value
{
    my $self = shift;    
    my $val = shift;
    $self->{ _value } = $val if ($val);
    return $self->{ _value };
}

sub max
{
    my $self = shift;
    my $val = shift;
    $self->{ _max } = $val if ($val);
    return $self->{ _max };
}

sub min
{
    my $self = shift;
    my $val = shift;
    $self->{ _min } = $val if ($val);
    return $self->{ _min };
}

sub increment
{
    my $self = shift;
    my $val = shift;
    $self->{ _increment } = $val if ($val);
    return $self->{ _increment };
}

sub skip
{
    my $self = shift;
    my $val = shift;
    $self->{ _skip } = $val if ($val);
    return $self->{ _skip };
}

sub STORE
{
    my $self  = shift;
    my $value = shift;
    $self->{ _value } = $value;
}

1;
__END__


=pod

=head1 NAME

Tie::CountLoop - Have a counter looping in a scalar with min max and increment value.

=head1 SYNOPSIS

	use Tie::CountLoop;

	tie my $counter , 'Tie::CountLoop',15 ,-1 ,15 ,7 ,0;

	my $t = tied $counter;
	$t->increment( 1 );

	for ( 1 .. 20 )
	{
		print "  <<$counter>> <$_>  \n";
	}
        ## stop temporary the auto increment behaviour
	$t->auto( 0 );
	for ( 1 .. 20 )
	{
		print "  <<$counter>> <$_>  \n";
	}

	or
	 
	## the default value allow this 
        ## it is the same as my $counter , 'Tie::CountLoop', 0 , 1 , ( 2**32 ) - 1 , 0 , 0;
	use Tie::CountLoop;
	tie my $counter , 'Tie::CountLoop';
	
	for ( 1 .. 20 )
	{
		print "  <<$counter>> <$_>  \n";
	}
	
        ## How to toggle a binary flag after 5 access to the valriable
	my $t1 = tie my $counter1 , 'Tie::CountLoop',0,1,1,0,5;
	
	for ( 1 .. 20 )
	{
		print "  <<$counter1>> <$_>  \n";
	}


=head1 DESCRIPTION

C<Tie::CountLoop> allows you to tie a scalar in such a way that it increments
each time it is used. 
The tie takes 4 optionals extra arguments.

Argument 1: is the I<start> value of the counter. (default =0).

Argument 2: is the I<increment> value. (default = 1).

Argument 3: is the I<maximal> value. When this value is reached, the counter is set to the I<minimal> value (default = (2**32) -1)

Argument 4: is the I<minimal> value. When this value is reached if we used an negative I<increment> value, the counter is set to the I<maximal value> (default = 0)

Argument 5: is a I<skipping> value. If set to 3, means that you could access the counter 3 time without incrementing (default=1)

=head1 METHODS

=over 1

The Tie::CountLoop provide 7 extra methods.

=back

=head2 auto

=over 3

which change the autoincrement behaviour.
With 1, the counter is incremented when accessed.
With 0, the counter is NOT incremented when accessed.

=back

=head2 toggle

=over 3

which toggle the autoincrement behaviour (on and off and again).

=back

=head2 value

=over 3

get/set the value of the counter without incrementing the counter.

=back

=head2 max

=over 3

get/set the maximal value for the counter.

=back

=head2 min

=over 3

get/set the minimal value for the counter.

=back

=head2 increment

=over 3

get/set the increment value for the counter.

=back

=head2 skip

=over 3

get/set the skipping value for the counter.

=back

=head1 REVISION HISTORY


    Revision 1.7  2008/09/25 15:52:27  fabrice
    add extra methods to access all parameter of the counter
    clean the code for auto and toggle to allow instantiation by object 


    Revision 1.6  2006/11/14 13:31:56  fabrice
    fix default value for skip parameter

    Revision 1.5  2006/02/03 10:42:55  fabrice
    add README file

    Revision 1.4  2006/02/03 10:21:37  fabrice
    correct code for maximal and minimal value after increment

    Revision 1.3  2006/01/26 19:31:20  fabrice
    add method 'retrieve'

    Revision 1.2  2006/01/26 15:53:56  fabrice
    pod created

    Revision: 1.1 start project


=head1 AUTHOR

This package was written by I<Dulaunoy Fabrice <fabrice@dulaunoy.com>>.

=head1 COPYRIGHT and LICENSE

This package is copyright 2006-2008 by I<Dulaunoy Fabrice <fabrice@dulaunoy.com>>.

Under the GNU GPL2

This program is free software; you can redistribute it and/or modify it 
under the terms of the GNU General Public 
License as published by the Free Software Foundation; either version 2 
of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful, 
but WITHOUT ANY WARRANTY;  without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. 
See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License 
along with this program; if not, write to the 
Free Software Foundation, Inc., 59 Temple Place, 
Suite 330, Boston, MA 02111-1307 USA

Tie::CountLoop Copyright (C) 2004-2008 DULAUNOY Fabrice  
Tie::CountLoop comes with ABSOLUTELY NO WARRANTY; 
for details See: L<http://www.gnu.org/licenses/gpl.html> 
This is free software, and you are welcome to redistribute 
it under certain conditions;
   

=cut
