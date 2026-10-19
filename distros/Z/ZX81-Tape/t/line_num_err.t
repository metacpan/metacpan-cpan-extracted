use Modern::Perl;
use Path::Tiny;
use Test::More;

BEGIN { use_ok 'ZX81::Tape', 'make_p' }

path("line_num_err.bas")->spew_raw(<<'END');
10 PRINT 1
 9 PRINT 2
END
eval { make_p( "line_num_err.bas", "line_num_err.p" ); };
like( $@, qr/lines out of order/, "lines out of order error" );

path("line_num_err.bas")->spew_raw(<<'END');
10000 PRINT 1
END
eval { make_p( "line_num_err.bas", "line_num_err.p" ); };
like( $@, qr/line number exceeds 9999/, "line number exceeds 9999 error" );

path("line_num_err.bas")->spew_raw(<<'END');
9999 PRINT 1
     PRINT 2
END
eval { make_p( "line_num_err.bas", "line_num_err.p" ); };
like( $@, qr/line number exceeds 9999/, "line number exceeds 9999 error" );

unlink "line_num_err.bas", "line_num_err.p";
done_testing();
