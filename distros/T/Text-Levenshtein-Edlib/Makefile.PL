use 5.014000;
use Devel::CheckLib;
use ExtUtils::MakeMaker;

check_lib_or_exit
  lib => 'edlib';

WriteMakefile(
	NAME              => 'Text::Levenshtein::Edlib',
	VERSION_FROM      => 'lib/Text/Levenshtein/Edlib.pm',
	ABSTRACT_FROM     => 'lib/Text/Levenshtein/Edlib.pm',
	AUTHOR            => 'Marius Gavrilescu <marius@ieval.ro>',
	MIN_PERL_VERSION  => '5.14.0',
	LICENSE           => 'perl',
	SIGN              => 1,
	CONFIGURE_REQUIRES => {
		qw/Devel::CheckLib     0
		   ExtUtils::MakeMaker 0/,
	},
	PREREQ_PM         => {},
	LIBS              => ['-ledlib'],
	META_ADD           => {
		dynamic_config => 1,
		resources      => {
			repository => 'https://git.ieval.ro/?p=text-levenshtein-edlib.git',
		},
	}
);
if  (eval {require ExtUtils::Constant; 1}) {
  # If you edit these definitions to change the constants used by this module,
  # you will need to use the generated const-c.inc and const-xs.inc
  # files to replace their "fallback" counterparts before distributing your
  # changes.
  my @names = (qw(EDLIB_EDOP_DELETE EDLIB_EDOP_INSERT EDLIB_EDOP_MATCH
		 EDLIB_EDOP_MISMATCH EDLIB_STATUS_ERROR EDLIB_STATUS_OK),
              {name=>"EDLIB_CIGAR_EXTENDED", macro=>"1"},
              {name=>"EDLIB_CIGAR_STANDARD", macro=>"1"},
              {name=>"EDLIB_MODE_HW", macro=>"1"},
              {name=>"EDLIB_MODE_NW", macro=>"1"},
              {name=>"EDLIB_MODE_SHW", macro=>"1"},
              {name=>"EDLIB_TASK_DISTANCE", macro=>"1"},
              {name=>"EDLIB_TASK_LOC", macro=>"1"},
              {name=>"EDLIB_TASK_PATH", macro=>"1"});
  ExtUtils::Constant::WriteConstants(
                                     NAME         => 'Text::Levenshtein::Edlib',
                                     NAMES        => \@names,
                                     DEFAULT_TYPE => 'IV',
                                     C_FILE       => 'const-c.inc',
                                     XS_FILE      => 'const-xs.inc',
                                  );

}
else {
  use File::Copy;
  use File::Spec;
  foreach my $file ('const-c.inc', 'const-xs.inc') {
    my $fallback = File::Spec->catfile('fallback', $file);
    copy ($fallback, $file) or die "Can't copy $fallback to $file: $!";
  }
}
