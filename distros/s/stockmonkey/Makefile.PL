# vi:set syntax=perl:

use ExtUtils::MakeMaker;

WriteMakefile(
    NAME         => 'Math::Business',
    DISTNAME     => 'stockmonkey',
    AUTHOR       => 'Paul Miller <jettero@cpan.org>',
    PREREQ_PM    => { constant => 1.05,

        # Not from StockMonkey:
        'Math::Business::Stochastic' => 0

    },
    VERSION_FROM => 'lib/Math/Business/StockMonkey.pm',

    ($ExtUtils::MakeMaker::VERSION ge '6.48'? 
        (MIN_PERL_VERSION => 5.006001,
            META_MERGE => {
                keywords => [qw(
                    ATR bollinger bands CCI DMI EMA HMA MACD RSI
                    SMA WMU ParabolicSAR Laguerre Stochastic ConnorRSI CRSI
                )],
                resources=> {
                    repository => 'http://github.com/jettero/stockmonkey',
                },
            },

        LICENSE	=> 'perl-artistic',
    ) : ()),
);
