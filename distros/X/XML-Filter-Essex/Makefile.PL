use ExtUtils::MakeMaker;

WriteMakefile(
    NAME          => 'XML::Filter::Essex',
    VERSION_FROM  => 'lib/XML/Filter/Essex.pm',
    EXE_FILES     => [],
    PREREQ_PM => {
        IPC::Run => 0,
        XML::SAX::Writer   => 0.42,
        XML::SAX::PurePerl => 0,
        XML::SAX::Base     => 0,
        XML::Filter::Dispatcher => 0.4,
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
