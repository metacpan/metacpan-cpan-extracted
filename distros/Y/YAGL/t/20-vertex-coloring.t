#!perl

use strict;
use warnings;
use experimentals;
use lib 'lib';
use Test::More tests => 7;
use YAGL;
use Cwd;

my $cwd = getcwd;

my $g = YAGL->new;

$g->read_csv("$cwd/t/20-vertex-coloring-00.csv");

ok( !$g->is_colored, "G is not yet colored, as expected." );

$g->color_vertices;

ok( $g->is_colored > 0, "G is now colored, as expected." );

my @expected = (
    [
        'am3718',
        {
            'color' => 'green'
        }
    ],
    [
        'an3688',
        {
            'color' => 'green'
        }
    ],
    [
        'bs8927',
        {
            'color' => 'blue'
        }
    ],
    [
        'bt4888',
        {
            'color' => 'red'
        }
    ],
    [
        'cr7531',
        {
            'color' => 'green'
        }
    ],
    [
        'cy5439',
        {
            'color' => 'red'
        }
    ],
    [
        'da472',
        {
            'color' => 'red'
        }
    ],
    [
        'fc9060',
        {
            'color' => 'blue'
        }
    ],
    [
        'fi4998',
        {
            'color' => 'blue'
        }
    ],
    [
        'fn135',
        {
            'color' => 'green'
        }
    ],
    [
        'fr3202',
        {
            'color' => 'red'
        }
    ],
    [
        'fv4507',
        {
            'color' => 'blue'
        }
    ],
    [
        'gl7784',
        {
            'color' => 'green'
        }
    ],
    [
        'gs7946',
        {
            'color' => 'green'
        }
    ],
    [
        'hi5396',
        {
            'color' => 'green'
        }
    ],
    [
        'is9454',
        {
            'color' => 'green'
        }
    ],
    [
        'jb5701',
        {
            'color' => 'green'
        }
    ],
    [
        'kg4166',
        {
            'color' => 'blue'
        }
    ],
    [
        'kh8290',
        {
            'color' => 'green'
        }
    ],
    [
        'kq1653',
        {
            'color' => 'green'
        }
    ],
    [
        'kr4059',
        {
            'color' => 'blue'
        }
    ],
    [
        'kv4941',
        {
            'color' => 'blue'
        }
    ],
    [
        'kw6581',
        {
            'color' => 'blue'
        }
    ],
    [
        'ky8701',
        {
            'color' => 'red'
        }
    ],
    [
        'lf2991',
        {
            'color' => 'green'
        }
    ],
    [
        'lv4411',
        {
            'color' => 'green'
        }
    ],
    [
        'ly7453',
        {
            'color' => 'green'
        }
    ],
    [
        'mb5499',
        {
            'color' => 'green'
        }
    ],
    [
        'my4137',
        {
            'color' => 'green'
        }
    ],
    [
        'my8558',
        {
            'color' => 'green'
        }
    ],
    [
        'nj32',
        {
            'color' => 'red'
        }
    ],
    [
        'nj6315',
        {
            'color' => 'red'
        }
    ],
    [
        'nm3498',
        {
            'color' => 'green'
        }
    ],
    [
        'nr2297',
        {
            'color' => 'red'
        }
    ],
    [
        'oc9696',
        {
            'color' => 'red'
        }
    ],
    [
        'pa3375',
        {
            'color' => 'red'
        }
    ],
    [
        'pb4824',
        {
            'color' => 'green'
        }
    ],
    [
        'qb9390',
        {
            'color' => 'red'
        }
    ],
    [
        'qc9454',
        {
            'color' => 'green'
        }
    ],
    [
        'qj9767',
        {
            'color' => 'red'
        }
    ],
    [
        'qm7274',
        {
            'color' => 'red'
        }
    ],
    [
        'qm9814',
        {
            'color' => 'red'
        }
    ],
    [
        'qr6637',
        {
            'color' => 'green'
        }
    ],
    [
        'qt5403',
        {
            'color' => 'green'
        }
    ],
    [
        'qw7754',
        {
            'color' => 'red'
        }
    ],
    [
        'rb8660',
        {
            'color' => 'green'
        }
    ],
    [
        'rk7618',
        {
            'color' => 'green'
        }
    ],
    [
        'rm4034',
        {
            'color' => 'green'
        }
    ],
    [
        'rr2851',
        {
            'color' => 'green'
        }
    ],
    [
        'sa1591',
        {
            'color' => 'red'
        }
    ],
    [
        'sc9595',
        {
            'color' => 'green'
        }
    ],
    [
        'sx6810',
        {
            'color' => 'green'
        }
    ],
    [
        'tf2708',
        {
            'color' => 'green'
        }
    ],
    [
        'uc3987',
        {
            'color' => 'red'
        }
    ],
    [
        'vj9307',
        {
            'color' => 'red'
        }
    ],
    [
        'wh5997',
        {
            'color' => 'red'
        }
    ],
    [
        'xb4278',
        {
            'color' => 'red'
        }
    ],
    [
        'xc9578',
        {
            'color' => 'red'
        }
    ],
    [
        'xg5620',
        {
            'color' => 'red'
        }
    ],
    [
        'xp9164',
        {
            'color' => 'red'
        }
    ],
    [
        'yf7778',
        {
            'color' => 'red'
        }
    ],
    [
        'yl8502',
        {
            'color' => 'red'
        }
    ],
    [
        'yu5902',
        {
            'color' => 'red'
        }
    ],
    [
        'zf6883',
        {
            'color' => 'red'
        }
    ]
);

my @got = $g->vertex_colors;
@got = sort { $a->[0] gt $b->[0] } @got;

is_deeply( \@expected, \@got, "The coloring of G was as expected." );

my $n = $g->chromatic_number;

ok( $n == 3, "Chromatic number of G is 3 as expected." );

# --------------------------------------------------------------------
# Second round: graph H with 512 vertices.

my @expected2 = (
    [
        'aa5233',
        {
            'color' => 'green'
        }
    ],
    [
        'ab3886',
        {
            'color' => 'red'
        }
    ],
    [
        'ac7477',
        {
            'color' => 'green'
        }
    ],
    [
        'ac7558',
        {
            'color' => 'red'
        }
    ],
    [
        'ae8904',
        {
            'color' => 'green'
        }
    ],
    [
        'af1779',
        {
            'color' => 'blue'
        }
    ],
    [
        'ag5722',
        {
            'color' => 'green'
        }
    ],
    [
        'ah4571',
        {
            'color' => 'red'
        }
    ],
    [
        'ai1358',
        {
            'color' => 'green'
        }
    ],
    [
        'ak4118',
        {
            'color' => 'green'
        }
    ],
    [
        'ak4814',
        {
            'color' => 'green'
        }
    ],
    [
        'al4959',
        {
            'color' => 'red'
        }
    ],
    [
        'am6042',
        {
            'color' => 'red'
        }
    ],
    [
        'am9416',
        {
            'color' => 'blue'
        }
    ],
    [
        'an4403',
        {
            'color' => 'green'
        }
    ],
    [
        'as5311',
        {
            'color' => 'red'
        }
    ],
    [
        'at4967',
        {
            'color' => 'red'
        }
    ],
    [
        'au2939',
        {
            'color' => 'red'
        }
    ],
    [
        'au7224',
        {
            'color' => 'blue'
        }
    ],
    [
        'au7703',
        {
            'color' => 'green'
        }
    ],
    [
        'az184',
        {
            'color' => 'blue'
        }
    ],
    [
        'az1985',
        {
            'color' => 'red'
        }
    ],
    [
        'az6386',
        {
            'color' => 'blue'
        }
    ],
    [
        'bc9189',
        {
            'color' => 'green'
        }
    ],
    [
        'be9331',
        {
            'color' => 'yellow'
        }
    ],
    [
        'bf2896',
        {
            'color' => 'red'
        }
    ],
    [
        'bf7284',
        {
            'color' => 'green'
        }
    ],
    [
        'bg3981',
        {
            'color' => 'green'
        }
    ],
    [
        'bh6421',
        {
            'color' => 'red'
        }
    ],
    [
        'bk8288',
        {
            'color' => 'blue'
        }
    ],
    [
        'bm4147',
        {
            'color' => 'red'
        }
    ],
    [
        'bn5781',
        {
            'color' => 'green'
        }
    ],
    [
        'bo3143',
        {
            'color' => 'red'
        }
    ],
    [
        'bx7525',
        {
            'color' => 'red'
        }
    ],
    [
        'ca1661',
        {
            'color' => 'green'
        }
    ],
    [
        'cd1196',
        {
            'color' => 'red'
        }
    ],
    [
        'ce2492',
        {
            'color' => 'green'
        }
    ],
    [
        'cf913',
        {
            'color' => 'red'
        }
    ],
    [
        'cg5732',
        {
            'color' => 'blue'
        }
    ],
    [
        'ch3596',
        {
            'color' => 'yellow'
        }
    ],
    [
        'ci7288',
        {
            'color' => 'blue'
        }
    ],
    [
        'ck9173',
        {
            'color' => 'green'
        }
    ],
    [
        'cm986',
        {
            'color' => 'blue'
        }
    ],
    [
        'cn6750',
        {
            'color' => 'green'
        }
    ],
    [
        'cn8124',
        {
            'color' => 'green'
        }
    ],
    [
        'cn9075',
        {
            'color' => 'green'
        }
    ],
    [
        'cp7916',
        {
            'color' => 'red'
        }
    ],
    [
        'ct2566',
        {
            'color' => 'blue'
        }
    ],
    [
        'cu5046',
        {
            'color' => 'red'
        }
    ],
    [
        'cw1950',
        {
            'color' => 'green'
        }
    ],
    [
        'cz2959',
        {
            'color' => 'red'
        }
    ],
    [
        'cz4473',
        {
            'color' => 'blue'
        }
    ],
    [
        'dd8634',
        {
            'color' => 'green'
        }
    ],
    [
        'de467',
        {
            'color' => 'green'
        }
    ],
    [
        'dg1351',
        {
            'color' => 'green'
        }
    ],
    [
        'dg2812',
        {
            'color' => 'blue'
        }
    ],
    [
        'dh523',
        {
            'color' => 'red'
        }
    ],
    [
        'dh7890',
        {
            'color' => 'blue'
        }
    ],
    [
        'dj7704',
        {
            'color' => 'blue'
        }
    ],
    [
        'dj8643',
        {
            'color' => 'red'
        }
    ],
    [
        'dk1196',
        {
            'color' => 'red'
        }
    ],
    [
        'dm289',
        {
            'color' => 'red'
        }
    ],
    [
        'do6293',
        {
            'color' => 'blue'
        }
    ],
    [
        'do6968',
        {
            'color' => 'green'
        }
    ],
    [
        'dp2336',
        {
            'color' => 'blue'
        }
    ],
    [
        'dq3437',
        {
            'color' => 'red'
        }
    ],
    [
        'dr9237',
        {
            'color' => 'green'
        }
    ],
    [
        'du154',
        {
            'color' => 'green'
        }
    ],
    [
        'dv5029',
        {
            'color' => 'blue'
        }
    ],
    [
        'dz6851',
        {
            'color' => 'yellow'
        }
    ],
    [
        'ec1555',
        {
            'color' => 'green'
        }
    ],
    [
        'ec1944',
        {
            'color' => 'green'
        }
    ],
    [
        'ec3443',
        {
            'color' => 'red'
        }
    ],
    [
        'ec5391',
        {
            'color' => 'green'
        }
    ],
    [
        'ee7634',
        {
            'color' => 'green'
        }
    ],
    [
        'ee7888',
        {
            'color' => 'red'
        }
    ],
    [
        'eg2686',
        {
            'color' => 'blue'
        }
    ],
    [
        'eh1473',
        {
            'color' => 'red'
        }
    ],
    [
        'ei472',
        {
            'color' => 'blue'
        }
    ],
    [
        'ek8183',
        {
            'color' => 'red'
        }
    ],
    [
        'ek8323',
        {
            'color' => 'red'
        }
    ],
    [
        'el6623',
        {
            'color' => 'blue'
        }
    ],
    [
        'em6133',
        {
            'color' => 'green'
        }
    ],
    [
        'en47',
        {
            'color' => 'red'
        }
    ],
    [
        'eq7321',
        {
            'color' => 'green'
        }
    ],
    [
        'er2522',
        {
            'color' => 'blue'
        }
    ],
    [
        'er9529',
        {
            'color' => 'blue'
        }
    ],
    [
        'et5403',
        {
            'color' => 'green'
        }
    ],
    [
        'ev3106',
        {
            'color' => 'red'
        }
    ],
    [
        'fa8142',
        {
            'color' => 'green'
        }
    ],
    [
        'fb3490',
        {
            'color' => 'green'
        }
    ],
    [
        'fc3375',
        {
            'color' => 'red'
        }
    ],
    [
        'fd912',
        {
            'color' => 'green'
        }
    ],
    [
        'fe904',
        {
            'color' => 'red'
        }
    ],
    [
        'fg7503',
        {
            'color' => 'blue'
        }
    ],
    [
        'fh182',
        {
            'color' => 'blue'
        }
    ],
    [
        'fk9509',
        {
            'color' => 'green'
        }
    ],
    [
        'fl7431',
        {
            'color' => 'blue'
        }
    ],
    [
        'fm54',
        {
            'color' => 'green'
        }
    ],
    [
        'fn5880',
        {
            'color' => 'red'
        }
    ],
    [
        'fr2296',
        {
            'color' => 'red'
        }
    ],
    [
        'fs3272',
        {
            'color' => 'red'
        }
    ],
    [
        'fs8419',
        {
            'color' => 'red'
        }
    ],
    [
        'ft5115',
        {
            'color' => 'red'
        }
    ],
    [
        'fv6232',
        {
            'color' => 'blue'
        }
    ],
    [
        'fv7200',
        {
            'color' => 'yellow'
        }
    ],
    [
        'fw9487',
        {
            'color' => 'red'
        }
    ],
    [
        'fw9818',
        {
            'color' => 'green'
        }
    ],
    [
        'fx132',
        {
            'color' => 'green'
        }
    ],
    [
        'fx1826',
        {
            'color' => 'blue'
        }
    ],
    [
        'fx2297',
        {
            'color' => 'green'
        }
    ],
    [
        'fx6598',
        {
            'color' => 'red'
        }
    ],
    [
        'fy3475',
        {
            'color' => 'green'
        }
    ],
    [
        'fy3651',
        {
            'color' => 'red'
        }
    ],
    [
        'fz6467',
        {
            'color' => 'green'
        }
    ],
    [
        'ga9055',
        {
            'color' => 'red'
        }
    ],
    [
        'gc3300',
        {
            'color' => 'green'
        }
    ],
    [
        'gd4919',
        {
            'color' => 'green'
        }
    ],
    [
        'gd9865',
        {
            'color' => 'blue'
        }
    ],
    [
        'ge3490',
        {
            'color' => 'red'
        }
    ],
    [
        'gi4134',
        {
            'color' => 'green'
        }
    ],
    [
        'gi6491',
        {
            'color' => 'red'
        }
    ],
    [
        'gi8205',
        {
            'color' => 'red'
        }
    ],
    [
        'gj2382',
        {
            'color' => 'blue'
        }
    ],
    [
        'gl6332',
        {
            'color' => 'red'
        }
    ],
    [
        'gl672',
        {
            'color' => 'green'
        }
    ],
    [
        'gm2892',
        {
            'color' => 'red'
        }
    ],
    [
        'gm3252',
        {
            'color' => 'blue'
        }
    ],
    [
        'gm9678',
        {
            'color' => 'green'
        }
    ],
    [
        'gq7417',
        {
            'color' => 'red'
        }
    ],
    [
        'gq9217',
        {
            'color' => 'green'
        }
    ],
    [
        'gu5761',
        {
            'color' => 'red'
        }
    ],
    [
        'gu8035',
        {
            'color' => 'blue'
        }
    ],
    [
        'gv2529',
        {
            'color' => 'green'
        }
    ],
    [
        'gx5104',
        {
            'color' => 'green'
        }
    ],
    [
        'gz3416',
        {
            'color' => 'green'
        }
    ],
    [
        'gz4167',
        {
            'color' => 'red'
        }
    ],
    [
        'gz8916',
        {
            'color' => 'blue'
        }
    ],
    [
        'ha2145',
        {
            'color' => 'red'
        }
    ],
    [
        'hb2719',
        {
            'color' => 'blue'
        }
    ],
    [
        'hb5778',
        {
            'color' => 'green'
        }
    ],
    [
        'hc2350',
        {
            'color' => 'green'
        }
    ],
    [
        'hc3433',
        {
            'color' => 'blue'
        }
    ],
    [
        'hd4499',
        {
            'color' => 'red'
        }
    ],
    [
        'hd9342',
        {
            'color' => 'blue'
        }
    ],
    [
        'he5237',
        {
            'color' => 'blue'
        }
    ],
    [
        'he6962',
        {
            'color' => 'red'
        }
    ],
    [
        'hf8740',
        {
            'color' => 'red'
        }
    ],
    [
        'hg8108',
        {
            'color' => 'red'
        }
    ],
    [
        'hh4186',
        {
            'color' => 'red'
        }
    ],
    [
        'hh4392',
        {
            'color' => 'blue'
        }
    ],
    [
        'hh5387',
        {
            'color' => 'blue'
        }
    ],
    [
        'hh6395',
        {
            'color' => 'green'
        }
    ],
    [
        'hh733',
        {
            'color' => 'blue'
        }
    ],
    [
        'hi4075',
        {
            'color' => 'green'
        }
    ],
    [
        'hi7649',
        {
            'color' => 'red'
        }
    ],
    [
        'hk4353',
        {
            'color' => 'blue'
        }
    ],
    [
        'hk6611',
        {
            'color' => 'green'
        }
    ],
    [
        'hk9532',
        {
            'color' => 'blue'
        }
    ],
    [
        'hm5725',
        {
            'color' => 'green'
        }
    ],
    [
        'hn1256',
        {
            'color' => 'green'
        }
    ],
    [
        'ho4079',
        {
            'color' => 'green'
        }
    ],
    [
        'hq8064',
        {
            'color' => 'green'
        }
    ],
    [
        'hr1138',
        {
            'color' => 'green'
        }
    ],
    [
        'hr2417',
        {
            'color' => 'red'
        }
    ],
    [
        'hv2478',
        {
            'color' => 'green'
        }
    ],
    [
        'hv4312',
        {
            'color' => 'red'
        }
    ],
    [
        'hv6123',
        {
            'color' => 'blue'
        }
    ],
    [
        'hv8592',
        {
            'color' => 'green'
        }
    ],
    [
        'hx3841',
        {
            'color' => 'yellow'
        }
    ],
    [
        'hy3174',
        {
            'color' => 'green'
        }
    ],
    [
        'hy3382',
        {
            'color' => 'green'
        }
    ],
    [
        'hz5317',
        {
            'color' => 'blue'
        }
    ],
    [
        'ic7857',
        {
            'color' => 'green'
        }
    ],
    [
        'ih7919',
        {
            'color' => 'green'
        }
    ],
    [
        'ii4132',
        {
            'color' => 'red'
        }
    ],
    [
        'il5505',
        {
            'color' => 'green'
        }
    ],
    [
        'io867',
        {
            'color' => 'green'
        }
    ],
    [
        'iq2323',
        {
            'color' => 'red'
        }
    ],
    [
        'ir1804',
        {
            'color' => 'green'
        }
    ],
    [
        'is6230',
        {
            'color' => 'blue'
        }
    ],
    [
        'is9349',
        {
            'color' => 'red'
        }
    ],
    [
        'ix2192',
        {
            'color' => 'red'
        }
    ],
    [
        'ix290',
        {
            'color' => 'green'
        }
    ],
    [
        'ix3120',
        {
            'color' => 'red'
        }
    ],
    [
        'iy1031',
        {
            'color' => 'green'
        }
    ],
    [
        'iy1831',
        {
            'color' => 'green'
        }
    ],
    [
        'jc7057',
        {
            'color' => 'blue'
        }
    ],
    [
        'jd5736',
        {
            'color' => 'blue'
        }
    ],
    [
        'je7901',
        {
            'color' => 'green'
        }
    ],
    [
        'jf4349',
        {
            'color' => 'green'
        }
    ],
    [
        'jg2446',
        {
            'color' => 'red'
        }
    ],
    [
        'jg8054',
        {
            'color' => 'red'
        }
    ],
    [
        'ji3943',
        {
            'color' => 'red'
        }
    ],
    [
        'jn5213',
        {
            'color' => 'red'
        }
    ],
    [
        'jp4131',
        {
            'color' => 'green'
        }
    ],
    [
        'jq7077',
        {
            'color' => 'green'
        }
    ],
    [
        'jr7393',
        {
            'color' => 'red'
        }
    ],
    [
        'jr8817',
        {
            'color' => 'red'
        }
    ],
    [
        'js758',
        {
            'color' => 'blue'
        }
    ],
    [
        'ju6568',
        {
            'color' => 'blue'
        }
    ],
    [
        'ju9183',
        {
            'color' => 'green'
        }
    ],
    [
        'jw3025',
        {
            'color' => 'blue'
        }
    ],
    [
        'jz5747',
        {
            'color' => 'green'
        }
    ],
    [
        'ka3831',
        {
            'color' => 'blue'
        }
    ],
    [
        'ka668',
        {
            'color' => 'blue'
        }
    ],
    [
        'kb5692',
        {
            'color' => 'green'
        }
    ],
    [
        'kb7767',
        {
            'color' => 'green'
        }
    ],
    [
        'ke606',
        {
            'color' => 'blue'
        }
    ],
    [
        'kf1575',
        {
            'color' => 'red'
        }
    ],
    [
        'kh8029',
        {
            'color' => 'green'
        }
    ],
    [
        'kk423',
        {
            'color' => 'red'
        }
    ],
    [
        'kl8501',
        {
            'color' => 'green'
        }
    ],
    [
        'km8121',
        {
            'color' => 'blue'
        }
    ],
    [
        'kq3776',
        {
            'color' => 'green'
        }
    ],
    [
        'kr2914',
        {
            'color' => 'red'
        }
    ],
    [
        'kt7351',
        {
            'color' => 'green'
        }
    ],
    [
        'kv4910',
        {
            'color' => 'red'
        }
    ],
    [
        'kw9551',
        {
            'color' => 'green'
        }
    ],
    [
        'kx4527',
        {
            'color' => 'green'
        }
    ],
    [
        'la2365',
        {
            'color' => 'green'
        }
    ],
    [
        'ld4764',
        {
            'color' => 'blue'
        }
    ],
    [
        'li8892',
        {
            'color' => 'green'
        }
    ],
    [
        'lj7780',
        {
            'color' => 'green'
        }
    ],
    [
        'lk9550',
        {
            'color' => 'red'
        }
    ],
    [
        'll3242',
        {
            'color' => 'green'
        }
    ],
    [
        'ln8088',
        {
            'color' => 'red'
        }
    ],
    [
        'lq8629',
        {
            'color' => 'green'
        }
    ],
    [
        'lt7281',
        {
            'color' => 'green'
        }
    ],
    [
        'lt9513',
        {
            'color' => 'green'
        }
    ],
    [
        'lu1915',
        {
            'color' => 'green'
        }
    ],
    [
        'lv8052',
        {
            'color' => 'green'
        }
    ],
    [
        'lx1045',
        {
            'color' => 'green'
        }
    ],
    [
        'lz9845',
        {
            'color' => 'green'
        }
    ],
    [
        'mb2034',
        {
            'color' => 'red'
        }
    ],
    [
        'md4523',
        {
            'color' => 'red'
        }
    ],
    [
        'md7040',
        {
            'color' => 'blue'
        }
    ],
    [
        'mf249',
        {
            'color' => 'green'
        }
    ],
    [
        'mh2517',
        {
            'color' => 'red'
        }
    ],
    [
        'mh2706',
        {
            'color' => 'green'
        }
    ],
    [
        'mh9553',
        {
            'color' => 'green'
        }
    ],
    [
        'mj5816',
        {
            'color' => 'red'
        }
    ],
    [
        'mm2662',
        {
            'color' => 'red'
        }
    ],
    [
        'mm7101',
        {
            'color' => 'green'
        }
    ],
    [
        'mn7468',
        {
            'color' => 'green'
        }
    ],
    [
        'mo4393',
        {
            'color' => 'green'
        }
    ],
    [
        'mp5609',
        {
            'color' => 'red'
        }
    ],
    [
        'mq1731',
        {
            'color' => 'blue'
        }
    ],
    [
        'mr6362',
        {
            'color' => 'blue'
        }
    ],
    [
        'ms2223',
        {
            'color' => 'green'
        }
    ],
    [
        'ms312',
        {
            'color' => 'red'
        }
    ],
    [
        'ms4711',
        {
            'color' => 'green'
        }
    ],
    [
        'mt9254',
        {
            'color' => 'green'
        }
    ],
    [
        'my4602',
        {
            'color' => 'red'
        }
    ],
    [
        'na1134',
        {
            'color' => 'blue'
        }
    ],
    [
        'na6482',
        {
            'color' => 'red'
        }
    ],
    [
        'na7320',
        {
            'color' => 'red'
        }
    ],
    [
        'na8469',
        {
            'color' => 'red'
        }
    ],
    [
        'nb2508',
        {
            'color' => 'green'
        }
    ],
    [
        'nc4472',
        {
            'color' => 'green'
        }
    ],
    [
        'nd3257',
        {
            'color' => 'blue'
        }
    ],
    [
        'ne6428',
        {
            'color' => 'green'
        }
    ],
    [
        'ne7522',
        {
            'color' => 'green'
        }
    ],
    [
        'ne9090',
        {
            'color' => 'green'
        }
    ],
    [
        'ni5492',
        {
            'color' => 'red'
        }
    ],
    [
        'nl258',
        {
            'color' => 'green'
        }
    ],
    [
        'nn867',
        {
            'color' => 'green'
        }
    ],
    [
        'np2341',
        {
            'color' => 'blue'
        }
    ],
    [
        'nq925',
        {
            'color' => 'red'
        }
    ],
    [
        'nv6812',
        {
            'color' => 'red'
        }
    ],
    [
        'nv860',
        {
            'color' => 'blue'
        }
    ],
    [
        'nw4625',
        {
            'color' => 'red'
        }
    ],
    [
        'nx9645',
        {
            'color' => 'green'
        }
    ],
    [
        'ny9206',
        {
            'color' => 'red'
        }
    ],
    [
        'nz4382',
        {
            'color' => 'green'
        }
    ],
    [
        'oa5255',
        {
            'color' => 'green'
        }
    ],
    [
        'oa655',
        {
            'color' => 'red'
        }
    ],
    [
        'oc6306',
        {
            'color' => 'green'
        }
    ],
    [
        'od148',
        {
            'color' => 'green'
        }
    ],
    [
        'od1494',
        {
            'color' => 'green'
        }
    ],
    [
        'od2814',
        {
            'color' => 'blue'
        }
    ],
    [
        'od588',
        {
            'color' => 'green'
        }
    ],
    [
        'oe7550',
        {
            'color' => 'green'
        }
    ],
    [
        'ok9103',
        {
            'color' => 'red'
        }
    ],
    [
        'oo315',
        {
            'color' => 'green'
        }
    ],
    [
        'oo5372',
        {
            'color' => 'blue'
        }
    ],
    [
        'oo7773',
        {
            'color' => 'red'
        }
    ],
    [
        'oq9020',
        {
            'color' => 'red'
        }
    ],
    [
        'or9035',
        {
            'color' => 'red'
        }
    ],
    [
        'os3755',
        {
            'color' => 'red'
        }
    ],
    [
        'ot2960',
        {
            'color' => 'red'
        }
    ],
    [
        'ot8931',
        {
            'color' => 'green'
        }
    ],
    [
        'ov1701',
        {
            'color' => 'red'
        }
    ],
    [
        'ow6377',
        {
            'color' => 'red'
        }
    ],
    [
        'ow7149',
        {
            'color' => 'blue'
        }
    ],
    [
        'ow7933',
        {
            'color' => 'green'
        }
    ],
    [
        'ox8252',
        {
            'color' => 'red'
        }
    ],
    [
        'ox9970',
        {
            'color' => 'red'
        }
    ],
    [
        'oy8324',
        {
            'color' => 'green'
        }
    ],
    [
        'pa1072',
        {
            'color' => 'green'
        }
    ],
    [
        'pc6840',
        {
            'color' => 'red'
        }
    ],
    [
        'pd1930',
        {
            'color' => 'red'
        }
    ],
    [
        'pd6030',
        {
            'color' => 'red'
        }
    ],
    [
        'pd9443',
        {
            'color' => 'blue'
        }
    ],
    [
        'pe7519',
        {
            'color' => 'green'
        }
    ],
    [
        'pe9783',
        {
            'color' => 'red'
        }
    ],
    [
        'pg409',
        {
            'color' => 'red'
        }
    ],
    [
        'pg4318',
        {
            'color' => 'red'
        }
    ],
    [
        'ph7161',
        {
            'color' => 'green'
        }
    ],
    [
        'pi120',
        {
            'color' => 'red'
        }
    ],
    [
        'pk3349',
        {
            'color' => 'red'
        }
    ],
    [
        'pk4400',
        {
            'color' => 'green'
        }
    ],
    [
        'pl2599',
        {
            'color' => 'green'
        }
    ],
    [
        'pl941',
        {
            'color' => 'green'
        }
    ],
    [
        'pm6302',
        {
            'color' => 'red'
        }
    ],
    [
        'pm6356',
        {
            'color' => 'red'
        }
    ],
    [
        'pu2190',
        {
            'color' => 'red'
        }
    ],
    [
        'px7283',
        {
            'color' => 'red'
        }
    ],
    [
        'px9961',
        {
            'color' => 'red'
        }
    ],
    [
        'py4885',
        {
            'color' => 'green'
        }
    ],
    [
        'py5378',
        {
            'color' => 'red'
        }
    ],
    [
        'qa9948',
        {
            'color' => 'green'
        }
    ],
    [
        'qb5715',
        {
            'color' => 'green'
        }
    ],
    [
        'qc6916',
        {
            'color' => 'green'
        }
    ],
    [
        'qe2408',
        {
            'color' => 'green'
        }
    ],
    [
        'qe3433',
        {
            'color' => 'green'
        }
    ],
    [
        'qf3840',
        {
            'color' => 'blue'
        }
    ],
    [
        'qf4663',
        {
            'color' => 'green'
        }
    ],
    [
        'qf9651',
        {
            'color' => 'green'
        }
    ],
    [
        'qg6028',
        {
            'color' => 'green'
        }
    ],
    [
        'qg7396',
        {
            'color' => 'green'
        }
    ],
    [
        'qi1254',
        {
            'color' => 'green'
        }
    ],
    [
        'qk5909',
        {
            'color' => 'red'
        }
    ],
    [
        'ql5695',
        {
            'color' => 'red'
        }
    ],
    [
        'qq3013',
        {
            'color' => 'blue'
        }
    ],
    [
        'qv9989',
        {
            'color' => 'red'
        }
    ],
    [
        'qz3065',
        {
            'color' => 'red'
        }
    ],
    [
        'qz4133',
        {
            'color' => 'blue'
        }
    ],
    [
        'qz6108',
        {
            'color' => 'blue'
        }
    ],
    [
        'qz6819',
        {
            'color' => 'green'
        }
    ],
    [
        'qz7117',
        {
            'color' => 'green'
        }
    ],
    [
        'rh2810',
        {
            'color' => 'green'
        }
    ],
    [
        'ri3059',
        {
            'color' => 'red'
        }
    ],
    [
        'ri5711',
        {
            'color' => 'red'
        }
    ],
    [
        'rj5854',
        {
            'color' => 'red'
        }
    ],
    [
        'rk7505',
        {
            'color' => 'red'
        }
    ],
    [
        'rm3464',
        {
            'color' => 'red'
        }
    ],
    [
        'rm4649',
        {
            'color' => 'green'
        }
    ],
    [
        'rn5778',
        {
            'color' => 'red'
        }
    ],
    [
        'ro2574',
        {
            'color' => 'green'
        }
    ],
    [
        'ro9902',
        {
            'color' => 'green'
        }
    ],
    [
        'rp5733',
        {
            'color' => 'red'
        }
    ],
    [
        'rp6452',
        {
            'color' => 'green'
        }
    ],
    [
        'rt4084',
        {
            'color' => 'green'
        }
    ],
    [
        'ry2913',
        {
            'color' => 'red'
        }
    ],
    [
        'ry6636',
        {
            'color' => 'green'
        }
    ],
    [
        'sb105',
        {
            'color' => 'green'
        }
    ],
    [
        'sb5092',
        {
            'color' => 'red'
        }
    ],
    [
        'sd6570',
        {
            'color' => 'green'
        }
    ],
    [
        'sf3297',
        {
            'color' => 'green'
        }
    ],
    [
        'sf7629',
        {
            'color' => 'blue'
        }
    ],
    [
        'sh2067',
        {
            'color' => 'green'
        }
    ],
    [
        'sh2460',
        {
            'color' => 'red'
        }
    ],
    [
        'si4037',
        {
            'color' => 'green'
        }
    ],
    [
        'sk9901',
        {
            'color' => 'green'
        }
    ],
    [
        'sp6461',
        {
            'color' => 'green'
        }
    ],
    [
        'sp7525',
        {
            'color' => 'red'
        }
    ],
    [
        'sr3372',
        {
            'color' => 'red'
        }
    ],
    [
        'sr9617',
        {
            'color' => 'red'
        }
    ],
    [
        'ss4569',
        {
            'color' => 'red'
        }
    ],
    [
        'st2304',
        {
            'color' => 'green'
        }
    ],
    [
        'su1485',
        {
            'color' => 'green'
        }
    ],
    [
        'su2910',
        {
            'color' => 'green'
        }
    ],
    [
        'sy4779',
        {
            'color' => 'red'
        }
    ],
    [
        'sy8858',
        {
            'color' => 'green'
        }
    ],
    [
        'sz2013',
        {
            'color' => 'green'
        }
    ],
    [
        'ta2687',
        {
            'color' => 'red'
        }
    ],
    [
        'ta8811',
        {
            'color' => 'green'
        }
    ],
    [
        'tb8059',
        {
            'color' => 'red'
        }
    ],
    [
        'tc8581',
        {
            'color' => 'green'
        }
    ],
    [
        'td4497',
        {
            'color' => 'red'
        }
    ],
    [
        'tf8733',
        {
            'color' => 'red'
        }
    ],
    [
        'tg4800',
        {
            'color' => 'green'
        }
    ],
    [
        'ti6048',
        {
            'color' => 'red'
        }
    ],
    [
        'tj8472',
        {
            'color' => 'green'
        }
    ],
    [
        'tk2433',
        {
            'color' => 'red'
        }
    ],
    [
        'tn1152',
        {
            'color' => 'red'
        }
    ],
    [
        'tp6781',
        {
            'color' => 'green'
        }
    ],
    [
        'tp9155',
        {
            'color' => 'red'
        }
    ],
    [
        'tq4436',
        {
            'color' => 'red'
        }
    ],
    [
        'tr1237',
        {
            'color' => 'green'
        }
    ],
    [
        'tr7186',
        {
            'color' => 'green'
        }
    ],
    [
        'ts445',
        {
            'color' => 'red'
        }
    ],
    [
        'tu4447',
        {
            'color' => 'green'
        }
    ],
    [
        'tu928',
        {
            'color' => 'green'
        }
    ],
    [
        'tw2019',
        {
            'color' => 'green'
        }
    ],
    [
        'tw9827',
        {
            'color' => 'green'
        }
    ],
    [
        'tx1494',
        {
            'color' => 'red'
        }
    ],
    [
        'ud8663',
        {
            'color' => 'red'
        }
    ],
    [
        'ud8747',
        {
            'color' => 'red'
        }
    ],
    [
        'ue4588',
        {
            'color' => 'red'
        }
    ],
    [
        'uf2800',
        {
            'color' => 'red'
        }
    ],
    [
        'uf3359',
        {
            'color' => 'red'
        }
    ],
    [
        'ug2812',
        {
            'color' => 'red'
        }
    ],
    [
        'uh304',
        {
            'color' => 'red'
        }
    ],
    [
        'uj6618',
        {
            'color' => 'red'
        }
    ],
    [
        'uj9536',
        {
            'color' => 'green'
        }
    ],
    [
        'uk1476',
        {
            'color' => 'green'
        }
    ],
    [
        'uk913',
        {
            'color' => 'green'
        }
    ],
    [
        'um5142',
        {
            'color' => 'red'
        }
    ],
    [
        'un4299',
        {
            'color' => 'red'
        }
    ],
    [
        'us8589',
        {
            'color' => 'red'
        }
    ],
    [
        'uu3136',
        {
            'color' => 'red'
        }
    ],
    [
        'uv7506',
        {
            'color' => 'red'
        }
    ],
    [
        'uv8665',
        {
            'color' => 'green'
        }
    ],
    [
        'ux232',
        {
            'color' => 'red'
        }
    ],
    [
        'uz246',
        {
            'color' => 'green'
        }
    ],
    [
        'va291',
        {
            'color' => 'red'
        }
    ],
    [
        'va3615',
        {
            'color' => 'green'
        }
    ],
    [
        'vc4113',
        {
            'color' => 'green'
        }
    ],
    [
        've6536',
        {
            'color' => 'red'
        }
    ],
    [
        'vf7195',
        {
            'color' => 'green'
        }
    ],
    [
        'vf7697',
        {
            'color' => 'green'
        }
    ],
    [
        'vg4706',
        {
            'color' => 'red'
        }
    ],
    [
        'vi8455',
        {
            'color' => 'red'
        }
    ],
    [
        'vn7687',
        {
            'color' => 'red'
        }
    ],
    [
        'vp6581',
        {
            'color' => 'red'
        }
    ],
    [
        'vq4907',
        {
            'color' => 'red'
        }
    ],
    [
        'vs1509',
        {
            'color' => 'green'
        }
    ],
    [
        'vv396',
        {
            'color' => 'green'
        }
    ],
    [
        'vv5266',
        {
            'color' => 'red'
        }
    ],
    [
        'vw1841',
        {
            'color' => 'red'
        }
    ],
    [
        'vw2262',
        {
            'color' => 'green'
        }
    ],
    [
        'vx5322',
        {
            'color' => 'green'
        }
    ],
    [
        'wb1473',
        {
            'color' => 'red'
        }
    ],
    [
        'wc7763',
        {
            'color' => 'red'
        }
    ],
    [
        'wd2398',
        {
            'color' => 'green'
        }
    ],
    [
        'we737',
        {
            'color' => 'red'
        }
    ],
    [
        'wi3934',
        {
            'color' => 'green'
        }
    ],
    [
        'wi9349',
        {
            'color' => 'red'
        }
    ],
    [
        'wj9923',
        {
            'color' => 'red'
        }
    ],
    [
        'wk5311',
        {
            'color' => 'red'
        }
    ],
    [
        'wm1134',
        {
            'color' => 'green'
        }
    ],
    [
        'wm959',
        {
            'color' => 'red'
        }
    ],
    [
        'wn1800',
        {
            'color' => 'red'
        }
    ],
    [
        'wq146',
        {
            'color' => 'green'
        }
    ],
    [
        'ws3135',
        {
            'color' => 'red'
        }
    ],
    [
        'ws3639',
        {
            'color' => 'red'
        }
    ],
    [
        'ws7365',
        {
            'color' => 'red'
        }
    ],
    [
        'wu9915',
        {
            'color' => 'red'
        }
    ],
    [
        'wz5535',
        {
            'color' => 'red'
        }
    ],
    [
        'xb1518',
        {
            'color' => 'red'
        }
    ],
    [
        'xb4042',
        {
            'color' => 'red'
        }
    ],
    [
        'xc5080',
        {
            'color' => 'red'
        }
    ],
    [
        'xf3819',
        {
            'color' => 'red'
        }
    ],
    [
        'xh1648',
        {
            'color' => 'red'
        }
    ],
    [
        'xh4758',
        {
            'color' => 'red'
        }
    ],
    [
        'xh7281',
        {
            'color' => 'green'
        }
    ],
    [
        'xj1482',
        {
            'color' => 'red'
        }
    ],
    [
        'xl1934',
        {
            'color' => 'red'
        }
    ],
    [
        'xm8218',
        {
            'color' => 'green'
        }
    ],
    [
        'xn176',
        {
            'color' => 'red'
        }
    ],
    [
        'xo1331',
        {
            'color' => 'red'
        }
    ],
    [
        'xp7295',
        {
            'color' => 'red'
        }
    ],
    [
        'xr5273',
        {
            'color' => 'red'
        }
    ],
    [
        'xs349',
        {
            'color' => 'red'
        }
    ],
    [
        'xs7608',
        {
            'color' => 'red'
        }
    ],
    [
        'xv276',
        {
            'color' => 'red'
        }
    ],
    [
        'xv6125',
        {
            'color' => 'red'
        }
    ],
    [
        'xx7916',
        {
            'color' => 'red'
        }
    ],
    [
        'yb1050',
        {
            'color' => 'red'
        }
    ],
    [
        'yb8561',
        {
            'color' => 'red'
        }
    ],
    [
        'yb9172',
        {
            'color' => 'green'
        }
    ],
    [
        'yc2224',
        {
            'color' => 'green'
        }
    ],
    [
        'yc4884',
        {
            'color' => 'red'
        }
    ],
    [
        'ye5945',
        {
            'color' => 'red'
        }
    ],
    [
        'ye6494',
        {
            'color' => 'red'
        }
    ],
    [
        'yg5116',
        {
            'color' => 'red'
        }
    ],
    [
        'yk6365',
        {
            'color' => 'red'
        }
    ],
    [
        'yl1187',
        {
            'color' => 'green'
        }
    ],
    [
        'yl9012',
        {
            'color' => 'red'
        }
    ],
    [
        'yl9725',
        {
            'color' => 'red'
        }
    ],
    [
        'yn1423',
        {
            'color' => 'red'
        }
    ],
    [
        'yt1640',
        {
            'color' => 'red'
        }
    ],
    [
        'yt4043',
        {
            'color' => 'red'
        }
    ],
    [
        'yx718',
        {
            'color' => 'red'
        }
    ],
    [
        'zb6924',
        {
            'color' => 'green'
        }
    ],
    [
        'ze6740',
        {
            'color' => 'red'
        }
    ],
    [
        'zf2607',
        {
            'color' => 'red'
        }
    ],
    [
        'zf3593',
        {
            'color' => 'red'
        }
    ],
    [
        'zf7611',
        {
            'color' => 'red'
        }
    ],
    [
        'zg5284',
        {
            'color' => 'red'
        }
    ],
    [
        'zi81',
        {
            'color' => 'red'
        }
    ],
    [
        'zj5063',
        {
            'color' => 'red'
        }
    ],
    [
        'zj6054',
        {
            'color' => 'red'
        }
    ],
    [
        'zj633',
        {
            'color' => 'red'
        }
    ],
    [
        'zj9867',
        {
            'color' => 'red'
        }
    ],
    [
        'zm6239',
        {
            'color' => 'red'
        }
    ],
    [
        'zn1446',
        {
            'color' => 'red'
        }
    ],
    [
        'zo39',
        {
            'color' => 'red'
        }
    ],
    [
        'zp8057',
        {
            'color' => 'red'
        }
    ],
    [
        'zq8076',
        {
            'color' => 'red'
        }
    ],
    [
        'zq9947',
        {
            'color' => 'red'
        }
    ],
    [
        'zr3285',
        {
            'color' => 'red'
        }
    ],
    [
        'zr4249',
        {
            'color' => 'red'
        }
    ],
    [
        'zs3569',
        {
            'color' => 'red'
        }
    ],
    [
        'zu5260',
        {
            'color' => 'red'
        }
    ],
    [
        'zv8418',
        {
            'color' => 'red'
        }
    ],
    [
        'zw5368',
        {
            'color' => 'red'
        }
    ],
    [
        'zx8907',
        {
            'color' => 'red'
        }
    ],
    [
        'zy949',
        {
            'color' => 'red'
        }
    ]
);

my $h = YAGL->new;
$h->read_csv("$cwd/t/20-vertex-coloring-01.csv");

$h->color_vertices;

my @got2 = $h->vertex_colors;
@got2 = sort { $a->[0] gt $b->[0] } @got2;

is_deeply( \@expected2, \@got2, "The coloring of H was as expected." );

# Chromatic number

my $n2 = $h->chromatic_number;

ok( $n2 == 4, "Chromatic number of H is 4 as expected." );

# Now, we remove all coloring from the graph.

$g->uncolor_vertices;

ok( !$g->is_colored, "G is once again uncolored, as expected." );

__END__

# Local Variables:
# compile-command: "cd .. && perl t/20-vertex-coloring.t"
# End:
