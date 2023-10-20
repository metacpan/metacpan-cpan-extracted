package Example::View::JS::Account::Edit;

use Moo;
use Example::Syntax;
extends 'Example::View::JS';

has 'account' => ( is=>'ro', required=>1 );

sub get_form_html($self) {
  my $content = $self->ctx->view(
    'HTML::Account::Form',
    account => $self->account
  )->get_rendered;
  return $self->escape_javascript($content);
}

1;

__DATA__
% my ($self, $c) = @_;
$(document).on('ajax:success', function(event, data, status, xhr) {
  $(event.target).html('<%=  $self->get_form_html %>');
});

