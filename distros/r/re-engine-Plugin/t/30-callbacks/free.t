=pod

Test the C<free> callback

=cut

use strict;
use Test::More tests => 2;

my $pat = 'pattern';

{
    use re::engine::Plugin (
        free => sub {
            pass 'default free callback';
        },
    );

    # Regexp destruction happens too late for Test::More, so do it in an eval.
    eval q[
        "str" =~ /$pat/;
    ];
    die $@ if $@;
}

{
    use re::engine::Plugin (
        comp => sub {
            my ($re) = @_;

            $re->callbacks(
                free => sub { pass 'free callback set in the comp callback' },
            );
        }
    );

    # Ditto.
    eval q[
        "str" =~ /$pat/;
    ];
    die $@ if $@;
}
