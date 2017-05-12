use strict;
use warnings;

use Test::More 0.88;
use Test::Deep;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';

use Test::LWP::UserAgent;

{
    package MyRequest;
    use overload '&{}' => sub {
        sub {
            ::isa_ok($_[0], 'HTTP::Request');
            $_[0]->method eq 'GET'
        }
    };
}
{
    package MyResponse;
    use overload '&{}' => sub {
        sub
        {
            ::isa_ok($_[0], 'HTTP::Request');
            HTTP::Response->new('202')
        }
    };
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


{
    # mapped response is a thingy that quacks like a coderef
    my $useragent = Test::LWP::UserAgent->new;
    $useragent->map_response(bless({}, 'MyRequest'), bless({}, 'MyResponse'));

    my $response = $useragent->get('http://localhost');

    isa_ok($response, 'HTTP::Response');
    is($response->code, '202', 'response from overload');
}

SKIP: {
    eval { require HTTP::Message::PSGI; 1 }
        or skip('HTTP::Message::PSGI is required for the remainder of these tests', 3);

    # mapped response is a coderef that turns a PSGI $env into an HTTP response
    my $useragent = Test::LWP::UserAgent->new;
    $useragent->register_psgi(MyHost->new('localhost'),
        sub { [ '200', [], ['home sweet home'] ] });

    my $response = $useragent->get('http://localhost');
    isa_ok($response, 'HTTP::Response');
    cmp_deeply(
        $response,
        methods(
            code => '200',
            content => 'home sweet home',
        ),
        'response from string overload',
    );

    $useragent->unregister_psgi(MyHost->new('localhost'));
    $response = $useragent->get('http://localhost');
    is($response->code, '404', 'mapping removed via str overload comparison');
}

done_testing;
