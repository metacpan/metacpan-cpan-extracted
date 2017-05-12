package Variable::Strongly::Typed::Array;

use version; $VERSION = qv('1.0.0');

use warnings;
use strict;
use Carp;

use base qw(Variable::Strongly::Typed);

{
    sub TIEARRAY {
        my($class, $type) = @_;

        my $self = bless \my($anon_scalar), $class;
        $self->_init([], $type);
    }

    ### Bummer have to implement all the array functions...
    sub FETCHSIZE { 
        my $arr = shift->_get_object;
        return scalar @{$arr}; 
    }

    sub STORESIZE { 
        my $arr = shift->_get_object;
        $#{$arr} = $_[0]-1;
    }

    sub STORE     { 
        my ($self, $index, $value) = @_;
        my $arr = $self->_get_object;

        $self->_check_values($value);
        $arr->[$index] = $value;
    }

    # Note we don't currently check on the way out as
    #   Tie::Constrained does...
    sub FETCH     { 
        my $arr = shift->_get_object;
        $arr->[$_[0]];
    }

    sub CLEAR     { 
        my $arr = shift->_get_object;
        @{$arr} = ();
    }

    sub POP       { 
        my $arr = shift->_get_object;
        pop(@{$arr});
    }

    sub PUSH      { 
        my ($self, @values) = @_;
        my $arr = $self->_get_object;

        $self->_check_values(@values);
        push(@$arr, @values);
    }

    sub SHIFT     { 
        my $arr = shift->_get_object;
        shift(@{$arr});
    }

    sub UNSHIFT   { 
        my ($self, @values) = @_;
        my $arr = $self->_get_object;

        $self->_check_values(@values);
        unshift(@$arr, @values);
    }

    sub EXISTS    { 
        my $arr = shift->_get_object;
        exists $arr->[$_[0]];
    }

    sub DELETE    { 
        my $arr = shift->_get_object;
        delete $arr->[$_[0]];
    }
    
    sub SPLICE {
        my ($self) = shift;
        my $arr = $self->_get_object;

        my $sz  = $arr->FETCHSIZE;
        my $off = @_ ? shift : 0;
        $off   += $sz if $off < 0;
        my $len = @_ ? shift : $sz - $off;

        $self->_check_values(@_) if (@_);

        return splice(@$arr, $off, $len, @_);
    }

    sub EXTEND {
        my ($self) = shift;
        $self->STORESIZE(shift);
    }
}

1;

__END__

=head1 NAME

Variable::Strongly::Typed::Array - Strongly typed array


=head1 VERSION

This document describes Variable::Strongly::Typed::Array version 1.0.0


=head1 SYNOPSIS

This class is utilized by Variable::Strongly::Typed - you don't
access this directly

    my @array_of_ints   :TYPE('int');       # Each slot must contain an int
    my @array_of_rgb :TYPE(\&red_green_blue); # my enumerated type
    
    # ... and later ...
    
    $array_of_ints[23] = 44;    # Groovy
    $array_of_ints[12] = 'yah'; # croak!
    
    # Return 1 if this val is RED, BLUE, or GREEN
    #   0 otherwise
    sub red_green_blue {
        local $_ = shift;
    
        /\A RED \z/xms || /\A BLUE \z/xms || /\A GREEN \z/xms;
    }
    
    $array_of_my_very_own_types[23] = 99;       # croak!
    $array_of_my_very_own_types[2] = 'BLUE';    # OK!

=head1 DESCRIPTION

DO NOT USE THIS MODULE DIRECTLY!!
It's used by Variable::Strongly::Typed to do its magic.

=head1 INTERFACE 
    
None for you

=head1 DIAGNOSTICS

None for you

=head1 CONFIGURATION AND ENVIRONMENT

None

=head1 DEPENDENCIES

Variable::Strongly::Typed

=head1 INCOMPATIBILITIES

None

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-perl-strongly-typed@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.


=head1 AUTHOR

Mark Ethan Trostler  C<< <mark@zzo.com> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2005, Mark Ethan Trostler C<< <mark@zzo.com> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
