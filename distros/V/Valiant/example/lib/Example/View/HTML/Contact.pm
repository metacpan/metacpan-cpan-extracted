package Example::View::HTML::Contact;

use Moose;
use Example::Syntax;
use Valiant::HTML::TagBuilder 'div', 'fieldset', 'a', 'br', 'button', 'legend', ':utils';

extends 'Example::View::HTML';

has 'contact' => (is=>'ro', required=>1);

__PACKAGE__->views(
  layout => 'HTML::Layout',
  navbar => 'HTML::Navbar',
  form_for => 'HTML::FormFor',
);

sub render($self, $c) {
  $self->layout(page_title=>'Contact List', sub($layout) {
    $self->navbar(active_link=>'/contacts'),
    $self->form_for($self->contact, +{style=>'width:35em; margin:auto'}, sub ($ff, $fb, $contact) {
      div +{ cond=>$fb->successfully_updated, class=>'alert alert-success', role=>'alert' }, 'Successfully Saved!',

      fieldset [
        $fb->legend,
        div +{ class=>'form-group' },
          $fb->model_errors({show_message_on_field_errors=>'Please fix the listed errors.'}),
        div +{ class=>'form-group' }, [
          $fb->label('first_name'),
          $fb->input('first_name'),
          $fb->errors_for('first_name'),
        ],
        div +{ class=>'form-group' }, [
          $fb->label('last_name'),
          $fb->input('last_name'),
          $fb->errors_for('last_name'),
        ],
        div +{ class=>'form-group' }, [
          $fb->label('notes'),
          $fb->text_area('notes'),
          $fb->errors_for('notes'),
        ],
      ],

      fieldset [
        div +{ class=>'form-group' }, [
          $fb->errors_for('emails'),
          $fb->fields_for('emails', sub($fb_e, $e) {
            $fb_e->legend,
            div +{ class=>'form-row' }, [
              div +{ class=>'col form-group' }, [
                $fb_e->label('address'),
                $fb_e->input('address'),
                $fb_e->errors_for('address'),
              ],
              div +{ class=>'col form-group col-2' }, [
                $fb_e->label('_delete'), br,
                $fb_e->checkbox('_delete', +{ checked=>$e->is_marked_for_deletion }),
              ],
            ]
          }, sub ($fb_final, $new_e) {
            $fb_final->button( '_add', +{ value=>1 }, 'Add Email Address');
          }),
        ],
      ],

      fieldset [
        div +{ class=>'form-group' }, [
          $fb->errors_for('phones'),
          $fb->fields_for('phones', sub($fb_e, $e) {
            $fb_e->legend,
            div +{ class=>'form-row' }, [
              div +{ class=>'col form-group' }, [
                $fb_e->label('phone_number'),
                $fb_e->input('phone_number'),
                $fb_e->errors_for('phone_number'),
              ],
              div +{ class=>'col form-group col-2' }, [
                $fb_e->label('_delete'), br,
                $fb_e->checkbox('_delete', +{ checked=>$e->is_marked_for_deletion }),
              ],
            ]
          }, sub ($fb_final, $new_e) {
            $fb_final->button( '_add', +{ value=>1 }, 'Add Phone Number');
          }),
        ],
      ],

      $fb->submit(),
      a {href=>'/contacts', class=>'btn btn-secondary btn-lg btn-block'}, 'Return to Contact List',
      button { cond=>$contact->in_storage, formaction=>'?x-tunneled-method=delete', formmethod=>'POST', class=>'btn btn-danger btn-lg btn-block'}, 'Delete Contact',
    }),
  });
}

__PACKAGE__->meta->make_immutable();
