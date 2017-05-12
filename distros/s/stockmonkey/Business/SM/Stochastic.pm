package Math::Business::SM::Stochastic;

use strict;
use warnings;
use Carp;

use Math::Business::SMA;

1;

sub tag { (shift)->{tag} }

use constant METHOD_LANE => 0;
use constant METHOD_FAST => 1;
use constant METHOD_SLOW => 2;
use constant METHOD_FULL => 3;

sub recommended { my $class = shift; return $class->new(METHOD_LANE,5,3); }

sub method_slow { my $class = shift; return $class->new(METHOD_SLOW,$_[0]||14,$_[1]||3); }
sub method_fast { my $class = shift; return $class->new(METHOD_FAST,$_[0]||14,$_[1]||3); }
sub method_full { my $class = shift; return $class->new(METHOD_FULL,$_[0]||14,$_[1]||3,$_[2]||3); }

sub new {
    my $class = shift;
    my $meth  = shift || METHOD_LANE;
    my $kp    = shift || 5;
    my $dp    = shift || 3;
    my $xp    = shift || 3;

    my $this  = bless {}, $class;

    $this->set_method( $meth );
    $this->set_days( $kp );
    $this->set_dperiod( $dp );
    $this->set_xperiod( $xp );

    return $this;
}

sub set_days { 
    my $this = shift;
    my $arg = shift;

    croak "days must be a positive non-zero integer" if $arg <= 0;

    $this->{kp} = $arg;
    $this->set_tag;
}

sub set_dperiod { 
    my $this = shift;
    my $arg = shift;

    croak "days must be a positive non-zero integer" if $arg <= 0;

    $this->{dp} = $arg;
    $this->set_tag;
}

sub set_xperiod { 
    my $this = shift;
    my $arg = shift;

    croak "days must be a positive non-zero integer" if $arg <= 0;

    $this->{xp} = $arg;
    $this->set_tag;
}

sub set_method {
    my $this = shift;
    my $meth = shift;

    croak "method not known" unless grep {$meth == $_} (METHOD_LANE, METHOD_FAST, METHOD_SLOW, METHOD_FULL);

    $this->{m} = $meth;

    delete $this->{ksma};
    delete $this->{dsma};

    $this->set_tag;

    return;
}

sub set_tag {
    my $this = shift;

    return if grep { not defined } @$this{qw(kp dp xp)};

    if( $this->{m} == METHOD_FULL ) {
        $this->{tag} = "FullSTO($this->{kp},$this->{dp},$this->{xp})";

    } elsif( $this->{m} == METHOD_FAST ) {
        $this->{tag} = "FSTO($this->{kp},$this->{dp})";

    } elsif( $this->{m} == METHOD_SLOW ) {
        $this->{tag} = "SSTO($this->{kp},$this->{dp})";

    } else {
        $this->{tag} = "STO($this->{kp},$this->{dp})";
    }
}

{
    my $method = {
        METHOD_LANE() => \&insert_lane,
        METHOD_FAST() => \&insert_fast,
        METHOD_SLOW() => \&insert_slow,
        METHOD_FULL() => \&insert_full,
    };

    sub insert {
        my $this = shift;
        my $m = $method->{$this->{m}};

        return $this->$m( @_ );
    }
}

# {{{ sub insert_lane
sub insert_lane {
    my $this = shift;

    my $l = ($this->{low_hist}  ||= []);
    my $h = ($this->{high_hist} ||= []);
    my $kp = $this->{kp};
    my $dp = $this->{dp};

    my ($K, $D);
    while( defined( my $point = shift ) ) {
        croak "insert takes three tuple (high, low, close)" unless ref $point eq "ARRAY" and @$point == 3;
        my ($t_high, $t_low, $t_close) = @$point;

        push @$l, $t_low;  shift @$l while @$l > $kp;
        push @$h, $t_high; shift @$h while @$h > $kp;

        if( @$l == $kp ) {
            my $L = $l->[0]; for( 1 .. $#$l ) { $L = $l->[$_] if $l->[$_] < $L };
            my $H = $h->[0]; for( 1 .. $#$h ) { $H = $h->[$_] if $h->[$_] > $H };

            $K = 100 * ($t_close - $L)/($H-$L);

            $L = $l->[-$dp]; for( (-$dp+1) .. -1 ) { $L = $l->[$_] if $l->[$_] < $L };
            $H = $h->[-$dp]; for( (-$dp+1) .. -1 ) { $H = $h->[$_] if $h->[$_] > $H };

            $D = 100 * $H / $L;
        }
    }

    $this->{K} = $K;
    $this->{D} = $D;

    return;
}

# }}}
# {{{ sub insert_fast
sub insert_fast {
    my $this = shift;

    my $l = ($this->{low_hist}  ||= []);
    my $h = ($this->{high_hist} ||= []);
    my $kp = $this->{kp};
    my $dp = $this->{dp};

    my $dsma = ($this->{dsma} ||= Math::Business::SMA->new($dp));

    my ($K, $D);
    while( defined( my $point = shift ) ) {
        croak "insert takes three tuple (high, low, close)" unless ref $point eq "ARRAY" and @$point == 3;
        my ($t_high, $t_low, $t_close) = @$point;

        push @$l, $t_low;  shift @$l while @$l > $kp;
        push @$h, $t_high; shift @$h while @$h > $kp;

        if( @$l == $kp ) {
            my $L = $l->[0]; for( 1 .. $#$l ) { $L = $l->[$_] if $l->[$_] < $L };
            my $H = $h->[0]; for( 1 .. $#$h ) { $H = $h->[$_] if $h->[$_] > $H };

            $K = 100 * ($t_close - $L)/($H-$L);

            $dsma->insert($K);
            $D = $dsma->query;
        }
    }

    $this->{K} = $K;
    $this->{D} = $D;

    return;
}

# }}}
# {{{ sub insert_slow
sub insert_slow {
    my $this = shift;

    my $l = ($this->{low_hist}  ||= []);
    my $h = ($this->{high_hist} ||= []);
    my $kp = $this->{kp};
    my $dp = $this->{dp};

    my $dsma = ($this->{dsma} ||= Math::Business::SMA->new($dp));
    my $ksma = ($this->{ksma} ||= Math::Business::SMA->new($dp));

    my ($K, $D);
    while( defined( my $point = shift ) ) {
        croak "insert takes three tuple (high, low, close)" unless ref $point eq "ARRAY" and @$point == 3;
        my ($t_high, $t_low, $t_close) = @$point;

        push @$l, $t_low;  shift @$l while @$l > $kp;
        push @$h, $t_high; shift @$h while @$h > $kp;

        if( @$l == $kp ) {
            my $L = $l->[0]; for( 1 .. $#$l ) { $L = $l->[$_] if $l->[$_] < $L };
            my $H = $h->[0]; for( 1 .. $#$h ) { $H = $h->[$_] if $h->[$_] > $H };

            $ksma->insert( 100 * ($t_close - $L)/($H-$L) );
            $K = $ksma->query;

            $dsma->insert($K);
            $D = $dsma->query;
        }
    }

    $this->{K} = $K;
    $this->{D} = $D;

    return;
}

# }}}
# {{{ sub insert_full
sub insert_full {
    my $this = shift;

    my $l = ($this->{low_hist}  ||= []);
    my $h = ($this->{high_hist} ||= []);
    my $kp = $this->{kp};
    my $dp = $this->{dp};
    my $xp = $this->{xp} || $this->{dp};

    my $dsma = ($this->{dsma} ||= Math::Business::SMA->new($xp));
    my $ksma = ($this->{ksma} ||= Math::Business::SMA->new($xp));

    my ($K, $D);
    while( defined( my $point = shift ) ) {
        croak "insert takes three tuple (high, low, close)" unless ref $point eq "ARRAY" and @$point == 3;
        my ($t_high, $t_low, $t_close) = @$point;

        push @$l, $t_low;  shift @$l while @$l > $kp;
        push @$h, $t_high; shift @$h while @$h > $kp;

        if( @$l == $kp ) {
            my $L = $l->[0]; for( 1 .. $#$l ) { $L = $l->[$_] if $l->[$_] < $L };
            my $H = $h->[0]; for( 1 .. $#$h ) { $H = $h->[$_] if $h->[$_] > $H };

            $ksma->insert( 100 * ($t_close - $L)/($H-$L) );
            $K = $ksma->query;

            $dsma->insert($K);
            $D = $dsma->query;
        }
    }

    $this->{K} = $K;
    $this->{D} = $D;

    return;
}

# }}}

sub query {
    my $this = shift;

    return ($this->{D}, $this->{K});
}

__END__

=encoding utf-8

=head1 NAME

Math::Business::SM::Stochastic - Technical Analysis: Stochastic Oscillator

=head1 SYNOPSIS

  use Math::Business::SM::Stochastic;

  my $sto = new Math::Business::SM::Stochastic;
     $sto->set_days(5);     # Lane uses 5 in his examples (if any)
     $sto->set_dperiod(30); # Lane
     $sto->set_method( Math::Business::SM::Stochastic::METHOD_LANE );
     # methods: METHOD_LANE, METHOD_SLOW, METHOD_FAST, METHOD_FULL
     $sto->set_xperiod(3); # used only by METHOD_FULL 


  # Lane's version
  my $sto = Math::Business::SM::Stochastic->recommended;


  # Probably more like what you expect (ie, matches up with
  # Yahoo/Google/Ameritrade, etc)

  my $sto_slow = Math::Business::SM::Stochastic->modern_slow;
  my $sto_fast = Math::Business::SM::Stochastic->modern_fast;
  my $sto_full = Math::Business::SM::Stochastic->modern_full;


  # basic usage

  $sto->insert($close);
  my ($D, $K) = $sto->query;
  my $K = $sto->query; # if you don't care about %D
  print "current stochastic: %K=$K and %D=$D\n";

=head1 RESEARCHER

The Stochastic was designed by R. George C. Lane.

It is difficult to find a good reference on this indicator.  Almost every
source disagrees with the next and some sources even disagree internally
(I'm looking at you Wikipedia).

The stochastic (among other things) purports to indicate an "overbought"
situation where the C<%K> is above 80 and "oversold" when below 20.

There are "divergences" and "convergences" to look for too, however.  If
there is a higher high or a lower low in the C<%K>, this can apperntly
indicate trend changes.  This concept is not easy to pin down explicitly,
and so is not described here.

=head1 FUTHER BACKGROUND ON COMPUTATION

The basic idea is that C<%K> should be a momentum indicator and C<%D>
should be a smoothed version of C<%K>.  Most sources generally agree that
C<%K(5)> should be computed as follows:

  $K = 100 * (close - min(@last_5_low))/(max(@last_5_high)-min(@last_5_low))

C<%D> is more sticky and various sources give various answers.   Lane
himself seemed to use:

  $D = 100 * max(@last_3_high)/min(@last_3_low)

But most charting sites and the Wikipedia seem to choose an SMA or EMA for
smothing on C<%D> and thus produce something like:

  $SMA->set_days(3);
  $SMA->insert($K);
  $D = $SMA->query;

The main problem getting this right is that Lane himself hasn't really
spelled it out in publication.  "Do this, then this, then that."  The
reason seems to be the lecture circuit.  He teaches this stuff in classes
and seminars (or tought) and hasn't really published it in the traditional
sense.

To a certain extent, we therefore feel free to pick whatever we want for
the defaults.

=head1 THANKS

Robby Oliver C<< <robbykaty@gmail.com> >>

=head1 AUTHOR

Paul Miller C<< <jettero@cpan.org> >>

I am using this software in my own projects...  If you find bugs, please please
please let me know.  There is a mailing list with very light traffic that you
might want to join: L<http://groups.google.com/group/stockmonkey/>.

=head1 WTF SM?

Well, this is the StockMonkey project afterall.  It seems
L<http://search.cpan.org/~yukinobu/> built a Stochastics module before
I did and I hadn't noticed.  In the olden days, when I first started,
I honestly expected to have a flood of these modules from dozens of
authors.  It never really happened, and when I got a request for
Stochastics ... I didn't even look first.  I just wrote one.  Fail.

I got an email from EMILY STARCK asking why my module was marked C<<
** UNAUTHORIZED RELEASE ** >>, so I renamed this module and pushed the
real L<Math::Business::Stochastic> to my C<< PREREQ_PM >>.  Problem
solved.

=head1 COPYRIGHT

Copyright © 2013 Paul Miller

=head1 LICENSE

This is released under the Artistic License. See L<perlartistic>.

=head1 SEE ALSO

perl(1), L<Math::Business::StockMonkey>, L<Math::Business::StockMonkey::FAQ>, L<Math::Business::StockMonkey::CookBook>

L<http://en.wikipedia.org/wiki/Stochastic_oscillator>

L<http://stockcharts.com/help/doku.php?id=chart_school:technical_indicators:stochastic_oscillato>

=cut
