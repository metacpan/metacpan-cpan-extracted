use ExtUtils::MakeMaker;

WriteMakefile (
    'NAME'          => 'Unamerican::Truth',
    'AUTHOR'        => 'John Beppu <beppu@cpan.org>',
    'VERSION_FROM'  => 'Truth.pm',
    'ABSTRACT_FROM' => 'Truth.pm',
    'PREREQ_PM'     => {
	'HTML::Parser'     => 0,
	'CGI::Application' => 0,
	'HTML::Template'   => 0,
    },
);

sub MY::libscan {
    my $self = shift;
    $_       = shift;

    # $self appears to be a blessed hashref that contains
    # all the attributes/value pairs passed to WriteMakeFile()
    # plus some other MakeMaker-related info.

    return 0 if /\.sw.$/ || /~$/;
    return $_;
}
