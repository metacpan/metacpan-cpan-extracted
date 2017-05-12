use FindBin;
use Data::Dumper;
use Test::More;

use utf8;
use strict;
use warnings;

{

    use_ok 'Validation::Class::Simple::Streamer';

    # passable

    my $params = {
        user    => 'admin',             # arbitrary
        pass    => 's3cret',            # arbitrary
        email_1 => 'admin@cpan.org',   # dynamic created
        email_2 => 'root@cpan.org',    # dynamic created
        email_3 => 'sa@cpan.org',      # dynamic created
    };

    my $p1 = Validation::Class::Simple::Streamer->new(params => $params);

    if ($p1->check('user')->min_length(5)) {
        if ($p1->max_length(50)) {
            $p1->filters(['alpha', 'trim', 'strip']);
            ok $p1, "p1 validated";
            ok $p1, "p1 still validated";
        }
    }

    ok !$p1->min_symbols(1), "p1 fails to validate min_symbols:1";
    ok $p1->min_symbols(0), "p1 passes to validate min_symbols:0";

    $p1->check('arbitrary')->required;
    $p1->validate;

    ok "$p1" eq "arbitrary is required", "p1 error message is accurate";

    $p1->fields->delete('user');

    $p1->alias(['user'])->validate;

    ok "$p1" eq "", "p1 has no error messages";

    $p1->clear;

    $p1->params->add(telephone => 11111);

    ok !$p1->check('telephone')->telephone, "p1 telephone number is invalid";

    $p1->params->add(telephone => 2155551212);

    ok $p1->validate, "p1 telephone number is now valid";

    $p1 = $p1->new(params => $params);

    $p1->check($_)->min_length(3)->required->email
        for qw(email_1 email_2 email_3)
    ;

    # we don't like @localhost
    ok $p1->validate, "all email addresses valid";

}

done_testing;
