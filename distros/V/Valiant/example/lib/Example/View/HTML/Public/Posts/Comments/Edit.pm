package Example::View::HTML::Public::Posts::Comments::Edit;

use Moo;
use Example::Syntax;
use Example::View::HTML
  -tags => qw(div a fieldset link_to legend br button hr form form_for),
  -helpers => qw(path),
  -views => 'HTML::Page', 'HTML::Navbar', 'HTML::Public::Posts::Comments::Form';

has 'comment' => (is=>'ro', required=>1);

sub render($self, $c) {
  html_page page_title => 'Post', sub($page) {
    html_navbar active_link => '/posts',
    div {class=>"col-5 mx-auto"}, [
      html_public_posts_comments_form comment => $self->comment,
      form { method=>'POST', action=>path('delete', [$self->comment->post_id, $self->comment->id], {'x-tunneled-method'=>'delete'}) },
        button { class => 'btn btn-danger btn-lg btn-block'}, 'Delete Post',
    ],
  };
}

1;