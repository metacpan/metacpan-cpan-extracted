package meon::Web::Form::Login;

use HTML::FormHandler::Moose;
extends 'HTML::FormHandler';

has '+name' => (default => 'form_login');
has '+widget_wrapper' => ( default => 'Bootstrap' );

has_field 'username' => ( type => 'Text', required => 1, label => 'Username' );
has_field 'password' => ( type => 'Password', required => 1 );
has_field 'remember_login' => ( type => 'Checkbox', );
has_field 'submit'   => ( type => 'Submit', value => 'Submit', );

no HTML::FormHandler::Moose;

1;
