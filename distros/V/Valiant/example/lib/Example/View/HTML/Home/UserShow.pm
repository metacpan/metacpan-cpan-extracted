package Example::View::HTML::Home::UserShow;

use Moo;
use Example::Syntax;
use Example::View::HTML
  -tags => qw(div blockquote link_to button),
  -views => 'HTML::Page', 'HTML::Navbar',
  -helpers => 'path';

has info => (is=>'rw', predicate=>'has_info');

sub add_info($self, $info) {
  my $existing = $self->has_info ? $self->info : '';
  $self->info($existing.$info);
  return $self;
}

sub render($self, $c) {
  html_page page_title => 'Home', sub($page) {
    html_navbar active_link=>'home',
    blockquote +{ if=>$self->has_info, 
      class=>"alert alert-primary", 
      role=>"alert" }, $self->info,
    div 'Welcome to your Example application Homepage',
    div [
      'See ', link_to path('/public/posts/list'), 'Recent Blogs'
    ],
     div [
      button {
        formaction=>path('user_show'),
        type=>'button', 
        class=>'btn btn-primary',
        data=>{remote=>'true', confirm=>'Are you Sure'} }, 'Test Button'
    ]   
  };
}

1;
