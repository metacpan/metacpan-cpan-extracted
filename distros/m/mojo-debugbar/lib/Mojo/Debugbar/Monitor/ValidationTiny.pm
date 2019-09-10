package Mojo::Debugbar::Monitor::ValidationTiny;
use Mojo::Base "Mojo::Debugbar::Monitor";

has 'icon' => '<i class="icon-flag"></i>';
has 'name' => 'Validation';

=head2 render
    Returns the html
=cut

sub render {
    my $self = shift;

    my $rows = '';

    foreach my $item (@{ $self->items }) {
        $rows .= sprintf(
            '<tr>
                <td><a href="javascript:jQuery(\'[name=%s]\').css({ background: \'red\'}).focus();">%s</a></td>
                <td>%s</td>
            </tr>',
            $item->{ field }, $item->{ field }, $item->{ message }
        );
    }

    return sprintf(
        '<table class="debugbar-templates table">
            <thead>
                <tr>
                    <th width="30%%">Field</th>
                    <th>Error</th>
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
    Listen for "after_dispatch" event and if there's anything in stash for validate_tiny.errors key,
    store the field name and the error
=cut

sub start {
    my $self = shift;

    $self->app->hook(after_dispatch => sub {
        my $c = shift;

        my $errors = $c->stash('validate_tiny.errors');

        my @items;
        
        push(@items, { field => $_, message => $errors->{ $_ } }) for keys(%$errors);

        $self->items(\@items);
    });
}

1;
