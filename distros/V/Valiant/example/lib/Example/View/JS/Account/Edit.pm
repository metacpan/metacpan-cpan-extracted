package Example::View::JS::Account::Edit;

use CatalystX::Moose;
use Example::Syntax;
use Example::View::JS;

has 'account' => ( is=>'ro', context=>1 );

sub get_form_html($self) {
  my $content = $self->ctx->view(
    'HTML::Account::Form',
    account => $self->account
  )->get_rendered;
  return my $escaped = $self->escape_javascript($content);
}

__PACKAGE__->meta->make_immutable;

__DATA__
$(document).on('ajax:success', function(event, data, status, xhr) {
  $(event.target).html('{:get_form_html}');
});

