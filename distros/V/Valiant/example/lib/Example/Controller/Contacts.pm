package Example::Controller::Contacts;

use Moose;
use MooseX::MethodAttributes;
use Example::Syntax;

extends 'Example::Controller';

sub contacts :Chained(../auth) CaptureArgs(0) ($self, $c, $user) {
  my $collection = $user->contacts;
  $c->next_action($collection);
}

  sub list :GET Chained(contacts) PathPart('') Args(0)  Name(contacts) ($self, $c, $collection) {
    $c->view('HTML::Contacts', list => $collection);
  }

__PACKAGE__->meta->make_immutable;
