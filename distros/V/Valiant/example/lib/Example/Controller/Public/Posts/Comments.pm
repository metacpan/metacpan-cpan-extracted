package Example::Controller::Public::Posts::Comments;

use Moose;
use MooseX::MethodAttributes;
use Example::Syntax;
use Types::Standard qw(Int);

extends 'Example::Controller';

sub root :At('$path_end/...') Via('../find') ($self, $c, $post) {
  $c->action->next(my $comments = $post->comments); # $post->comments_for($c->user);
}

  sub prepare_build :At('...') Via('root') ($self, $c, $comments) { 
    # Keep in mind $user could be an unauthenticated user.  IRL you might wish
    # to redirect to a register page or something.
    $self->view_for('build', comment => my $comment = $comments->build_for_user($c->user));
    $c->action->next($comment);
  }

    # GET /posts/{post-id}/comments/new
    sub build :Get('new') Via('prepare_build') ($self, $c, $comment) { return }

    # POST /posts/{post-id}/comments
    sub create :Post('') Via('prepare_build') BodyModel ($self, $c, $comment, $bm) {
      return $comment->set_from_request($bm);
    }

  sub find :At('{:Int}/...') Via('root') ($self, $c, $comments, $id) {
    my $comment = $comments->find_with_person($id) //
      $c->detach_error(404, +{error=>"Post Id '$id' not found"});
    $c->action->next($comment);
  }

    # GET /posts/{post-id}/comments/{comment-id}
    sub show :Get('') Via('find') ($self, $c, $comment) {
      return $self->view(comment => $comment);
    }

    # DELETE /posts/{post-id}/comments/{comment-id}
    sub delete :Delete('') Via('find') ($self, $c, $comment) {
      return $comment->delete && $c->redirect_to_action('../show', [$comment->post_id]);
    }

    sub prepare_edit :At('...') Via('find') ($self, $c, $comment) { 
      $self->view_for('edit', comment => $comment);
      $c->action->next($comment);
    }

      # GET /posts/{post-id}/comments/{comment-id}/edit
      sub edit :Get('edit') Via('prepare_edit') ($self, $c, $comment) { return }

      # PATCH /posts/{post-id}/comments/{comment-id}
      sub update :Patch('') Via('prepare_edit') BodyModelFor('create') ($self, $c, $comment, $bm) {
        return $comment->set_from_request($bm);
      }

__PACKAGE__->meta->make_immutable;
