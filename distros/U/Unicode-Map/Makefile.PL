#!/usr/bin/perl

use ExtUtils::MakeMaker;

WriteMakefile (
   "NAME"         => "Unicode::Map",
   "VERSION_FROM" => "Map.pm",
   "LIBS"         => [""],
   "DEFINE"       => "",
   "INC"          => "",
   "dist"         => {
      "COMPRESS"  => "gzip", 
      "SUFFIX"    => "gz"
   },
   "EXE_FILES"    => [
      "tools/map",
      "tools/mirrorMappings",
      "tools/mkCSGB2312",
      "tools/mkmapfile"
   ],
);

