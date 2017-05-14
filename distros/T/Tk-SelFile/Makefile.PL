use ExtUtils::MakeMaker;
WriteMakefile(
   NAME => "Tk::SelFile",
   DISTNAME => "Tk-SelFile",
   linkext => {LINKTYPE => ''}, # not needed for MakeMakers >= 5
   VERSION => "0.02",
   dist => {COMPRESS=>'gzip -9f'},
);

