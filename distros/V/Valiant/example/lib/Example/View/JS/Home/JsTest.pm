package Example::View::JS::Home::JsTest;

use Moo;
use Example::Syntax;
use Example::View::JS;

has 'name' => (is=>'ro', required=>1);

1;

__DATA__
$(document).on('ajax:success', function(event, data, status, xhr) {
  event.target.innerHTML = 'you clicked me {:name}!';
});
