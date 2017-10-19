#!perl

use Test::More;
use ZMQ::Raw;

ok (ZMQ::Raw->FEATURE_IPC);
ok (ZMQ::Raw->FEATURE_PGM);
ok (ZMQ::Raw->FEATURE_TIPC);
ok (!ZMQ::Raw->has (ZMQ::Raw->FEATURE_NORM));
ok (!ZMQ::Raw->has (ZMQ::Raw->FEATURE_GSSAPI));
ok (ZMQ::Raw->has (ZMQ::Raw->FEATURE_CURVE));
ok (ZMQ::Raw->has (ZMQ::Raw->FEATURE_DRAFT));

done_testing;

