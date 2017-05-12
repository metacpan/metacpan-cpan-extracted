use Module::Build '0.25';

my $class = Module::Build->subclass(
		class => 'Module::Build::Win32PingICMP',
		code => q{
			sub ppm_name {
				my $self = shift;
				mkdir('MSWin32-x86-multi-thread');
				return 'MSWin32-x86-multi-thread/' . $self->dist_dir;
			}

			sub ACTION_ppmzip {
				my $self = shift;

				$self->depends_on('ppmdist');
				my $ppmzip = $self->dist_dir().'.ppm.zip';
				my $ppm_name = $self->ppm_name();
				unlink($ppmzip);
				system("zip -9 $ppmzip *.ppd $ppm_name.tar.gz");
			}

		},
	);

my $build = $class->new(
		module_name => 'Win32::PingICMP',
		dist_name => 'Win32-PingICMP',
		license => 'perl',
		requires => {
				'Data::BitMask' => '0',
				'Win32::API' => '0',
			},
		requires_os => 'MSWin32',
		create_readme => 1,
	);
$build->create_build_script;
