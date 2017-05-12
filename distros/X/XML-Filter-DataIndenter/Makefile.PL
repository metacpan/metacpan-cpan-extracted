use ExtUtils::MakeMaker;

WriteMakefile(
    NAME          => 'XML::Filter::DataIndenter',
    VERSION_FROM  => 'lib/XML/Filter/DataIndenter.pm',
    EXE_FILES     => [],
    PREREQ_PM => {
        XML::SAX::PurePerl => 0, ## for testing only
        XML::SAX::Writer   => 0, ## for testing only
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
