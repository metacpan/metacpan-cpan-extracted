#!perl

use strict;
use warnings;

use Fatal qw( open close waitpid );
use English qw( -no_match_vars );
use IPC::Open2;
use POSIX qw(WIFEXITED);
use Text::Diff;

{

    package CountHunks;
    @CountHunks::ISA = qw( Text::Diff::Base );
    sub hunk { return '1' }

}

package main;

my %exclude = map { ( $_, 1 ) } qw(
    Changes
    MANIFEST
    META.yml
    Makefile.PL
    README
    etc/perlcriticrc
    etc/perltidyrc
    etc/last_minute_check.sh
);

sub run_tidy {
    my $file = shift;
    my @cmd  = qw(perltidy --profile=perltidyrc);
    push @cmd, $file;
    my ( $child_out, $child_in );

    my $pid = IPC::Open2::open2( $child_out, $child_in, @cmd )
        or Carp::croak("IPC::Open2 of perltidy pipe failed: $ERRNO");
    close $child_in;
    my $tidy_output = do {
        local ($RS) = undef;
        <$child_out>;
    };
    close $child_out;
    waitpid $pid, 0;

    my $diff = Text::Diff::diff $file, \$tidy_output,
        { STYLE => 'CountHunks', CONTEXT => 0 };

    if ( my $child_error = $CHILD_ERROR ) {
        Carp::croak("perltidy returned $child_error");
    }

    return $diff;
}

open my $manifest, '<', '../MANIFEST'
    or Carp::croak("open of MANIFEST failed: $ERRNO");

FILE: while ( my $file = <$manifest> ) {
    chomp $file;
    $file =~ s/\s*[#].*\z//xms;
    next FILE if $file =~ /.pod\z/xms;
    next FILE if $file =~ /.marpa\z/xms;
    next FILE if $file =~ /\/Makefile\z/xms;
    next FILE if $exclude{$file};
    $file = '../' . $file;
    next FILE if -d $file;
    Carp::croak("No such file: $file") unless -f $file;

    my $result = run_tidy($file);
    if ($result) {
        print "$file: ", ( length $result ), " perltidy issues\n"
            or Carp::croak('Cannot print to STDOUT');
    }
    else {
        print "$file: clean\n"
            or Carp::croak('Cannot print to STDOUT');
    }
}
close $manifest;
