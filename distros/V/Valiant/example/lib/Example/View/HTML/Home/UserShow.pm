package Example::View::HTML::Home::UserShow;

use CatalystX::Moose;
use Example::Syntax;
use Example::View::HTML qw(link_to uri);

has info => (is=>'rw', predicate=>'has_info');

sub add_info($self, $info) {
  my $existing = $self->has_info ? $self->info : '';
  $self->info($existing.$info);
  return $self;
}

sub render($self, $c) {
  $self->view('HTML::Page', { page_title => 'Home' }, sub($page) {
    $self->view('HTML::Navbar', { active_link=>'home' }),
    Blockquote +{ if=>$self->has_info, 
      class=>"alert alert-primary", 
      role=>"alert" }, $self->info,
    Div 'Welcome to your Example application Homepage',
    Div $self->link_to($self->uri('/public/posts/list'), 'See Recent Blogs'),
    Div [
      Button {
        type => 'button', 
        class => 'btn btn-primary',
        data => +{ remote=>'true', url=>$self->uri('js_test'), confirm=>'Are you Sure?' },
      }, 'Test Button'
    ]   
  });
}

1;
