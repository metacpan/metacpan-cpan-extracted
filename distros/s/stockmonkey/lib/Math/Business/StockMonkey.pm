# vi:syntax=perl:

package Math::Business::StockMonkey;

our $VERSION = "2.9410";

1;

=head1 NAME

Math::Business::StockMonkey - Base documentation for the StockMonkey Collection

=head1 README

The stockmonkey distribution is supposed to contain all the technical analysis
tools you'd ever want.  It has a few things, but it's sadly lacking.

Here's the tiny catalog so far:

L<Math::Business::SMA> - Simple Moving Average

L<Math::Business::EMA> - Exponential Moving Average

L<Math::Business::WMA> - Weighted Moving Average

L<Math::Business::HMA> - Hull Moving Average

L<Math::Business::LaguerreFilter> - Laguerre Filter (DSP technique)

L<Math::Business::MACD> - Moving Average Convergence/Divergence

L<Math::Business::RSI> - Relative Strength Index

L<Math::Business::BollingerBands> - Bollinger Bands

L<Math::Business::ATR> - Average True Value

L<Math::Business::DMI> - Directional Movement Index (aka ADX)

L<Math::Business::ADX> - Alias for DMI

L<Math::Business::ParabolicSAR> - Parabolic Stop and Reversal

L<Math::Business::CCI> - Commodity Channel Index

L<Math::Business::ConnorRSI> - Connor's 3 tuple average RSI with PriceRank

L<Math::Business::SM::Stochastic> -Stochastic Oscillator

=head1 CONTACT

If you'd like to help, or even just I<suggest> a module, just let me know.

Links to the algorithm are helpful as our spreadsheets with example
calculations, but they are not necessary.

I do check rt.cpan.org, so that's definitely one way to go.

L<https://rt.cpan.org/Dist/Display.html?Status=Active&Queue=stockmonkey>

If you're into things like this, you might enjoy the mailing list:

L<http://groups.google.com/group/stockmonkey/>

=head1 AUTHOR

Paul Miller C<< <jettero@cpan.org> >>

I am using this software in my own projects...  If you find bugs, please please
please let me know.  There is a mailing list with very light traffic that you
might want to join: L<http://groups.google.com/group/stockmonkey/>.

=head1 COPYRIGHT

Copyright © 2013 Paul Miller

=head1 LICENSE

This is released under the Artistic License. See L<perlartistic>.
