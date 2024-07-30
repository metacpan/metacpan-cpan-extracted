package Example::View::JS::Session::Build;

use CatalystX::Moose;
use Example::Syntax;
use Example::View::JS;

has replace => (is=>'ro', required=>1);

sub get_form_html($self) {
  my $content = $self->ctx->view('HTML::Session::Form')->get_rendered;
  return my $escaped = $self->escape_javascript($content);
}

__PACKAGE__->meta->make_immutable;

__DATA__
$('{:replace}').on('ajax:success', function(event, data, status, xhr) {
  $(event.target).html('{:get_form_html}');
});