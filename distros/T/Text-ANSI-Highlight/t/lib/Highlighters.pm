package Highlighters;

use v5.16;
use warnings;
use File::Spec;

# The highlighters whose command is installed, and works
my %COMMAND = (
    pandoc          => 'pandoc',
    sourcehighlight => 'source-highlight',
    skylighting     => 'skylighting',
);

sub available {
    grep {
        my $command = $COMMAND{$_};
        my $found = grep { -x "$_/$command" } File::Spec->path;
        # the ansi writer of pandoc is not in an old one
        $found &&= `pandoc --list-output-formats 2>/dev/null` =~ /^ansi$/m
            if $_ eq 'pandoc';
        $found;
    } qw(pandoc sourcehighlight skylighting);
}

1;
