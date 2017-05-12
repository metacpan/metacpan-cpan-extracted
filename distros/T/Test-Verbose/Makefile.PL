use ExtUtils::MakeMaker;

WriteMakefile(
    NAME          => 'Test::Verbose',
    VERSION_FROM  => 'lib/Test/Verbose.pm',
    EXE_FILES     => [ 'bin/tv' ],
);

sub MY::libscan {
    package MY;
    my $self = shift;
    my ( $path ) = @_;
    return '' if /\.sw[a-z]$/;
    return '' unless length $self->SUPER::libscan( $path );
    return $path;
}
