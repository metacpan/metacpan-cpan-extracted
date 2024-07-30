package Example::View::HTML::Navbar;

use CatalystX::Moose;
use Example::Syntax;
use Example::View::HTML qw(uri user);

has active_link => (is=>'ro', required=>1);

sub navlinks ($self) {
  my @links = (
    +{ href => $self->uri('/home/user_show'), data => {title=>'Home', key=>'home'} },
    +{ href => $self->uri('/account/edit'), data => {title=>'Account Details', key=>'account_details'} },
    +{ href => $self->uri('/todos/list'), data => {title=>'Todo List', key=>'todo_list'} },
    +{ href => $self->uri('/contacts/list'), data => {title=>'Contact List', key=>'contact_list'} },
    +{ href => $self->uri('/posts/list'), data => {title=>'My Posts', key=>'my_posts'} }, 
    +{ href => $self->uri('/session/logout'), data => {title=>'Logout', key=>'logout'} }, 
  );
  return @links;
}

sub generate_navlinks ($self) {
  my @local_links = map {
    my $title = $_->{data}{title} // die 'Missing title for link';
    my $key = $_->{data}{key} // die 'Missing key for link';
    my $local_class = $self->active_link eq $key ?
      "nav-item nav-link active" : "nav-item nav-link";
    A +{ class => $local_class, %{$_} }, $title;
  } $self->navlinks;
  return $self->safe_concat(@local_links);
}

sub render($self, $c) {
  Nav +{ class=>"navbar navbar-expand-lg navbar-light bg-light" }, [
    A +{ class=>"navbar-brand", href=>"/" }, 'Example Application',
    Button +{
      class=>"navbar-toggler", type=>"button",
      data=>{toggle=>"collapse", target=>"#navbarNavAltMarkup"},
      aria=>{controls=>"navbarNavAltMarkup", expanded=>"false", label=>"Toggle navigation"},
    }, Span +{ class=>"navbar-toggler-icon" }, '',
    Div +{ class=>"collapse navbar-collapse", id=>"navbarNavAltMarkup" },
      Div +{ class=>"navbar-nav" },
        $self->generate_navlinks,
  ];
}

__PACKAGE__->meta->make_immutable;