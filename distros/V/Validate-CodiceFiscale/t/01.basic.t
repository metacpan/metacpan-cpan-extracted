#!/usr/bin/env perl
use v5.24;
use warnings;
use experimental 'signatures';

use Test::More;
use Test::Exception;

use Validate::CodiceFiscale qw< assert_valid_cf is_valid_cf validate_cf >;

# We set two fictious people:
#
# - Mario Rossi, born 1998/11/03 in B833
# - Carla Risi,  born 1999/03/11 in C967
#
# Both are impossible because the two location codes were suppressed in
# their respective years of use above (this validator does not validate
# *this*).

my @tests = (
   ['RSSMRA98S03B833G', [], {}, ''],
   ['RSICRL99C51C967W', [], {}, ''],
   [
      'RSICRL99C51C967W',
      [],
      {
         data => {
            name       => 'Carla',
            surname    => 'Risi',
            birthdate  => '1999-03-11',
            birthplace => 'C967',
            sex        => 'f'
         }
      },
      ''
   ],
   ['RSICRL99C51C967WX', ['invalid length'],                  {}, ''],
   ['RSICRL99C51C967X',  ['invalid checksum (should be: W)'], {}, ''],
   ['RISCRL99C51C967F',  ['invalid surname'], {}, 'invalid surname'],
   ['RSICAL99C51C967P',  ['invalid name'],    {}, 'invalid name'],
   [
      'RSICRL99O51C967C', ['invalid birth date'], {},
      'invalid date (month)'
   ],
   ['RSICRL99B30C967Q', ['invalid birth date'],  {}, 'invalid date (day)'],
   ['RSICRL99C51CC67G', ['invalid birth place'], {}, 'invalid place'],
   [
      'RSICRL99C51C967W',            ['surname mismatch'],
      {data => {surname => 'Rosi'}}, 'surname mismatch'
   ],
   [
      'RSICRL99C51C967W',             ['name mismatch'],
      {data => {name => 'Carolina'}}, 'name mismatch'
   ],
   [
      'RSICRL99C51C967W',                    ['birth date mismatch'],
      {data => {birthdate => '1999-03-12'}}, 'birth date mismatch'
   ],
   [
      'RSICRL99C51C967W',               ['birth place mismatch'],
      {data => {birthplace => 'B833'}}, 'birth place mismatch'
   ],
   [
      'RSICRL99C11C967S',     ['sex mismatch'],
      {data => {sex => 'f'}}, 'sex mismatch'
   ],
   [
      'RSICRL99C11C967X',
      ['invalid checksum (should be: S)', 'sex mismatch'],
      {data => {sex => 'f'}},
      'sex mismatch & invalid checksum'
   ],
   [
      'RISCRL99C11C967X',
      [
         'invalid surname',
         'invalid checksum (should be: B)',
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
   ok $comparison, "is_valid, $msg";

   my $got = validate_cf($cf, $opts->%*) // [];
   is_deeply $got, $exp, "validate_cf, $msg";

   if ($exp) {
      dies_ok { assert_cf($cf, $opts->%*) } "assert_cf, $msg";
   }
   else {
      lives_ok { assert_valid_cf($cf, $opts->%*) } "assert_cf, $msg";
   }
} ## end for my $test (@tests)

done_testing();
