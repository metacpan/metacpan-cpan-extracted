use ExtUtils::MakeMaker;

#   we need to create the .spec so MM doesn't complain it's missing
#   from the kit, but it must have an old timestamp or else make
#   refuses to make it

system "touch -t 0001010000 cpan2rpm.spec";

WriteMakefile
    NAME => "CPAN::RPM",
    DISTNAME => "cpan2rpm",
    VERSION_FROM => "cpan2rpm",
    $] < 5.005 ? () : (
        AUTHOR => 'Erick Calder <ecalder@cpan.org>',
        ABSTRACT_FROM => "cpan2rpm",
    ),
    EXE_FILES => [ "cpan2rpm" ],
    PREREQ_PM => {
        'ExtUtils::MakeMaker' => 5.4302,
        'LWP::UserAgent' => 0,
        'HTTP::Request' => 0,
    },
    dist => {
        COMPRESS => "gzip -9 -vf",
    },
    ;


package MY;

sub processPL {
    my $self = shift;
    my $block = $self->SUPER::processPL(@_);
    # "Version:" in spec needs to match
    # "$VERSION" from VERSION_FROM
    $block =~ s%(spec.PL\s*)$%$1 \$\(VERSION_FROM\)%m;
    $block;
    }

sub libscan {
    my $self = shift;
    my $path = shift;
    ($path =~ / \bCVS\b | \~$ /x) ? undef : $path;
    }

1;
