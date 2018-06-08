package Math::Business::CCI;

use strict;
use warnings;
use Carp;

use Math::Business::SMA;

1;

sub tag { (shift)->{tag} }

sub recommended { croak "no recommendation" }

sub new {
    my $class = shift;
    my $days  = shift || 20;
    my $mul   = shift || 0.015;

    my $this  = bless {
        sma => Math::Business::SMA->new($days),
    }, $class;

    $this->set_days($days);
    $this->set_scale($mul);

    return $this;
}

sub set_days { 
    my $this = shift;
    my $arg = shift;

    croak "days must be a positive non-zero integer" if $arg <= 0;

    $this->{sma}->set_days($arg);
    $this->{len} = $arg;

    return unless exists $this->{mul};
    my $s = sprintf("%0.0f", 1/$this->{mul});
    $this->{tag} = "CCI($arg,$s)";
}

sub set_scale {
    my $this  = shift;
    my $scale = shift;

    # NOTE: "Lambertset the constant at 0.015 to ensure that approximately 70
    # to 80 percent of CCI values would fall between −100 and +100"

    $this->{mul} = 1/$scale;

    return unless exists $this->{len};
    my $s = sprintf("%0.0f", $scale);
    $this->{tag} = "CCI($this->{len},$s)";
}

sub insert {
    my $this = shift;
    my $sma = $this->{sma};
    my $mul = $this->{mul};
    my $len = $this->{len};

    my $hist = ($this->{pt_hist} ||= []);

    my $cci;
    while( defined( my $point = shift ) ) {
        croak "insert takes three tuple (high, low, close)" unless ref $point eq "ARRAY" and @$point == 3;
        my ($t_high, $t_low, $t_close) = @$point;
        my $pt = ($t_high + $t_low + $t_close) / 3;

        push @$hist, $pt;
        shift @$hist while @$hist > $len;

        $sma->insert( $pt );
        if( defined (my $v = $sma->query) ) {
            my @mad = map { abs($v - $_) } @$hist;
            my $mad = shift @mad;
               $mad += $_ for @mad;
               $mad /= @mad+1;

            if( @$hist == $len ) {
                $cci = $mul * ( $pt - $v ) / $mad;
            }
        }
    }

    $this->{CCI} = $cci;

    return;
}

sub query {
    my $this = shift;

    return $this->{CCI};
}

__END__

=encoding utf-8

=head1 NAME

Math::Business::CCI - Technical Analysis: Commodity Channel Index

=head1 SYNOPSIS

  use Math::Business::CCI;

  my $rsi = new Math::Business::CCI;
     $rsi->set_scale(0.015); # Lambert used 0.015, which is default
     $rsi->set_days(20);     # defaults to 20, no recommendation

=head1 RESEARCHER

The CCI was designed by Donald Lambert circa 1980.

The index is meant to indicate oversold and overbought status.  Numbers over
100 are called “overbought” and numbers under -100 are called “oversold.”
Longer periods will result in less spikes above and below these thresholds.

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

perl(1), L<Math::Business::StockMonkey>, L<Math::Business::StockMonkey::FAQ>, L<Math::Business::StockMonkey::CookBook>

L<http://en.wikipedia.org/wiki/Relative_Strength_Index>

=cut
