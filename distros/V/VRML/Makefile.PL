use ExtUtils::MakeMaker;
WriteMakefile(
        NAME => 'VRML',
        VERSION_FROM => 'VRML.pm',
+         ($[ >= 5.005 ?
+           (ABSTACT => 'Specification independent VRML-Methods (1.0, 2.0, 97)',
+            AUTHOR  => 'Hartmut Palm (palm@gfz-potsdam.de)') : ()),
        DISTNAME => 'VRML',
        dist => {COMPRESS=>'gzip -9f', SUFFIX => 'gz'}
);
