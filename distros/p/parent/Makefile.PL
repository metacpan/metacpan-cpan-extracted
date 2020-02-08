use ExtUtils::MakeMaker;

WriteMakefile1(
    'NAME'            => 'parent',
    'ABSTRACT_FROM'   => 'lib/parent.pm', # retrieve abstract from module
    'AUTHOR'          => 'Max Maischein <corion@cpan.org>',
    'VERSION_FROM'    => "lib/parent.pm", # finds $VERSION
    'PREREQ_PM'       => {},
    'TEST_REQUIRES' => {
        'Test::More' => '0.40',
    },
    # parent.pm joined the core with 5.10.1
    # 5.12 fixed the @INC order so that site/ comes before perl/
    # So we only install into perl/ for versions between the two
    'INSTALLDIRS' => ($] >= 5.010001 and $] < 5.012 ? 'perl' : 'site'),
    'LICENSE'       => 'perl',
    META_MERGE => {
        "meta-spec" => { version => 2 },
        resources => {
            repository => {
                web => "https://github.com/Corion/parent",
                url => "git://github.com/Corion/parent.git",
                type => 'git',
            }
        },
        dynamic_config   => 0, # we promise to keep META.* up-to-date
        x_static_install => 1, # we are pure Perl and don't do anything fancy
    },
    MIN_PERL_VERSION => '5.006', # We use "our" in some places
);

1;

sub WriteMakefile1 {  #Compatibility code for old versions of EU::MM. Written by Alexandr Ciornii, version 2. Added by eumm-upgrade.
    my %params=@_;
    my $eumm_version=$ExtUtils::MakeMaker::VERSION;
    $eumm_version=eval $eumm_version;
    die "EXTRA_META is deprecated" if exists $params{EXTRA_META};
    die "License not specified" if not exists $params{LICENSE};
    if ($params{AUTHOR} and ref($params{AUTHOR}) eq 'ARRAY' and $eumm_version < 6.5705) {
        $params{META_ADD}->{author}=$params{AUTHOR};
        $params{AUTHOR}=join(', ',@{$params{AUTHOR}});
    }
    if ($params{TEST_REQUIRES} and $eumm_version < 6.64) {
        $params{BUILD_REQUIRES}={ %{$params{BUILD_REQUIRES} || {}} , %{$params{TEST_REQUIRES}} };
        delete $params{TEST_REQUIRES};
    }
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
          )
          if $ENV{PERL_TEST_ALL};

        my $out;
        foreach my $perl (@perls) {
            $out .= $self->SUPER::test_via_harness($perl, $tests);
        }

        return $out;
    }
}

1; # so you can require this Makefile.PL
