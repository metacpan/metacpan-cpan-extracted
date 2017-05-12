use ExtUtils::MakeMaker;

WriteMakefile(
    NAME          => 'XML::Filter::TableWrapper',
    VERSION_FROM  => 'lib/XML/Filter/TableWrapper.pm',
    PREREQ_PM => {
       "XML::SAX::Base"    => 0,
       "XML::SAX::Writer"  => 0.42,  ## for test suite
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
