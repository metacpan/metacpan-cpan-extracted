package Example::View::HTML::Account::Edit;

use Moo;
use Example::Syntax;
use Example::View::HTML
  -tags => qw(div),
  -views => 'HTML::Page', 'HTML::Navbar' ,'HTML::Account::Form';

has 'account' => ( is=>'ro', required=>1 );

sub render($self, $c) {
  return html_page page_title=>'Homepage', sub($page) {
    return html_navbar active_link=>'account_details',
    div {class=>"col-5 mx-auto"},
      html_account_form { account=>$self->account };
  };
}

1;
