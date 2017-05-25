# ABSTRACT: Utilities for the testrail command line functions, and their main loops.
# PODNAME: TestRail::Utils

package TestRail::Utils;
$TestRail::Utils::VERSION = '0.040';
use strict;
use warnings;

use Carp qw{confess cluck};
use Pod::Usage ();
use TestRail::API;

use IO::Interactive::Tiny ();
use Term::ANSIColor 2.01 qw(colorstrip);
use Scalar::Util qw{blessed};

sub help {
    Pod::Usage::pod2usage(
        '-verbose'   => 2,
        '-noperldoc' => 1,
        '-exitval'   => 'NOEXIT'
    );
    return 0;
}

sub userInput {
    local $| = 1;
    my $rt = <STDIN>;
    chomp $rt;
    return $rt;
}

sub interrogateUser {
    my ( $options, @keys ) = @_;
    foreach my $key (@keys) {
        if ( !$options->{$key} ) {
            print "Type the $key for your TestRail install below:\n";
            $options->{$key} = TestRail::Utils::userInput();
            die "$key cannot be blank!" unless $options->{$key};
        }
    }
    return $options;
}

sub parseConfig {
    my ( $homedir, $login_only ) = @_;
    my $results = {};
    my $arr     = [];

    open( my $fh, '<', $homedir . '/.testrailrc' )
      or return ( undef, undef, undef );    #couldn't open!
    while (<$fh>) {
        chomp;
        @$arr = split( /=/, $_ );
        if ( scalar(@$arr) != 2 ) {
            warn("Could not parse $_ in '$homedir/.testrailrc'!\n");
            next;
        }
        $results->{ lc( $arr->[0] ) } = $arr->[1];
    }
    close($fh);
    return ( $results->{'apiurl'}, $results->{'password'}, $results->{'user'} )
      if $login_only;
    return $results;
}

sub getFilenameFromTapLine {
    my $orig = shift;

    $orig =~ s/ *$//g;    # Strip all trailing whitespace

    #Special case
    my ($is_skipall) = $orig =~ /(.*)\.+ skipped:/;
    return $is_skipall if $is_skipall;

    my @process_split = split( / /, $orig );
    return 0 unless scalar(@process_split);
    my $dotty =
      pop @process_split;    #remove the ........ (may repeat a number of times)
    return 0
      if $dotty =~
      /\d/;  #Apparently looking for literal dots returns numbers too. who knew?
    chomp $dotty;
    my $line = join( ' ', @process_split );

    #IF it ends in a bunch of dots
    #AND it isn't an ok/not ok
    #AND it isn't a comment
    #AND it isn't blank
    #THEN it's a test name

    return $line
      if ( $dotty =~ /^\.+$/
        && !( $line =~ /^ok|not ok/ )
        && !( $line =~ /^# / )
        && $line );
    return 0;
}

sub TAP2TestFiles {
    my $file = shift;
    my ( $fh, $fcontents, @files );

    if ($file) {
        open( $fh, '<', $file );
        while (<$fh>) {
            $_ = colorstrip($_);    #strip prove brain damage

            if ( getFilenameFromTapLine($_) ) {
                push( @files, $fcontents ) if $fcontents;
                $fcontents = '';
            }
            $fcontents .= $_;
        }
        close($fh);
        push( @files, $fcontents ) if $fcontents;
    }
    else {
        #Just read STDIN, print help if no file was passed
        die
          "ERROR: no file passed, and no data piped in! See --help for usage.\n"
          if IO::Interactive::Tiny::is_interactive();
        while (<>) {
            $_ = colorstrip($_);    #strip prove brain damage
            if ( getFilenameFromTapLine($_) ) {
                push( @files, $fcontents ) if $fcontents;
                $fcontents = '';
            }
            $fcontents .= $_;
        }
        push( @files, $fcontents ) if $fcontents;
    }
    return @files;
}

sub getRunInformation {
    my ( $tr, $opts ) = @_;
    confess("First argument must be instance of TestRail::API")
      unless blessed($tr) eq 'TestRail::API';

    my $project = $tr->getProjectByName( $opts->{'project'} );
    confess "No such project '$opts->{project}'.\n" if !$project;

    my ( $run, $plan );

    if ( $opts->{'plan'} ) {
        $plan = $tr->getPlanByName( $project->{'id'}, $opts->{'plan'} );
        confess "No such plan '$opts->{plan}'!\n" if !$plan;
        $run =
          $tr->getChildRunByName( $plan, $opts->{'run'}, $opts->{'configs'} );
    }
    else {
        $run = $tr->getRunByName( $project->{'id'}, $opts->{'run'} );
    }

    confess
      "No such run '$opts->{run}' matching the provided configs (if any).\n"
      if !$run;

    #If the run/plan has a milestone set, then return it too
    my $milestone;
    my $mid = $plan ? $plan->{'milestone_id'} : $run->{'milestone_id'};
    if ($mid) {
        $milestone = $tr->getMilestoneByID($mid);
        confess "Could not fetch run milestone!"
          unless $milestone;    #hope this doesn't happen
    }

    return ( $project, $plan, $run, $milestone );
}

sub getHandle {
    my $opts = shift;

    $opts->{'debug'} = 1 if ( $opts->{'browser'} );

    my $tr = TestRail::API->new(
        $opts->{apiurl},     $opts->{user}, $opts->{password},
        $opts->{'encoding'}, $opts->{'debug'}
    );
    if ( $opts->{'browser'} ) {
        $tr->{'browser'} = $opts->{'browser'};
        $tr->{'debug'}   = 0;
    }
    return $tr;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

TestRail::Utils - Utilities for the testrail command line functions, and their main loops.

=head1 VERSION

version 0.040

=head1 SCRIPT HELPER FUNCTIONS

=head2 help

Print the perldoc for $0 and exit.

=head2 userInput

Wait for user input and return it.

=head2 interrogateUser($options,@keys)

Wait for specified keys via userInput, and put them into $options HASHREF, if they are not already defined.
Returns modified $options HASHREF.
Dies if the user provides no value.

=head2 parseConfig(homedir)

Parse .testrailrc in the provided home directory.

Returns:

ARRAY - (apiurl,password,user)

=head2 getFilenameFromTapLine($line)

Analyze TAP output by prove and look for filename boundaries (no other way to figure out what file is run).
Long story short: don't end 'unknown' TAP lines with any number of dots if you don't want it interpreted as a test name.
Apparently this is the TAP way of specifying the file that's run...which is highly inadequate.

Inputs:

STRING LINE - some line of TAP

Returns:

STRING filename of the test that output the TAP.

=head2 TAP2TestFiles(file)

Returns ARRAY of TAP output for the various test files therein.
file is optional, will read TAP from STDIN if not passed.

=head2 getRunInformation

Return the relevant project definition, plan, run and milestone definition HASHREFs for the provided options.

Dies in the event the project/plan/run could not be found.

=head2 getHandle(opts)

Convenience method for binaries and testing.
Returns a new TestRail::API when passed an options hash such as is built by most of the binaries,
or returned by parseConfig.

Has a special 'mock' hash key that can only be used by those testing this distribution during 'make test'.

=head1 SPECIAL THANKS

Thanks to cPanel Inc, for graciously funding the creation of this module.

=head1 AUTHOR

George S. Baugh <teodesian@cpan.org>

=head1 SOURCE

The development version is on github at L<http://github.com/teodesian/TestRail-Perl>
and may be cloned from L<git://github.com/teodesian/TestRail-Perl.git>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by George S. Baugh.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
