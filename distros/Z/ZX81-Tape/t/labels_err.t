use Modern::Perl;
use Path::Tiny;
use Test::More;

BEGIN { use_ok 'ZX81::Tape', 'make_p' }

path("labels_err.bas")->spew_raw(<<'END');
@start: PRINT 1
@start: PRINT 2
END
eval { make_p( "labels_err.bas", "labels_err.p" ); };
like( $@, qr/duplicate label/, "duplicate label error" );

path("labels_err.bas")->spew_raw(<<'END');
GOTO @end
END
eval { make_p( "labels_err.bas", "labels_err.p" ); };
like( $@, qr/undefined label/, "undefined label error" );

path("labels_err.bas")->spew_raw(<<'END');
PRINT &addr
END
eval { make_p( "labels_err.bas", "labels_err.p" ); };
like( $@, qr/undefined label/, "undefined label error" );

unlink "labels_err.bas", "labels_err.p";
done_testing();
