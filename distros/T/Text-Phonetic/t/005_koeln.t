# -*- perl -*-

# t/005_koeln.t - Test koelner phonetik

use Test::Most tests=>82+1;
use Test::NoWarnings;
use utf8;

use Text::Phonetic::Koeln;

my $cologne = Text::Phonetic::Koeln->new();

require "t/global.pl";

my %TEST = (
    'wikipedia'             => '3412',
    'müller-lüdenscheidt'   => '65752682',
    'breschnew'             => '17863',
    'müller'                => '657',
    'schmidt'               => '862', # or 8628?
    'schneider'             => '8627',
    'fischer'               => '387',
    'auerbach'              => '0714',
    'ohrbach'               => '0714',
    'moskowitz'             => '68438',
    'moskovitsch'           => '68438',
    'ceniow'                => '863',
    'tsenyuv'               => '863',
    'weber'                 => '317',
    'beier'                 => '17',
    'maier'                 => '67',
    'major'                 => '67',
    'meyer'                 => '67',
    'wagner'                => '3467', # or 367?
    'schulz'                => '858', # or 85?
    'becker'                => '147',
    'hoffmann'              => '0366',
    'schäfer'               => '837',
    'cater'                 => '427',
    'axel'                  => '0485',

    # C as initial sound before A, H, K, L, O, Q, R, U, X = '4'
    'ca'                    => '4',
    'ch'                    => '4',
    'ck'                    => '4',
    'cl'                    => '45',
    'co'                    => '4',
    'cq'                    => '4',
    'cr'                    => '47',
    'cu'                    => '4',
    'cx'                    => '48',

    # Ca as initial sound NOT before A, H, K, L, O, Q, R, U, X = '8'
    'cb'                    => '81',
    'cc'                    => '8',
    'cd'                    => '82',
    'ce'                    => '8',
    'cf'                    => '83',
    'cg'                    => '84',
    'ci'                    => '8',
    'cj'                    => '8',
    'cm'                    => '86',
    'cn'                    => '86',
    'cp'                    => '81',
    'cs'                    => '8',
    'ct'                    => '82',
    'cv'                    => '83',
    'cw'                    => '83',
    'cy'                    => '8',
    'cz'                    => '8',
    # C after S, Z = '8'
    'sc'                    => '8',
    'zc'                    => '8',
    'scx'                   => '8',
    'zcx'                   => '8',

    # C before A, H, K, O, Q, U, X but NOT after S, Z = '4'
    'bca',                  => '14',
    'bch',                  => '14',
    'bck',                  => '14',
    'bco',                  => '14',
    'bcq',                  => '14',
    'bcu',                  => '14',
    'bcx',                  => '148',
    # c notb efore a, h, k, o, q, u, x = '8'
    'bcb',                  => '181',
    'bcc',                  => '18',
    'bcd',                  => '182',
    'bce',                  => '18',
    'bcf',                  => '183',
    'bcg',                  => '184',
    'bci',                  => '18',
    'bcj',                  => '18',
    'bcl',                  => '185',
    'bcm',                  => '186',
    'bcn',                  => '186',
    'bcp',                  => '181',
    'bcr',                  => '187',
    'bcs',                  => '18',
    'bct',                  => '182',
    'bcv',                  => '183',
    'bcw',                  => '183',
    'bcy',                  => '18',
    'bcz',                  => '18',
);

isa_ok($cologne,'Text::Phonetic::Koeln');
while (my($key,$value) = each(%TEST)) {
    test_encode($cologne,$key,$value);
}





