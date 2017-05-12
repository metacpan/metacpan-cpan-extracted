use Module::Build '0.24';

my $class = Module::Build->subclass(
		class => 'Module::Build::Win32Security',
		code => q{
			sub make_executable {
				my $self = shift;

				foreach my $script (@_) {
					if ($script =~ /Perm(Chg|Dump|Fix)\.pl$/i) {
						$self->Module::Build::Base::make_executable($script);
					} else {
						$self->SUPER::make_executable($script);
					}
				}
			}

			sub ACTION_distdir {
				my ($self) = shift;

				$self->SUPER::ACTION_distdir();
				my $dist_dir = $self->dist_dir();
				my $dist_files = $self->_read_manifest('MANIFEST');
				foreach my $file (keys %$dist_files) {
					$file =~ /t\/[^\/.]+\.t/ or next;
					$file = "$dist_dir/$file";
					unless (open(MBWS_TEMP_FILE, "<$file")) {
						warn "Unable to open '$file' for reading.\n";
						next;
					}
					my(@orig_data) = <MBWS_TEMP_FILE>;
					close(MBWS_TEMP_FILE);

					my $orig_data = join('', @orig_data);
					my $new_data = join('', map {s/^(\s*\$enabled\s*=\s*)\d(\s*;\s*(?:\#.*)?)$/${1}0${2}/; $_} @orig_data);
					if ($orig_data ne $new_data) {
						print "Disabling tests in '$file'.\n";
						unless (open(MBWS_TEMP_FILE, ">$file")) {
							warn "Unable to open '$file' for writing.\n";
							next;
						}
						print MBWS_TEMP_FILE $new_data;
						close(MBWS_TEMP_FILE);
					}
				}
			}

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

			sub ACTION_ppmdist {
				my ($self) = @_;
				
				$self->depends_on('build', 'html', 'ppd');
				opendir(TEMPDIR, $self->blib().'/libdoc');
				foreach my $i (grep(!/^\.\.?$/, readdir(TEMPDIR))) {
					unlink($self->blib().'/libdoc/'.$i);
				}
				closedir(TEMPDIR);
				rmdir($self->blib().'/libdoc');
				$self->add_to_cleanup($self->ppm_name);
				$self->make_tarball($self->blib, $self->ppm_name);
			}

		},
	);

my $build = $class->new(
		module_name => 'Win32::Security',
		dist_name => 'Win32-Security',
		dist_version_from => 'lib/Win32/Security/NamedObject.pm',
		license => 'perl',
		requires => {
				'Class::Prototyped' => '0.98',
				'Data::BitMask' => '0.13',
				'Win32::API' => '0',
			},
		script_files => [
				'script/PermChg.pl',
				'script/PermDump.pl',
				'script/PermFix.pl'
			],
		requires_os => 'MSWin32',
		create_readme => 1,
	);
$build->create_build_script;
