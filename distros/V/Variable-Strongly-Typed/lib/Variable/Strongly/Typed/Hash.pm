package Variable::Strongly::Typed::Hash;

use version; $VERSION = qv('1.0.0');

use warnings;
use strict;
use Carp;

use base qw(Variable::Strongly::Typed);

{
    sub TIEHASH {
        my($class, $type) = @_;

        my $self = bless \my($anon_scalar), $class;
        $self->_init({}, $type);
    }

    sub STORE    { 
        my($self, $key, $value) = @_;
        my $hash = $self->_get_object;

        $self->_check_values($value);
        $hash->{$key} = $value;
    }

    sub FETCH    { 
        my($self, $key) = @_;
        my $hash = $self->_get_object;
        $hash->{$key};
    }

    sub FIRSTKEY { 
        my($self) = @_;
        my $hash = $self->_get_object;
        my $a = scalar keys %{$hash}; 
        each %{$hash};
    }

    sub NEXTKEY  { 
        my($self) = @_;
        my $hash = $self->_get_object;
        each %{$hash};
    }

    sub EXISTS   { 
        my($self, $key) = @_;
        my $hash = $self->_get_object;
        exists $hash->{$key}; 
    }

    sub DELETE   { 
        my($self, $key) = @_;
        my $hash = $self->_get_object;
        delete $hash->{$key};
    }   

    sub CLEAR    { 
        my($self) = @_;
        my $hash = $self->_get_object;
        %{$hash} = () 
    }

    sub SCALAR   { 
        my($self) = @_;
        my $hash = $self->_get_object;
        scalar %{$hash}; 
    }

}

1;

__END__

=head1 NAME

Variable::Strongly::Typed::Hash - Strongly typed hash


=head1 VERSION

This document describes Variable::Strongly::Typed::Hash version 1.0.0


=head1 SYNOPSIS

This class is utilized by Variable::Strongly::Typed - you don't
access this directly

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
