use ExtUtils::MakeMaker;

use 5.005;

use Config;
eval { require Scalar::Util };

if ( $Config{usethreads} and !$Config{use5005threads} and not defined(&Scalar::Util::weaken) ) {
  warn "WARNING - You are using a threaded perl but Scalar::Util::weaken is not available. Do not share refhashes across threads";
}

WriteMakefile
(
          'NAME' => 'Tie::RefHash',
          'VERSION_FROM' => 'lib/Tie/RefHash.pm',
          'PREREQ_PM' => {},
          'INSTALLDIRS' => 'perl',
          'PL_FILES' => {}
        )
;


