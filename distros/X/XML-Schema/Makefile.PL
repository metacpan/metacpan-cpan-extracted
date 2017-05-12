use ExtUtils::MakeMaker;

my %opts = (
    'NAME'	   => 'XML::Schema',
    'VERSION_FROM' => 'lib/XML/Schema.pm',
#   'EXE_FILES'    => [ ],
    'dist'         => {
	'COMPRESS' => 'gzip',
	'SUFFIX'   => 'gz',
    },
);

if ($ExtUtils::MakeMaker::VERSION >= 5.43) {
    $opts{ AUTHOR }   = 'Andy Wardley <abw@kfs.org>';
    $opts{ ABSTRACT } = 'XML Schema modules for Perl',
}

WriteMakefile( %opts );

