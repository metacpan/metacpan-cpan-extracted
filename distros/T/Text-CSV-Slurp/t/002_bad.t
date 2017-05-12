#!perl

use strict;
use warnings;

use lib 'lib';

use Test::Most tests => 8;
use Text::CSV::Slurp;

my $expected = [
  {
    "Phone" => "555 1234",
    "Email" => "albert\@example.com",
    "Email 1" => "Albert\@example.com",
    "Email 1 Is Operational" => "True",
    "Email 2" => "",
    "Email 2 Is Operational" => "False",
    "First/Given Name" => "Albert",
    "Full Name" => "Albery Hitchcock",
    "Home Country/Region" => "United States of America",
    "Last/Family Name" => "Hichcock",
    "Mobile Phone" => "",
  },
];

=head1 SUMMARY

Test handling poorly formatted CSV

=cut

{
    my $data = eval {
                Text::CSV::Slurp->load(file => 't/data/valid.csv');
               };

    is $@, '', "Valid CSV doesn't error";
    cmp_deeply $data, $expected, 'Valid CSV parsed';
}

{
    my $data = eval {
                Text::CSV::Slurp->load(file => 't/data/bad_whitespace.csv');
               };

    like $@, qr/Loose unescaped quote/, "Bad whitespace CSV returns an error";
    is ref($data), '', 'Bad whitespace CSV not parsed';
}

{
    my $data = eval {
                Text::CSV::Slurp->load(file => 't/data/bad_whitespace.csv', allow_whitespace => 1 );
               };

    is $@, '', "Bad whitespace CSV doesn't error when allow_whitespace option set";
    cmp_deeply $data, $expected, 'Bad whitespace CSV parsed when allow_whitespace option set';
}

{
    my $data = eval {
                Text::CSV::Slurp->load(file => 't/data/i_dont_exist.csv', allow_whitespace => 1 );
               };
    like $@, qr^Could not open t/data/i_dont_exist\.csv .+^, "Inexistent input file returns intelligible error";
    is ref($data), '', 'Inexistent input file not parsed';
}
