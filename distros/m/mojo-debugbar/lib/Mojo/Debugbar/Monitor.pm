package Mojo::Debugbar::Monitor;
use Mojo::Base -base;

use Mojo::Server;

has 'app' => sub { Mojo::Server->new->build_app('Mojo::HelloWorld') }, weak => 1;
has 'icon' => '';
has 'items' => sub { [] };
has 'name' => 'Monitor';

=head2 count
    Returns the number that will be shown in the title
=cut

sub count {
    return scalar(@{ shift->items });
}

=head2 render
    Returns the html
=cut

sub render {
    return '';
}

=head2 stop
    Stop the monitor
=cut

sub stop {
    shift->items([]);
}

=head2 start
    Start the monitor
=cut

sub start {
}

1;
