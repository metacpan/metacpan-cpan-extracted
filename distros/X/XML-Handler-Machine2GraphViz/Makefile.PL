use ExtUtils::MakeMaker;

WriteMakefile(
    NAME          => 'XML::Handler::Machine2GraphViz',
    VERSION_FROM  => 'lib/XML/Handler/Machine2GraphViz.pm',
    PREREQ_PM => {
       "XML::Filter::Dispatcher" => 0,
       "XML::SAX::Machines"      => 0,
       "GraphViz"                => 0,
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
