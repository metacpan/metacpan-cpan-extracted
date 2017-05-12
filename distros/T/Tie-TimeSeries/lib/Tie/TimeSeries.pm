# =============================================================================
package Tie::TimeSeries;
# -----------------------------------------------------------------------------
$Tie::TimeSeries::VERSION = '0.01';
# -----------------------------------------------------------------------------
use 5.006;
use strict;
use warnings FATAL => 'all';

=head1 NAME

Tie::TimeSeries - Convenient hash tyng for time series data.

=head1 SYNOPSIS

    use Tie::TimeSeries;

    # Using with tie()
    tie %data, 'Tie::TimeSeries';
    $data{ time() } = [ 0.14, 0.06, 0.01 ];

    %data = ();
    $data{1361970900} = 10;
    $data{1361971200} = 20;
    $data{1361971500} = 30;
    $,=',';
    print values %data;                 # 10,20,30

    $data{1361971050} = 5;
    print values %data;                 # 10,5,20,30

    # OO
    $data = Tie::TimeSeries->new(
        1361970900 => 10,
        1361971200 => 20,
        1361971500 => 30,
    );
    print $data->values();              # 10,20,30
    $data->store( 1361971050 => 15 );
    print $data->values();              # 15,20,30
    $data->store( 1361971800 => 40 );
    print $data->values();              # 15,20,30,40


=head1 DESCRIPTION

When using time series data like throughput, statistics or so, this module is
convenient that key will be sorted automatically.
And this also is able to provide instance for OO using.

=cut


# =============================================================================
use Carp;
use Search::Binary;

use base qw/ Tie::Hash /;

# =============================================================================

=head1 STANDARD TIE HASH

There are standard interfaces usage with tie().

    tie %yourhash, 'Tie::TimeSeries' [, $time => $value [, ... ]]

On this way, use C<%yourhash> as regular Perl hashes, but keys and values will be stored in order internally.

With several arguments given, initialization stores them. C<$time> must be
integer number. C<$value> can be any type of scalar.

=cut

# -----------------------------------------------------------------------------
sub TIEHASH {
    my $class = shift;

    my $self = {
        h  => {},       # Hash for fetching which has same data of $self->{d} has.
        t  => [],       # Array of key means time;    [  t1,  t2,  ...,  tx  ]
        d  => [],       # Array of data warpped array;[ [v1],[v2], ..., [vx] ]
        c  => 0,        # for each()
        _i => 0,        # for _readindex(), last read index
    };

    bless $self, $class;
    while ( @_ ){
        $self->STORE( shift, shift );
    }
    return $self;
}


sub FETCH {
    my ($self, $key) = (@_);

    return (defined $key && CORE::exists($self->{h}{$key}))? $self->{h}{$key}->[0]: undef;
}


sub STORE {
    my ($self, $key, $val) = (@_);

    # Validation
    unless ( defined($key) && $key =~ /^\d+$/ ){
        carp("Not a number given as key of hash.");
        return;
    }

    # Storing
    if ( CORE::exists $self->{h}{$key} ){
        push  @{ $self->{h}{$key} }, $val;
        shift @{ $self->{h}{$key} };

    } else {
        my $d = [ $val ];

        # In the case of inserting just ordered data by number as key,
        # this cheking will be effective...
        my $nums = $#{$self->{t}};
        if ( $nums >= 0 && $key > $self->{t}[ $nums ] ){
            push @{ $self->{t} }, $key+0;
            push @{ $self->{d} }, $d;
        }
        else {
            # Caluculation prefer index of array to insert
            my $posi = binary_search(0, $#{$self->{t}}, $key, \&_readindex, $self);
            splice @{ $self->{t} }, $posi, 0, $key+0;
            splice @{ $self->{d} }, $posi, 0, $d;
        }
        $self->{h}{$key} = $d;
    }
}


sub DELETE {
    my ($self, $key) = (@_);

    if ( CORE::exists $self->{h}{$key} ){
        # Seek index
        my $posi = binary_search(0, $#{$self->{t}}, $key, \&_readindex, $self);
        splice @{ $self->{t} }, $posi, 1;
        splice @{ $self->{d} }, $posi, 1;
        my $val = $self->{h}{$key}->[0];
        CORE::delete $self->{h}{$key};
        return $val;
    }
    return undef;
}

sub EXISTS {
    my ($self, $key) = (@_);
    return CORE::exists( $self->{h}{$key} )? 1: undef;
}


sub FIRSTKEY {
    my ($self, $key) = (@_);

    $self->{c} = 0;
    $self->NEXTKEY();
}


sub NEXTKEY {
    my ($self) = (@_);

    return $self->{c} <= $#{$self->{t}}? $self->{t}[ $self->{c}++ ]: undef;
}


# =============================================================================

=head1 OBJECTIVE USAGE

This modules provides object instance and methods.

=head2 CONSTRUCTOR

    $tied = tie %yourhash, 'Tie::TimeSeries' [, $time => $value [, ... ]]
    $tied = Tie::TimeSeries->new( $time => $value [, ... ] );

Call method C<new()> to get instance or get return value of tie().

=cut


# -----------------------------------------------------------------------------
# OO Methods
# -----------------------------------------------------------------------------
sub new {
    TIEHASH( @_ );
}


# =============================================================================

=head2 METHODS

=head3 fetch()

Method C<fetch()> will fetch a value bound specified key.

    $tied->fetch( $time [, ... ] );
    $tied->fetch( \@keys_array );

=cut

# -----------------------------------------------------------------------------
sub fetch {
    my $self = shift;

    my @ret = ();

    if ( ref($_[0]) eq 'ARRAY' ){
        foreach ( @{$_[0]} ){
            push @ret, $self->FETCH( $_ );
        }
    }
    else {
        while ( @_ ){
            push @ret, $self->FETCH( shift );
        }
    }
    if ( wantarray ){
        return @ret;
    } else {
        if ( @ret == 1 ){
            return $ret[0];
        } else {
            return \@ret;
        }
    }
}


# =============================================================================

=head3 store()

Method C<store()> will store keys of time and values to the object.

    $tied->store( $time => $value [, ... ] );
    $tied->store( \%pairs_hash );

=cut

# -----------------------------------------------------------------------------
sub store {
    my $self = shift;

    if ( ref($_[0]) eq 'HASH' ){
        while ( my ($k, $v) = each %{$_[0]} ){
            $self->STORE( $k, $v );
        }
    }
    else {
        while ( @_ ){
            $self->STORE( shift, shift );
        }
    }
}


# =============================================================================

=head3 delete()

Method C<delete()> will remove key and value from the object.

    $tied->delete( $time [, ... ] );
    $tied->delete( \@keys_array );

And this method will return deleted value(s).

=cut

# -----------------------------------------------------------------------------
sub delete {
    my $self = shift;

    my @deleted = ();

    if ( ref($_[0]) eq 'ARRAY' ){
        foreach ( @{$_[0]} ){
            push @deleted, $self->DELETE( $_ );
        }
    }
    else {
        while ( @_ ){
            push @deleted, $self->DELETE( shift );
        }
    }
    if ( wantarray ){
        return @deleted;
    } else {
        if ( @deleted == 1 ){
            return $deleted[0];
        } else {
            return \@deleted;
        }
    }
}


# =============================================================================

=head3 exists()

Method C<exists()> returns boolean value.

    $tied->exists( $time );

=cut

# -----------------------------------------------------------------------------
sub exists {
    my $self = shift;

    return $self->EXISTS(shift);
}


# =============================================================================

=head3 keys()

Method C<keys()> returns keys list of the object.

    $tied->keys();

=cut

# -----------------------------------------------------------------------------
sub keys {
    return @{(shift)->{t}};
}


# =============================================================================

=head3 values()

Method C<values()> returns values list of the object.

    $tied->values();

=cut

# -----------------------------------------------------------------------------
sub values {
    return map { $_->[0] } @{(shift)->{d}};
}


# =============================================================================

=head3 iterate()

Method C<iterate()> execute a routine for each keys and values.

    $tied->iterate(\&subroutine);

Given subroutine will call by iterator with two argument, key and value.

    # Iterator example
    $obj->iterate(sub {
        ($key, $val) = @_;
        $obj->{$key} = $val * 100;
    });

=cut

# -----------------------------------------------------------------------------
sub iterate {
    my ($self, $func) = @_;
    unless ( ref($func) eq 'CODE' ){
        croak("Not a subrotine was given to iterate().");
    }

    foreach my $key ( @{$self->{t}} ){
        $func->( $key, $self->FETCH($key) );
    }
}


# =============================================================================


# -----------------------------------------------------------------------------
# Private functions
# -----------------------------------------------------------------------------
sub _readindex {
    my ($self, $val, $posi ) = @_;

    if ( defined $posi ){
        $self->{_i} = $posi;
        return ( $val <=> $self->{t}[$posi], $posi );
    } else {
        return $self->{_i} <= $#{$self->{t}}?
            ( $val <=> $self->{t}[ $self->{_i} ], $self->{_i}++ ):
            ( -1, $self->{_i}++ );
    }
}


# -----------------------------------------------------------------------------


=head1 SEE ALSO

See L<<Tie::IxHash>> - The great module brings many hints to this module.


=head1 AUTHOR

Takahiro Onodera, C<< <ong at garakuta.net> >>


=head1 LICENSE AND COPYRIGHT

Copyright 2010 T.Onodera.

This program is free software; you can redistribute it and/or modify it under the terms of either: the GNU General Public License as published by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1;
