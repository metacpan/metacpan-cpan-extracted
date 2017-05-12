package Math::Business::RSI;

use strict;
use warnings;
use Carp;

use Math::Business::SMA;
use Math::Business::EMA;

1;

sub tag { (shift)->{tag} }

sub recommended {
    my $class = shift;

    $class->new(14);
}

sub new {
    my $class = shift;
    my $this  = bless {
        U   => Math::Business::EMA->new,
        D   => Math::Business::EMA->new,
        RSI => undef,
        cy  => undef,
    }, $class;

    my $alpha = shift;
    if( defined $alpha ) {
        $this->set_alpha( $alpha );
    }

    return $this;
}

sub set_alpha {
    my $this  = shift;
    my $alpha = shift;

    # NOTE: this alpha is different than you might think ... it's really inverse alpha
    # Wilder uses alpha=14 instead of alpha=(1/14) like you might expect

    my $days = 2*$alpha - 1; # so days is 2*$alpha-1 instead of the expected 2*(1/$alpha)-1

    eval { $this->set_days( $days ) };
    croak "set_alpha() is basically set_days(2*$alpha-1), which complained: $@" if $@;
    $this->set_tag;
}

sub set_standard {
    my $this = shift;
    my $rm   = ref $this->{U};

    if( $rm =~ m/SMA/ ) {
        $this->{U} = Math::Business::EMA->new;
        $this->{D} = Math::Business::EMA->new;

        if( my $d = $this->{days} ) {
            $this->set_days($d);
        }
    }
    $this->set_tag;
}

sub set_cutler {
    my $this = shift;
    my $rm   = ref $this->{U};

    if( $rm =~ m/EMA/ ) {
        $this->{U} = Math::Business::SMA->new;
        $this->{D} = Math::Business::SMA->new;

        if( my $d = $this->{days} ) {
            $this->set_days($d);
        }
    }
    $this->set_tag;
}

sub set_days {
    my $this = shift;
    my $arg  = int(shift);

    croak "days must be a positive non-zero integer" if $arg <= 0;

    $this->{U}->set_days($this->{days} = $arg);
    $this->{D}->set_days($arg);
    delete $this->{cy};
    delete $this->{RSI};
    $this->set_tag;
}

sub set_tag {
    my $this = shift;

    if( $this->{U}->isa("Math::Business::EMA") ) {
        $this->{tag} = "RSI($this->{days})";

    } else {
        $this->{tag} = "RSI($this->{days},cutler)";
    }
}

sub insert {
    my $this = shift;
    my $close_yesterday = $this->{cy};

    my $EMA_U = $this->{U};
    my $EMA_D = $this->{D};

    croak "You must set the number of days before you try to insert" if not $this->{days};
    while( defined( my $close_today = shift ) ) {
        if( defined $close_yesterday ) {
            my $delta = $close_today - $close_yesterday;

            my ($U,$D) = (0,0);
            if( $delta > 0 ) {
                $U = $delta;
                $D = 0;

            } elsif( $delta < 0 ) {
                $U = 0;
                $D = abs $delta;
            }

            $EMA_U->insert($U);
            $EMA_D->insert($D);
        }

        if( defined(my $eu = $EMA_U->query) ) {
            my $ed = $EMA_D->query;
            my $rs = (($ed == 0) ? 100 : $eu/$ed ); # NOTE: This is by definition apparently.

            $this->{RSI} = 100 - 100/(1+$rs);
        }

        $close_yesterday = $close_today;
    }

    $this->{cy} = $close_yesterday;
}

sub query {
    my $this = shift;

    return $this->{RSI};
}

__END__

=encoding utf-8

=head1 NAME

Math::Business::RSI - Technical Analysis: Relative Strength Index

=head1 SYNOPSIS

  use Math::Business::RSI;

  my $rsi = new Math::Business::RSI;
     $rsi->set_alpha(14); # issues a set days of 2*14-1
     $rsi->set_days(27);  # equivilent to set_alpha(14)

  # equivelent to set_days(27)/set_alpha(14):
  my $rsi = new Math::Business::RSI(14);

  # or to just get the recommended model ... set_alpha(14)
  my $rsi = Math::Business::RSI->recommended;

  my @closing_values = qw(
      3 4 4 5 6 5 6 5 5 5 5
      6 6 6 6 7 7 7 8 8 8 8
  );

  # choose one:
  $rsi->insert( @closing_values );
  $rsi->insert( $_ ) for @closing_values;

  if( defined(my $q = $rsi->query) ) {
      print "RSI: $q.\n";

  } else {
      print "RSI: n/a.\n";
  }

=head1 RESEARCHER

The RSI was designed by J. Welles Wilder Jr in 1978.

According to Wilder, a security is "overbought" it the RSI reaches an upper
bound of 70 and is "oversold" when it moves below 30.  Some sources also
use thresholds of 80 and 20.

Therefore, moving above the upper threshold is a selling signal, whlie moving
below the lower threshold is a signal to buy.

Oddly, RSI(14) uses a "smoothing period" of 14 days -- referring to an alpha of
1/14.  This means the EMA[N]u/EMA[N]d has N set to 27.  This also means the
alpha is upside of other alpha you might see.  RSI(14) actually uses an alpha
of ~0.0714, but set_alpha() takes the inverse to make C<$rsi->set_alpha(14)>
work.

If all of the above seems really confusing, no worries: RSI(14) means
C<set_alpha(14)> (or C<new(14)> and is equivelent to C<set_days(27)>.

=head2 Cutler

There are differing schools of thought on how to calculate this and how
important it is to stick to precisely the formula Wilder used.  Cutler used
simple moving averages instead of exponential moving averages.

You can switch between Wilder and Cutler mode with these:

    $rsi->set_cutler; # for simple moving averages
    $rsi->set_standard; # for exponential moving averages

WARNING: Both of these clear out the value queue!  If you need to track
both, you'll need two objects.

=head1 THANKS

Todd Litteken C<< <cl@xganon.com> >>

Amit Dutt C<< <amit_dutt@hotmail.com> >>

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

L<http://en.wikipedia.org/wiki/Relative_Strength_Index>

=cut
