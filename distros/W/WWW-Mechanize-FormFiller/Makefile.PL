use ExtUtils::MakeMaker;

use lib 'lib';

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'    => 'WWW::Mechanize::FormFiller',
    'VERSION_FROM'  => 'lib/WWW/Mechanize/FormFiller.pm', # finds $VERSION
    'PREREQ_PM'    => { 'HTML::Form' => 0,
			'Test::More' => 0,
			'HTML::Tagset' => 0,
    			'Data::Random' => 0.05,
    		}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'lib/WWW/Mechanize/FormFiller.pm', # retrieve abstract from module
       AUTHOR     => 'Max Maischein <corion@cpan.org>') : ()),
);

use vars qw($have_test_inline);
BEGIN {
  eval { require Test::Inline;
         $have_test_inline = $Test::Inline::VERSION ge '0.15_001'; };
  undef $@;
  if ($have_test_inline) {
    print "Good - you have a patched Test::Inline\n";
  } else {
    print "Test::Inline 0.15_001 is nice for testing the examples, but not necessary\n"
  };
};

# Autocreate the synopsis test from the pod of every module
# (if we have Test::Inline)
if (0) { eval q{
    package MY;
    use strict;
    sub top_targets {

        my($self) = @_;
        my $out = "POD2TEST_EXE = pod2test\n";

        $out .= $self->SUPER::top_targets(@_);
        return $out unless $main::have_test_inline;

        $out =~ s/^(pure_all\b.*)/$1 testifypods/m;

        $out .= "\n\ntestifypods : \n";

        foreach my $pod (keys %{$self->{MAN1PODS}},
                         keys %{$self->{MAN3PODS}})
        {
            (my $test = $pod) =~ s/\.(pm|pod)$//;
            $test =~ s|/|-|g;
            $test =~ s/^lib\W//;
            $test =~ s/\W/-/;
            $test = "embedded-$test.t";
            $out .= "\t$self->{NOECHO}\$(POD2TEST_EXE) ".
                    "$pod t/$test\n";
        }

        return $out;
    }
}}

# To make Test::Prereq happy
1;
