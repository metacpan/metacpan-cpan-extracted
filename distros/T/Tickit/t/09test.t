#!/usr/bin/perl

use strict;
use warnings;

use Test::Builder::Tester tests => 16;
use Tickit::Test;

my $term = mk_term lines => 3, cols => 10;

# termlog empty
{
   test_out( "ok 1 - Termlog initially empty" );
   is_termlog( [],
               'Termlog initially empty' );
   test_test( 'is_termlog empty pass' );

   test_out( "ok 1 - Display initially" );
   is_display( [],
               'Display initially' );
   test_test( 'is_display empty pass' );

   test_out( "not ok 1 - Termlog initially has CLEAR" );
   test_fail( +2 );
   test_diag( "Expected terminal operation clear(), got none at step 0" );
   is_termlog( [ CLEAR ],
               'Termlog initially has CLEAR' );
   test_test( 'is_termlog none-empty fail' );

   test_out( "not ok 1 - Display initially filled" );
   test_fail( +4 );
   test_diag( "Display differs on line 0" );
   test_diag( "Got:      '          '" );
   test_diag( "Expected: '12345     '" );
   is_display( [ "12345" ],
               'Display initially filled' );
   test_test( 'is_display non-empty fail' );
}

# termlog
{
   $term->goto( 2, 2 );
   $term->print( "hello!" );

   test_out( "ok 1 - Termlog after goto+print" );
   is_termlog( [ GOTO(2,2),
                 PRINT("hello!") ],
               'Termlog after goto+print' );
   test_test( 'is_termlog non-empty pass' );

   test_out( "ok 1 - Display after goto+print" );
   is_display( [ "",
                 "",
                 "  hello!" ],
               'Display after goto+print' );
   test_test( 'is_display after goto+print pass' );

   test_out( "ok 1 - Cursor position after goto+print" );
   is_cursorpos( 2, 8,
                 'Cursor position after goto+print' );
   test_test( 'is_cursorpos pass' );

   test_out( "not ok 1 - Cursor position after goto+print" );
   test_fail( +2 );
   test_diag( "Expected to be on column 6, actually on column 8" );
   is_cursorpos( 2, 6,
                 'Cursor position after goto+print' );
   test_test( 'is_cursorpos pass' );

   $term->clear;
   drain_termlog;
}

# termlog position-associative
{
   $term->goto( 0, 0 );
   $term->print( "Line 0" );
   $term->goto( 1, 0 );
   $term->print( "Line 1" );

   test_out( "ok 1 - Termlog associative" );
   is_termlog( { "0,0" => [ PRINT("Line 0") ],
                 "1,0" => [ PRINT("Line 1") ] },
               'Termlog associative' );
   test_test( 'is_termlog associative' );

   $term->goto( 1, 0 );
   $term->print( "Line 1" );
   $term->goto( 0, 0 );
   $term->print( "Line 0" );

   test_out( "ok 1 - Termlog associative in reverse order" );
   is_termlog( { "0,0" => [ PRINT("Line 0") ],
                 "1,0" => [ PRINT("Line 1") ] },
               'Termlog associative in reverse order' );
   test_test( 'is_termlog associative in reverse order' );

   $term->goto( 0, 0 );
   $term->setpen();
   $term->print( "Line 0" );
   $term->goto( 1, 0 );
   $term->print( "Line 1" );

   test_out( "not ok 1 - Termlog associative" );
   test_fail( +2 );
   test_diag( 'Expected terminal operation print("Line 0"), got setpen({}) at step 0' );
   is_termlog( { "0,0" => [ PRINT("Line 0") ],
                 "1,0" => [ PRINT("Line 1") ] },
               'Termlog associative' );
   test_test( 'is_termlog associative fails mismatch' );

   $term->goto( 0, 0 );
   $term->print( "Line 0" );
   $term->print( "Hi!" );
   $term->goto( 1, 0 );
   $term->print( "Line 1" );

   test_out( "not ok 1 - Termlog associative" );
   test_fail( +3 );
   test_diag( 'Expected terminal operation none, got print("Hi!") at step 1' );
   test_diag( '  after print("Line 0")');
   is_termlog( { "0,0" => [ PRINT("Line 0") ],
                 "1,0" => [ PRINT("Line 1") ] },
               'Termlog associative' );
   test_test( 'is_termlog associative fails extra' );

   $term->goto( 0, 0 );
   $term->goto( 1, 0 );
   $term->print( "Line 1" );

   test_out( "not ok 1 - Termlog associative" );
   test_fail( +2 );
   test_diag( 'Expected terminal operation print("Line 0"), got none at step 0' );
   is_termlog( { "0,0" => [ PRINT("Line 0") ],
                 "1,0" => [ PRINT("Line 1") ] },
               'Termlog associative' );
   test_test( 'is_termlog associative fails missing' );

   $term->clear;
   drain_termlog;
}

# is_display with attributes
{
   $term->goto( 0, 0 );
   $term->chpen( fg => 1 );
   $term->print( "ABC" );
   $term->chpen( fg => 2 );
   $term->print( "DE" );

   test_out( "ok 1 - Display with attributes" );
   is_display( [ [TEXT("ABC",fg => 1), TEXT("DE",fg => 2)] ],
               'Display with attributes' );
   test_test( 'is_display with attributes pass' );

   test_out( "not ok 1 - Display with attributes" );
   test_fail( +4 );
   test_diag( "Display differs on line 0 at column 5" );
   test_diag( "Got:      '   '" );
   test_diag( "Expected: 'FGH'" );
   is_display( [ [TEXT("ABC",fg => 1), TEXT("DE",fg => 2), TEXT("FGH")] ],
               'Display with attributes' );
   test_test( 'is_display with attributes fail text' );

   test_out( "not ok 1 - Display with attributes" );
   test_fail( +4 );
   test_diag( "Display differs on line 0 at column 3" );
   test_diag( "Got pen:      {fg=2}" );
   test_diag( "Expected pen: {fg=2,u=1}" );
   is_display( [ [TEXT("ABC",fg => 1), TEXT("DE",fg => 2, u => 1)] ],
               'Display with attributes' );
   test_test( 'is_display with attributes fail attrs' );
}
