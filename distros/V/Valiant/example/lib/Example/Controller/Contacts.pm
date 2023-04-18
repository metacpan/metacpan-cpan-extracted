package Example::Controller::Contacts;

use Moose;
use MooseX::MethodAttributes;
use Example::Syntax;
use Types::Standard qw(Int);

extends 'Example::Controller';

# Example of a classic full CRUDL controller

# /contacts/...
sub collection :Via('*Private') At('contacts/...') ($self, $c, $user) {
  $c->action->next(my $contacts = $user->contacts);
}

  # /contacts/...
  sub search :Via('collection') At('/...') QueryModel(ContactsQuery) ($self, $c, $collection, $contacts_query) {
    my $sessioned_query = $c->model('ContactsQuery::Session', $contacts_query);
    my $list = $collection->filter_by_request($sessioned_query);
    $c->action->next($list);
  }

    # GET /contacts
    sub list :GET Via('search') At('') QueryModel(ContactsQuery) ($self, $c, $contacts, $contacts_query) {
      return $c->view('HTML::Contacts', list => $contacts)->set_http_ok;
    }

  # /contacts/...
  sub new_entity :Via('collection') At('/...') ($self, $c, $collection) {
    my $new_contact = $collection->new_contact;
    $c->view('HTML::Contacts::CreateContact', contact => $new_contact );
    $c->action->next($new_contact);
  }

    # GET /contacts/init
    sub init :GET Via('new_entity') At('/init') ($self, $c, $new_contact) {
      return $c->view->set_http_ok;
    }

    # POST /contacts/
    sub create :POST Via('new_entity') At('') BodyModel(ContactRequest) ($self, $c, $new_contact, $r) {
      return $new_contact->set_from_request($r) ?
        $c->view->set_http_ok : 
          $c->view->set_http_bad_request;
    }

  # /contacts/{:Int}/...
  sub entity :Via('collection') At('{:Int}/...') ($self, $c, $collection, $id) {
    my $contact = $collection->find($id) // $c->detach_error(404, +{error=>"Contact id $id not found"});
    $c->action->next($contact);
  }

    # GET /contacts/{:Int}
    sub show :GET Via('entity') At('') ($self, $c, $contact) {
      # This is just a placeholder for how I'd add a route to handle
      # showing a non editable webpage.
    }

    # DELETE /contacts/{:Int}
    sub delete :DELETE Via('entity') At('') ($self, $c, $contact) {
      return $contact->delete && $c->redirect_to_action('list');
    }

    # /contacts/{:Int}/...
    sub setup_update :Via('entity') At('/...') ($self, $c, $contact) {
      $c->view('HTML::Contacts::EditContact', contact => $contact);
      $c->action->next($contact);
    }

      # GET /contacts/{:Int}/edit
      sub edit :GET Via('setup_update') At('edit') ($self, $c, $contact) {
        return $c->view->set_http_ok;
      }
    
      # PATCH /contacts/{:Int}
      sub update :PATCH Via('setup_update') At('') BodyModel(ContactRequest) ($self, $c, $contact, $r) {
        return $contact->set_from_request($r) ?
          $c->view->set_http_ok :
            $c->view->set_http_bad_request;
      }


sub edit_entity_path($self, $c, $contact, $attrs=+{}) {
  return $self->ctx->uri('edit', [$contact->id], $attrs);
}

sub create_entity_path($self, $c, $attrs=+{}) {
  return $self->ctx->uri('create', $attrs);
}

sub update_entity_path($self, $c, $contact, $attrs=+{}) {
  return $self->ctx->uri('update', [$contact->id], $attrs);
}

sub init_entity_path ($self, $c, $attrs=+{}) {
  return $self->ctx->uri('init', $attrs);
}

sub delete_entity_path ($self, $c, $contact, $attrs=+{}) {
  return $self->ctx->uri('delete', [$contact->id], $attrs);
}

sub list_entities_path ($self, $c, $attrs=+{}) {
  return $self->ctx->uri('list', $attrs);
}



__PACKAGE__->meta->make_immutable;
