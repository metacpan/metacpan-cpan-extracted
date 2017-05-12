package Math::Business::DMI;

use strict;
use warnings;
use Carp;

use Math::Business::ATR;

1;

sub tag { (shift)->{tag} }

sub recommended {
    my $class = shift;

    $class->new(14);
}

sub new {
    my $class = shift;
    my $this  = bless {
        ATR => new Math::Business::ATR,
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

    $this->{ATR}->set_days($arg);
    $this->{days} = $arg;
    $this->{R}  = ($arg-1)/$arg;
    $this->{R1} = 1/$arg;

    $this->{tag} = "DMI($this->{days})";
}

sub insert {
    my $this = shift;

    my $y_point = $this->{y};
    while( defined( my $point = shift ) ) {
        croak "insert takes three tuple (high, low, close)" unless ref $point eq "ARRAY" and @$point == 3;
        my ($t_high, $t_low, $t_close) = @$point;

        if( defined $y_point ) {
            my $atr = $this->{ATR};
               $atr->insert($point);

            my ($y_high, $y_low, $y_close) = @$y_point;

            my ($PDM, $MDM) = (0,0);
            my $A = $t_high - $y_high;
            my $B = $y_low  - $t_low;

            if( $A > 0 and $A > $B ) {
                $PDM = $A;
                $MDM = 0;

            } elsif( $B > 0 and $B > $A ) {
                $PDM = 0;
                $MDM = $B;
            }

            if( defined(my $pdm = $this->{aPDM}) ) {
                my $mdm = $this->{aMDM};

                my $R  = $this->{R};
                my $R1 = $this->{R1};

                my $aPDM = $this->{aPDM} = $R * $pdm + $R1 * $PDM;
                my $aMDM = $this->{aMDM} = $R * $mdm + $R1 * $MDM;

                my $ATR = $atr->query;

                if( $ATR == 0 ) {
                    my $DX = $this->{PDI} = $this->{MDI} = 0;
                    $this->{ADX} = $R * $this->{ADX} + $R1 * $DX;

                } else {
                    my $PDI = $this->{PDI} = $aPDM / $ATR;
                    my $MDI = $this->{MDI} = $aMDM / $ATR;

                    my $DI = abs( $PDI - $MDI );
                    my $DX = $DI ? $DI / ($PDI + $MDI) : 0;
                    # 0/0 is indeterminent form, but I think 0 makes sense

                    $this->{ADX} = $R * $this->{ADX} + $R1 * $DX;
                }

            } else {
                my $p;
                my $N = $this->{days};
                if( ref($p = $this->{_p}) and (@$p >= $N-1) ) {
                    my $psum = 0;
                       $psum += $_ for @$p;
                       $psum += $PDM;

                    my $m = $this->{_m};
                    my $msum = 0;
                       $msum += $_ for @$m;
                       $msum += $MDM;

                    my $aPDM = $this->{aPDM} = $psum / $N;
                    my $aMDM = $this->{aMDM} = $msum / $N;

                    my $ATR = $atr->query;
                    if( $ATR == 0 ) {
                        $this->{PDI} = $this->{MDI} = $this->{ADX} = 0;

                    } else {
                        my $PDI = $this->{PDI} = $aPDM / $ATR;
                        my $MDI = $this->{MDI} = $aMDM / $ATR;

                        my $DI = abs( $PDI - $MDI );
                        my $DX = $DI ? $DI / ($PDI + $MDI) : 0;
                        # 0/0 is indeterminent form, but I think 0 makes sense

                        $this->{ADX} = $DX; # is this right?  No idea...  I assume this is well documented in his book
                    }

                    delete $this->{_p};
                    delete $this->{_m};

                } else {
                    push @{$this->{_p}}, $PDM;
                    push @{$this->{_m}}, $MDM;
                }
            }
        }

        $y_point = $point;
    }

    $this->{y} = $y_point;
}

sub query_pdi  { my $this = shift; return $this->{PDI}; }
sub query_mdi  { my $this = shift; return $this->{MDI}; }

sub query {
    my $this = shift;

    return ($this->{PDI}, $this->{MDI}, $this->{ADX}) if wantarray;
    return $this->{ADX};
}

__END__

=encoding utf-8

=head1 NAME

Math::Business::DMI - Technical Analysis: Directional Movement Index (aka ADX)

=head1 SYNOPSIS

  use Math::Business::DMI;

  my $dmi = new Math::Business::DMI;
     $dmi->set_days(14);

  # alternatively/equivilently
  my $dmi = new Math::Business::DMI(14);

  # or to just get the recommended model ... (14)
  my $dmi = Math::Business::DMI->recommended;

  my @data_points = (
      [ 5, 3, 4 ], # high, low, close
      [ 6, 4, 5 ],
      [ 5, 4, 4.5 ],
  );

  # choose one:
  $dmi->insert( @data_points );
  $dmi->insert( $_ ) for @data_points;

  my $adx = $dmi->query;     # ADX
  my $pdi = $dmi->query_pdi; # +DI
  my $mdi = $dmi->query_mdi; # -DI

  # or
  my ($pdi, $mdi, $adx) = $dmi->query;

  if( defined $adx ) {
      print "ADX: $adi.\n";

  } else {
      print "ADX: n/a.\n";
  }

=head1 RESEARCHER

The ADX/DMI was designed by J. Welles Wilder Jr circa 1978.

The +DI and -DI signals measure the force of directional changes.  When the
+DI crosses above the -DI it may indicate that it's time to buy and when
the -DI crosses above the +DI it may be time to sell.

The ADX tries to combine the two.  It may indicate the strength of the
current trend (but not it's direction).  When it moves above 20 it may be
the beginning of a trend and when it falls below 40, it may be the end of
it.

The DMI uses the ATR to try to measure volatility.

NOTE: The +DI, -DI and ADX returned by this module are probabilities ranging
from 0 to 1.  Most sources seem to show the DMI values as numbers from 0 to
100.  Simply multiply the three tuple by 100 to get this result.

    my @DMI = map { 100*$_ } = $dmi->query;

=head1 AUTHOR

Paul Miller C<< <jettero@cpan.org> >>

I am using this software in my own projects...  If you find bugs, please please
please let me know.  There is a mailing list with very light traffic that you
might want to join: L<http://groups.google.com/group/stockmonkey/>.

=head1 COPYRIGHT

Copyright © 2013 Paul Miller

=head1 LICENSE

This is released under the Artistic License. See L<perlartistic>.

=head1 THANKS

BobBack C<< <drchap...@gmail.com> >>

=head1 SEE ALSO

perl(1), L<Math::Business::StockMonkey>, L<Math::Business::StockMonkey::FAQ>, L<Math::Business::StockMonkey::CookBook>

L<http://fxtrade.oanda.com/learn/graphs/indicators/adx.shtml>

=cut
