#!perl
# ABSTRACT: Helper for PSGI-based HTTP mocking in tests

package Test::Bugzilla::PSGI;

use v5.24;
use strict;
use warnings;
use LWP::Protocol::PSGI;
use Test::More;

my $CURRENT_MOCK;

sub register_mock {
    my ($mock) = @_;
    LWP::Protocol::PSGI->register($mock->app);
    $CURRENT_MOCK = $mock;
}

sub unregister_mock {
    LWP::Protocol::PSGI->unregister;
    $CURRENT_MOCK = undef;
}

sub mock {
    require Test::Bugzilla::PSGIApp;
    my $mock = Test::Bugzilla::PSGIApp->new;
    register_mock($mock);
    return $mock;
}

sub with_mock {
    my ($code) = @_;
    my $mock = mock();
    my $cb = sub { $code->($mock) };
    my $ret;
    my $err;

    {
        local @INC = ('lib', 't/lib', @INC);
        $ret = eval { $cb->() };
        $err = $@;
    }

    unregister_mock();

    die $err if $err;
    return $ret;
}

1;

__END__

=head1 SYNOPSIS

    use Test::More;
    use Test::Bugzilla::PSGI;

    my $mock = Test::Bugzilla::PSGI::mock();

    $mock->set_route('GET', '/rest/bug/123', {
        bugs => [{ id => 123, summary => 'Test Bug' }]
    });

    my $bz = WebService::Bugzilla->new(
        base_url => 'http://localhost/rest',
        api_key  => 'test',
    );

    my $bug = $bz->bug->get(123);
    is($bug->id, 123);
    is($bug->summary, 'Test Bug');

    Test::Bugzilla::PSGI::unregister_mock();

=head1 DESCRIPTION

Helper module for setting up LWP::Protocol::PSGI mocks in tests.

=cut
