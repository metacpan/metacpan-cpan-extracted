package WWW::UsePerl::Server::Controller::Root;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller' }

#
# Sets the actions in this controller to be registered with no prefix
# so they function identically to actions created in MyApp.pm
#
__PACKAGE__->config( namespace => '' );

=head1 NAME

WWW::UsePerl::Server::Controller::Root - Root Controller for WWW::UsePerl::Server

=head1 DESCRIPTION

[enter your description here]

=head1 METHODS

=head2 index

The root page (/)

=cut

sub index : Path : Args(0) {
    my ( $self, $c ) = @_;
    my $db_model = $c->model('DB');

    my $count_stories = $c->model('DB::Story')->count( {} );
    $c->stash->{count_stories} = $count_stories;
    my @stories = $c->model('DB::Story')->search(
        {},
        {   page     => 1,
            rows     => 20,
            order_by => { -desc => 'time' }
        }
    );
    $c->stash->{stories} = \@stories;

    my $count_users = $c->model('DB::User')->count( {} );
    $c->stash->{count_users} = $count_users;
    my @users = $c->model('DB::User')->search(
        {},
        {   page     => 1,
            rows     => 20,
            order_by => { -desc => 'journal_last_entry_date' }
        }
    );
    $c->stash->{users} = \@users;

    my $count_journals = $c->model('DB::Journal')->count( {} );
    $c->stash->{count_journals} = $count_journals;
    my @journals = $c->model('DB::Journal')->search(
        {},
        {   prefetch => 'user',
            page     => 1,
            rows     => 20,
            order_by => { -desc => 'date' },
        }
    );
    $c->stash->{journals} = \@journals;
}

=head2 about

About

=cut

sub about : Path('about') {
    my ( $self, $c ) = @_;
}

=head2 story entry

A story entry

=cut

sub story : Regex('^article\.pl') {
    my ( $self, $c ) = @_;
    my ($sid) = $c->request->param('sid');
    my $story
        = $c->model('DB::Story')
        ->search( { sid => $sid }, { prefetch => 'user' } )->single
        || die "Story $sid not found";
    $c->stash->{story} = $story;
    my $comments = $c->model('DB::Comment')->search(
        { stoid => $story->stoid },
        {   prefetch => 'user',
            order_by => 'sequence'
        }
    );
    $c->stash->{comments} = [ $comments->all ];
}

=head2 stories

All stories

=cut

sub stories : Path('stories') {
    my ( $self, $c ) = @_;
    my $current_page = $c->request->param('page') || 1;
    my $stories = $c->model('DB::Story')->search(
        {},
        {   page     => $current_page,
            rows     => 20,
            order_by => { -desc => 'time' }
        }
    );
    $c->stash->{stories} = [ $stories->all ];
    $self->_pageset( $c, $stories->pager );
}

=head2 author

An author

=cut

sub author : Regex('^~([^/]+)/?$') {
    my ( $self, $c ) = @_;
    my ($nickname) = @{ $c->req->captures };
    my $current_page = $c->request->param('page') || 1;
    my $user = $c->model('DB::User')->single( { nickname => $nickname } )
        || die "No user found for $nickname";
    $c->stash->{user} = $user;
    my $journals = $c->model('DB::Journal')->search(
        { uid => $user->uid },
        {   page     => $current_page,
            rows     => 20,
            order_by => { -desc => 'date' },
        }
    );
    $c->stash->{journals} = [ $journals->all ];
    $self->_pageset( $c, $journals->pager );
}

=head2 authors

All authors

=cut

sub authors : Path('authors') {
    my ( $self, $c ) = @_;
    my $current_page = $c->request->param('page') || 1;
    my $users = $c->model('DB::User')->search(
        {},
        {   page     => $current_page,
            rows     => 20,
            order_by => { -desc => 'journal_last_entry_date' }
        }
    );
    $c->stash->{users} = [ $users->all ];
    $self->_pageset( $c, $users->pager );
}

=head2 journal entry

A user's journal entry

=cut

sub journal : Regex('^~([^/]+)/journal/(\d+)$') {
    my ( $self,     $c )          = @_;
    my ( $nickname, $journal_id ) = @{ $c->req->captures };
    my $user = $c->model('DB::User')->single( { nickname => $nickname } )
        || die "No user found for $nickname";
    $c->stash->{user} = $user;
    my $journal = $c->model('DB::Journal')->single(
        {   id  => $journal_id,
            uid => $user->uid,
        }
    ) || die "Journal $journal_id not found for user $nickname";
    $c->stash->{journal} = $journal;
    my $comments = $c->model('DB::Comment')->search(
        { journal_id => $journal_id },
        {   prefetch => 'user',
            order_by => 'sequence'
        }
    );
    $c->stash->{comments} = [ $comments->all ];
}

=head2 journal entries

All journal entries

=cut

sub journals : Path('journals') {
    my ( $self, $c ) = @_;
    my $current_page = $c->request->param('page') || 1;
    my $journals = $c->model('DB::Journal')->search(
        {},
        {   prefetch => 'user',
            page     => $current_page,
            rows     => 20,
            order_by => { -desc => 'date' },
        }
    );
    $c->stash->{journals} = [ $journals->all ];
    $self->_pageset( $c, $journals->pager );
}

=head2 default

Standard 404 error page

=cut

sub default : Path {
    my ( $self, $c ) = @_;
    $c->response->body('Page not found');
    $c->response->status(404);
}

=head2 end

Attempt to render a view, if needed.

=cut

sub end : ActionClass('RenderView') {
}

sub _pageset {
    my ( $self, $c, $pager ) = @_;
    $c->stash->{pageset} = Data::Pageset->new(
        {   'total_entries'    => $pager->total_entries,
            'entries_per_page' => $pager->entries_per_page,
            'current_page'     => $pager->current_page,
            'pages_per_set'    => 10,
            'mode'             => 'slide',
        }
    );
}

=head1 AUTHOR

Leon Brocard,,,

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
