package Example::Controller::Posts;

use Moose;
use MooseX::MethodAttributes;
use Example::Syntax;
use Types::Standard qw(Int);

extends 'Example::Controller';

sub root :At('$path_end/...') Via('../protected') ($self, $c, $user) {
  $c->action->next(my $posts = $user->posts);
}

  sub search :At('/...') Via('root') QueryModel ($self, $c, $posts, $q) {
    $posts = $posts->filter_by_request($q);
    $c->action->next($posts);
  }

    # GET /posts
    sub list :Get('') Via('search')  ($self, $c, $posts) {
      return $self->view(list => $posts);
    }

  sub prepare_build :At('...') Via('root')  ($self, $c, $posts) {
    $self->view_for('build', post => my $post = $posts->build);
    $c->action->next($post);
  }

    # GET /posts/new
    sub build :Get('new') Via('prepare_build') ($self, $c, $post) { return }

    # POST /posts
    sub create :Post('') Via('prepare_build') BodyModel ($self, $c, $post, $r) {
      return $post->set_from_request($r);
    }

  sub find :At('{:Int}/...') Via('root') ($self, $c, $posts, $id) {
    my $post = $posts->find($id) // $c->detach_error(404, +{error=>"Post Id '$id' not found"});
    $c->action->next($post);
  }

    # GET /posts/1
    sub show :Get('') Via('find') ($self, $c, $post) {
      $self->view(post => $post);
    }

    # DELETE /posts/1
    sub delete :Delete('') Via('find') ($self, $c, $post) {
      return $post->delete && $c->redirect_to_action('list');
    }

    sub prepare_edit :At('...') Via('find') ($self, $c, $post) { 
      $self->view_for('edit',  post => $post);
      $c->action->next($post);
    }

      # GET /posts/1/edit
      sub edit :Get('edit') Via('prepare_edit') ($self, $c, $post) { return }
    
      # PATCH /posts/1
      sub update :Patch('') Via('prepare_edit') BodyModelFor('create') ($self, $c, $post, $r) {
        return $post->set_from_request($r);
      }

__PACKAGE__->meta->make_immutable;
