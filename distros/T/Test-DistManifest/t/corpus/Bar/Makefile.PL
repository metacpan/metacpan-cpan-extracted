use ExtUtils::MakeMaker;

WriteMakefile(
  "ABSTRACT" => "A sample dist",
  "AUTHOR" => "Anne O'Thor <author\@example.com>",
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "7.0507",
  },
  "DISTNAME" => "Bar",
  "LICENSE" => "perl",
  "NAME" => "Bar",
  "PREREQ_PM" => {
    "strict" => "0",
  },
  "VERSION" => "1.234",
  "test" => {
    "TESTS" => "t/*.t"
  }
);
