#line 1
package Plack::Middleware::DirIndex;
{
  $Plack::Middleware::DirIndex::VERSION = '0.01';
}

# ABSTRACT: Append an index file to request PATH's ending with a /

use parent qw( Plack::Middleware );
use Plack::Util::Accessor qw(dir_index);

#line 33

sub prepare_app {
    my ($self) = @_;

    $self->dir_index('index.html') unless $self->dir_index;
}

sub call {
    my ( $self, $env ) = @_;

    if ( $env->{PATH_INFO} =~ m{/$} ) {
        $env->{PATH_INFO} .= $self->dir_index();
    }

    return $self->app->($env);
}

1;
