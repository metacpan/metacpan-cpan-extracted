package Mojo::Debugbar::Monitor::Session;
use Mojo::Base "Mojo::Debugbar::Monitor";

use Mojo::JSON qw(encode_json);


has 'icon' => '<i class="icon-cloud"></i>';
has 'name' => 'Session';

=head2 render
    Returns the html
=cut

sub render {
    my $self = shift;

    my $rows = '';

    foreach my $item (@{ $self->items }) {
        $rows .= sprintf(
            '<tr>
                <td>%s</td>
                <td>%s</td>
            </tr>',
            $item->{ key }, $item->{ value } || ''
        );
    }

    return sprintf(
        '<table class="debugbar-templates table">
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
        $rows
    );
}

=head2 start
    Listen for "after_dispatch" event and collect session data
=cut

sub start {
    my $self = shift;

    my @items;


    $self->app->hook(after_dispatch => sub {
        my $c = shift;

        my $session = $c->session;

        for my $key (keys(%$session)) {
            my $value = $session->{ $key };
            $value = encode_json($value) if ref($value);

            push(@items, { key => $key, value => $value });
        }
    });

    $self->items(\@items);
}

1;
