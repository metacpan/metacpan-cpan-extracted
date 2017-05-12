use inc::latest Module::Build;

my $class = Module::Build->subclass(
	class => 'TPD::Builder',
	code  => <<'END_CODE',
sub ACTION_authortest {
    my ($self) = @_;

    $self->depends_on('build');
    $self->depends_on('manifest');
    $self->depends_on('distmeta');

    $self->test_files( qw< t xt/author > );
    $self->depends_on('test');

    return;
}


sub ACTION_manifest {
    my ($self, @arguments) = @_;

    if (-e 'MANIFEST') {
        unlink 'MANIFEST' or die "Can't unlink MANIFEST: $!";
    }

    return $self->SUPER::ACTION_manifest(@arguments);
}
END_CODE
);

my $builder = $class->new(
    module_name         => 'Test::Perl::Dist',
    license             => 'perl',
    dist_author         => 'Curtis Jewell <CSJewell@cpan.org>',
    dist_version_from   => 'lib/Test/Perl/Dist.pm',
	dist_abstract       => 'Test module for Perl::Dist::WiX and subclasses',
	create_readme       => 1,
	create_license      => 1,
	create_makefile_pl  => 'small',
	configure_requires  => {
        'Module::Build'      => 0.36,
	},
    requires => {
	    'perl'               => 5.008001,
		'parent'             => 0.221,
		'File::Remove'       => 1.42,
		'LWP::Online'        => 1.07,
		'Test::More'         => 0.88,
		'URI'                => 1.40,
		'Win32'              => 0.39,
    },
	build_requires      => {
        'Test::More'         => 0.88,
	},
	meta_merge     => {
        resources  => {
            homepage    => 'http://csjewell.comyr.com/perl/',
            bugtracker  => 'http://rt.cpan.org/NoAuth/Bugs.html?Dist=Test-Perl-Dist',
            repository  => 'http://svn.ali.as/cpan/trunk/Test-Perl-Dist/'
        },
    },
    add_to_cleanup      => [ 'Test-Perl-Dist-*', ],
);

$builder->create_build_script();
