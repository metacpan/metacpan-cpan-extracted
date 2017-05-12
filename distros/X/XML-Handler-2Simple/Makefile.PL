use ExtUtils::MakeMaker;

WriteMakefile(
    NAME          => 'XML::Handler::2Simple',
    VERSION_FROM  => 'lib/XML/Handler/2Simple.pm',
    PREREQ_PM => {
       "XML::Simple" => 0,
       "XML::Handler::Trees" => 0,
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
