package ojo::ServeDir::App;

use Mojo::Base 'Mojolicious';
use Cwd;

sub startup {
    my $app = shift;
    my $dir = $ENV{SERVE_DIRECTORY} // getcwd;
    $app->static->paths([$dir]);
    $app->log->info("Serving directory '$dir'...")->level('error');
}

1;

__END__
