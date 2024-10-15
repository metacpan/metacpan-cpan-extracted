package Mojo::Debugbar::Monitor::Template;
use Mojo::Base "Mojo::Debugbar::Monitor";

has 'icon' => '<i class="icon-file-code"></i>';
has 'name' => 'Templates';


=head2 render

    Returns the html

=cut

sub render {
    my $self = shift;

    return sprintf(
        '<table class="debugbar-templates table" data-debugbar-ref="%s">
            <thead>
                <tr><th>Path</th></tr>
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
    my $rows = sprintf('<tr><td>Templates at %s:%s:%s (%s)</td></tr>', $hour, $min, $sec, scalar @{ $self->items });

    foreach my $template (@{ $self->items }) {
        $rows .= sprintf('<tr><td>templates/%s.html.ep</td></tr>', $template);
    }

    return $rows;
}

=head2 start
    Listen for "before_render" event and store template names
=cut

sub start {
    my $self = shift;

    my @templates;

    $self->app->hook(before_render => sub {
        my ($c, $args) = @_;

        push(@templates, $args->{ template }) if ($args->{ template });
    });

    $self->items(\@templates);
}

1;
