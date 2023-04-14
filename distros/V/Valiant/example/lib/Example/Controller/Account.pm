package Example::Controller::Account;

use Moose;
use MooseX::MethodAttributes;
use Example::Syntax;

extends 'Example::Controller';

sub setup_entity :Via(*Private) At('account/...') ($self, $c, $user) {
  $c->action->next($user->account);
}

  sub setup_update :Via('setup_entity') At('/...') ($self, $c, $account) { 
    $c->view('HTML::Account', account => $account);
    $c->action->next($account);
  }

    sub edit :GET Via('setup_update') At('edit') ($self, $c, $account) {
      return  $c->view->set_http_ok;
    }

    sub update :PATCH Via('setup_update') At('') BodyModel(AccountRequest) ($self, $c, $account, $r) {
      return $account->update_account($r) ?
        $c->view->set_http_ok : 
          $c->view->set_http_bad_request;
    }

__PACKAGE__->meta->make_immutable;