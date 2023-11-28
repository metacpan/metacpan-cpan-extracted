package Misleading;
use vars qw< $VERSION >;

$VERSION = 0.42;
my ($major, $minor) = $VERSION =~ m/(\d+)(?:\.(\d+))?/;

my %opt = ();
%opt = (
    package => (exists($opt{package}) ? $opt{package} : (caller)[0]),
);

1;
