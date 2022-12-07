package Example::Controller::Contacts::Contact;

use Moose;
use MooseX::MethodAttributes;
use Example::Syntax;

extends 'Example::Controller';

sub contact :Chained(../contacts) PathPart('') CaptureArgs(0) ($self, $c, $collection) {
  $c->next_action($collection);
}

  sub create :Chained(contact) PathPart(new) Args(0) Verbs(GET,POST) ($self, $c, $collection) {
    my $contact = $collection->new_contact;
    $c->view('HTML::Contact', contact => $contact);
    $c->next_action($contact);
  }

    sub POST_create :Action RequestModel(ContactRequest) ($self, $c, $r, $contact) {
      return $contact->set_from_request($r) ?
        $c->redirect_to($self->action_for('edit'), $contact->id) : 
          $c->view->set_http_bad_request;
    }

  sub edit :Chained(contact) PathPart('') Args(1) Verbs(GET,PATCH,DELETE) ($self, $c, $id, $collection) {
    my $contact = $collection->find($id) // $c->detach_error(404, +{error=>"Contact id $id not found"});
    $c->view('HTML::Contact', contact => $contact);
    $c->next_action($contact);
  }

    sub PATCH_edit :Action RequestModel(ContactRequest) ($self, $c, $r, $contact) {
      return $contact->set_from_request($r) ?
        $c->view->set_http_ok :
          $c->view->set_http_bad_request;
    }

    sub DELETE_edit :Action ($self, $c, $contact) {
      return $contact->delete && $c->redirect_to_action('#contacts');
    }

__PACKAGE__->meta->make_immutable;
