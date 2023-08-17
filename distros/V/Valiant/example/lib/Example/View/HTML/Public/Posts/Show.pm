package Example::View::HTML::Public::Posts::Show;

use Moo;
use Example::Syntax;
use Example::View::HTML
  -tags => qw(div h1 h2 p span link_to br),
  -views => 'HTML::Page', 'HTML::Navbar',
  -helpers => qw(path $sf user);

has 'post' => (is=>'ro', required=>1);

sub render($self, $c) {
  html_page page_title=>$self->post->author->$sf("{:first_name} {:last_name}"), sub($page) {
    html_navbar active_link=>path('show', [$self->post->id]),
    div {class=>"col-5 mx-auto"}, [
      h1 $self->post->title,
      p $self->post->content,
      br, 
      h2 'Comments',
      p {repeat=>$self->post->comments_rs }, sub($self, $comment, $idx) {
        p {class=>'card card-body'}, [
          $comment->person->$sf("{:first_name} {:last_name} said:"),
          span { class=>'mt-3'}, $comment->content,
          link_to path('comments/edit', [$comment->post_id, $comment->id]),
            {if=>sub { $comment->person->id == user->id}, class=>'mt-3'}, 'Edit this Comment',
        ]
      },
      link_to path('comments/build', [$self->post->id]), {class=>'btn btn-primary btn-lg btn-block'}, 'Add a new Comment',  
      link_to path('list'), {class=>'btn btn-secondary btn-lg btn-block'}, 'Return to Recent Blogs',
    ],
  },
}

1;
