package Example::View::HTML::Public::Posts::Comments::Form;

use Moo;
use Example::Syntax;
use Example::View::HTML
  -tags => qw(div a fieldset link_to legend br form_for),
  -util => qw(path);

has 'comment' => (is=>'ro', required=>1);

sub create_or_update_path :Renders ($self)  {
  return $self->comment->in_storage ?
   path('update', [$self->comment->post_id, $self->comment->id]) :
    path('create', [$self->comment->post_id]); 
}

sub render($self, $c) {
  form_for $self->comment, +{action=>$self->create_or_update_path}, sub ($self, $fb, $comment) {
    div +{ if=>$fb->successfully_updated, 
      class=>'alert alert-success', role=>'alert' 
    }, 'Successfully Saved!',

    fieldset [
      $fb->legend,
      div +{ class=>'form-group' }, $fb->form_has_errors(),
      div +{ class=>'form-group' }, [
        $fb->label('content', "Your Comment"),
        $fb->text_area('content'),
        $fb->errors_for('content'),
      ],
    ],

    $fb->submit(),
    link_to path('../show', [$self->comment->post_id]), {class=>'btn btn-secondary btn-lg btn-block'}, 'Return to Post',
  };
}

1;
