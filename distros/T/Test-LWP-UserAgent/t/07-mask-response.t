use strict;
use warnings;

use Test::More 0.88;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';

use Test::LWP::UserAgent;

{
    my $useragent = Test::LWP::UserAgent->new;
    $useragent->map_response('bar.com', HTTP::Response->new('200'));
    Test::LWP::UserAgent->map_response('foo.com', HTTP::Response->new('201'));
    $useragent->map_response('foo.com', undef);

    my $response = $useragent->get('http://foo.com');
    is($response->code, '404', 'global mapping is masked on the instance');
}

{
    my $useragent = Test::LWP::UserAgent->new;

    $useragent->map_response('bar.com', HTTP::Response->new('200'));
    $useragent->map_response('foo.com', HTTP::Response->new('201'));
    $useragent->map_response('foo.com', undef);

    # send request - it should hit a 404.
    my $response = $useragent->get('http://foo.com');
    is($response->code, '404', 'previous mapping is masked');
}

{
    package MyHost;
    sub new
    {
        my ($class, $string) = @_;
        bless { _string => $string }, $class;
    }
    use overload '""' => sub {
        my $self = shift;
        $self->{_string};
    };
    use overload 'cmp' => sub {
        my ($self, $other, $swap) = @_;
        $self->{_string} cmp $other;
    };
}

# same tests as above are repeated, but with overloaded string objects.

{
    my $useragent = Test::LWP::UserAgent->new;
    $useragent->map_response(MyHost->new('bar.com'), HTTP::Response->new('200'));
    Test::LWP::UserAgent->map_response(MyHost->new('foo.com'), HTTP::Response->new('201'));
    $useragent->map_response(MyHost->new('foo.com'), undef);

    my $response = $useragent->get('http://foo.com');
    is($response->code, '404', 'global mapping is masked on the instance');
}

{
    my $useragent = Test::LWP::UserAgent->new;

    $useragent->map_response(MyHost->new('bar.com'), HTTP::Response->new('200'));
    $useragent->map_response(MyHost->new('foo.com'), HTTP::Response->new('201'));
    $useragent->map_response(MyHost->new('foo.com'), undef);

    # send request - it should hit a 404.
    my $response = $useragent->get('http://foo.com');
    is($response->code, '404', 'previous mapping is masked');
}

done_testing;
