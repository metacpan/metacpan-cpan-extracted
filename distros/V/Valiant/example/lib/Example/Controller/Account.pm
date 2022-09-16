package Example::Controller::Account;

use Moose;
use MooseX::MethodAttributes;
use Example::Syntax;

extends 'Example::Controller';

sub account :Chained(../auth) CaptureArgs(0)  ($self, $c, $user) {
  $c->next_action($user->account);
}

  sub edit :Chained(account) PathPart('') Verbs(GET,PATCH) Args(0) ($self, $c, $account) {
    $c->view('HTML::Account', account => $account);
    $c->next_action($account);
  }

    sub PATCH :Action RequestModel(AccountRequest) ($self, $c, $request, $account) {
      $account->update_account($request);
      return $account->valid ? 
        $c->view->set_http_ok : 
          $c->view->set_http_bad_request;
    }

__PACKAGE__->meta->make_immutable;

