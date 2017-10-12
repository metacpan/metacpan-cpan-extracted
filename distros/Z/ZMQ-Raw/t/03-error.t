#!perl

use Test::More;
use ZMQ::Raw;

isnt 0, ZMQ::Raw::Error->ENOTSUP;
isnt 0, ZMQ::Raw::Error->EPROTONOSUPPORT;
isnt 0, ZMQ::Raw::Error->ENOBUFS;
isnt 0, ZMQ::Raw::Error->ENETDOWN;
isnt 0, ZMQ::Raw::Error->EADDRINUSE;
isnt 0, ZMQ::Raw::Error->EADDRNOTAVAIL;
isnt 0, ZMQ::Raw::Error->ECONNREFUSED;
isnt 0, ZMQ::Raw::Error->EINPROGRESS;
isnt 0, ZMQ::Raw::Error->ENOTSOCK;
isnt 0, ZMQ::Raw::Error->EMSGSIZE;
isnt 0, ZMQ::Raw::Error->EAFNOSUPPORT;
isnt 0, ZMQ::Raw::Error->ENETUNREACH;
isnt 0, ZMQ::Raw::Error->ECONNABORTED;
isnt 0, ZMQ::Raw::Error->ECONNRESET;
isnt 0, ZMQ::Raw::Error->ENOTCONN;
isnt 0, ZMQ::Raw::Error->ETIMEDOUT;
isnt 0, ZMQ::Raw::Error->EHOSTUNREACH;
isnt 0, ZMQ::Raw::Error->ENETRESET;
isnt 0, ZMQ::Raw::Error->EFSM;
isnt 0, ZMQ::Raw::Error->ENOCOMPATPROTO;
isnt 0, ZMQ::Raw::Error->ETERM;
isnt 0, ZMQ::Raw::Error->EMTHREAD;

done_testing;

