#!/usr/bin/env perl
use v5.24;
use warnings;
use experimental 'signatures';

use Test::More;
use Test::Exception;

use Validate::CodiceFiscale qw< assert_valid_cf is_valid_cf validate_cf >;

# We set two fictious people:
#
# - Mario Rossi, born 1998/11/03 in H501
# - Carla Risi,  born 1999/03/11 in A020
#
# Both are impossible because the two location codes were suppressed in
# their respective years of use above (this validator does not validate
# *this*).

my @tests = (
   ['RSSMRA98S03H501W', [], {}, ''],
   ['RSICRL99C51A020G', [], {}, ''],
   [
      'RSICRL99C51A020G',
      [],
      {
         data => {
            name    => 'Carla',
            surname => 'Risi',
            date    => '1999-03-11',
            place   => 'ACERENZA',
            sex     => 'f'
         }
      },
      ''
   ],
   ['RSICRL99C51C967WX', ['invalid length'],                  {}, ''],
   ['RSICRL99C51A020X',  ['invalid checksum (should be: G)'], {}, ''],
   ['RISCRL99C51A020P',  ['invalid surname'], {}, 'invalid surname'],
   ['RSICAL99C51A020Z',  ['invalid name'],    {}, 'invalid name'],
   [
      'RSICRL99O51A020M', ['invalid birth date'], {},
      'invalid date (month)'
   ],
   ['RSICRL99B30A020A', ['invalid birth date'],  {}, 'invalid date (day)'],
   ['RSICRL99C51A003K', ['invalid birth place'], {}, 'invalid place (expired)'],
   [
      'RSICRL99C51A020G',            ['surname mismatch'],
      {data => {surname => 'Rosi'}}, 'surname mismatch'
   ],
   [
      'RSICRL99C51A020G',             ['name mismatch'],
      {data => {name => 'Carolina'}}, 'name mismatch'
   ],
   [
      'RSICRL99C51A020G',                    ['birth date mismatch'],
      {data => {date => '1999-03-12'}}, 'birth date mismatch'
   ],
   [
      'RSICRL99C51A020G',               ['birth place mismatch'],
      {data => {place => 'B833'}}, 'birth place mismatch'
   ],
   [
      'RSICRL99C11A020C',     ['sex mismatch'],
      {data => {sex => 'f'}}, 'sex mismatch'
   ],
   [
      'RSICRL99C11A020X',
      ['invalid checksum (should be: C)', 'sex mismatch'],
      {data => {sex => 'f'}},
      'sex mismatch & invalid checksum'
   ],
   [
      'RISCRL99C11A020X',
      [
         'invalid surname',
         'invalid checksum (should be: L)',
         'sex mismatch'
      ],
      {data => {sex => 'f'}},
      'multiple errors',
   ],
);

for my $test (@tests) {
   my ($cf, $exp, $opts, $msg) = $test->@*;
   $msg ||= $cf;

   # quick check
   my $got_valid  = is_valid_cf($cf, $opts->%*);
   my $comparison = ($got_valid xor !!($exp->@*));
   ok $comparison, "is_valid, $msg"
      or diag "got<$got_valid> exp<@{[ !!($exp->@*) ]}> comparison<$comparison>";

   my $got = validate_cf($cf, $opts->%*) // [];
   is_deeply $got, $exp, "validate_cf, $msg";

   if ($exp->@*) {
      dies_ok  { assert_valid_cf($cf, $opts->%*) } "assert_cf, $msg";
   }
   else {
      lives_ok { assert_valid_cf($cf, $opts->%*) } "assert_cf, $msg";
   }

   #last;
} ## end for my $test (@tests)

done_testing();
