package Example::View::JS::Session::Build;

use Moo;
use Example::Syntax;
extends 'Example::View::JS';

sub login_path($self) {
  return my $login_path = $self->ctx->uri('build');
};

1;

__DATA__
% my ($self, $c) = @_;
$(document).on('ajax:success', function(event, data, status, xhr) {
  console.log("Redirecting: <%= $self->login_path %>");
  alert("Your session has expired; redirecting to login page.");
  window.location.href = "<%= $self->login_path %>";
});
