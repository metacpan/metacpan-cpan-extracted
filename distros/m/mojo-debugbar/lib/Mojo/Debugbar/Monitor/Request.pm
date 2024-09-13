package Mojo::Debugbar::Monitor::Request;
use Mojo::Base "Mojo::Debugbar::Monitor";

has 'icon' => '<i class="icon-tag"></i>';
has 'name' => 'Request';

=head2 render

    Returns the html

=cut

sub render {
    my $self = shift;

    return sprintf(
        '<table class="debugbar-templates table" data-debugbar-ref="%s">
            <thead>
                <tr>
                    <th width="30%%">Key</th>
                    <th>Value</th>
                </tr>
            </thead>
            <tbody>
                %s
            </tbody>
        </table>',
        ref($self), $self->rows
    );
}

=head2 rows

    Build the rows

=cut

sub rows {
    my $self = shift;

    my $time = time;
    my ($sec, $min, $hour) = localtime($time);

    my $rows = sprintf('<tr><td colspan="2">Request at %s:%s:%s (%s)</td></tr>', $hour, $min, $sec, scalar @{ $self->items });

    foreach my $item (@{ $self->items }) {
        $rows .= sprintf(
            '<tr>
                <td>%s</td>
                <td>%s</td>
            </tr>',
            $item->{ key }, $item->{ value } || ''
        );
    }

    return $rows;
}

=head2 start

    Listen for "after_dispatch" event and push:
        - request method
        - request params as string
        - controller package name
        - current action name

=cut

sub start {
    my $self = shift;

    my @items;

    $self->app->hook(after_dispatch => sub {
        my $c = shift;

        push(@items, (
            { key => 'Method', value => $c->req->method },
            { key => 'Params', value => $c->req->params->to_string },
            { key => 'Controller', value => ref $c },
            { key => 'Action', value => $c->stash('action') },
        ));
    });

    $self->items(\@items);
}

1;
