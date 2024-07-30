package Example::View::JS::Register::Build;

use CatalystX::Moose;
use Example::Syntax;
use Example::View::JS;
use Mojo::DOM;

has replace => (is=>'ro', required=>1);

sub get_form_html($self) {
  my $content = $self->ctx->view('HTML::Register::Form')->get_rendered;
  my $replacement = Mojo::DOM->new($content)->at($self->replace);
  return my $escaped = $self->escape_javascript($replacement);
}

__PACKAGE__->meta->make_immutable;

__DATA__
$(document).on('ajax:success', function(event, data, status, xhr) {
  let currentFocusedElement = $(':focus');
  $('{:replace}').replaceWith('{:get_form_html}');
  currentFocusedElement.length && $('#'+currentFocusedElement[0].id).focus();
});