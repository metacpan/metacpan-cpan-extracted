package Mojo::Debugbar::Monitor::Git;
use Mojo::Base "Mojo::Debugbar::Monitor";

has 'icon' => '<i class="icon-tree-conifer"></i>';
has 'name' => 'Git';

=head2 render

    Returns the html

=cut

sub render {
    my $self = shift;

    return sprintf(
        '<table class="debugbar-templates table" data-debugbar-ref="%s">
            <thead>
                <tr>
                    <th width="30%%">Field</th>
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

    my $rows = sprintf('<tr><td colspan="2">Git at %s:%s:%s (%s)</td></tr>', $hour, $min, $sec, scalar @{ $self->items });

    foreach my $item (@{ $self->items }) {
        $rows .= sprintf(
            '<tr>
                <td><a href="javascript:jQuery(\'[name=%s]\').css({ background: \'red\'}).focus();">%s</a></td>
                <td>%s</td>
            </tr>',
            $item->{ field }, $item->{ field }, $item->{ message }
        );
    }

    return $rows;
}

=head2 start
    Listen for "after_dispatch" event and if there's anything in stash for validate_tiny.errors key,
    store the field name and the error
=cut

sub start {
    my $self = shift;

    $self->app->hook(after_dispatch => sub {
        my $c = shift;

        my $home = $self->app->home;
        my $gitinfo = $self->git_info($home);
        my @items;

        push(@items, { field => $_, message => $gitinfo->{ $_ } }) for keys(%$gitinfo);

        $self->items(\@items);
    });
}

sub git_info {
    my $self = shift;
    my $home = shift;

    my $command = "git -P --work-tree=$home log -n1 --no-color --decorate";
    my $old_path = $ENV{'PATH'};
    $old_path =~ /(.+)/;
    $old_path = $1;
    $ENV{'PATH'} = $old_path;

    my $git_output = `$command`;

    $git_output =~ //;
    my @lines = split /[\r\n]+/, $git_output;

    my $line = shift @lines;
    my ($commit, $branch) = $line =~ /commit (\w+) .+ -> ([^,]+),.+/g;

    $line = shift @lines;
    my ($author) = $line =~ /Author: (.+) <(.+)/;

    $line = shift @lines;
    my ($date) = $line =~ /Date: (.+)/;

    my $comment = join ', ', @lines;

    return {
        branch => $branch,
        commit => $commit,
        author => $author,
        date => $date,
        comment => $comment
    };


}

1;
