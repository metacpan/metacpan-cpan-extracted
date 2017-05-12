use strict;
use warnings;
use Test::More;

use Validation::Class::Simple;

sub validate_ignoring_filters_1
{
    my ($validation, $hashref) = @_;
    $validation->params->clear;
    $validation->params->add(%$hashref);
    no warnings "redefine";
    local *Validation::Class::Directive::Filters::execute_filtering = sub { $_[0] };
    my $r = eval { $validation->validate };
    return $r;
}

sub validate_ignoring_filters_2
{
    my ($validation, $hashref) = @_;
    $validation->filtering("off");
    $validation->params->clear;
    $validation->params->add(%$hashref);
    my $r = eval { $validation->validate };
    $validation->filtering("pre");
    return $r;
}

my $vsimple = "Validation::Class::Simple"->new(
    fields => {
        name => { required => 1, pattern  => qr{^\w+$}, filters => "trim" },
    },
);

my $should_pass = { name =>  "foo"  };
my $should_fail = { name => " foo " };

ok(
    validate_ignoring_filters_1($vsimple, $should_pass),
    'validate_ignoring_filters_1($vsimple, $should_pass)',
);

ok(
    !validate_ignoring_filters_1($vsimple, $should_fail),
    '!validate_ignoring_filters_1($vsimple, $should_fail)',
);

ok(
    validate_ignoring_filters_2($vsimple, $should_pass),
    'validate_ignoring_filters_2($vsimple, $should_pass)',
);

ok(
    !validate_ignoring_filters_2($vsimple, $should_fail),
    '!validate_ignoring_filters_2($vsimple, $should_fail)',
);

done_testing;
