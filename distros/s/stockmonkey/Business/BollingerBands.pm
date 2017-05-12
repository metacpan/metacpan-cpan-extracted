package Math::Business::BollingerBands;

use strict;
use warnings;
use Carp;

1;

sub tag { (shift)->{tag} }

sub recommended {
    my $class = shift;

    $class->new(20, 2);
}

sub new {
    my $class = shift;
    my $this  = bless {
        dev => [],
        val => [],
        N => undef, # days in the average
        K => undef, # deviations
    }, $class;

    if( @_ == 2 ) {
        $this->set_days($_[0]);
        $this->set_deviations($_[1]);
    }

    return $this;
}

sub set_deviations {
    my $this = shift;
    my $arg  = shift;

    croak "deviations must be a positive non-zero integer" if $arg <= 0;
    $this->{K} = $arg;

    $this->{tag} = "BOLL($this->{K},$this->{N})";
}

sub set_days {
    my $this = shift;
    my $arg  = int shift;

    croak "days must be a positive non-zero integer" if $arg <= 0;
    $this->{N} = $arg;

    $this->{val} = [];
    $this->{dev} = [];

    delete $this->{M};
    delete $this->{U};
    delete $this->{L};

    no warnings 'uninitialized';
    $this->{tag} = "BOLL($this->{K},$this->{N})";
}

sub insert {
    my $this = shift;
    my $val  = $this->{val};

    my $N = $this->{N};
    my $K = $this->{K};

    croak "You must set the number of days and deviations before you try to insert" unless $N and $K;
    while( defined(my $value = shift) ) {
        push @$val, $value;

        if( @$val >= $N ) {
            if( defined( my $s = $this->{M} ) ) {
                my $old = shift @$val;
                $this->{M} = my $M = $s - $old/$N + $value/$N;

                my @dev = map {($_-$M)**2} @$val;

                my $sum = 0;
                $sum += $_ for @dev;
                $sum /= $N;

                my $k_stddev = $K * ($sum<0.000_000_000_6 ? 0 : sqrt($sum));
                $this->{L} = $M - $k_stddev;
                $this->{U} = $M + $k_stddev;

            } else {
                my $sum = 0;
                   $sum += $_ for @$val;

                $this->{M} = my $M = $sum/$N;
                my @dev = map {($_-$M)**2} @$val;

                $sum = 0;
                $sum += $_ for @dev;
                $sum /= $N;

                my $k_stddev = $K * ($sum<0.000_000_000_6 ? 0 : sqrt($sum));
                $this->{L} = $M - $k_stddev;
                $this->{U} = $M + $k_stddev;
            }
        }
    }
}

sub query {
    my $this = shift;

    return ($this->{L}, $this->{M}, $this->{U}) if wantarray;
    return $this->{M};
}

__END__

=encoding utf-8

=head1 NAME

Math::Business::BollingerBands - Technical Analysis: Bollinger Bands

=head1 SYNOPSIS

  use Math::Business::BollingerBands;

  my $bb = new Math::Business::BollingerBands;
     $bb->set_days(20);
     $bb->set_deviations(2);

  # alternatively/equivalently
  my $bb = new Math::Business::BollingerBands(20, 2);

  # or to just get the recommended model ... (20, 2);
  my $bb = Math::Business::BollingerBands->recommended;

  my @closing_values = qw(
      3 4 4 5 6 5 6 5 5 5 5
      6 6 6 6 7 7 7 8 8 8 8
  );

  # choose one:
  $bb->insert( @closing_values );
  $bb->insert( $_ ) for @closing_values;

  my ($L,$M,$U) = $bb->query;
  if( defined $M ) {
      print "BB: $L < $M < $U.\n";

  } else {
      print "BB: n/a.\n";
  }

=head1 RESEARCHER

The Bollinger Bands were designed by John Bollinger in the 1980s.

The bands provide a high and low water mark for the closing price.
Volatility determines the width of the bands.

Conventional wisdom dictates that when prices consistently touch the upper
band they are "overbought" and when they continually touch the lower band
they are "oversold."

When the prices "bounce" off the lower band and cross the middle line, it
is thought to indicate a buy-signal.  The same (but opposite) could be said
about bouncing off the upper band and crossing the middle line on the way
down.

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

L<http://en.wikipedia.org/wiki/Bollinger_Bands>

L<http://stockcharts.com/school/doku.php?id=chart_school:technical_indicators:bollinger_bands>

=cut
