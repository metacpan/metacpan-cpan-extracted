#!perl

use strict;
use warnings;

use lib 'lib';

use Test::Most tests => 2;
use Text::CSV::Slurp;

my $input  = [
  {
    "Currency Symbol" => '$',
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
  {
    "Phone" => "555 8885",
    "Email" => "fanny\@example.com",
    "Email 1" => "Fanny\@example.com",
    "Email 2" => "",
    "Email 2 Is Operational" => "False",
    "Home Country/Region" => "UK",
    "Last/Family Name" => "Adams",
    "Mobile Phone" => "44 1495 525252",
    "First/Given Name" => "Fanny",
    "Full Name" => "Fanny Adams",
    "Currency Symbol" => "£",
  },
];

my $output = 'Email,"Email 1","Email 1 Is Operational","Email 2","Email 2 Is Operational","First/Given Name","Full Name","Home Country/Region","Last/Family Name","Mobile Phone",Phone,"Currency Symbol"
albert@example.com,Albert@example.com,True,,False,Albert,"Albery Hitchcock","United States of America",Hichcock,,"555 1234",$
fanny@example.com,Fanny@example.com,,,False,Fanny,"Fanny Adams",UK,Adams,"44 1495 525252","555 8885",£';


=head1 SUMMARY

Test creating CSV from array of hashes

=cut

{

    my @field_order = ( "Email",
                        "Email 1",
                        "Email 1 Is Operational",
                        "Email 2",
                        "Email 2 Is Operational",
                        "First/Given Name",
                        "Full Name",
                        "Home Country/Region",
                        "Last/Family Name",
                        "Mobile Phone",
                        "Phone",
                        "Currency Symbol" );

    my $csv = eval {
                Text::CSV::Slurp->create( input => $input, field_order => \@field_order );
               };

    is $@, '', "Valid input doesn't error";
    is $csv, $output, "Produces the CSV we expected";

}