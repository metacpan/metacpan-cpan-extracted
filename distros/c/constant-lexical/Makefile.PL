BEGIN { require 5.008 } # 5.6.[12] %^H scoping bug

use ExtUtils::MakeMaker;
$USE_XS = $] >= 5.022;

if ($USE_XS) {
 -e 'lexical.xs' or $created = 1, open FH, ">lexical.xs" and close FH;
 *MY'postamble = sub {
   require File'Spec'Functions;
   my $xs_file = File'Spec'Functions'catfile("xs", 'lexical.xs');
   <<END;
lexical.xs : $xs_file
	\$(PERLRUN) -MFile::Copy "-ecopy '$xs_file', 'lexical.xs'"
END
 }

}
else { unlink 'lexical.xs', 'lexical.c' }

WriteMakefile(
    NAME                => 'constant::lexical',
    AUTHOR              => 'Father Chrysostomos <sprout [hat] cpan . org>',
    VERSION_FROM        => 'lib/constant/lexical.pm',
    ABSTRACT_FROM       => 'lib/constant/lexical.pm',
    PL_FILES            => {},
    PREREQ_PM => {
         $USE_XS ? (
          Carp        => 0,
          XSLoader    => 0,
         ) :
         $] >= 5.011002 ? (
          Carp        => 0,
          Lexical'Sub => 0,
         ) : (
          constant    => 1.03, # multiple
          Sub::Delete =>
              0+$] eq 5.01
           && eval {require Sub::Delete }
           && VERSION Sub::Delete >= .03
                       ? 1.00001 # %^H scoping bug
                       : 0,
          eval 'require Hash::Util::FieldHash'
           ? (Tie'Hash => 0)
           : (),
         ),
    },
    dist               => { COMPRESS => 'gzip -9f', SUFFIX => 'gz',
                            TAR => 'COPYFILE_DISABLE=1 tar' },
    clean              => { FILES => 'constant-lexical-* lexical.*' },
);

if ($USE_XS) {
 unlink 'lexical.xs' if $created;
}

