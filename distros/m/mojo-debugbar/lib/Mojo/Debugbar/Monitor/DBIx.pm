package Mojo::Debugbar::Monitor::DBIx;
use Mojo::Base "Mojo::Debugbar::Monitor";

use Mojo::Debugbar::Storage::DBIx;

has 'css' => <<'EOF'
<style type="text/css">
.debugbar-queries .source {
    display: none;
    font-style: italic;
}
.debugbar-queries tr:hover .source {
    display: block;
}
</style>
EOF
;
has 'icon' => '<i class="icon-database"></i>';
has 'name' => 'Queries';
has 'seen' => sub {{}};

=head2 render
    Returns the html
=cut

sub render {
    my $self = shift;

    my $rows = '';

    my $total_duration = 0;

    foreach my $query (@{ $self->items }) {
        my $seen = $self->seen->{ $query->{ sql } };
        my $seen_icon = $seen > 1 ? sprintf(' <span title="Seen %s times"><i class="icon-attention"></i></span>', $seen) : '';

        my $source = '';

        foreach my $frame (@{ $query->{ frames } }) {
            my $index = index($frame->filename, '../');
            $source .= substr($frame->filename, $index >= 0 ? $index + 3 : 0) . ':' . $frame->line .'<br />';
        }

        $rows .= sprintf(
            '<tr>
                <td>%s%s%s</td>
                <td>%ss</td>
            </tr>', 
            $query->{ sql }, $seen_icon, ($source ? '<br /><div class="source">' . $source . '</div>' : ''), $query->{ duration }
        );

        $total_duration += $query->{ duration };
    }

    return sprintf ('%s
        <table class="debugbar-queries table">
        <thead>
            <tr>
                <th>Query</th>
                <th width="70px">Duration</th>
            </tr>
        </thead>
        <tbody>
            %s
        </tbody>
            <tfoot>
                <tr>
                    <th class="text align right">Total</th>
                    <th>%ss</th>
                </tr>
            </tfoot>
        </table>',
        $self->css, $rows, $total_duration
    );
}

=head2 stop
    Stop debugging and clear "seen" items
=cut

sub stop {
    my $self = shift;

    $self->SUPER::stop();

    # turn off debugging
    $self->app->schema->storage->debug(0);

    $self->seen({});
}

=head2 start
    Change the debugobj for DBIX storage and record queries
=cut

sub start {
    my $self = shift;

    # turn on debugging
    $self->app->schema->storage->debug(1);

    my $debugobj = Mojo::Debugbar::Storage::DBIx->new();
    $debugobj->app_name(ref($self->app));

    $debugobj->recorder(sub {
        my $query = shift;

        my $items = $self->items;

        push(@$items, $query);

        $self->items($items);
        $self->seen->{ $query->{ sql } } += 1;
    });

    $self->app->schema->storage->debugobj($debugobj);
}

1;
