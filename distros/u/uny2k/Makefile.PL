#!/usr/bin/perl -w

# A template for Makefile.PL
# - Set the $PACKAGE variable to the name of your module.
# - Set $LAST_API_CHANGE to reflect the last version you changed the API 
#   of your module.
# - Fill in your dependencies in PREREQ_PM
# Alternatively, you can say the hell with this and use h2xs.

use ExtUtils::MakeMaker;

$PACKAGE = 'uny2k';
($PACKAGE_FILE) = $PACKAGE =~ /(?:\::)?([^:]+)$/;
$LAST_API_CHANGE = 0;

eval "require $PACKAGE";


unless ($@) { # Make sure we did find the module.
    print <<"CHANGE_WARN" if ${$PACKAGE.'::VERSION'} < $LAST_API_CHANGE;

NOTE: There have been API changes between this version and any older
than version $LAST_API_CHANGE!  Please read the Changes file if you
are upgrading from a version older than $LAST_API_CHANGE.

CHANGE_WARN
}

WriteMakefile(
    NAME            => $PACKAGE,
    VERSION_FROM    => "lib/$PACKAGE_FILE.pm", # finds $VERSION
    PREREQ_PM       => { 
        Test::More  => 0.08
    },
    LICENSE         => 'perl'
);


{
    package MY;
    sub top_targets {
        my($self) = @_;
        my $out = "POD2TEST_EXE = pod2test\n";

        $out .= $self->SUPER::top_targets(@_);
        $out =~ s/^(pure_all\b.*)/$1 testifypods/m;

        my @pods = (keys %{$self->{MAN1PODS}}, keys %{$self->{MAN3PODS}});
        my @tests;

        # Build a list of test files for each POD.
        for my $pod (@pods)
        {
            (my $test = $pod) =~ s/\.(pm|pod)$//;
            $test =~ s/^lib\W//;
            $test =~ s/\W/-/;
            $test = "t/embedded-$test.t";

            push @tests, $test;
        }

        # Create a target for each test.
        for my $idx (0..$#tests) {
            my $test = $tests[0];
            my $pod  = $pods [0];

            $out .= "\n\n$test : $pod\n";
            $out .= "\t- \$(POD2TEST_EXE) $pod $test\n";
        }

        # And the overall testifypods target
        $out .= "\n\ntestifypods : @tests\n";
        $out .= "\t\$(NOOP)\n";

        return $out;
    }
}
