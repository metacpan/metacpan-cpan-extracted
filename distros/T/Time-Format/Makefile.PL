use ExtUtils::MakeMaker;

my $MMV = $ExtUtils::MakeMaker::VERSION;
$MMV =~ s/_.*$//;
$MMV += 0.0;

my @wm_args =      (
                    NAME            => 'Time::Format',
                    VERSION_FROM    => 'lib/Time/Format.pm', # finds $VERSION
                    PREREQ_PM       => {
                                        'Test::Simple'   => '0.40',
                                        'Time::Local'    => '1.07',
                                       },
                    PL_FILES        => {},
                   );

if ($] >= 5.005)
{
    push @wm_args, (
                    ABSTRACT_FROM   => 'lib/Time/Format.pm', # retrieve abstract from module
                    AUTHOR          => 'Eric Roode <roode@cpan.org>',
                   );
}

if ($WWV >= 6.18  &&  MM->can('signature_target'))
{
    push @wm_args, (
                    SIGN            => 1,
                   );
}

if ($WWV >= 6.31)
{
    push @wm_args, (
                    LICENSE         => 'unrestricted',
                   );
}

if ($WWV > 6.55)
{
    push @wm_args, (
                    BUILD_REQUIRES  => {
                                        'Test::Simple'   => '0.40',
                                       },
                   );
}

if ($WWV >= 6.64)
{
    push @wm_args, (
                    TEST_REQUIRES   => {
                                        'FindBin'        => 0,
                                       },
                   );
}

WriteMakefile (@wm_args);
