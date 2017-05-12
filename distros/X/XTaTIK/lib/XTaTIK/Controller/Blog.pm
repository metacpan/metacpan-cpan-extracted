package XTaTIK::Controller::Blog;

our $VERSION = '0.005002'; # VERSION

use Mojo::Base 'Mojolicious::Controller';

sub index {
    my $self = shift;
    $self->stash( posts => $self->blog->brief_list );
}

sub read {
    my $self = shift;

    my ( $title, $date, $metas, $body, $prev, $next )
    = $self->blog->post( $self->param('post') );

    $title // $self->redirect_to('/404');

    $self->stash(
        blog_title  => $title,
        title       => $title,
        blog_date   => $date,
        metas       => $metas,
        blog_body   => $body,
        blog_prev   => $prev,
        blog_next   => $next,
    );
}

1;