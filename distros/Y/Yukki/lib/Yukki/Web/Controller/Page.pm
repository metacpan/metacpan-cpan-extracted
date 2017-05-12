package Yukki::Web::Controller::Page;
{
  $Yukki::Web::Controller::Page::VERSION = '0.140290';
}
use 5.12.1;
use Moose;

with 'Yukki::Web::Controller';

use Try::Tiny;
use Yukki::Error qw( http_throw );

# ABSTRACT: controller for viewing and editing pages


sub fire {
    my ($self, $ctx) = @_;

    given ($ctx->request->path_parameters->{action}) {
        when ('view')    { $self->view_page($ctx) }
        when ('edit')    { $self->edit_page($ctx) }
        when ('history') { $self->view_history($ctx) }
        when ('diff')    { $self->view_diff($ctx) }
        when ('preview') { $self->preview_page($ctx) }
        when ('attach')  { $self->upload_attachment($ctx) }
        when ('rename')  { $self->rename_page($ctx) }
        when ('remove')  { $self->remove_page($ctx) }
        default {
            http_throw('That page action does not exist.', {
                status => 'NotFound',
            });
        }
    }
}


sub repo_name_and_path {
    my ($self, $ctx) = @_;

    my $repo_name  = $ctx->request->path_parameters->{repository};
    my $path       = $ctx->request->path_parameters->{page};

    if (not defined $path) {
        my $repo_config 
            = $self->app->settings->repositories->{$repo_name};

        my $path_str = $repo_config->default_page;

        $path = [ split m{/}, $path_str ];
    }

    return ($repo_name, $path);
}


sub lookup_page {
    my ($self, $repo_name, $page) = @_;

    my $repository = $self->model('Repository', { name => $repo_name });

    my $final_part = pop @$page;
    my $filetype;
    if ($final_part =~ s/\.(?<filetype>[a-z0-9]+)$//) {
        $filetype = $+{filetype};
    }

    my $path = join '/', @$page, $final_part;
    return $repository->file({ path => $path, filetype => $filetype });
}


sub view_page {
    my ($self, $ctx) = @_;

    my ($repo_name, $path) = $self->repo_name_and_path($ctx);

    my $page    = $self->lookup_page($repo_name, $path);

    my $breadcrumb = $self->breadcrumb($page->repository, $path);

    my $body;
    if (not $page->exists) {
        my @files = $page->list_files;

        $body = $self->view('Page')->blank($ctx, { 
            title      => $page->file_name,
            breadcrumb => $breadcrumb,
            repository => $repo_name, 
            page       => $page->full_path,
            files      => \@files,
        });
    }

    else {
        $body = $self->view('Page')->view($ctx, { 
            title      => $page->title,
            breadcrumb => $breadcrumb,
            repository => $repo_name,
            page       => $page->full_path, 
            file       => $page,
        });
    }

    $ctx->response->body($body);
}


sub edit_page {
    my ($self, $ctx) = @_;

    my ($repo_name, $path) = $self->repo_name_and_path($ctx);

    my $page = $self->lookup_page($repo_name, $path);

    my $breadcrumb = $self->breadcrumb($page->repository, $path);

    if ($ctx->request->method eq 'POST') {
        my $new_content = $ctx->request->parameters->{yukkitext};
        my $position    = $ctx->request->parameters->{yukkitext_position};
        my $comment     = $ctx->request->parameters->{comment};

        if (my $user = $ctx->session->{user}) {
            $page->author_name($user->{name});
            $page->author_email($user->{email});
        }

        $page->store({ 
            content => $new_content,
            comment => $comment,
        });

        $ctx->response->redirect(join '/', '/page/edit', $repo_name, $page->full_path, '?yukkitext_position='.$position);
        return;
    }

    my @attachments = grep { $_->filetype ne 'yukki' } $page->list_files;
    my $position = $ctx->request->parameters->{yukkitext_position} // -1;

    $ctx->response->body( 
        $self->view('Page')->edit($ctx, { 
            title       => $page->title,
            breadcrumb  => $breadcrumb,
            repository  => $repo_name,
            page        => $page->full_path, 
            position    => $position,
            file        => $page,
            attachments => \@attachments,
        }) 
    );
}


sub rename_page {
    my ($self, $ctx) = @_;

    my ($repo_name, $path) = $self->repo_name_and_path($ctx);

    my $page = $self->lookup_page($repo_name, $path);

    my $breadcrumb = $self->breadcrumb($page->repository, $path);

    if ($ctx->request->method eq 'POST') {
        my $new_name = $ctx->request->parameters->{yukkiname_new};

        my $part = qr{[_a-z0-9-.]+(?:\.[_a-z0-9-]+)*}i;
        if ($new_name =~ m{^$part(?:/$part)*$}) {

            if (my $user = $ctx->session->{user}) {
                $page->author_name($user->{name});
                $page->author_email($user->{email});
            }

            $page->rename({
                full_path => $new_name,
                comment   => 'Renamed ' . $page->full_path . ' to ' . $new_name,
            });

            $ctx->response->redirect(join '/', '/page/edit', $repo_name, $new_name);
            return;

        }
        else {
            $ctx->add_errors('the new name must contain only letters, numbers, underscores, dashes, periods, and slashes');
        }
    }

    $ctx->response->body( 
        $self->view('Page')->rename($ctx, { 
            title       => $page->title,
            breadcrumb  => $breadcrumb,
            repository  => $repo_name,
            page        => $page->full_path, 
            file        => $page,
        }) 
    );
}


sub remove_page {
    my ($self, $ctx) = @_;

    my ($repo_name, $path) = $self->repo_name_and_path($ctx);

    my $page = $self->lookup_page($repo_name, $path);

    my $breadcrumb = $self->breadcrumb($page->repository, $path);

    my $confirmed = $ctx->request->body_parameters->{confirmed};
    if ($ctx->request->method eq 'POST' and $confirmed) {
        my $return_to = $page->parent // $page->repository->default_file;
        if ($return_to->full_path ne $page->full_path) {
            if (my $user = $ctx->session->{user}) {
                $page->author_name($user->{name});
                $page->author_email($user->{email});
            }

            $page->remove({
                comment   => 'Removing ' . $page->full_path . ' from repository.',
            });

            $ctx->response->redirect(join '/', '/page/view', $repo_name, $return_to->full_path);
            return;

        }

        else {
            $ctx->add_errors('you may not remove the top-most page of a repository');
        }
    }

    $ctx->response->body( 
        $self->view('Page')->remove($ctx, { 
            title       => $page->title,
            breadcrumb  => $breadcrumb,
            repository  => $repo_name,
            page        => $page->full_path, 
            file        => $page,
            return_link => join('/', '/page/view', $repo_name, $page->full_path),
        }) 
    );
}


sub view_history {
    my ($self, $ctx) = @_;

    my ($repo_name, $path) = $self->repo_name_and_path($ctx);

    my $page = $self->lookup_page($repo_name, $path);

    my $breadcrumb = $self->breadcrumb($page->repository, $path);

    $ctx->response->body(
        $self->view('Page')->history($ctx, {
            title      => $page->title,
            breadcrumb => $breadcrumb,
            repository => $repo_name,
            page       => $page->full_path,
            revisions  => [ $page->history ],
        })
    );
}


sub view_diff {
    my ($self, $ctx) = @_;

    my ($repo_name, $path) = $self->repo_name_and_path($ctx);

    my $page = $self->lookup_page($repo_name, $path);

    my $breadcrumb = $self->breadcrumb($page->repository, $path);

    my $r1 = $ctx->request->query_parameters->{r1};
    my $r2 = $ctx->request->query_parameters->{r2};

    try {

        my $diff = '';
        for my $chunk ($page->diff($r1, $r2)) {
            given ($chunk->[0]) {
                when (' ') { $diff .= $chunk->[1] }
                when ('+') { $diff .= sprintf '<ins markdown="1">%s</ins>', $chunk->[1] }
                when ('-') { $diff .= sprintf '<del markdown="1">%s</del>', $chunk->[1] }
                default { warn "unknown chunk type $chunk->[0]" }
            }
        }

        my $file_preview = $page->file_preview(
            content => $diff,
        );

        $ctx->response->body(
            $self->view('Page')->diff($ctx, {
                title      => $page->title,
                breadcrumb => $breadcrumb,
                repository => $repo_name,
                page       => $page->full_path,
                file       => $file_preview,
            })
        );
    }

    catch {
        my $ERROR = $_;
        if ("$_" =~ /usage: git diff/) {
            http_throw 'Diffs will not work with git versions before 1.7.2. Please use a newer version of git. If you are using a newer version of git, please file a support issue.';
        }
        die $ERROR;
    };
}


sub preview_page {
    my ($self, $ctx) = @_;

    my ($repo_name, $path) = $self->repo_name_and_path($ctx);

    my $page = $self->lookup_page($repo_name, $path);

    my $breadcrumb = $self->breadcrumb($page->repository, $path);

    my $content      = $ctx->request->body_parameters->{yukkitext};
    my $position     = $ctx->request->parameters->{yukkitext_position};
    my $file_preview = $page->file_preview(
        content  => $content,
        position => $position,
    );

    $ctx->response->body(
        $self->view('Page')->preview($ctx, { 
            title      => $page->title,
            breadcrumb => $breadcrumb,
            repository => $repo_name,
            page       => $page->full_path,
            file       => $file_preview,
        })
    );
}


sub upload_attachment {
    my ($self, $ctx) = @_;

    my $repo_name = $ctx->request->path_parameters->{repository};
    my $path      = delete $ctx->request->path_parameters->{page};

    my $page = $self->lookup_page($repo_name, $path);

    my @file = split m{/}, $page->path;
    push @file, $ctx->request->uploads->{file}->filename;

    $ctx->request->path_parameters->{action} = 'upload';
    $ctx->request->path_parameters->{file}   = \@file;

    $self->controller('Attachment')->fire($ctx);
}


sub breadcrumb {
    my ($self, $repository, $path_parts) = @_;

    my @breadcrumb;
    my @path_acc;

    push @breadcrumb, {
        label => $repository->title,
        href  => join('/', '/page/view/', $repository->name),
    };
    
    for my $path_part (@$path_parts) {
        push @path_acc, $path_part;
        my $file = $repository->file({
            path     => join('/', @path_acc),
            filetype => 'yukki',
        });

        push @breadcrumb, {
            label => $file->title,
            href  => join('/', '/page/view', $repository->name, $file->full_path),
        };
    }

    return \@breadcrumb;
}

1;

__END__

=pod

=head1 NAME

Yukki::Web::Controller::Page - controller for viewing and editing pages

=head1 VERSION

version 0.140290

=head1 DESCRIPTION

Controller for viewing and editing pages

=head1 METHODS

=head2 fire

On a view request routes to L</view_page>, edit request to L</edit_page>, preview request to L</preview_page>, and attach request to L</upload_attachment>.

=head2 repo_name_and_path

This is a helper for looking up the repository name and path for the request.

=head2 lookup_page

Given a repository name and page, returns a L<Yukki::Model::File> for it.

=head2 view_page

Tells either L<Yukki::Web::View::Page/blank> or L<Yukki::Web::View::Page/view>
to show the page.

=head2 edit_page

Displays or processes the edit form for a page using.

=head2 rename_page

Displays the rename page form.

=head2 remove_page

Displays the remove confirmation.

=head2 view_history

Displays the page's revision history.

=head2 view_diff

Displays a diff of the page.

=head2 preview_page

Shows the preview for an edit to a page using L<Yukki::Web::View::Page/preview>..

=head2 upload_attachment

This is a facade that wraps L<Yukki::Web::Controller::Attachment/upload>.

=head2 breadcrumb

Given the repository and path, returns the breadcrumb.

=head1 AUTHOR

Andrew Sterling Hanenkamp <hanenkamp@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Qubling Software LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
