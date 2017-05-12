package Perlude;
use Perlude::Open;
use strict;
use warnings;
use 5.10.0;
use Carp qw< croak >;
use Exporter qw< import >;
our @EXPORT = qw<
    fold unfold 
    takeWhile take drop
    filter apply
    now
    cycle range
    tuple
    concat concatC concatM
    records lines 
    pairs
    nth
    chunksOf
    open_file
>; 

# ABSTRACT: Shell and Powershell pipes, haskell keywords mixed with the awesomeness of perl. forget shell scrpting now! 

use Carp;

our $VERSION = '0.61';

sub pairs ($) {
    my ( $ref ) = @_;
    my $isa = ref $ref or die "'$ref' isn't a ref";

    # TODO: use reftypes here!
    if ($isa eq 'HASH') {
        sub {
            my @pair;
            while ( @pair = each %$ref ) { return \@pair }
            ()
        }
    }
    # elsif ($isa eq 'ARRAY') {
    #     my $index = 1;
    #     sub {
    #         return if $index > @$ref;
    #         my $r =
    #             [ $$ref[$index-1]
    #             , $$ref[$index] ];
    #         $index+=2;
    #         $r;
    #     }
    # }
    else { die "can't pair this kind of ref: $isa" }
}

# sub pairs (&$) {
#     my ( $do, $on ) = @_;
#     sub {
# 	while ( @$_ = each %$on ) { return $do->() }
# 	()
#     }
# }

# private helpers
sub _buffer ($) {
    my ($i) = @_;
    my @b;
    sub {
        return shift @b if @b;
        @b = ( $i->() );
        return @b ? shift @b : ();
    }
}

# interface with the Perl world
sub unfold (@) {
    my @array = @_;
    sub { @array ? shift @array : () }
}

sub fold ($) {
    my ( $i ) = @_;
    my @v;
    unless (wantarray) {
        if (defined wantarray) {
            my $n = 0;
            $n += @v while @v = $i->();
            return $n;
        } else {
            undef while @v = $i->();
            return;
        }
    }
    my @r;
    push @r, @v while @v = $i->();
    @r;
}

# stream consumers (lazy)
sub takeWhile (&$) {
    my ($cond, $i ) = @_;
    sub {
        ( my @v = $i->() ) or return;
        return $cond->() ? @v : () for @v;
    }
}

sub filter (&$) {
    my ( $cond, $i ) = @_;
    $i = _buffer $i;
    sub {
        while (1) {
            ( my @v = $i->() ) or return;
            $cond->() and return @v for @v;
        }
    }
}

sub take ($$) {
    my ( $n, $i ) = @_;
    $i = _buffer $i;
    sub {
        $n-- > 0 or return;
        $i->()
    }
}

sub drop ($$) {
    my ( $n, $i ) = @_;
    $i = _buffer $i;
    fold take $n, $i;
    $i;
}

sub apply (&$) {
    my ( $code, $i ) = @_;
    sub {
        ( my @v = $i->() ) or return;
        (map $code->(), @v)[0];
    }
}

# stream consumers (exhaustive)
sub now (&$) {
    my ( $code, $i ) = @_;
    my @b;
    while (1) {
        ( my @v = $i->() ) or return pop @b;
        @b = map $code->(), @v;
    }
}

sub records {
    my $source = shift;
    sub { <$source> // () }
}


sub lines {
    my $fh = &open_file;
    my $line;
    sub {
        return unless defined ( $line = <$fh> );
        chomp $line;
        $line;
    }
}

sub concat {
    my ($s, @ss) = @_; # streams
    my @v;
    sub {
        while (1) {
            @v = $s->() and return @v;
            $s = shift @ss or return ();
        }
    }
}

sub concatC ($) {
    my $ss = shift; # stream
    my ($s) = $ss->() or return sub {()};
    my @v;
    sub {
        while (1) {
            @v = $s->() and return @v;
            $s = $ss->() or return ();
        }
    }
}

sub concatM (&$) {
    my ( $apply, $stream ) = @_;
    concatC apply {$apply->()} $stream;
}

# stream generators
sub cycle (@) {
    (my @ring = @_) or return sub {};
    my $index = -1;
    sub { $ring[ ( $index += 1 ) %= @ring ] }
}

sub range {
    my $begin = shift // croak "range begin undefined";
    my $end   = shift;
    my $step  = shift // 1;

    return sub { () } if $step == 0;

    $begin -= $step;
    if (defined $end) {
        if ($step > 0) {
            sub { (($begin += $step) <= $end) ? ($begin) : () }
        } else {
            sub { (($begin += $step) >= $end) ? ($begin) : () }
        }
    } else {
        sub { ($begin += $step) }
    }
}


sub tuple ($$) {
    my ( $n, $i ) = @_;
    croak "$n is not a valid parameter for tuple()" if $n <= 0;
    $i = _buffer $i;
    sub {
        my @v = fold take $n, $i;
        @v ? \@v : ();
    }
}

sub nth {
    my ( $n, $s ) = @_;
    $n--;
    take 1, drop $n, $s 
}

sub chunksOf ($$;$) {

    my ( $n, $src, $offset ) = @_;
    $n > 1 or die "chunksOf must be at least 1 (don't forget unfold)";
    $offset //= 0;

    my  ( $end   , $exhausted , $from, $to )
    =   ( $#$src , 0 );

    sub {
        return if $exhausted;

        ( $from   , $offset      )=
        ( $offset , $offset + $n );

        $end <= ($to = $offset - 1) and do {
            $exhausted=1;
            $to = $end;
        };

        [ @{$src}[$from..$to] ];
    }
}


1;

