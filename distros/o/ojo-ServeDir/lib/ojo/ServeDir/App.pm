package ojo::ServeDir::App;

use Mojo::Base 'Mojolicious';
use Mojo::File 'path';
use Cwd;

sub startup {
    my $app = shift;
    my $dir = path($ENV{SERVE_DIRECTORY} // getcwd)->to_abs;
    $app->static->paths([$dir]);
    $app->routes->get('/')->to(text => 'No index', status => 404);
    $app->log->info("Serving directory '$dir'...")->level('error');
}

1;

__END__
