package Lisp::Subr::Perl;

# Make many perl functions available in the lisp envirionment

use strict;
use vars qw($DEBUG $VERSION);

$VERSION = sprintf("%d.%02d", q$Revision: 1.4 $ =~ /(\d+)\.(\d+)/);

use Lisp::Symbol qw(symbol);

my @code;

# Perl builtins that does take zero arguments
for (qw(time times getlogin getppid fork wait)) {
    push(@code, qq(symbol("$_")->function(sub { $_ });\n));
}

# Perl builtins that take one optional argument
for (qw(sin cos rand srand exp log sqrt int hex oct abs ord chr
        ucfirst lcfirst uc lc quotemeta caller reset exit
        umask chdir chroot readlink rmdir getpgrp
        localtime gmtime alarm sleep
        require stat length chop chomp defined undef study pos
        -r -w -x -o -R -W -X -O -e -z -s -f -d -l -p -S -b -c
        -t -u -g -k -u -g -k -T -B -M -A -C
    ))
{
    push(@code, qq(symbol("$_")->function(sub { \@_==0?$_:$_ \$_[0] });\n));
}

print join("", @code) if $DEBUG;
eval join("", @code);
die $@ if $@;

# some additional stuff
symbol("perl-eval")->function(sub { eval $_[0] });

1;
