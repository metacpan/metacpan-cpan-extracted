use strict;
use warnings;
use English;
use Test::More;

if ( not $ENV{AUTHOR_TESTING} ) {
    my $msg =
'Author test. Set the environment variable AUTHOR_TESTING to enable this test.';
    plan( skip_all => $msg );
}

eval { require Test::Spelling; };

if ($EVAL_ERROR) {
    my $msg = 'Test::Spelling required to check spelling of POD';
    plan( skip_all => $msg );
}

Test::Spelling::all_pod_files_spelling_ok();
