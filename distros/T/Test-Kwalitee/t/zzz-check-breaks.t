use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::CheckBreaks 0.017

use Test::More tests => 1;

SKIP: {
    skip 'no conflicts module found to check against', 1;
}

# this data duplicates x_breaks in META.json
my $breaks = {
  "Dist::Zilla::Plugin::Test::Kwalitee" => "<= 2.04"
};

use CPAN::Meta::Requirements;
use CPAN::Meta::Check 0.011;

my $reqs = CPAN::Meta::Requirements->new;
$reqs->add_string_requirement($_, $breaks->{$_}) foreach keys %$breaks;

our $result = CPAN::Meta::Check::check_requirements($reqs, 'conflicts');

if (my @breaks = grep { defined $result->{$_} } keys %$result)
{
    diag 'Breakages found with Test-Kwalitee:';
    diag "$result->{$_}" for sort @breaks;
    diag "\n", 'You should now update these modules!';
}
