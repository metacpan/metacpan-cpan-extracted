package Catalyst::Model::WebService::CRUST;

use strict;

use base qw( WebService::CRUST Catalyst::Model );


sub new {
    my ($self, $c) = @_;

    return $self->NEXT::new(%{$self->config});
}


1;

__END__

=head1 NAME

Catalyst::Model::WebService::CRUST - Catalyst model class for making REST
queries using WebService::CRUST

=head1 SYNOPSIS

Create a controller using the helper:

  script/myapp_create.pl model MyService WebService::CRUST

Or make your own:

  package MyAPP::Model::MyService;
  
  use strict;
  use base 'Catalyst::Model::WebService::CRUST';
  
  # Optionally set a base or any other WebService::CRUST options
  __PACKAGE__->config(
      base => 'http://something/'
  );
  
  1;


Then in your Catalyst app:

  $c->stash->{result} = $c->model('MyService')->get('foo');
  
or if you like the autoload stuff:

  $c->stash->{foo} = $c->model('MyService')->foo;
  $c->stash->{bar} = $c->model('MyService')->post_bar(key => $val);


=head1 SEE ALSO

L<WebService::CRUST>, L<Catalyst::Model>

=head1 AUTHOR

Chris Heschong E<lt>chris@wiw.orgE<gt>

=cut