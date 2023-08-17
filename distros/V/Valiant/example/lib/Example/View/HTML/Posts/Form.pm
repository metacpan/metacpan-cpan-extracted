package Example::View::HTML::Posts::Form;

use Moo;
use Example::Syntax;
use Example::View::HTML
  -tags => qw(div a fieldset link_to legend br form_for),
  -util => qw(path);

has 'post' => (is=>'ro', required=>1);

sub create_or_update_path :Renders ($self)  {
  return $self->post->in_storage ?
   path('update', [$self->post->id]) :
    path('create'); 
}

sub render($self, $c) {
  form_for $self->post, +{action=>$self->create_or_update_path}, sub ($self, $fb, $post) {
    div +{ if=>$fb->successfully_updated, 
      class=>'alert alert-success', role=>'alert' 
    }, 'Successfully Saved!',

    fieldset [
      $fb->legend,
      div +{ class=>'form-group' }, $fb->form_has_errors(),
      div +{ class=>'form-group' }, [
        $fb->label('title'),
        $fb->input('title'),
        $fb->errors_for('title'),
      ],
      div +{ class=>'form-group' }, [
        $fb->label('content'),
        $fb->text_area('content'),
        $fb->errors_for('content'),
      ],
    ],

    $fb->submit(),
    link_to path('list'), {class=>'btn btn-secondary btn-lg btn-block'}, 'Return to Posts List',
  };
}

1;
