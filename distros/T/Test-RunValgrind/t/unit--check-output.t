#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 3;

use Test::RunValgrind ();

{
    my $obj = Test::RunValgrind->new;

    # TEST
    ok( scalar( $obj->_calc_verdict( \<<'EOF') ), 'normal is fine by default' );
==26077== Memcheck, a memory error detector
==26077== Copyright (C) 2002-2017, and GNU GPL'd, by Julian Seward et al.
==26077== Using Valgrind-3.13.0 and LibVEX; rerun with -h for copyright info
==26077== Command: /bin/true
==26077==
==26077==
==26077== HEAP SUMMARY:
==26077==     in use at exit: 0 bytes in 0 blocks
==26077==   total heap usage: 0 allocs, 0 frees, 0 bytes allocated
==26077==
==26077== All heap blocks were freed -- no leaks are possible
==26077==
==26077== For counts of detected and suppressed errors, rerun with: -v
==26077== ERROR SUMMARY: 0 errors from 0 contexts (suppressed: 0 from 0)
EOF
}

{
    my $obj = Test::RunValgrind->new;

    # TEST
    ok(
        scalar(
            !$obj->_calc_verdict( \<<'EOF') ), 'leak is not fine by default' );
==30012== Memcheck, a memory error detector
==30012== Copyright (C) 2002-2017, and GNU GPL'd, by Julian Seward et al.
==30012== Using Valgrind-3.13.0 and LibVEX; rerun with -h for copyright info
==30012== Command: ./a.out
==30012==
==30012==
==30012== HEAP SUMMARY:
==30012==     in use at exit: 100 bytes in 1 blocks
==30012==   total heap usage: 1 allocs, 0 frees, 100 bytes allocated
==30012==
==30012== 100 bytes in 1 blocks are definitely lost in loss record 1 of 1
==30012==    at 0x4C27EDB: malloc (vg_replace_malloc.c:299)
==30012==    by 0x400518: main (in /home/shlomif/progs/C/snippets/shlomif-c-snippets/a.out)
==30012==
==30012== LEAK SUMMARY:
==30012==    definitely lost: 100 bytes in 1 blocks
==30012==    indirectly lost: 0 bytes in 0 blocks
==30012==      possibly lost: 0 bytes in 0 blocks
==30012==    still reachable: 0 bytes in 0 blocks
==30012==         suppressed: 0 bytes in 0 blocks
==30012==
==30012== For counts of detected and suppressed errors, rerun with: -v
==30012== ERROR SUMMARY: 1 errors from 1 contexts (suppressed: 0 from 0)
EOF
}

{
    my $obj = Test::RunValgrind->new( { ignore_leaks => 1 } );

    # TEST
    ok( scalar( $obj->_calc_verdict( \<<'EOF') ), 'leak is fine if ignored' );
==30012== Memcheck, a memory error detector
==30012== Copyright (C) 2002-2017, and GNU GPL'd, by Julian Seward et al.
==30012== Using Valgrind-3.13.0 and LibVEX; rerun with -h for copyright info
==30012== Command: ./a.out
==30012==
==30012==
==30012== HEAP SUMMARY:
==30012==     in use at exit: 100 bytes in 1 blocks
==30012==   total heap usage: 1 allocs, 0 frees, 100 bytes allocated
==30012==
==30012== 100 bytes in 1 blocks are definitely lost in loss record 1 of 1
==30012==    at 0x4C27EDB: malloc (vg_replace_malloc.c:299)
==30012==    by 0x400518: main (in /home/shlomif/progs/C/snippets/shlomif-c-snippets/a.out)
==30012==
==30012== LEAK SUMMARY:
==30012==    definitely lost: 100 bytes in 1 blocks
==30012==    indirectly lost: 0 bytes in 0 blocks
==30012==      possibly lost: 0 bytes in 0 blocks
==30012==    still reachable: 0 bytes in 0 blocks
==30012==         suppressed: 0 bytes in 0 blocks
==30012==
==30012== For counts of detected and suppressed errors, rerun with: -v
==26077== ERROR SUMMARY: 0 errors from 0 contexts (suppressed: 0 from 0)
EOF
}
