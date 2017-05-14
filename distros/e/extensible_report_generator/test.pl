#! /usr/local/bin/perl

#  version:  1.13
#  date:     9/2/98

#  this program is a demonstration of using the extensible report generator
#  (ERG) to produce reports on files in a directory.  the format of the
#  report can be changed by altering the report specification strings.

#  s. luebking   phoenixL@aol.com


require "file_reporter.pm";
require "erg_page_manager.pm";
require 5.000;


#  specifications for report generators

$directoryReportSpecification = "20|name|'Directory'  3b  9b  3b  20|mtime::date-time|'Modify time' 3b 20|atime::date|'Access'";

$fileReportSpecification = "20|name|'File'  3b  9r|size::total::avg|'Size'  3b  20|mtime::date-time|'Modify time' 3b 20|atime::date|'Access'";


#  specifications for page manager

$pageHeader = undef;
$pageTrailer = "count-format:  '\n' 60b 'Page ' * '\n\n'";
$maxPageLine = 24;



#  get lists of directories and files

@directories = ();
@files = ();

opendir(DIR,".");

while($file = readdir(DIR))
{
   next if ($file =~ /^([.]|[.][.])$/);
   push(@directories,$file) if (-d $file);
   push(@files,$file) if (-f $file);
}


#  create report generators and page manager

$directoryReporter = file_reporter->new($directoryReportSpecification);
$fileReporter = file_reporter->new($fileReportSpecification);
$pageManager = ERG::page_manager->new($maxPageLine,$pageHeader ,$pageTrailer );


#  write report

if($#directories < 0)
{
   $pageManager->writeLines("No directories\n");
}
else
{
   $newLine = $directoryReporter->formatFieldHeadings("") . "\n\n";

   foreach $name (sort(@directories))
   {
      $newLine .= $directoryReporter->formatInfo($name);
      $pageManager->writeLines($newLine);

      $newLine = "";
   }

   $pageManager->writeLines("\n");
}

if($#files < 0)
{
   $pageManager->writeLines("No files\n");
}
else
{
   $newLine = $fileReporter->formatFieldHeadings("") . "\n\n";

   foreach $name (sort(@files))
   {
      $newLine .= $fileReporter->formatInfo($name);
      $pageManager->writeLines($newLine);

      $newLine = "";
   }

   if($fileReportSpecification =~ /::total/i)
   {
      $newLine = "\n" . $fileReporter->formatSummary("Total");
      $pageManager->writeLines($newLine);
   }

   if($fileReportSpecification =~ /::avg/i)
   {
      $newLine = "\n" . $fileReporter->formatSummary("Average");
      $pageManager->writeLines($newLine);
   }
}


$pageManager->close();

sleep 30;


############################# Copyright #######################################

# Copyright (c) 1998 Scott Luebking. All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

###############################################################################
