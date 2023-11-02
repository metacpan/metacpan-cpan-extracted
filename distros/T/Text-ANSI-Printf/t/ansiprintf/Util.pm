use v5.14;
use warnings;

use App::ansiprintf;
use Command::Runner;

sub ansiprintf {
    my @argv = @_;
    Command::Runner->new(
	command => sub { eval { App::ansiprintf->new->run(@argv) } },
	stderr  => sub { warn "err: $_[0]\n" },
	)->run;
}

1;
