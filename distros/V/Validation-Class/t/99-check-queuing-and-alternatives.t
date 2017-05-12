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
        our $i = 0;

        field email => { min_length => 1 };
        field passw => { validation => sub { return ++$i } };

        profile create1 => sub {
            my ($self) = @_;
            return 0 unless $self->validate;
            return $self->validate('+email') ? 1 : 0;
        };

        profile create2 => sub {
            my ($self) = @_;
            $self->queue('+email');
            return $self->validate ? 1 : 0;
        };

        profile create3 => sub {
            my ($self) = @_;
            return $self->validate($self->params->keys, '+passw') ? 1 : 0;
        };

        profile create4 => sub {
            my ($self) = @_;
            $self->queue($self->params->keys, '+passw');
            return $self->validate ? 1 : 0;
        };
    }

    package main;

    my $t = T->new(
        ignore_unknown => 1,
        report_unknown => 1,
    );

    $t->params->add({'email' => 'bob@test.net','unknown' => 'test'});

    ok "T" eq ref $t, "T instantiated";

    ok ! $t->validate_profile('create1'), 't profile create1 DOES NOT validate';

    $t->report_unknown(0);

    ok $t->validate_profile('create1'), 't profile create1 validates';
    ok $t->validate_profile('create2'), 't profile create2 validates';

    $t->params->add(passw => 's3cret');

    ok $t->validate_profile('create3'), 't profile create3 validates';
    ok 1 == $T::i, 'validate method aggregated fields specified';

    ok $t->validate_profile('create4'), 't profile create4 validates';
    ok 2 == $T::i, 'validate method aggregated fields specified via queue';

}

done_testing();
