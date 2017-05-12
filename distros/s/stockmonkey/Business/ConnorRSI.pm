package Math::Business::ConnorRSI;

use strict;
use warnings;
use Carp;

use Math::Business::RSI;

1;

sub tag { (shift)->{tag} }

sub recommended { (shift)->new() }

sub new {
    my $class = shift;
    my $this = bless {}, $class;

    $this->set_cdays(shift ||   3);
    $this->set_sdays(shift ||   2);
    $this->set_pdays(shift || 100);

    $this->{cRSI} = Math::Business::RSI->new($this->{cdays});
    $this->{sRSI} = Math::Business::RSI->new($this->{sdays});

    return $this;
}

sub reset {
    my $this = shift;

    delete $this->{cy};
    delete $this->{st};

    $this->{cRSI} = Math::Business::RSI->new($this->{cdays}) if exists $this->{cRSI};
    $this->{sRSI} = Math::Business::RSI->new($this->{sdays}) if exists $this->{sRSI};
    $this->{prar} = [];
}

sub set_cdays {
    my $this = shift;
    my $arg  = int(shift);

    croak "days must be a positive non-zero integer" if $arg <= 0;

    $this->{cdays} = $arg;
    $this->{tag} = "CRSI($this->{cdays},$this->{sdays},$this->{pdays})"
       unless grep {not defined} @$this{qw(cdays sdays pdays)};

    $this->reset;
}

sub set_sdays {
    my $this = shift;
    my $arg  = int(shift);

    croak "days must be a positive non-zero integer" if $arg <= 0;

    $this->{sdays} = $arg;
    $this->{tag} = "CRSI($this->{cdays},$this->{sdays},$this->{pdays})"
       unless grep {not defined} @$this{qw(cdays sdays pdays)};

    $this->reset;
}

sub set_pdays {
    my $this = shift;
    my $arg  = int(shift);

    croak "days must be a positive non-zero integer" if $arg <= 0;

    $this->{pdays} = $arg;
    $this->{tag} = "CRSI($this->{cdays},$this->{sdays},$this->{pdays})"
       unless grep {not defined} @$this{qw(cdays sdays pdays)};

    $this->reset;
}

sub insert {
    my $this = shift;
    my $close_yesterday = $this->{cy};
    my $streak          = $this->{st} || 0;

    my $sRSI  = $this->{sRSI};
    my $cRSI  = $this->{cRSI};
    my $prar  = $this->{prar};
    my $pdays = $this->{pdays};

    # we store 1 extra so we can compare $pdays values
    my $pdaysp1 = $pdays + 1;

    while( defined( my $close_today = shift ) ) {
        if( defined $close_yesterday ) {
            if( $close_yesterday > $close_today ) {
                $streak = $streak >= 0 ? -1 : $streak-1;

            } elsif( $close_yesterday < $close_today ) {
                $streak = $streak <= 0 ? 1 : $streak+1;

            } else {
                $streak = 0;
            }

            $sRSI->insert($streak);

            push @$prar, ($close_today - $close_yesterday)/$close_yesterday;
            shift @$prar while @$prar > $pdaysp1;
        }

        $cRSI->insert($close_today);

        $close_yesterday = $close_today;
    }

    $this->{srsi} = my $srsi = $sRSI->query;
    $this->{crsi} = my $crsi = $cRSI->query;

    if( defined $srsi and defined $crsi and @$prar==$pdaysp1 ) {
        my $v = $prar->[-1];
        my $p = 0;
        my $i = $#$prar;

        # we skip the first one, cuz that's $v
        while( (--$i) >= 0 ) {
            $p ++ if $prar->[$i] < $v;
        }

        $this->{prank} = my $PR = 100 * ($p/$pdays);
        $this->{connor} = ( $srsi + $crsi + $PR ) / 3;
    }

    $this->{cy} = $close_yesterday;
    $this->{st} = $streak;
}

sub query {
    my $this = shift;

    return $this->{connor};
}

__END__

=encoding utf-8

=head1 NAME

Math::Business::ConnorRSI - Technical Analysis: Connor's 3 tuple average RSI with PriceRank

=head1 SYNOPSIS

  use Math::Business::ConnorRSI;

  my $rsi = Math::Business::ConnorRSI->new(3,2,100);

  # Equivalent set functions
  $rsi->set_cdays(3);
  $rsi->set_sdays(2);
  $rsi->set_pdays(100);

  # or to just use the recommended settings (3,2,100)
  my $rsi = Math::Business::RSI->recommended;

  my @closing_values = qw(
      3 4 4 5 6 5 6 5 5 5 5
      6 6 6 6 7 7 7 8 8 8 8
  );

  # choose one:
  $rsi->insert( @closing_values );
  $rsi->insert( $_ ) for @closing_values;

  if( defined(my $q = $rsi->query) ) {
      print "CRSI: $q.\n";

  } else {
      print "CRSI: n/a.\n";
  }

=head1 RESEARCHER

The RSI was designed by Connors Research, LLC 2012

Connor desired to combine information about price momentum (via traditional RSI)
relative price magnitude information (called PriceRank) and information about
price rate streaks (an RSI of the streak information).

The way he has constructed it, the informations are all on the same scale (0
through 100), and he then combines them in the natural way: a mean.

   $close_rsi = RSI(close,3); # nothing unusual about this
   # this is the first parameter, or set_cdays()

Streaks are ore confusing.  They are constructed as follows.

    if( $close_yesterday < $close_today ) {
        $streak = $streak >= 0 ? -1 : $streak-1;

    } elsif( $close_yesterday > $close_today ) {
        $streak = $streak <= 0 ? 1 : $streak+1;

    } else {
        $streak = 0;
    }

Such that, if our closing values are 20, 20.5, 20.75, 19.75, 19.5... our state
would be: undef, 1, 2, -1, -2.  This streak stream is then fed to another RSI
object:

   $streak_rsi = RSI(streak,2);
   # this size is set via set_sdays()

Lastly, his PriceRank value is determined as a percent winning rate of change.
Say we have an array like so:

    @items = (
      (20.5-20)/20,
      (20.75-20.5)/20.5,
      (19.75-20.75)/20.75,
      (19.5-19.75)/19.75,
    );

Suppose we get a closing value today of 20.  Then the price rank would be
computed as follows:

    $today_rank = (20-19.75)/19.75;
    $items_beat = 0;
    for(@items) {
        $items_beat ++ if $today_rank > $_;
    }

    $PriceRank = 100 * ( $items_beat / @items );

Finally, we compute CRSI as the average of these three items:

    $CRSI = ( $PriceRank + $close_rsi + $streak_rsi ) / 3;

The interpretation is rather similar to the standard RSI.  If the CRSI is above
some threshold, it is considered overbought.  If it is below some threshold,
then it is oversold.  He states that this method adapts very quickly and has a
high level of accuracy.  His original paper has many charts to suport this
conclusion.

=head1 THANKS

Robby Oliver C<< <robbykaty@gmail.com> >>

=head1 AUTHOR

Paul Miller C<< <jettero@cpan.org> >>

I am using this software in my own projects...  If you find bugs, please please
please let me know.  There is a mailing list with very light traffic that you
might want to join: L<http://groups.google.com/group/stockmonkey/>.

=head1 COPYRIGHT

Copyright © 2013 Paul Miller

=head1 LICENSE

This is released under the Artistic License. See L<perlartistic>.

=head1 SEE ALSO

perl(1), L<Math::Business::RSI>, L<Math::Business::StockMonkey>, L<Math::Business::StockMonkey::FAQ>, L<Math::Business::StockMonkey::CookBook>

"An Introduction to ConnorsRSI" by Connors Research, LLC, 2012

=cut
