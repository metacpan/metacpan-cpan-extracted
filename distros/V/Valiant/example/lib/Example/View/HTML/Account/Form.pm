package Example::View::HTML::Account::Form;

use CatalystX::Moose;
use Example::Syntax;
use Example::View::HTML qw(form_for uri user),

has 'account' => ( is=>'ro', context=>1 );

sub form_group($self, $attribute, $fb, %opts) {
  my $id = $fb->tag_id_for_attribute($attribute, 'form_group');
  return Div +{ class=>'form-group', id=>$id }, [
    $fb->label($attribute),
    $fb->input($attribute, { data => { remote=>1, replace=>"#${id}" }, %opts }),
    $fb->errors_for($attribute),
  ];
}

sub render($self, $c) {
  return $self->form_for('account', {data=>{remote=>1}, edit_url=>sub {shift->uri('update')} }, sub ($self, $fb, $account) {
    Div +{ if=>$fb->successfully_updated, class=>'alert alert-success', role=>'alert' }, 'Successfully Updated',
    Fieldset [
      $fb->legend,
      $fb->model_errors(+{show_message_on_field_errors=>'Please fix validation errors'}),
      $self->form_group('first_name', $fb),
      $self->form_group('last_name', $fb),
      $self->form_group('username', $fb),
    ],
    Fieldset [
      Legend $account->human_attribute_name('profile'),
      $fb->errors_for('profile', +{ class=>'alert alert-danger', role=>'alert' }),
      $fb->fields_for('profile', sub ($self, $fb_profile, $profile) {
        Div +{ class=>'form-group' }, [
          $fb_profile->label('address'),
          $fb_profile->input('address'),
          $fb_profile->errors_for('address'),
        ],
        Div +{ class=>'form-group' }, [
          $fb_profile->label('city'),
          $fb_profile->input('city'),
          $fb_profile->errors_for('city'),
        ],
        Div +{ class=>'form-row' }, [
          Div +{ class=>'col form-group' }, [
            $fb_profile->label('state_id'),
            $fb_profile->collection_select(state_id => +{ include_blank=>1 }),
            $fb_profile->errors_for('state_id'),
          ],
          Div +{ class=>'col form-group' }, [
            $fb_profile->label('zip'),
            $fb_profile->input('zip'),
            $fb_profile->errors_for('zip'),
          ],
        ],
        Div +{ class=>'form-row' }, [
          Div +{ class=>'col form-group' }, [
            $fb_profile->label('phone_number'),
            $fb_profile->input('phone_number'),
            $fb_profile->errors_for('phone_number'),
          ],
          Div +{ class=>'col form-group' }, [
            $fb_profile->label('birthday'),
            $fb_profile->date_field('birthday'),
            $fb_profile->errors_for('birthday'),
          ],
        ],
        Div +{ class=>'form-row' }, [
          Div +{ class=>'col form-group' }, [
            Fieldset [
              $fb->legend_for('person_roles'),
                $fb->collection_checkbox({person_roles => 'role_id'}, sub ($fb_roles) {
                  Div +{class=>'form-check'}, [
                    $fb_roles->checkbox(),
                    $fb_roles->label({class=>'form-check-label'}),
                  ],
                }),
                $fb->errors_for('person_roles'),
            ],
          ],
          Div +{ class=>'col form-group' }, [
            Fieldset [
              $fb_profile->legend_for('status'),
              $fb_profile->radio_buttons(status => sub ($fb_status) {
                Div +{class=>'custom-control custom-radio'}, [
                  $fb_status->radio_button(),
                  $fb_status->label({class=>'custom-control-label'}),
                ],
              }),
              $fb_profile->errors_for('status'),
            ]
          ],
          Div +{ class=>'col form-group' }, [
            Fieldset [
              $fb_profile->legend_for('employment_id'),
              $fb_profile->collection_radio_buttons('employment_id', sub ($fb_emp) {
                Div +{class=>'custom-control custom-radio'}, [
                  $fb_emp->radio_button(),
                  $fb_emp->label({class=>'custom-control-label'}),
                ],
              }),
              $fb_profile->errors_for('employment_id'),
            ]
          ],
        ],
        Div +{ class=>'form-group' }, [
          Fieldset [
            Legend $account->human_attribute_name('Registration'),
              Div + { class=>'form-check' }, [
                $fb_profile->checkbox('registered'),
                $fb_profile->label('registered', +{ class=>'form-check-label'}),
                $fb_profile->errors_for('registered'),
              ], 
          ],
        ],
      }),
    ],
    Fieldset [
      Legend $account->human_attribute_name('credit_cards'),
      Div +{ class=>'form-group' }, [
        $fb->errors_for('credit_cards', +{ class=>'alert alert-danger', role=>'alert' }),
        $fb->fields_for('credit_cards', sub($self, $fb_cc, $cc) {
          Div +{ class=>'form-row' }, [
            Div +{ class=>'col form-group' }, [
              $fb_cc->label('card_number'),
              $fb_cc->input('card_number'),
              $fb_cc->errors_for('card_number'),
            ],
            Div +{ class=>'col form-group col-4' }, [
              $fb_cc->label('expiration'),
              $fb_cc->date_field('expiration'),
              $fb_cc->errors_for('expiration'),
            ],
            Div +{ class=>'col form-group col-2' }, [
              Div + { class=>'form-check' }, [
                $fb_cc->checkbox('_delete'),
                $fb_cc->label('_delete'),
              ],
            ],
          ]
        }, sub ($self, $fb_final, $new_cc) {
          $fb_final->button( '_add', 'Add Credit Card')
        }),
      ],
    ],
    Fieldset $fb->submit(+{data=>{'disable-with'=>'Submitting...'}}),
  });
}

__PACKAGE__->meta->make_immutable;