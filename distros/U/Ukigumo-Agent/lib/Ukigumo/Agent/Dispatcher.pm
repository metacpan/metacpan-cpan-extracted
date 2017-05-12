package Ukigumo::Agent::Dispatcher;
use strict;
use warnings;
use utf8;

use Amon2::Web::Dispatcher::RouterBoom;
use Ukigumo::Agent::Manager;
use Data::Validator;
use JSON;

get '/' => sub {
    my $c = shift;

    $c->render(
        'index.tt' => {
            children           => $c->manager->children,
            job_queue          => $c->manager->job_queue,
            server_url         => $c->manager->server_url,
            work_dir           => $c->manager->work_dir,
            max_children       => $c->manager->max_children,
            timeout            => $c->manager->timeout,
            ignore_github_tags => $c->manager->ignore_github_tags,
            force_git_url      => $c->manager->force_git_url,
            cleanup_cycle      => $c->manager->cleanup_cycle,
        }
    );
};

my $rule = Data::Validator->new(
    repository => { isa => 'Str' },
    branch     => { isa => 'Str' },
)->with('NoThrow');
post '/api/v0/enqueue' => sub {
    my $c = shift;

    my $args = $rule->validate(+{%{$c->req->parameters}});
    if ($rule->has_errors) {
        my $errors = $rule->clear_errors();

        my $res = $c->render_json({errors => $errors});
        $res->code(400);
        return $res;
    }

    $c->manager->register_job(+{%$args});

    return $c->render_json(+{});
};

post '/api/github_hook' => sub {
    my $c = shift;

    $c->logger->infof("payload: %s", $c->req->param('payload'));
    my $payload = from_json $c->req->param('payload');
    my $args;
    if (!$payload->{deleted} and my $ref = $payload->{ref}) {
        eval {
            # TODO How to pass commit id?
            # my @commits = @{$payload->{commits}};
            #   ...
            # commit => $commits[$#commits]->{id},
            my $repo_url = $payload->{repository}->{url};
            if ($c->manager->force_git_url) {
                # From: https://github.com/tokuhirom/plenv.git
                # To: git@github.com:tokuhirom/plenv.git
                $repo_url =~ s!\Ahttps?://([^/]+)/!git\@$1:!;
            }

            my $tag;
            my $branch;
            if ($ref =~ s!\Arefs/heads/!!) {
                $branch = $ref;
            }
            elsif ($ref =~ s!\Arefs/tags/!! && !$c->manager->ignore_github_tags) {
                $tag = $ref;
            }

            if ($branch || $tag) {
                $args = +{
                    repository       => $repo_url,
                    branch           => $branch || $tag,
                    compare_url      => $payload->{compare} || '',
                    repository_owner => $payload->{repository}->{owner}->{name} || '',
                    repository_name  => $payload->{repository}->{name} || '',
                };
            }
        };
        if (my $e = $@) {
            $c->logger->warnf("An error occured: %s", $e);
            my $res = $c->render_json({errors => $e});
            $res->code(400);
            return $res;
        }

        if ($args) {
            $c->manager->register_job($args);
        }
    }
    return $c->render_json($args || +{});
};

1;
