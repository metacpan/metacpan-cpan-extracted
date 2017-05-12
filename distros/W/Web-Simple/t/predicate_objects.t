use strict;
use warnings FATAL => 'all';

use Data::Dumper::Concise;
use Test::More 'no_plan';
use Plack::Test;

{
    use Web::Simple 't::Web::Simple::SubDispatchArgs';
    package t::Web::Simple::SubDispatchArgs;
    use Web::Dispatch::Predicates;

    has 'attr' => (is=>'ro');

    sub dispatch_request {
        my $self = shift;
        ## sub(/) {
        match_path(qr/(?-xism:^(\/)$)/), sub {
            $self->show_landing(@_);
        },
        ## sub(/...) {
        match_path_strip(qr/(?-xism:^()(\/.*)$)/) => sub {
            match_and
            (
                match_method('GET'),
                match_path(qr/(?-xism:^(\/user(?:\.\w+)?)$)/)
            )  => sub {
                $self->show_users(@_);
            },
            match_path(qr/(?-xism:^(\/user\/([^\/]+?)(?:\.\w+)?)$)/), sub {
                match_method('GET') => sub {
                    $self->show_user(@_);
                },
                match_and
                (
                  match_method('POST'),
                  match_body
                  ({
                    named => [
                      {
                        multi => "",
                        name => "id"
                      },
                      {
                        multi => 1,
                        name => "roles"
                      }
                    ],
                    required => ["id"]
                  })
                ) => sub {
                  $self->process_post(@_);
                }
            },
        }
    };

    sub show_landing {
        my ($self, @args) = @_;
        local $self->{_dispatcher};
        local $args[-1]->{'Web::Dispatch.original_env'};
        return [
            200, ['Content-Type' => 'application/perl' ],
            [::Dumper \@args],
        ];
    }
    sub show_users {
        my ($self, @args) = @_;
        local $self->{_dispatcher};
        local $args[-1]->{'Web::Dispatch.original_env'};
        return [
            200, ['Content-Type' => 'application/perl' ],
            [::Dumper \@args],
        ];
    }
    sub show_user {
        my ($self, @args) = @_;
        local $self->{_dispatcher};
        local $args[-1]->{'Web::Dispatch.original_env'};
        return [
            200, ['Content-Type' => 'application/perl' ],
            [::Dumper \@args],
        ];
    }
    sub process_post {
        my ($self, @args) = @_;
        local $self->{_dispatcher};
        local $args[-1]->{'Web::Dispatch.original_env'};
        return [
            200, ['Content-Type' => 'application/perl' ],
            [::Dumper \@args],
        ];
    }
}

ok my $app = t::Web::Simple::SubDispatchArgs->new,
  'made app';

sub run_request { $app->run_test_request(@_); }

ok my $get_landing = run_request(GET => 'http://localhost/' ),
  'got landing';

cmp_ok $get_landing->code, '==', 200,
  '200 on GET';

no strict 'refs';

{
    my ($self, $env, @noextra) = @{eval($get_landing->content)||[]};
    die $@ if $@;
    is scalar(@noextra), 0, 'No extra stuff';
    is ref($self), 't::Web::Simple::SubDispatchArgs', 'got object';
    is ref($env), 'HASH', 'Got hashref';
}

ok my $get_users = run_request(GET => 'http://localhost/user'),
  'got user';

cmp_ok $get_users->code, '==', 200,
  '200 on GET';

{
    my ($self, $env, @noextra) = @{eval $get_users->content};
    is scalar(@noextra), 0, 'No extra stuff';
    is ref($self), 't::Web::Simple::SubDispatchArgs', 'got object';
    is ref($env), 'HASH', 'Got hashref';
}

ok my $get_user = run_request(GET => 'http://localhost/user/42'),
  'got user';

cmp_ok $get_user->code, '==', 200,
  '200 on GET';

{
    my ($self, $env, @noextra) = @{eval $get_user->content};
    is scalar(@noextra), 0, 'No extra stuff';
    is ref($self), 't::Web::Simple::SubDispatchArgs', 'got object';
    is ref($env), 'HASH', 'Got hashref';
}

ok my $post_user = run_request(POST => 'http://localhost/user/42', id => '99' ),
  'post user';

cmp_ok $post_user->code, '==', 200,
  '200 on POST';

{
    my ($self, $params, $env, @noextra) = @{eval $post_user->content or die $@};
    is scalar(@noextra), 0, 'No extra stuff';
    is ref($self), 't::Web::Simple::SubDispatchArgs', 'got object';
    is ref($params), 'HASH', 'Got POST hashref';
    is $params->{id}, 99, 'got expected value for id';
    is ref($env), 'HASH', 'Got hashref';
}
