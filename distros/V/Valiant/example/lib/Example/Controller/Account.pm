package Example::Controller::Account;

use CatalystX::Moose;
use Example::Syntax;
use Types::Standard qw(Int);

extends 'Example::Controller';

has 'account' => (is=>'rw', context=>'user');

sub root :At('$path_end/...') Via('../protected')  ($self, $c) { }

  # /account/{:Int}/...
  sub find :At('...') Via('root')  ($self, $c) { }

    sub prepare_edit :At('...') Via('find') QueryModel ($self, $c, $q) { 
      $self->view_for('edit');
    }

      # GET /account
      sub edit :Get('edit') Via('prepare_edit') ($self, $c) { return }

      # PATCH /account
      sub update :Patch('') Via('prepare_edit') BodyModel ($self, $c, $bm) {
        return $self->account->set_from_request($bm);
      }

__PACKAGE__->meta->make_immutable;
