package Math::Business::ParabolicSAR;

use strict;
use warnings;
use Carp;
use constant {
    LONG  => 7,
    SHORT => 9,
    HP    => 1,
    LP    => 0,
};

1;

sub tag { (shift)->{tag} }

sub recommended {
    my $class = shift;
       $class->new(0.02, 0.20);
}

sub new {
    my $class = shift;
    my $this  = bless {e=>[], y=>[]}, $class;

    if( @_ ) {
       eval { $this->set_alpha(@_) };
       croak $@ if $@;
    }

    return $this;
}

sub set_alpha {
    my $this = shift;
    my ($as,$am) = @_;

    croak "set_alpha(as,am) takes two arguments, the alpha start (0<as<1) and the alpha max (0<as<am<1)"
        unless 0 < $as and $as < $am and $am < 1;

    $this->{as} = $as;
    $this->{am} = $am;

    $this->{tag} = "PSAR($as,$am)";

    return;
}

sub insert {
    my $this = shift;

    my ($as,$am);
    croak "must set_alpha(as,am) before inserting data" unless defined( $am = $this->{am} ) and defined( $as = $this->{as} );

    my ($y_low, $y_high) = @{$this->{y}};
    my ($open,$high,$low,$close);

    my $S;
    my $P = $this->{S};
    my $A = $this->{A};
    my $e = $this->{e};

    my $ls = $this->{ls};

    while( defined( my $ar = shift ) ) {
        croak "arguments to insert must be four tuple (open,high,low,close) with high greater than or equal to low"
            unless ref($ar) eq "ARRAY" and @$ar==4 and $ar->[2]<=$ar->[1];

        # NOTE: we really only use open and close to initialize ...
        ($open,$high,$low,$close) = @$ar;

        if( defined $ls ) {
            # calculate sar_t
            # The Encyclopedia of Technical Market Indicators - Page 495

            my @oe = @$e;
            $e->[HP] = $high if $high > $e->[HP]; # the highest point during the trend
            $e->[LP] = $low  if $low  < $e->[LP]; # the  lowest point during the trend

            if( $ls == LONG ) {
                $S = $P + $A*($e->[HP] - $P); # adjusted upwards from the reset like so

                # NOTE: many sources say you should flop short/long if you get
                # inside the price range for the last *two* periods.  Amazon,
                # Yahoo! and stockcharts dont' seem to do it that way.

                if( $S > $low ) {
                    $ls = SHORT; # new short position

                    $S  = $e->[HP];
                    $A  = $as;

                    $e->[HP] = ($high>$y_high ? $high : $y_high);
                    $e->[LP] = ($low <$y_low  ? $low  : $y_low );

                } elsif( $S > $y_low ) {
                    $S = $y_low;

                } elsif( $oe[HP] != $e->[HP] ) {
                    $A += $as;
                    $A = $am if $A > $am;
                }

            } else {
                $S = $P + $A*($e->[LP] - $P); # adjusted downwards from the reset like so

                # NOTE: many sources say you should flop short/long if you get
                # inside the price range for the last *two* periods.  Amazon,
                # Yahoo! and stockcharts dont' seem to do it that way.

                if( $S < $high ) {
                    $ls = LONG; # new long position

                    $S  = $e->[LP];
                    $A  = $as;

                    $e->[HP] = ($high>$y_high ? $high : $y_high);
                    $e->[LP] = ($low <$y_low  ? $low  : $y_low );

                } elsif( $S < $y_high ) {
                    $S = $y_high;

                } elsif( $oe[LP] != $e->[LP] ) {
                    $A += $as;
                    $A = $am if $A > $am;
                }
            }

        } else {
            # circa 2010: initialize somehow
            # (never did find a good description of how to initialize this mess.
            #   I think you're supposed to tell it how to start)
            # this is the only time we use open/close and it's not even in the definition
            #
            # 2011-01-03: I did look this up, it's the "SIP" or significant
            # point.  It should be the lowest (or the highest) point we have
            # from our recent-ish data or "long trade" as he calls it.  This'll
            # do as an approximation of that imo — otherwise we'll have to
            # start asking for a few days previous trades just to initialize.

            $A = $as;

            if( $open < $close ) {
                $ls = LONG;
                $S  = $low;

            } else {
                $ls = SHORT;
                $S  = $high;
            }

            $e->[HP] = $high;
            $e->[LP] = $low;
        }

        $P = $S;

        ($y_low, $y_high) = ($low, $high);
    }

    ## DEBUG ## warn "{S}=$S; {A}=$A";

    $this->{S}  = $S;
    $this->{A}  = $A;
    $this->{ls} = $ls;

    @{$this->{y}} = ($y_low, $y_high);
}

sub query {
    my $this = shift;

    $this->{S};
}

sub long {
    my $this = shift;
    $this->{ls} == LONG;
}

sub short {
    my $this = shift;
    $this->{ls} == SHORT;
}

__END__

=encoding utf-8

=head1 NAME

Math::Business::ParabolicSAR - Technical Analysis: Stop and Reversal (aka SAR)

=head1 SYNOPSIS

  use Math::Business::ParabolicSAR;

  my $sar = new Math::Business::ParabolicSAR;
     $sar->set_alpha(0.02, 0.2);

  # alternatively/equivilently
  my $sar = new Math::Business::ParabolicSAR(0.02, 0.2);

  # or to just get the recommended model ... (0.02, 0.2)
  my $sar = Math::Business::ParabolicSAR->recommended;

  my @data_points = (
      ["35.0300", "35.1300", "34.3600", "34.3900"],
      ["34.6400", "35.0000", "34.2100", "34.7400"],
      ["34.6900", "35.1400", "34.3800", "34.7900"],
      ["35.2900", "35.7900", "35.0800", "35.5200"],
      ["35.9000", "36.0600", "35.7500", "36.0600"],
      ["36.1300", "36.7200", "36.0500", "36.5800"],
      ["36.4100", "36.6400", "36.2600", "36.6100"],
      ["36.3500", "36.5500", "35.9400", "35.9700"],
  );

  # choose one:
  $sar->insert( @data_points );
  $sar->insert( $_ ) for @data_points;

  my $sar = $sar->query;
  print "SAR: $sar\n";

  # Briefly, the SAR is below the price data when you're meant to
  # be holding stocks (long) and above it when you're meant to be
  # on margin (short).

  print "The SAR is long  today.\n" if $sar->long;
  print "The SAR is short today.\n" if $sar->short;

=head1 RESEARCHER

The Parabolic Stop and Reversal was designed by J. Welles Wilder Jr circa 1978.

The SAR is meant to be used to "stop loss" on a position.  It assumes you always
have a position in the market (long if you're holding stocks and short when
you're on margin).  When the SAR crosses the price data, it signals a sell (when
you're long) or a buy (when you're short).

Wilder himself felt the SAR was particularly vulnerable to "whipsaws" and
recommended only using the SAR when the ADX is above 30 -- that is, when there
is a strong trend going.

=head1 THANKS

Gustav C<< <gustavf@gmail.com> >>

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

L<http://en.wikipedia.org/wiki/Parabolic_SAR>

The Encyclopedia of Technical Market Indicators - Page 495

=cut
