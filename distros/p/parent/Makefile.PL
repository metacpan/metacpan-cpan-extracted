# A template for Makefile.PL.
# - Set the $PACKAGE variable to the name of your module.
# - Set $LAST_API_CHANGE to reflect the last version you changed the API
#   of your module.
# - Fill in your dependencies in PREREQ_PM
# Alternatively, you can say the hell with this and use h2xs.

use ExtUtils::MakeMaker;

WriteMakefile1(
    'NAME'            => 'parent',
    'ABSTRACT_FROM'   => 'lib/parent.pm', # retrieve abstract from module
    'AUTHOR'          => 'Max Maischein <corion@cpan.org>',
    'VERSION_FROM'    => "lib/parent.pm", # finds $VERSION
    'PREREQ_PM'       => { Test::More => 0.40 },
    # parent.pm joined the core with 5.10.1
    # 5.12 fixed the @INC order so that site/ comes before perl/
    # So we only install into perl/ for versions between the two
    'INSTALLDIRS' => ($] >= 5.010001 and $] < 5.012 ? 'perl' : 'site'),
    'LICENSE'       => 'perl',
     'META_MERGE' => {
        'resources' => {
            'repository' => 'https://github.com/Corion/parent',
        },
    },
);

1;

sub WriteMakefile1 {  #Written by Alexandr Ciornii, version 0.21.
    my %params=@_;
    my $eumm_version=$ExtUtils::MakeMaker::VERSION;
    $eumm_version=eval $eumm_version;
    die "EXTRA_META is deprecated" if exists $params{EXTRA_META};
    die "License not specified" if not exists $params{LICENSE};
    if ($params{BUILD_REQUIRES} and $eumm_version < 6.5503) {
        #EUMM 6.5502 has problems with BUILD_REQUIRES
        $params{PREREQ_PM}={ %{$params{PREREQ_PM} || {}} , %{$params{BUILD_REQUIRES}} };
        delete $params{BUILD_REQUIRES};
    }
    delete $params{CONFIGURE_REQUIRES} if $eumm_version < 6.52;
    delete $params{MIN_PERL_VERSION} if $eumm_version < 6.48;
    delete $params{META_MERGE} if $eumm_version < 6.46;
    delete $params{META_ADD} if $eumm_version < 6.46;
    delete $params{LICENSE} if $eumm_version < 6.31;
    delete $params{AUTHOR} if $] < 5.005;
    delete $params{ABSTRACT_FROM} if $] < 5.005;
    delete $params{BINARY_LOCATION} if $] < 5.005;
    
    WriteMakefile(%params);
}

# Leftover voodoo for testing various Perl distributions
{
    package MY;

    sub test_via_harness {
        my($self, $orig_perl, $tests) = @_;

        my @perls = ($orig_perl);
        push @perls, qw(bleadperl
                        perl5.6.1
                        perl5.6.0
                        perl5.005_03
                        perl5.004_05
                        perl5.004_04
                        perl5.004)
          if $ENV{PERL_TEST_ALL};

        my $out;
        foreach my $perl (@perls) {
            $out .= $self->SUPER::test_via_harness($perl, $tests);
        }

        return $out;
    }
}

1; # so you can require this Makefile.PL
