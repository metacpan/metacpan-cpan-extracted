package Example::Controller::Account;

use Moose;
use MooseX::MethodAttributes;
use Example::Syntax;
use Types::Standard qw(Int);

extends 'Example::Controller';

sub root :At('$path_end/...') Via('../protected')  ($self, $c, $user) {
  $c->action->next(my $people = $user->accessible_people);

}

  # /account/{:Int}/...
  sub find :At('{:Int}/...') Via('root')  ($self, $c, $people, $id) {
    my $account = ($people->find_account($id) //$c->detach_error(404, +{error=>"account id $id not found"}));
    $c->action->next($account);
  }

    sub prepare_edit :At('...') Via('find') ($self, $c, $account) { 
      $self->view_for('edit', account => $account);
      $c->action->next($account);
    }

      # GET /account
      sub edit :Get('edit') Via('prepare_edit') ($self, $c, $account) { return }

      # PATCH /account
      sub update :Patch('') Via('prepare_edit') BodyModel ($self, $c, $account, $bm) {
        return $account->set_from_request($bm);
      }

__PACKAGE__->meta->make_immutable;
