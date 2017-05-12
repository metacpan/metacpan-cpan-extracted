package Perlude::Lazy;
use strict;
use warnings;
use 5.10.0;
use Carp qw< croak >;
use Exporter qw< import >;
our $VERSION = '0.0';
our @EXPORT = qw<

    enlist unfold
    fold
    takeWhile take drop
    filter apply
    now
    cycle range
    tuple
    lines
    concat

>;

use Carp;

# End-of-list value: always return itself, with no data
{
    my $NIL;
    $NIL = sub { $NIL };
    sub NIL() { $NIL }
}

# interface with the Perl world
sub enlist (&) {
    my ($i) = @_;
    my ( $l, @b );
    $l = sub {
        if (@_) {
            my $n = shift;
            return ( $l, @b[ 0 .. $n - 1 ] ) if @b >= $n;    # there's enough
            push @b, my @v = $i->();                         # need more
            push @b, @v = $i->() while @b < $n && @v;        # MOAR
            return ( $l, @b < $n ? @b : @b[ 0 .. $n - 1 ] ); # give it a peek
        }
        else {
            return ( $l, shift @b ) if @b;    # use the buffer first
            push @b, $i->();                  # obtain more items
            return @b ? ( $l, shift @b ) : NIL;
        }
    };
}

sub concat {
    my ($l, @ls)= @_;
    my @v;
    my $r;
    $r = sub {
        while ($l) {
            ( $l, @v ) = $l->();
            return ($r,@v) if @v;
            $l = shift @ls;
        }
    };
    $r
}

sub unfold (@) {
    my @array = @_;
    enlist { @array ? shift @array : () };
}

sub fold ($) {
    my ($l) = @_;
    my @v;
    unless (wantarray) {
        if ( defined wantarray ) {
            my $n = 0;
            $n += @v while 1 < ( ( $l, @v ) = $l->() );
            return $n;
        }
        else {
            # The real lazy one: when called in scalar context, values are
            # ignored:
            #     undef while defined ( $l = $l->() );
            # But producers must be able to handle that
            # So keep that for later and use the eager implementation for now
            undef while 1 < ( ( $l, @v ) = $l->() );
            return;
        }
    }
    my @r;
    push @r, @v while 1 < ( ( $l, @v ) = $l->() );
    @r;
}

# stream consumers (lazy)
sub takeWhile (&$) {
    my ( $cond, $l ) = @_;
    my $m;
    $m = sub {
        1 < ( ( $l, my @v ) = $l->() ) or return ($l);
        return $cond->() ? ( $m, @v ) : ( sub { ( $l, @v ) } ) for @v;
    };
}

sub filter (&$) {
    my ( $cond, $l ) = @_;
    my $m;
    $m = sub {
        while (1) {
            1 < ( ( $l, my @v ) = $l->() ) or return ($l);
            $cond->() and return ($m, @v) for @v;
        }
    };
}

sub take ($$) {
    my ( $n, $l ) = @_;
    my $m;
    $m = sub {
        $n-- > 0 or return ($l);
        1 < ( ( $l, my @v ) = $l->() ) or return ($l);
        ( $m, @v );
    }
}

sub drop ($$) {
    my ( $n, $l ) = @_;
    fold take $n, $l;
    $l;
}

sub apply (&$) {
    my ( $code, $l ) = @_;
    my $m;
    $m = sub {
        1 < ( ( $l, my @v ) = $l->() ) or return $l;
        ( $m, map $code->(), @v );
    }
}

# stream consumers (exhaustive)
sub now (&$) {
    my ( $code, $l ) = @_;
    my @b;
    while (1) {
        1 < ( ( $l, my @v ) = $l->() ) or return pop @b;
        @b = map $code->(), @v;
    }
}

# stream generators
sub cycle (@) {
    (my @ring = @_) or return NIL;
    my $index = -1;
    enlist { $ring[ ( $index += 1 ) %= @ring ] }
}

sub range ($$;$) {
    my $begin = shift // croak "range begin undefined";
    my $end   = shift;
    my $step  = shift // 1;

    return NIL if $step == 0;

    $begin -= $step;
    my $l;
    return $l = defined $end
        ? $step > 0
            ? sub { ( ( $begin += $step ) <= $end ) ? ( $l, $begin ) : ($l) }
            : sub { ( ( $begin += $step ) >= $end ) ? ( $l, $begin ) : ($l) }
        : sub { ( $l, $begin += $step ) };
}


sub tuple ($$) {
    my ( $n, $l ) = @_;
    croak "$n is not a valid parameter for tuple()" if $n <= 0;
    my $m;
    $m = sub {
        $l = take $n, $l;
        my (@r, @v);
        push @r, @v while 1 < ( ( $l, @v ) = $l->() );
        @r ? ( $m, \@r ) : ( $l )
    }
}

sub lines {
    # private sub that coerce path to handles
    state $fh_coerce = sub {
        my $v = shift;
        return $v if ref $v;
        open my ($fh),$v;
        $fh;
    };
    my $fh = $fh_coerce->( pop );

    # only 2 forms accepted for the moment
    # form 1: lines 'file'
    @_ or return enlist { <$fh> // () };

    # confess if not 2nd form
    $_[0] eq 'chomp' or confess 'cannot handle parameters ' , join ',', @_ ;

    # lines chomp => 'file'
    enlist {
        defined (my $v = <$fh>) or return;
        chomp $v;
        $v;
    }

}

1;

=head1 Perlude::Lazy

An experimentation of implementing real lazy lists in Perl5.
For real world usecases, please use Perlude instead.

=head1 SYNOPSIS

Haskell prelude miss you when you write perl stuff? Perlude is a port of the
most common keywords. Some other keywords where added when there is no haskell
equivalent.

Example: in haskell you can write

    nat        = [0..]
    is_even x  = ( x `mod` 2 ) == 0
    evens      = filter is_even
    main       =  mapM_ print
        $ take 10
        $ evens nat

in perlude, the same code will be:

    use Perlude;
    my $nat = enlist { state $x = 0; $x++ };
    sub is_even { ($_ % 2) == 0 }
    sub evens   { filter {is_even} shift }
    traverse {say} take 10, evens $nat

=head1 FUNCTIONS

all the Perlude documentation is relevent. just replace sub by enlist

=cut

