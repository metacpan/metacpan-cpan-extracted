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

has 'account' => ( is=>'ro', required=>1 );

sub render($self, $c) {
  $self->layout(page_title=>'Homepage', sub($layout) {
    $self->navbar(active_link=>'/account'),
    $self->form_for($self->account, +{style=>'width:35em; margin:auto'}, sub ($ff, $fb, $account) {
      div +{ cond=>$fb->successfully_updated, class=>'alert alert-success', role=>'alert' }, 'Successfully Updated',
      fieldset [
        $fb->legend,
        div +{ class=>'form-group' },
          $fb->model_errors(+{show_message_on_field_errors=>'Please fix validation errors'}),
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
          $fb->label('username'),
          $fb->input('username'),
          $fb->errors_for('username'),
        ],
      ],
      fieldset [
        legend $self->account->human_attribute_name('profile'),
        $fb->errors_for('profile', +{ class=>'alert alert-danger', role=>'alert' }),
        $fb->fields_for('profile', sub ($fb_profile, $profile) {
          div +{ class=>'form-group' }, [
            $fb_profile->label('address'),
            $fb_profile->input('address'),
            $fb_profile->errors_for('address'),
          ],
          div +{ class=>'form-group' }, [
            $fb_profile->label('city'),
            $fb_profile->input('city'),
            $fb_profile->errors_for('city'),
          ],
          div +{ class=>'form-row' }, [
            div +{ class=>'col form-group' }, [
              $fb_profile->label('state_id'),
              $fb_profile->collection_select(state_id => 'state_select_options', +{ include_blank=>1 }),
              $fb_profile->errors_for('state_id'),
            ],
            div +{ class=>'col form-group' }, [
              $fb_profile->label('zip'),
              $fb_profile->input('zip'),
              $fb_profile->errors_for('zip'),
            ],
          ],
          div +{ class=>'form-row' }, [
            div +{ class=>'col form-group' }, [
              $fb_profile->label('phone_number'),
              $fb_profile->input('phone_number'),
              $fb_profile->errors_for('phone_number'),
            ],
            div +{ class=>'col form-group' }, [
              $fb_profile->label('birthday'),
              $fb_profile->date_field('birthday'),
              $fb_profile->errors_for('birthday'),
            ],
          ],
          div +{ class=>'form-row' }, [
            div +{ class=>'col form-group' }, [
              fieldset [
                $fb->legend_for('person_roles'),
                  $fb->collection_checkbox({person_roles => 'role_id'}, 'role_checkbox_options', sub ($fb_roles) {
                    div +{class=>'form-check'}, [
                      $fb_roles->checkbox(),
                      $fb_roles->label({class=>'form-check-label'}),
                    ],
                  }),
                  $fb->errors_for('person_roles'),
              ],
            ],
            div +{ class=>'col form-group' }, [
              fieldset [
                $fb_profile->legend_for('status'),
                $fb_profile->radio_buttons(status => 'status_options', sub ($fb_status) {
                  div +{class=>'custom-control custom-radio'}, [
                    $fb_status->radio_button(),
                    $fb_status->label({class=>'custom-control-label'}),
                  ],
                }),
                $fb_profile->errors_for('status'),
              ]
            ],
            div +{ class=>'col form-group' }, [
              fieldset [
                $fb_profile->legend_for('employment_id'),
                $fb_profile->collection_radio_buttons(employment_id => 'employment_radio_options', sub ($fb_emp) {
                  div +{class=>'custom-control custom-radio'}, [
                    $fb_emp->radio_button(),
                    $fb_emp->label({class=>'custom-control-label'}),
                  ],
                }),
                $fb_profile->errors_for('employment_id'),
              ]
            ],
          ],
          div +{ class=>'form-group' }, [
            fieldset [
              legend $self->account->human_attribute_name('Registration'),
                div + { class=>'form-check' }, [
                  $fb_profile->checkbox('registered'),
                  $fb_profile->label('registered', +{ class=>'form-check-label'}),
                  $fb_profile->errors_for('registered'),
                ], 
            ],
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
                $fb_cc->input('card_number'),
                $fb_cc->errors_for('card_number'),
              ],
              div +{ class=>'col form-group col-4' }, [
                $fb_cc->label('expiration'),
                $fb_cc->date_field('expiration'),
                $fb_cc->errors_for('expiration'),
              ],
              div +{ class=>'col form-group col-2' }, [
                div + { class=>'form-check' }, [
                  $fb_cc->checkbox('_delete'),
                  $fb_cc->label('_delete'),
                ],
              ],
            ]
          }, sub ($fb_final, $new_cc) {
            $fb_final->button( '_add', 'Add Credit Card')
          }),
        ],
      ],
      fieldset $fb->submit(),
    }),
  });
}

__PACKAGE__->meta->make_immutable();
