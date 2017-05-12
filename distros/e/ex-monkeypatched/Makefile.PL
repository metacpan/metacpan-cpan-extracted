use 5.008;
use ExtUtils::MakeMaker;

my $file = 'lib/ex/monkeypatched.pm';
my %data = (
    NAME                  => 'ex::monkeypatched',
    LICENSE               => 'perl',
    MIN_PERL_VERSION      => '5.008',
    META_MERGE            => {
        resources         => {
            repository    => 'https://github.com/arc/p5-ex-monkeypatched',
        },
    },
    VERSION_FROM          => $file,
    ABSTRACT_FROM         => $file,
    AUTHOR                => 'Aaron Crane <arc@cpan.org>',
    BUILD_REQUIRES        => {
        'Test::More'      => '0.88',
        'Test::Exception' => 0,
    },
    PREREQ_PM             => {
        'Sub::Name'       => 0,
    },
);

for ($ExtUtils::MakeMaker::VERSION) {
    delete $data{MIN_PERL_VERSION} if $_ < 6.48;
    delete $data{META_MERGE}       if $_ < 6.46;
    delete $data{LICENSE}          if $_ < 6.31;
    $data{PREREQ_PM} = { %{ $data{PREREQ_PM} }, %{ delete $data{BUILD_REQUIRES} } }
                                   if $_ < 6.5503;
}

WriteMakefile(%data);
