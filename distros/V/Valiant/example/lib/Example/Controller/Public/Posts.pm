package Example::Controller::Public::Posts;

use Moose;
use MooseX::MethodAttributes;
use Types::Standard qw(Int);
use Example::Syntax;

extends 'Example::Controller';

sub root :At('$path_prefix/...') Via('/public')  ($self, $c, $user) {
  $c->action->next(my $posts = $user->viewable_posts);
}

  sub search :At('/...') Via('root') QueryModel ($self, $c, $posts, $q) {
    $c->action->next($posts = $posts->filter_by_request($q));
  }

    # GET /posts
    sub list :Get('') Via('search') ($self, $c, $posts) {
      return $self->view(list => $posts);
    }

  sub find :At('{:Int}/...') Via('root') ($self, $c, $posts, $id) {
    my $post = $posts->find_with_author_and_comments($id) //
      return $c->detach_error(404, +{error=>"Post Id '$id' not found"});
    $c->action->next($post);
  }

    # GET /posts/{id}
    sub show :Get('') Via('find') ($self, $c, $post) {
      return $self->view(post => $post);
    }

__PACKAGE__->meta->make_immutable;
