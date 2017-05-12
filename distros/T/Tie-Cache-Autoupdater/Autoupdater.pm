package Tie::Cache::Autoupdater;

use strict;
use warnings;

use Storable 'dclone';

BEGIN {
    eval { require Time::HiRes; };
    Time::HiRes->import('time') unless $@;
}

our $VERSION = 0.21;

sub TIEHASH {
    my $class       = shift;
    my %structure   = @_;
    
    my $self = {};
    while ( my ($k, $v) = each %structure ) {
        $self->{ $k } = {
            timeout => $v->{timeout} || 1,
            source  => $v->{source},
            last    => 0,
            result  => undef,
            clone   => $v->{clone} ? 1 : 0
        }
    }

    bless $self, $class;
}

sub FETCH { 
    my ( $self, $k ) = @_;

    return undef unless exists $self->{ $k };
    _fetch( $_[0], $k )
}

sub STORE {
    my ( $self, $k, $v ) = @_;
    $self->{ $k } = {
        timeout => $v->{timeout} || 1,
        source  => $v->{source},
        last    => 0,
        result  => undef,
        clone   => $v->{clone} ? 1 : 0
    }
}

sub FIRSTKEY {
    keys %{$_[0]};
    my ( $k, $v ) = each %{$_[0]};
    _fetch( $_[0], $k )
}

sub NEXTKEY  {
    my ( $k, $v ) = each %{$_[0]};
    _fetch( $_[0], $k )
}

sub EXISTS   { exists $_[0]->{ $_[1] } }
sub DELETE   { delete $_[0]->{ $_[1] } }
sub CLEAR    { %{ $_[0] } = () }
sub SCALAR   { scalar %{ $_[0] } }
sub UNTIE    { $_[0] = undef }
sub DESTROY  { }

sub _fetch {
    my ( $self, $k ) = @_;
    
    if ( $self->{$k}{last} + $self->{$k}{timeout} < time() ) {

        my @result = eval { $self->{$k}{source}->() };
        if ( $@ ) { 
            warn qq/Check source subroutine for key $k. Error - $@\n/;
            return undef
        }

        if ( @result == 1 ) {
            $self->{$k}{result} = $result[0];
        } elsif ( !@result ) {
            $self->{$k}{result} = undef;
        } else {
            $self->{$k}{result} = \@result;
        }

        $self->{$k}{last} = time();
    }
    
    return $self->{$k}{clone} && ref $self->{$k}{result}
        ? dclone($self->{$k}{result})
        : $self->{$k}{result};
}

1;

__END__

=head1 NAME

Tie::Cache::Autoupdater - Cache that automatically updated 

=head1 VERSION

This documentation refers to <Tie::Cache::Autoupdater> version 0.21

=head1 AUTHOR

<Anton Morozov>  (<antonfin@cpan.org>)

=head1 SYNOPSIS

        use Tie::Cache::Autoupdate;

        tie my %cache, 'Tie::Cache::Autoupdate', 
            key1 => { source => sub { ....; return $ref },  timeout => 10 },
            key2 => { source => \&get_data_from_db,         timeout => 30 },
            key2 => { source => \&get_data_from_file,       timeout => 60 };

        my ( $data1, $data2, $data3 );

        $data1 = $cache{key1};   # data, that return anonymous subroutine
        $data2 = $cache{key2};   # data, that return get_data_from_db
        $data3 = $cache{key3};   # data, that return get_data_from_file

        ##########################     2 seconds ago    #######################

        $data1 = $cache{key1};   # update data, call anonymous subroutine
        $data2 = $cache{key2};   # old data, nothing called
        $data3 = $cache{key3};   # old data, nothing called

        ##########################     15 seconds ago    ######################

        $data1 = $cache{key1};   # update data, call anonymous subroutine
        $data2 = $cache{key2};   # update data, call get_data_from_db
        $data3 = $cache{key3};   # old data, nothing called

        ##########################    1 minute 10 seconds ago    ##############

        $data1 = $cache{key1};   # update data, call anonymous subroutine one more
        $data2 = $cache{key2};   # update data, call get_data_from_db
        $data3 = $cache{key3};   # update data, call get_data_from_file

        # If you have Time::HiRes package, that you can use float timeout
        $cache{key4} = {
            source  => \&get_data_from_db2,
            timeout => 0.5
        };

        # If you plane to change the returned data you may cloned there.
        # Set true to a flag "clone".
        $cache{key4} = {
            source  => \&get_data_from_db3,
            timeout => 1,
            clone   => 1
        };

=head1 DESCRIPTION

Sometimes I need show in web rarely changes data. You may save it in memory, 
but you never don't know how long script will be work. For example, fcgi scripts
may work few days or weeks, but counters of database tables or site settings may 
changed more frequent in the day, each hour or each 10 minutes. I wrote package,
that help you cached data on fixed time.

=head2 How to use

You may created hash and tied it usages this package.

        tie my %cache, 'Tie::Cache::Autoupdater';

And set it in hash

        $cache{db_query} = {
            timeout => 10,
            source  => sub { 
                my $sth = $DBH->prepare('select * from table'); 
                $sth->execute;
                return $sth->fetchall_arrayref
            }
        };

Package call anonymous subroutine when you want to get value from C<%cache> 
with key C<db_query>.
        
Or you may set cache parameters when you tied hash. Like this:

        tie %cache, 'Tie::Cache::Autoupdater', db_query => {
            timeout => 10,
            source  => sub { 
                my $sth = $DBH->prepare('select * from table'); 
                $sth->execute;
                return $sth->fetchall_arrayref
            }
        };


=head2 Parameters

You may set unlimited pairs key => value where key is unique cache key. Value is
hash reference, where:

=head3 timeout

It's time for data saving. Default 1 second. If you have C<Time::HiRes> module
that you can set float timeout.

In next example value for key C<db_counters> will be updated each 0.2 second, and 
value for C<file_count> will be updated each 2.5 seconds.

        tie %cache, 'Tie::Cache::Autoupdater',
            db_counters => {
                timeout => 0.2,
                source  => sub { 
                    my $sth = $DBH->prepare('select count(*) from table2'); 
                    $sth->execute;
                    return ($sth->fetchrow_array);
                }
            },
            file_count => {
                timeout => 2.5,
                source  => sub {
                    my $file_count = glob( "$path/*" );
                    return $file_count;
                }
            };

=head3 source

Subroutine reference that return data for cache

=head3 clone

A flag that determines to clone or not clone the returned reference

=head2 NOTE1

If source subroutine return list, that package automatically convert it in array
reference.

=head2 NOTE2

If system has C<Time::HiRes> package that C<Tie::Cache::Autoupdater> use 
C<Time::HiRes::time> for timeout control.

=head2 NOTE3

For cloned references used C<dclone> subroutine from C<Storage> package

=head1 DEVELOPMENT

=head2 Repository

http://github.com/antonfin/Tie-Cache-Autoupdater

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2011 (antonfin@cpan.org)

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

