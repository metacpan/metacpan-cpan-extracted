package Example::View::HTML::Register::Form;

use CatalystX::Moose;
use Example::Syntax;
use Example::View::HTML
  qw(form_for link_to uri);

has 'registration' => (is=>'ro', required=>1, context=>1);
  
sub render($self, $c) {
  $self->form_for('registration', {data=>{remote=>1}}, sub ($self, $fb, $registration) {
    Fieldset [
      $fb->legend,
      $fb->model_errors(+{show_message_on_field_errors=>1}),
      $self->form_group('first_name', $fb),
      $self->form_group('last_name', $fb),
      $self->form_group('username', $fb),
      
      Div {id=>'registration_pw_confirm'}, [
        $self->form_group('password', $fb, 
          extra=>$fb->tag_name_for_attribute('password_confirmation'),
          replace_id=>'registration_pw_confirm',
          type=>'password'),
        $self->form_group('password_confirmation', $fb, 
          extra=>$fb->tag_name_for_attribute('password'), 
          replace_id=>'registration_pw_confirm',
          type=>'password'),
      ],
      
      $fb->submit(+{data=>{'disable-with'=>'Submitting...'}}),
    ],
    Div { class=>'text-center' },
      $self->link_to($self->uri('/session/build'), 'Login to existing account.'),
  });
}

sub form_group($self, $attribute, $fb, %opts) {
  my $id = exists $opts{replace_id}
    ? delete $opts{replace_id}
    : $fb->tag_id_for_attribute($attribute, 'form_group');
  my %data = (remote=>1, replace=>"#${id}");
  $data{extra} = delete($opts{extra}) if exists $opts{extra};
  return Div +{ class=>'form-group', id=>$id }, [
    $fb->label($attribute),
    $fb->input($attribute, { data => \%data, %opts }),
    $fb->errors_for($attribute),
  ];
}

__PACKAGE__->meta->make_immutable;