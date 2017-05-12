use strict;
use warnings;
package WebService::ChatWorkApi::DataSet;
use Carp ( );
use Readonly;
use String::CamelCase qw( camelize );
use Class::Load qw( try_load_class );
use Smart::Args;
use Mouse;

Readonly my %OP => (
    eq    => sub { my $o = shift; return sub { shift( ) eq $o    } },
    ne    => sub { my $o = shift; return sub { shift( ) ne $o    } },
    lt    => sub { my $o = shift; return sub { shift( ) lt $o    } },
    le    => sub { my $o = shift; return sub { shift( ) le $o    } },
    gt    => sub { my $o = shift; return sub { shift( ) gt $o    } },
    ge    => sub { my $o = shift; return sub { shift( ) ge $o    } },
    q{=~} => sub { my $o = shift; return sub { shift( ) =~ m{$o} } },
    q{!~} => sub { my $o = shift; return sub { shift( ) !~ m{$o} } },
    q{==} => sub { my $o = shift; return sub { shift( ) == $o    } },
    q{!=} => sub { my $o = shift; return sub { shift( ) != $o    } },
    q{>}  => sub { my $o = shift; return sub { shift( ) >  $o    } },
    q{>=} => sub { my $o = shift; return sub { shift( ) >= $o    } },
    q{<}  => sub { my $o = shift; return sub { shift( ) <  $o    } },
    q{<=} => sub { my $o = shift; return sub { shift( ) <= $o    } },
);

has dh => ( is => "rw", isa => "WebService::ChatWorkApi::UserAgent" );

sub relationship {
    my $self = shift;
    my $name = shift;
    my $class_name = join q{::}, __PACKAGE__, camelize( $name );
    try_load_class( $class_name )
        or die "Could not load $class_name.";
    return $class_name->new(
        dh => $self->dh,
        @_,
    );
}

sub _get_filter_sub {
    args_pos my $self,
             my $query;

    if ( ref $query eq ref sub { } ) {
        return $query;
    }
    elsif ( ref $query eq ref [ ] ) {
        my( $operator, $operand ) = @{ $query };
        return $OP{ $operator }->( $operand );
    }
    else {
        Carp::carp( "Unknown query found: ", Data::Dumper->new( [ $query ] )->Terse( 1 )->Sortkeys( 1 )->Indent( 0 )->Useqq( 1 )->Dump );
    }

    return;
}

sub grep {
    args_pos my $self,
             my $condition_ref,
             my $objects_ref;

    for my $key ( keys %{ $condition_ref } ) {
        if ( !ref( $condition_ref->{ $key } ) ) {
            $condition_ref->{ $key } = [ "eq", $condition_ref->{ $key } ];
        }

        my $op = $self->_get_filter_sub( $condition_ref->{ $key } );
        @{ $objects_ref } = grep { $op->( $_->$key ) } @{ $objects_ref };
    }

    return $objects_ref;
}

sub search {
    my $self      = shift;
    my %condition = @_;
    my @objects = $self->retrieve_all;
    return @{ $self->grep( \%condition, \@objects ) };
}

sub bless {
    my $self  = shift;
    my %param = @_;
    my $object = $self->data->new( %param );
    $object->ds( $self );
    return $object;
}

1;

__END__
=encoding utf8

=head1 NAME

WebService::ChatWorkApi::DataSet - isa dataset of Data class

=head1 SYNOPSIS

  use WebService::ChatWorkApi::DataSet::Me;
  my $ds = WebService::ChatWorkApi::DataSet::Me->new( dh => $ua );
  my $data = $ds->retrieve;

=head1 DESCRIPTION

This module provides a few methods to access the dataset, and
has responsibility to make response to be data class.

=head1 TODO

No iteration class now.  It may be needed.
