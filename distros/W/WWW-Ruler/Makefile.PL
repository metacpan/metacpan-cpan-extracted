use strict;
use warnings;

use inc::Module::Install;

name 'WWW-Ruler';
abstract 'Simple helper for making ruler for WWW pages';

author 'Perlover <perlover@perlover.com>';
version_from 'lib/WWW/Ruler.pm';

auto_set_repository;
license 'perl';

WriteAll();

package MY;

sub distdir {
    my $inherited = shift->SUPER::distdir(@_);
    $inherited =~ s/^(create_distdir\s.*)/$& README/m;
    $inherited .= "README : lib/WWW/Ruler.pm\n\tperldoc -t lib/WWW/Ruler.pm > README\n";
    return $inherited;
}
