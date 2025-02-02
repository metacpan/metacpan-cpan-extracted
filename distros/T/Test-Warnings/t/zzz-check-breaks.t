use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::CheckBreaks 0.020

use Test::More tests => 2;
use Term::ANSIColor 'colored';

SKIP: {
    skip 'no conflicts module found to check against', 1;
}

SKIP: {
    # this data duplicates x_breaks in META.json
    my $breaks = {
      "File::pushd" => "< 1.004"
    };

    skip 'This information-only test requires CPAN::Meta::Requirements', 1
        if not eval { +require CPAN::Meta::Requirements };
    skip 'This information-only test requires CPAN::Meta::Check 0.011', 1
        if not eval { +require CPAN::Meta::Check; CPAN::Meta::Check->VERSION(0.011) };

    my $reqs = CPAN::Meta::Requirements->new;
    $reqs->add_string_requirement($_, $breaks->{$_}) foreach keys %$breaks;

    our $result = CPAN::Meta::Check::check_requirements($reqs, 'conflicts');

    if (my @breaks = grep defined $result->{$_}, keys %$result) {
        diag colored('Breakages found with Test-Warnings:', 'yellow');
        diag colored("$result->{$_}", 'yellow') for sort @breaks;
        diag "\n", colored('You should now update these modules!', 'yellow');
    }

    pass 'checked x_breaks data';
}
