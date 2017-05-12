use 5.008;
# I think this works with 5.6.1, it does use 'our'.  But tests use Test::More.
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

# Add proper shebang line to executables.
my @executables;

use Config;
foreach my $source (<*.source>) {
    my    $script      = $source;
    $script            =~ s/\.source/.pl/;
    open  SCRIPT,       ">$script" or next;
    open  SOURCE,        "$source" or next;
    chmod 0755,          "$script";
    push @executables,   "$script";
    print SCRIPT "$Config{startperl}\n";
    while (<SOURCE>) {
        print SCRIPT;
    }
    close SCRIPT;
    close SOURCE;
}

WriteMakefile(
        'NAME'		=> 'UML::State',
        'VERSION_FROM'	=> 'State.pm', # finds $VERSION
        'PREREQ_PM'     => {}, # e.g., Module::Name => 1.1
        ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
         (ABSTRACT_FROM => 'State.pm', # retrieve abstract from module
          AUTHOR        => 'Phil Crow <philcrow2000@yahoo.com>') : ()
        ),
        'EXE_FILES'     => \@executables # drawstate.pl
);
