use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::CheckBreaks 0.017

use Test::More tests => 1;

SKIP: {
    skip 'no conflicts module found to check against', 1;
}

SKIP: {
# this data duplicates x_breaks in META.json
my $breaks = {
  "Try::Tiny::Except" => "<= 0.01"
};

skip 'This information-only test requires CPAN::Meta::Requirements', 0
    if not eval 'require CPAN::Meta::Requirements';
skip 'This information-only test requires CPAN::Meta::Check 0.011', 0
    if not eval 'require CPAN::Meta::Check; CPAN::Meta::Check->VERSION(0.011)';

my $reqs = CPAN::Meta::Requirements->new;
$reqs->add_string_requirement($_, $breaks->{$_}) foreach keys %$breaks;

our $result = CPAN::Meta::Check::check_requirements($reqs, 'conflicts');

if (my @breaks = grep { defined $result->{$_} } keys %$result)
{
    diag 'Breakages found with Try-Tiny:';
    diag "$result->{$_}" for sort @breaks;
    diag "\n", 'You should now update these modules!';
}
}
