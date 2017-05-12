use ExtUtils::MakeMaker;

warn "DEPRECATED, see WordPress::CLI distro instead";

WriteMakefile(
   NAME => 'WordPress::Post',
   VERSION_FROM => 'lib/WordPress/Post.pm',
   ABSTRACT_FROM => 'lib/WordPress/Post.pm',
   PREREQ_PM => {
      'YAML' => 0,
      'Smart::Comments' => 0,
      'Date::Simple' => 0,
      'XMLRPC::Lite' => 0,
      'File::Type' => 0,
      'MIME::Base64' => 0,
      'LEOCHARRE::CLI' => 0,
      'Image::Magick' => 0,

   },
   EXE_FILES => ['bin/wppost'],

);
