#!/usr/bin/perl

use WWW::Testafy;
use strict;
use warnings;

my $te = new WWW::Testafy(
    testafy_username => 'your_username',
    testafy_password => 'your_password',
);


my $id = $te->run_test(
    product => 'Google',
    pbehave => qq{
        For the url http://www.google.com

        Given a test delay of 1 second
        When the search query field is "Grant Street Group"
        Then the text "Grant Street Group" is present
        and the text "Forbes Ave" is present

        When the "Advanced search" link is clicked
        and the "all these words" textbox is "grant street group"
        and the "Advanced Search" button is clicked
        Then the text "Grant Street Group" is present
        and the text "Forbes Ave" is present

        When the "Advanced search" link is clicked
        and "Indian River" is typed in the "All these words" textbox
        and "grantstreet.com" is typed in the "Search within a site" textbox
        and the "Advanced Search" button is clicked
        Then the text TaxSys is present
    },
    verbose => 1,
);


die "API Error: ".$te->error_string."\n" unless $id;

print "Running $id\n";

my $status = $te->test_status($id);
while($status !~ /^(completed|skipped|stopped|failed)$/) {
    sleep 5;
    my $passed  = $te->test_passed($id);
    my $planned = $te->test_planned($id);
    print "Passed $passed tests out of $planned: $status\n";
    $status = $te->test_status($id);
}
print $te->test_results_as_string($id);
