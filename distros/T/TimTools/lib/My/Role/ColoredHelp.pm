package My::Role::ColoredHelp;

use Mojo::Base -role;
use Term::ANSIColor qw( colored );

=head2 color_msg

Apply some colors to a help message.

=cut

sub color_msg {
    my ( $s, $msg, $script ) = @_;

    # Script.
    $msg =~ s/ <SCRIPT> / colored($script,"YELLOW") /xge;

    # Quotes.
    $msg =~ s/ ( ' [^']*+ ' ) / colored($1,"GREEN") /xge;

    # Variables.
    $msg =~ s/ (\$\w+) / colored($1,"GREEN") /xge;

    # Functions.
    $msg =~ s/ ( \w+\(\) ) / colored($1,"GREEN") /xge;

    # Options.
    $msg =~ s/ (-+\w[^#]+) / colored($1,"GREEN") /xge;

    # Comments.
    $msg =~ s/ (\#.+) / colored($1,"ON_BRIGHT_BLACK") /xge;

    # Errors.
    $msg =~ s/ ^ (ERROR:.+) / colored($1,"RED") /xge;

    $msg;
}

1;
