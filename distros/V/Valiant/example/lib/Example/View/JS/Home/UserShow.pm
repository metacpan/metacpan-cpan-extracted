package Example::View::JS::Home::UserShow;

use Moo;
use Example::Syntax;
extends 'Example::View::JS';

sub alert { return "aaaaaaa" }
sub add_info { return shift }

1;

__DATA__
% my ($self, $c) = @_;
$(document).on('ajax:success', function(event, data, status, xhr) {
  event.target.innerHTML = 'you clicked me!';
});
