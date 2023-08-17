package Example::View::HTML::Navbar;

use Moo;
use Example::Syntax;
use Example::View::HTML
  -tags => qw(nav a div button span);

has active_link => (is=>'ro', required=>1);

sub navlinks ($self) {
  state @links = (
    +{ href => $self->path('/home/user_show'), data => {title=>'Home', key=>'home'} },
    +{ href => $self->path('/account/edit'), data => {title=>'Account Details', key=>'account_details'} },
    +{ href => $self->path('/todos/list'), data => {title=>'Todo List', key=>'todo_list'} },
    +{ href => $self->path('/contacts/list'), data => {title=>'Contact List', key=>'contact_list'} },
    +{ href => $self->path('/posts/list'), data => {title=>'My Posts', key=>'my_posts'} }, 
    +{ href => $self->path('/session/logout'), data => {title=>'Logout', key=>'logout'} }, 
  );
  return @links;
}

sub render($self, $c) {
  nav +{ class=>"navbar navbar-expand-lg navbar-light bg-light" }, [
    a +{ class=>"navbar-brand", href=>"/" }, 'Example Application',
    button +{
      class=>"navbar-toggler", type=>"button",
      data=>{toggle=>"collapse", target=>"#navbarNavAltMarkup"},
      aria=>{controls=>"navbarNavAltMarkup", expanded=>"false", label=>"Toggle navigation"},
    }, span +{ class=>"navbar-toggler-icon" }, '',
    div +{ class=>"collapse navbar-collapse", id=>"navbarNavAltMarkup" },
      div +{ class=>"navbar-nav" },
        $self->generate_navlinks,
  ];
}

sub generate_navlinks ($self) {
  state $class = "nav-item nav-link";
  
  my @local_links = map {
    my $title = $_->{data}{title} // die 'Missing title for link';
    my $key = $_->{data}{key} // die 'Missing key for link';
    my $local_class = $self->active_link eq $key ?
      "$class active" : $class;
    a +{ class => $local_class, %{$_} }, $title;
  } $self->navlinks;

  return $self->safe_concat(@local_links);
}

1;
