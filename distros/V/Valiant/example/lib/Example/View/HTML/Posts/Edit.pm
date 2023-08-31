package Example::View::HTML::Posts::Edit;

use Moo;
use Example::Syntax;
use Example::View::HTML
  -tags => qw(div a fieldset link_to legend br button hr form form_for),
  -helpers => qw(delete_uri),
  -views => 'HTML::Page', 'HTML::Navbar', 'HTML::Posts::Form';

has 'post' => (is=>'ro', required=>1);

sub render($self, $c) {
  html_page page_title => 'Post', sub($page) {
    html_navbar active_link => 'my_posts',
    div {class=>"col-5 mx-auto"}, [
      html_posts_form post => $self->post,
      form { method=>'POST', action=>delete_uri([$self->post->id], {'x-tunneled-method'=>'delete'}) },
        button { class => 'btn btn-danger btn-lg btn-block'}, 'Delete Post',
    ],
  };
}

1;
