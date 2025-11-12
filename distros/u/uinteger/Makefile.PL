#!perl -w
use strict;
use ExtUtils::MakeMaker 6.46;
use Config;
use 5.016;

$Config{uvsize} == 8
  or die "Perl built with 64-bit integers required for uinteger\n";

my %opts = 
  (
   NAME => 'uinteger',
   VERSION_FROM => 'lib/uinteger.pm',
   OBJECT => 'uinteger$(OBJ_EXT)',
   LICENSE => "perl_5",
   AUTHOR => 'Tony Cook <tony@develop-help.com>',
   ABSTRACT => 'Unsigned integer math (eventually)',
   META_MERGE =>
   {
     'meta-spec' =>
     {
       version => "2",
       url => "https://metacpan.org/pod/CPAN::Meta::Spec",
     },
     resources =>
     {
       homepage => "http://github.com/tonycoz/perl5-uinteger/",
       repository =>
       {
         type => "git",
         url => "https://github.com/tonycoz/perl5-uinteger.git",
         web => "https://github.com/tonycoz/perl5-uinteger/",
       },
       bugtracker =>
       {
         web => "https://github.com/tonycoz/perl5-uint/",
       },
     },
   },
  );


$opts{META_MERGE}{prereqs} =
  {
    configure =>
    {
      requires =>
      {
        "ExtUtils::MakeMaker" => "6.46",
      },
    },
    build =>
    {
      requires =>
      {
        "Test::More" => "0.47",
        perl => "5.016",
      }
    },
    runtime =>
    {
      requires =>
      {
      }
    },
    test =>
    {
      requires =>
      {
        "Test::More" => "0.47",
      }
    },
  };
$opts{PREREQ_PM} =
  {
    XSLoader => 0,
  };

WriteMakefile
  (
    %opts,
    #DEFINE => $cflags,
    #LIBS => $ldflags,
   );
