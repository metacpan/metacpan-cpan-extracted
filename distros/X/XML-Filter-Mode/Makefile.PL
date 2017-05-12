use ExtUtils::MakeMaker;

WriteMakefile(
    NAME          => 'XML::Filter::Mode',
    VERSION_FROM  => 'lib/XML/Filter/Mode.pm',
    EXE_FILES     => [],
    PREREQ_PM => {
    },
);


sub MY::libscan {
    package MY;
    my $self = shift;
    my ( $path ) = @_;
    return '' if /\.sw[a-z]$/;
    return '' unless length $self->SUPER::libscan( $path );
    return $path;
}
