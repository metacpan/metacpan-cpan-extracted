package Example::View::HTML::Account;

use Moo;
use Example::Syntax;
use Example::View::HTML
  -tags => qw(div a fieldset legend br form_for),
  -util => qw(path),
  -views => 'HTML::Page', 'HTML::Navbar';

has 'account' => ( is=>'ro', required=>1 );
has 'states' => (is=>'ro', required=>1, lazy=>1, default=>sub ($self) { $self->ctx->model('Schema::State') } );
has 'roles' => (is=>'ro', required=>1, lazy=>1, default=>sub ($self) { $self->ctx->model('Schema::Role') } );
has 'status_list' => (is=>'ro', required=>1, lazy=>1, default=>sub ($self) { [map { [ucfirst($_) => $_] } $self->account->profile->status_list ] } );
has 'employment_options' => (is=>'ro', required=>1, lazy=>1, default=>sub ($self) { $self->ctx->model('Schema::Employment') } );

sub render($self, $c) {
  html_page page_title=>'Homepage', sub($page) {
    html_navbar active_link=>'/account',
    div {class=>"col-5 mx-auto"},
    form_for $self->account, {action=>path('update')}, sub ($self, $fb, $account) {
      div +{ if=>$fb->successfully_updated, class=>'alert alert-success', role=>'alert' }, 'Successfully Updated',
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
        $fb->fields_for('profile', sub ($self, $fb_profile, $profile) {
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
              $fb_profile->collection_select(state_id => $self->states, id=>'name', +{ include_blank=>1 }),
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
                  $fb->collection_checkbox({person_roles => 'role_id'}, $self->roles, id=>'label', sub ($fb_roles) {
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
                $fb_profile->radio_buttons(status => $self->status_list, sub ($fb_status) {
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
                $fb_profile->collection_radio_buttons(employment_id => $self->employment_options, id=>'label', sub ($fb_emp) {
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
          $fb->fields_for('credit_cards', sub($self, $fb_cc, $cc) {
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
          }, sub ($self, $fb_final, $new_cc) {
            $fb_final->button( '_add', 'Add Credit Card')
          }),
        ],
      ],
      fieldset $fb->submit(),
    },
  };
}

1;
