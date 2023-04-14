package Example::View::HTML::Navbar;

use Moo;
use Example::Syntax;
use Example::View::HTML
  -tags => qw(nav a div button span),
  -util => qw($sf content_for path ),

has active_link => (is=>'ro', required=>1, default=>sub($self) { $self->ctx->req->uri->path });

sub links :Renders ($self) {
  my $class = "nav-item nav-link";
  state @links = (
    +{ href => '/', title => 'Home' },
    +{ href => path('/account/edit'), title => 'Account Details' },
    +{ href => path('/todos/list'), title => 'Todo List' },
    +{ href => path('/contacts/list'), title => 'Contact List' },
    +{ href => path('/session/logout'), title => 'Logout' },
  );

  return map {
    a +{
      class => ( $self->active_link eq $_->{href} ? "$class active" : $class), 
      href => "$_->{href}"
    }, $_->{title};
  } @links;
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
        [ $self->links ]
  ];
}

1;
