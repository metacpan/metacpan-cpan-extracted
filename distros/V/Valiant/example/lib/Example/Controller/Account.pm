package Example::Controller::Account;

use Moose;
use MooseX::MethodAttributes;
use Example::Syntax;

extends 'Example::Controller';

has account => (is=>'rw');

sub root :Chained(/auth) PathPart('account') Args(0) Does(Verbs) View(HTML::Account) ($self, $c) {
  $c->build_view(account => my $account = $c->user->account);
  $self->account($account);
}

  sub GET :Action ($self, $c) { return $c->view->set_http_ok }

  sub PATCH :Action RequestModel(AccountRequest) ($self, $c, $request) {
    $self->account->update_account($request);
    return $self->account->valid ? 
      $c->view->set_http_ok : 
        $c->view->set_http_bad_request;
  }

__PACKAGE__->meta->make_immutable;

