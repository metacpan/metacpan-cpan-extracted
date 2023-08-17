package Example::View::HTML::Contacts::Build;

use Moo;
use Example::Syntax;
use Example::View::HTML
  -tags => qw(div a fieldset link_to legend br button form_for),
  -util => qw(path),
  -views => 'HTML::Page', 'HTML::Navbar', 'HTML::Contacts::Form';

has 'contact' => (is=>'ro', required=>1);

sub render($self, $c) {
  html_page page_title=>'Contact List', sub($page) {
    html_navbar active_link=>'contact_list',
    div {class=>"col-5 mx-auto"},
      html_contacts_form contact=>$self->contact,
  };
}

1;
