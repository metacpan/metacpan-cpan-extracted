use strict;
use warnings;
use utf8;

use Test::More;
use ThaiSchema::JSON;
use ThaiSchema;

my $json = q/{"prop": {"subprop": 1}}/;
my $null_json = q/{"prop": null}/;

my $schema = +{
    prop => type_maybe(type_hash(+{
        subprop => type_int
    }))
};

my $j = ThaiSchema::JSON->new();

{
    # This test will pass.
    my ($ok, $errors) = $j->validate($null_json, $schema);
    ok($ok);
    diag($_) for @$errors;
}

{
    # This test case will fail.
    # at ThaiSchema.t line 32.
    # Can't locate object method "schema" via package "ThaiSchema::Maybe"
    #   at /Library/Perl/5.18/ThaiSchema/JSON.pm line 190.
    my ($ok, $errors) = $j->validate($json, $schema);
    ok($ok);
    diag($_) for @$errors;
}
done_testing;
