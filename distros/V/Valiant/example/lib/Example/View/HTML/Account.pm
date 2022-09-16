package Example::View::HTML::Account;

use Moose;
use Example::Syntax;
use Valiant::HTML::TagBuilder 'div', 'fieldset', 'legend', 'br', ':utils';
use Valiant::HTML::Form 'form_for';

extends 'Example::View::HTML';

__PACKAGE__->views(
  layout => 'HTML::Layout',
  navbar => 'HTML::Navbar',
  form_for => 'HTML::FormFor',
);

has 'account' => (
  is=>'ro', 
  required=>1,
  handles=>{
    states => 'available_states',
    roles => 'available_roles',
  },
);

sub status_options($self) {
  return [map { [ucfirst($_) => $_] } $self->account->profile->status_options ];
}

sub render($self, $c) {
  $self->layout(page_title=>'Homepage', sub($layout) {
    $self->navbar(active_link=>'/account'),
    $self->form_for($self->account, +{style=>'width:35em; margin:auto'}, sub ($ff, $fb, $account) {
      div +{ cond=>$fb->successfully_updated, class=>'alert alert-success', role=>'alert' }, 'Successfully Updated',
      fieldset [
        $fb->legend,
        div +{ class=>'form-group' },
          $fb->model_errors(+{class=>'alert alert-danger', role=>'alert', show_message_on_field_errors=>'Please fix validation errors'}),
        div +{ class=>'form-group' }, [
          $fb->label('first_name'),
          $fb->input('first_name', +{ class=>'form-control', errors_classes=>'is-invalid' }),
          $fb->errors_for('first_name', +{ class=>'invalid-feedback' }),
        ],
        div +{ class=>'form-group' }, [
          $fb->label('last_name'),
          $fb->input('last_name', +{ class=>'form-control', errors_classes=>'is-invalid' }),
          $fb->errors_for('last_name', +{ class=>'invalid-feedback' }),
        ],
        div +{ class=>'form-group' }, [
          $fb->label('username'),
          $fb->input('username', +{ class=>'form-control', errors_classes=>'is-invalid' }),
          $fb->errors_for('username', +{ class=>'invalid-feedback' }),
        ],
      ],
      fieldset [
        legend $self->account->human_attribute_name('profile'),
        $fb->errors_for('profile', +{ class=>'alert alert-danger', role=>'alert' }),
        $fb->fields_for('profile', sub ($fb_profile, $profile) {
          div +{ class=>'form-group' }, [
            $fb_profile->label('address'),
            $fb_profile->input('address', +{ class=>'form-control', errors_classes=>'is-invalid' }),
            $fb_profile->errors_for('address', +{ class=>'invalid-feedback' }),
          ],
          div +{ class=>'form-group' }, [
            $fb_profile->label('city'),
            $fb_profile->input('city', +{ class=>'form-control', errors_classes=>'is-invalid' }),
            $fb_profile->errors_for('city', +{ class=>'invalid-feedback' }),
          ],
          div +{ class=>'form-row' }, [
            div +{ class=>'col form-group' }, [
              $fb_profile->label('state_id'),
              $fb_profile->collection_select('state_id', $self->states, id=>'name', +{ include_blank=>1, class=>'form-control', errors_classes=>'is-invalid'}),
              $fb_profile->errors_for('state_id', +{ class=>'invalid-feedback' }),
            ],
            div +{ class=>'col form-group' }, [
              $fb_profile->label('zip'),
              $fb_profile->input('zip', +{ class=>'form-control', errors_classes=>'is-invalid' }),
              $fb_profile->errors_for('zip', +{ class=>'invalid-feedback' }),
            ],
          ],
          div +{ class=>'form-row' }, [
            div +{ class=>'col form-group' }, [
              $fb_profile->label('phone_number'),
              $fb_profile->input('phone_number', +{ class=>'form-control', errors_classes=>'is-invalid' }),
              $fb_profile->errors_for('phone_number', +{ class=>'invalid-feedback' }),
            ],
            div +{ class=>'col form-group' }, [
              $fb_profile->label('birthday'),
              $fb_profile->date_field('birthday', +{ class=>'form-control', errors_classes=>'is-invalid' }),
              $fb_profile->errors_for('birthday', +{ class=>'invalid-feedback' }),
            ],
          ],
           div +{ class=>'form-row' }, [
            div +{ class=>'col form-group' }, [
              div + { class=>'form-check' }, [
                $fb_profile->checkbox('registered', +{ class=>'form-check-input', errors_classes=>'is-invalid' }),
                $fb_profile->label('registered', +{ class=>'form-check-label'}),
                $fb_profile->errors_for('registered', +{ class=>'invalid-feedback' }),
              ],
            ],
            div +{ class=>'col form-group' }, [
              fieldset [
                $fb_profile->legend_for('status'),
                $fb_profile->radio_buttons('status', $self->status_options, sub ($fb_status) {
                  div +{class=>'form-check'}, [
                    $fb_status->radio_button({class=>'form-check-input'}),
                    $fb_status->label({class=>'form-check-label'}),
                  ],
                }),
              ]
            ],
          ],
        }),
      ],
      fieldset [
        legend $self->account->human_attribute_name('roles'),
        $fb->errors_for('person_roles', +{ class=>'alert alert-danger', role=>'alert' }),
        div +{ class=>'form-group' },
          $fb->collection_checkbox({person_roles => 'role_id'}, $self->roles, id=>'label', sub ($fb_roles) {
            div +{class=>'form-check'}, [
              $fb_roles->checkbox({class=>'form-check-input'}),
              $fb_roles->label({class=>'form-check-label'}),
            ],
          }),
      ],
      fieldset [
        legend $self->account->human_attribute_name('credit_cards'),
        div +{ class=>'form-group' }, [
          $fb->errors_for('credit_cards', +{ class=>'alert alert-danger', role=>'alert' }),
          $fb->fields_for('credit_cards', sub($fb_cc, $cc) {
            div +{ class=>'form-row' }, [
              div +{ class=>'col form-group' }, [
                $fb_cc->label('card_number'),
                $fb_cc->input('card_number', +{ class=>'form-control', errors_classes=>'is-invalid' }),
                $fb_cc->errors_for('card_number', +{ class=>'invalid-feedback' }),
              ],
              div +{ class=>'col form-group col-4' }, [
                $fb_cc->label('expiration'),
                $fb_cc->date_field('expiration', +{ class=>'form-control', errors_classes=>'is-invalid' }),
                $fb_cc->errors_for('expiration', +{ class=>'invalid-feedback' }),
              ],
              div +{ class=>'col form-group col-2' }, [
                $fb_cc->label('_delete'), br,
                $fb_cc->checkbox('_delete', +{ checked=>$fb_cc->model->is_marked_for_deletion }),
              ],
            ]
          }, sub ($fb_final, $new_cc) {
            $fb_final->button( '_add', +{ class=>'btn btn-lg btn-primary btn-block', value=>1 }, 'Add Credit Card')
          }),
        ],
      ],
      fieldset $fb->submit(+{class=>'btn btn-lg btn-primary btn-block'}),
    }),
  });
}

__PACKAGE__->meta->make_immutable();
