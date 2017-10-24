#!perl

use Test::More;
use ZMQ::Raw;

ZMQ::Raw->has (ZMQ::Raw->FEATURE_IPC);
ZMQ::Raw->has (ZMQ::Raw->FEATURE_PGM);
ZMQ::Raw->has (ZMQ::Raw->FEATURE_TIPC);
ok (!ZMQ::Raw->has (ZMQ::Raw->FEATURE_NORM));
ok (!ZMQ::Raw->has (ZMQ::Raw->FEATURE_GSSAPI));
ok (ZMQ::Raw->has (ZMQ::Raw->FEATURE_CURVE));
ok (ZMQ::Raw->has (ZMQ::Raw->FEATURE_DRAFT));
ok (!eval {ZMQ::Raw->has (-1)});

done_testing;

