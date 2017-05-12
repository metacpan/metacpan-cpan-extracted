#!/usr/bin/perl
use Module::Build;

my $class = Module::Build->subclass
    (class => 'My::Builder',
     code => q{
	 sub ACTION_build {
	     my $self = shift;

	     # Run the normal build
	     $self->SUPER::ACTION_build(@_);

	     # Now add in our extra files
	     $self->process_extra_files;
	 }
	 
	 sub process_extra_files {
	     my $self = shift;
	     my $files = $self->find_extra_files;
	     foreach my $file (@$files) {
		 $self->copy_if_modified($file, 'blib');
	     }
	 }

	 sub find_extra_files {
	     my $self = shift;
	     return $self->{properties}{extra_files} || [];
	 }
     },
     );

$class->new
    ( module_name  => 'Unicode::Collate::Standard::V3_1_1',
      author       => 'Ben Bennett <fiji@limey.net>',
      license      => 'perl',

      requires     => { 'Unicode::Collate' => 0,
			'File::Spec'       => 0,
                      },

      # The additional files to include
      extra_files  => ['lib/Unicode/Collate/Standard/V3_1_1.txt'],
    )->create_build_script;
