use strict;
use warnings;
use Test::Most;

BEGIN { use_ok('Test::Mockingbird') }

{
	package Dummy::Scoped;
	sub foo { "original foo" }
	sub bar { "original bar" }
}

subtest 'scoped mock (shorthand)' => sub {

    {
        my $g = mock_scoped 'Dummy::Scoped::foo' => sub { "scoped foo" };
        is Dummy::Scoped::foo(), "scoped foo", 'scoped mock active inside block';
    }

    is Dummy::Scoped::foo(), "original foo", 'scoped mock automatically restored';
};

subtest 'scoped mock (longhand)' => sub {

    {
        my $g = mock_scoped('Dummy::Scoped', 'bar', sub { "scoped bar" });
        is Dummy::Scoped::bar(), "scoped bar", 'longhand scoped mock active';
    }

    is Dummy::Scoped::bar(), "original bar", 'longhand scoped mock restored';
};

subtest 'scoped mock does not interfere with normal mock' => sub {

    mock 'Dummy::Scoped::foo' => sub { "persistent foo" };
    is Dummy::Scoped::foo(), "persistent foo", 'persistent mock active';

    {
        my $g = mock_scoped 'Dummy::Scoped::foo' => sub { "temporary foo" };
        is Dummy::Scoped::foo(), "temporary foo", 'scoped mock overrides persistent mock';
    }

    is Dummy::Scoped::foo(), "persistent foo", 'persistent mock restored after scope';

	unmock 'Dummy::Scoped::foo';
	is(Dummy::Scoped::foo(), 'original foo', 'persistent mock cleaned up');
};

done_testing();
