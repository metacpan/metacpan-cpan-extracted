package Math::Business::ATR;

use strict;
use warnings;
use Carp;

1;

sub tag { (shift)->{tag} }

sub recommended {
    my $class = shift;

    $class->new(14);
}

sub new {
    my $class = shift;
    my $this  = bless {
    }, $class;

    my $days = shift;
    if( defined $days ) {
        $this->set_days( $days );
    }

    return $this;
}

sub set_days {
    my $this = shift;
    my $arg  = int(shift);

    croak "days must be a positive non-zero integer" if $arg <= 0;

    $this->{tag} = "ATR($arg)";

    # NOTE: wilder uses 13/14 * last + 1/14 * current for his exponential average ...
    # probably wouldn't have been my first choice, but that's how ATR is defined.

    $this->{days} = $arg;
    $this->{R1}  = ($arg-1)/$arg;
    $this->{R} = 1/$arg;
}

sub insert {
    my $this = shift;

    my $y_close = $this->{y_close};
    while( defined( my $point = shift ) ) {
        croak "insert takes three tuple [high, low, close]" unless ref $point eq "ARRAY" and @$point == 3;
        my ($t_high, $t_low, $t_close) = @$point;

        if( defined $y_close ) {
            my $A = abs( $t_high - $t_low );
            my $B = abs( $t_high - $y_close );
            my $C = abs( $t_low  - $y_close );

            my $true_range = $A;
               $true_range = $B if $B > $true_range;
               $true_range = $C if $C > $true_range;

            if( defined(my $atr = $this->{ATR}) ) {
                $this->{ATR} = $this->{R1} * $atr + $this->{R} * $true_range;

            } else {
                my $p;
                my $N = $this->{days};
                if( ref($p = $this->{_p}) and (@$p >= $N-1) ) {
                    my $sum = 0;
                       $sum += $_ for @$p;
                       $sum += $true_range;

                    $this->{ATR} = $sum / $N;
                    delete $this->{_p};

                } else {
                    push @{$this->{_p}}, $true_range;
                }
            }

        } else {
            my $true_range = $t_high - $t_low;

            # NOTE: _p shouldn't exist because this initializer is only used for the very first entry
            die "something is clearly wrong, see note below above line" if exists $this->{_p};

            # NOTE: this initializer sucks because the calculation is done
            # differently than it would be if you had data from the day before.
            # IMO, we should just return undef for an extra day, but this
            # appears to be by definition, so we do it:

            $this->{_p} = [$true_range];
        }

        $y_close = $t_close;
    }

    $this->{y_close} = $y_close;
}

sub query {
    my $this = shift;

    return $this->{ATR};
}

__END__

=encoding utf-8

=head1 NAME

Math::Business::ATR - Technical Analysis: Average True Range

=head1 SYNOPSIS

  use Math::Business::ATR;

  my $atr = new Math::Business::ATR;
     $atr->set_days(14);

  # alternatively/equivilently
  my $atr = new Math::Business::ATR(14);

  # or to just get the recommended model ... (14)
  my $atr = Math::Business::ATR->recommended;

  my @data_points = (
      [ 5, 3, 4 ], # high, low, close
      [ 6, 4, 5 ],
      [ 5, 4, 4.5 ],
  );

  # choose one:
  $atr->insert( @data_points );
  $atr->insert( $_ ) for @data_points;

  my $atr = $atr->query;

  if( defined( my $q = $atr->query ) ) {
      print "ATR: $q.\n";

  } else {
      print "ATR: n/a.\n";
  }

=head1 RESEARCHER

The ATR was designed by J. Welles Wilder Jr circa 1978.

The ATR is meant to be a measure of the volatility of the stock price.  It
does not provide any indication of the direction of the moves, only how
erratic the moves may be.

Wilder felt that large ranges meant traders are willing to I<continue>
bidding up (or selling down) a stock.

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

perl(1), L<Math::Business::StockMonkey>, L<Math::Business::StockMonkey::FAQ>, L<Math::Business::StockMonkey::CookBook>

L<http://fxtrade.oanda.com/learn/graphs/indicators/atr.shtml>

=cut
