
BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    print qq{1..0 # SKIP these tests are for testing by the author\n};
    exit
  }
}

use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/WebService/RESTCountries.pm',
    't/00-compile.t',
    't/000-report-versions.t',
    't/00_compile.t',
    't/01_instantiation.t',
    't/02_request.t',
    't/03_search_all.t',
    't/04_search_by_country_name.t',
    't/05_search_by_country_full_name.t',
    't/06_search_by_country_code.t',
    't/07_search_by_country_codes.t',
    't/08_search_by_currency.t',
    't/09_search_by_language_code.t',
    't/10_search_by_capital_city.t',
    't/11_search_by_calling_code.t',
    't/12_search_by_region.t',
    't/13_search_by_region_bloc.t',
    't/14_ping.t',
    't/15_download.t',
    't/author-eol.t',
    't/author-minimum-version.t',
    't/author-pod-coverage.t',
    't/author-pod-syntax.t',
    't/cache/restcountries/0/3/03d59173bad1d8fe9276fbe970f51598.dat',
    't/cache/restcountries/0/4/04c42b9ae2f1456d6798571b0a449807.dat',
    't/cache/restcountries/0/f/0fd43302fc7cd8adfd3e3be0e6116906.dat',
    't/cache/restcountries/1/3/13e0d988c2a7d6488fc616cfac90a951.dat',
    't/cache/restcountries/1/4/14c6aaff0786c171372e76c3c3f64c2f.dat',
    't/cache/restcountries/1/6/16f0e8425d888acc3ff8bbf2eae80931.dat',
    't/cache/restcountries/1/7/177b1a96f19a29fb7d0492f6d36ca452.dat',
    't/cache/restcountries/1/8/186861b2dbe1b5b6d215123ede991e90.dat',
    't/cache/restcountries/1/d/1d6f217ad1b7f2414109666ca9661781.dat',
    't/cache/restcountries/2/0/20383aed74b90405150ea35fca864734.dat',
    't/cache/restcountries/2/8/28643c28d00f5f8a73682cbdda276035.dat',
    't/cache/restcountries/2/f/2f214384184906e871fa639f15c46380.dat',
    't/cache/restcountries/3/4/34e873d64d6341d479d341614b756e6e.dat',
    't/cache/restcountries/3/b/3b70607a1d847a2d0c08c11d0d2c75b2.dat',
    't/cache/restcountries/3/e/3edda0034b67e14c50c46dec112a03bd.dat',
    't/cache/restcountries/3/e/3edde218aef315f6fbb671ae3dac9de9.dat',
    't/cache/restcountries/4/c/4cbcc6ffbfe27d04847de67685f0e8ec.dat',
    't/cache/restcountries/4/f/4f65c52994c3c961e60fb920dbff6e4c.dat',
    't/cache/restcountries/4/f/4ff0a51921aab604da4031d462428194.dat',
    't/cache/restcountries/5/1/5181336446cefb7b5300875862832d55.dat',
    't/cache/restcountries/5/1/51d16bd0915c073144edea3920eb43f3.dat',
    't/cache/restcountries/5/5/5574cd255adbee43bf3595f445e7a773.dat',
    't/cache/restcountries/5/5/55f30714f273342107e13a4a41c5449b.dat',
    't/cache/restcountries/5/7/5792845b1848b39af38129d0bd39db78.dat',
    't/cache/restcountries/6/2/625babbae39246d4376f71e4a6f27f0a.dat',
    't/cache/restcountries/6/4/64cdea3c2ead8d4d11eeaa1dff7ec22a.dat',
    't/cache/restcountries/6/6/661ec91109450f2ba4a6f7591f4a889e.dat',
    't/cache/restcountries/6/9/69352ee886f7aeadd5e2d6fcc346528a.dat',
    't/cache/restcountries/6/9/698778a0b3fed91d1f335e1f147444a8.dat',
    't/cache/restcountries/7/2/72ceb090aa0b35de572b2ff09caca3a1.dat',
    't/cache/restcountries/7/6/76410091ae8af27d612b542931c3e6c9.dat',
    't/cache/restcountries/7/8/78151a52b5938d78b38ab547ad415ff0.dat',
    't/cache/restcountries/7/a/7a63ae18edb5fb804b2bc1c4d9b7d824.dat',
    't/cache/restcountries/7/b/7b68741196b8a7cc7cca9600b9e68564.dat',
    't/cache/restcountries/8/1/81a7c4065699f90587484e1432fb90bd.dat',
    't/cache/restcountries/8/9/89d4e36c2dedfa8fde3f27d6122d10df.dat',
    't/cache/restcountries/8/e/8eb9d1e94bddbc22e53be30aad940c56.dat',
    't/cache/restcountries/9/8/98d51192b35861acd068809d6f40839e.dat',
    't/cache/restcountries/9/9/99064b9666682a09d42c5ff36f5065e3.dat',
    't/cache/restcountries/9/9/9915a9375d0687e127c23a7b6de9cbb7.dat',
    't/cache/restcountries/9/d/9d94050d88e143ceaa007865079cd553.dat',
    't/cache/restcountries/a/b/abb38e2797cd66d0df5d08c63294b333.dat',
    't/cache/restcountries/a/d/ad7621479f6b7b3a1c16f18852c31484.dat',
    't/cache/restcountries/b/7/b7575122e5e7b82064834f432dd8f064.dat',
    't/cache/restcountries/b/8/b8e468a3b0851be43e481cfffb7bb9bd.dat',
    't/cache/restcountries/b/b/bbded1d40db0a5563a26ad32d79c3017.dat',
    't/cache/restcountries/b/d/bd78737e12ae41932b810760a4130bed.dat',
    't/cache/restcountries/c/1/c16973d774a601a5510156d38cc51636.dat',
    't/cache/restcountries/c/f/cf3784d87ce55c757378cb7637bb448b.dat',
    't/cache/restcountries/c/f/cfdbf194ad379649a2e41ab92bd1f68f.dat',
    't/cache/restcountries/d/0/d0796cc850a63f55e67e7629f43055ca.dat',
    't/cache/restcountries/d/4/d4f8aeb7493754bd33363e1f4f7c6ea3.dat',
    't/cache/restcountries/d/b/db9e65f2958e154e6473b8c01b3df208.dat',
    't/cache/restcountries/d/c/dca5605bcfaef5e81f6a34724a26dabe.dat',
    't/cache/restcountries/d/e/de7aeb7fb5cebd834decb72e5203f994.dat',
    't/cache/restcountries/e/4/e48e6301f4a534a4b57bda81e4444a0a.dat',
    't/cache/restcountries/e/4/e4ae7c392f74ec2456037a8ed9860a86.dat',
    't/cache/restcountries/e/e/ee3129e927e5f9b5c4937a3d8c8bacf4.dat',
    't/cache/restcountries/e/e/ee4384e41ed14dd3175e116bc30ef38c.dat',
    't/cache/restcountries/e/e/eeb2a4e6a82885a2628e538331e32f4c.dat',
    't/cache/restcountries/e/f/ef5e2511cfd53368f4087d897e19f936.dat',
    't/cache/restcountries/f/5/f51a16b67e556ab7f63b109f260347b6.dat',
    't/cache/restcountries/f/d/fd5cd4c45f420eae17782de07a9cab4b.dat',
    't/cache/restcountries/f/e/fefeac1ff86ce4764ce0927c6bbfb290.dat',
    't/release-dist-manifest.t',
    't/release-distmeta.t',
    't/release-has-version.t',
    't/release-kwalitee.t',
    't/release-unused-vars.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
