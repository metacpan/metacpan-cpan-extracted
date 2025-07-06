use v5.14;
use warnings;

use Test2::V0;
use Test2::API qw( intercept );
use Test2::Plugin::UTF8;
use Test2::Tools::Exception qw( dies );

use Test::MixedScripts qw( file_scripts_ok );

file_scripts_ok(__FILE__);

file_scripts_ok( 't/data/bad-01.txt', qw( Latin Armenian Common ) );

file_scripts_ok( 't/data/bad-01.txt', { scripts => [qw( Latin Armenian Common )] } );

my $b1 = intercept {
    file_scripts_ok('t/data/bad-01.txt');
};

is $b1->squash_info->flatten,
  [
    {
        about          => "fail",
        causes_failure => 1,
        diag           => [ "Unexpected Armenian character ARMENIAN SMALL LETTER CO on line 8 character 22 in t/data/bad-01.txt", ],
        name           => 't/data/bad-01.txt',
        pass           => 0,
        trace_file     => __FILE__,
        trace_line     => 18,
    }
  ],
  "expected failure";


file_scripts_ok( 't/data/bad-02.js', qw( Latin Armenian Common ) );

my $b2 = intercept {
    file_scripts_ok('t/data/bad-02.js');
};

is $b2->squash_info->flatten,
  [
    {
        about          => "fail",
        causes_failure => 1,
        diag           => [ "Unexpected Armenian character ARMENIAN SMALL LETTER CO on line 4 character 41 in t/data/bad-02.js", ],
        name           => 't/data/bad-02.js',
        pass           => 0,
        trace_file     => __FILE__,
        trace_line     => 39,
    }
  ],
  "expected failure";

file_scripts_ok( 't/data/good-03.pod' );

like(
     dies { file_scripts_ok( 't/data/good-03.pod', 'BadScriptName' ) },
     qr/^Unknown script BadScriptName/,
     "died on unknown script name"
);

file_scripts_ok( 't/data/ascii-01.txt', qw( ASCII ) );

my $b3 = intercept {
    file_scripts_ok('t/data/bad-03.txt', qw( ASCII ) );
};

is $b3->squash_info->flatten,
  [
    {
        about          => "fail",
        causes_failure => 1,
        diag           => [ "Unexpected Latin character LATIN SMALL LETTER E WITH CIRCUMFLEX on line 4 character 4 in t/data/bad-03.txt", ],
        name           => 't/data/bad-03.txt',
        pass           => 0,
        trace_file     => __FILE__,
        trace_line     => 67,
    }
  ],
  "expected failure";

file_scripts_ok( 't/data/ascii-01.txt', qw( Latin Common ) );


done_testing;
