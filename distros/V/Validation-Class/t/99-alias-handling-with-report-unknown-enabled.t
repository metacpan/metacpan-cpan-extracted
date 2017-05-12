use FindBin;
use Test::More;
use utf8;
use strict;
use warnings;

{

    use_ok 'Validation::Class';

}

{

    {
        package T;
        use Validation::Class;

        field foo => { required => 1, alias => ['bar'] };

    }

    package main;

    my $t = T->new(
        ignore_unknown => 1,
        report_unknown => 1,
    );

    $t->params->add({'bar' => 'ayeoke'});

    ok "T" eq ref $t, "T instantiated";
    ok $t->validate, 't validates all params successfully';
    ok !$t->error_count, 't has no errors';

}

done_testing();
