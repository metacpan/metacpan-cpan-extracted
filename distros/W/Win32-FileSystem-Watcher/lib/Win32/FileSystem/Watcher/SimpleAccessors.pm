package Win32::FileSystem::Watcher::SimpleAccessors;

use strict;
use warnings;
use Scalar::Util qw(blessed);

sub accessor {
    my ( $pkg, $name ) = @_;
    $pkg = blessed($pkg) || $pkg;
    my $sub = sub {
        @_ > 1 ? $_[0]->{$name} = $_[1] : $_[0]->{$name};
    };

    {
        no strict 'refs';
        *{ "$pkg" . "::$name" } = $sub;
    }
}

1;
