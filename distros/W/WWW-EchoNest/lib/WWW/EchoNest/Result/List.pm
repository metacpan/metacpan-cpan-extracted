package WWW::EchoNest::Result::List;

use 5.010;
use strict;
use warnings;
use Carp;

use WWW::EchoNest;
our $VERSION = $WWW::EchoNest::VERSION;

use JSON;

use overload
    '""'  => '_stringify',
    'cmp' => '_compare',
    '=='  => '_compare',
    ;

# FUNCTIONS ############################################################
#
sub _json_rep {   JSON->new->utf8->pretty()->encode( $_[0] )   }

sub _stringify {
    return _json_rep( $_[0]->list() );
}

sub _compare {
    return $_[0]->_stringify() cmp $_[1]->_stringify();
}



########################################################################
#
# METHODS
#
sub new {
    my ( $class, $aref, %args ) = @_;
    
    return bless
        {
         list       => $aref,
         start      => $args{start}   // 0,
         total      => $args{total}   // scalar(@$aref),
        }, ref($class) || $class;
}

sub iterator {
    my ( $self, )     = @_;
    my @list          = $self->list;
    my $index         = 0;
    
    return sub {
        my $element = $list[$index++];
        return $element ? $element : undef;
    }
}

sub push {
    push @{ $_[0]->{list} }, $_[1];
}

sub get {
    return $_[0]->{list}->[ $_[1] ];
}

sub list      {   return @{ $_[0]->{list} };    }
sub start     {   return $_[0]->{start};        }
sub total     {   return $_[0]->{total};        }

1;

__END__

=head1 NAME

WWW::EchoNest::Result::List

=head1 AUTHOR

Brian Sorahan, C<< <bsorahan@gmail.com> >>

=head1 SUPPORT

Join the Google group: <http://groups.google.com/group/www-echonest>

=head1 ACKNOWLEDGEMENTS

Thanks to all the folks at The Echo Nest for providing access to their
powerful API.

=head1 LICENSE AND COPYRIGHT

Copyright 2011 Brian Sorahan.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.
