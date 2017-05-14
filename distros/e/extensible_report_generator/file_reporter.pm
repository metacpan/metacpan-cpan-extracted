package file_reporter;
@ISA = qw( ERG::report_generator_base );

#  version:  1.13
#  date:     7/2/98

#  this package is a demo file report generator class based on the report
#  generator class.

#  the package includes:
#
#      new
#	  creates file report generator
#      formatInfo
#         format information for a file
#      fileInfo
#         get information for a file
#      formatFieldValue
#         format a field
#      processSummaryFieldValue
#         process a field value for summary
#      tellSummaryFieldValue
#         tell a summary field value
#      formatSummary
#         format a summary line
#
#  s. luebking   phoenixL@aol.com

require "erg_report_generator.pm";
require "erg_report_summary.pm";
require 5.000;



#
#------------------------------------------------------------------------------
#
#  new method
#
#  ARGS:
#
#     1  -  spec string
#
#  RETURNS:  new object

sub new
{
   my $this = shift;
   my $specStr = shift;

   my $self;

   $self = $this->SUPER::new($specStr);


#  set up file report summary in case it's used

   $$self{'report-summary'} = ERG::report_summary->new();


   return $self;
}


#
#------------------------------------------------------------------------------
#
#  method to format file info
#
#  ARGS:
#
#     1  -  file name
#
#  RETURNS:  a string with line created by formatting file info
#
#  this method also processes field values to create summary field values

sub formatInfo
{
   my $self = shift;
   my $fileName = shift;

   my $returnStr;
   my @values;

   @values = $self->fileInfo($fileName,$self->tellFieldTypes());

   $self->processSummaryFieldValueList($$self{'report-summary'},"",@values);

   $returnStr = $self->formatLine($self->formatFieldValueList(@values));

   return $returnStr;
}


#
#------------------------------------------------------------------------------
#
#  method to get file information
#
#  ARGS:
#
#     1  -  file name
#     2  -  field type
#     3  -  field type
#     .
#     .
#     .
#
#  RETURNS:  a list of values specified by field type arguments

sub fileInfo
{
   my $self = shift;
   my $fileName = shift;

   my @fieldtypes;
   my @returnList;
   my $valName;
   my @names;
   my %valTable;

   @fieldTypes = @_;

   @returnList = ();


#  build value table

   %valTable = ( "name", $fileName);

   @names = ("dev", "ino", "mode", "nlink", "uid", "gid", "rdev", "size",
                "atime", "mtime", "ctime", "blksize", "blocks");

   foreach $statValue (stat($fileName))
   {
      $valTable{shift @names} = $statValue;
   }

   foreach $fieldType ( @fieldTypes )
   {
      $str = "unknown $fieldType";

      $valName = $fieldType;
      $valName =~ s/::.*//;

      if(defined $valTable{$valName})
      {
         $str = $valTable{$valName};
      }

      push(@returnList,$str);
   }
   
   return @returnList;
}


#
#------------------------------------------------------------------------------
#
#  method to format field value
#
#  ARGS:
#
#     1  -  field type
#     2  -  field value
#
#  RETURNS:  a string with formatted field value

sub formatFieldValue
{
   my $self = shift;
   my $fieldType = shift;
   my $fieldValue = shift;

   my $returnStr;

   $returnStr = $fieldValue;

   if(defined $fieldValue)
   {
      if($fieldType =~ /::date-time/)
      {
         $returnStr = $self->dateStr($fieldValue) . " " . $self->timeStr($fieldValue);
      }
      elsif($fieldType =~ /::date/)
      {
         $returnStr = $self->dateStr($fieldValue);
      }
      elsif($fieldType =~ /::time/)
      {
         $returnStr = $self->timeStr($fieldValue);
      }
      elsif($fieldType =~ /^size/)
      {
         $returnStr = $self->generalNumberFormatter(
	 			$fieldValue, 3, ",", ".", 0);
      }
   }

   return $returnStr;
}


#======================================================================
#
#  this section contains various methods used for processing information
#  for summaries
#
#======================================================================


#
#------------------------------------------------------------------------------
#
#  method to process summary field value
#
#  ARGS:
#
#     1  -  report summary object
#     2  -  summary type
#     3  -  field type
#     4  -  field value
#
#  RETURNS:  none

sub processSummaryFieldValue
{
   my $self = shift;
   my $reportSummary = shift;
   my $summaryType = shift;
   my $fieldType = shift;
   my $fieldValue = shift;

   my $name;

   $name = $fieldType;
   $name =~ s/::.*//;

   if($fieldType =~ /::total/i)
   {
      $reportSummary->addValue($name . "##total", $fieldValue);
   }

   if($fieldType =~ /::avg/i)
   {
      $reportSummary->avgAddValue($name . "##average", $fieldValue);
   }
}


#
#------------------------------------------------------------------------------
#
#  method to tell summary field value
#
#  ARGS:
#
#     1  -  report summary object
#     2  -  summary type
#     3  -  field type
#
#  RETURNS:  a summary field value of type specified

sub tellSummaryFieldValue
{
   my $self = shift;
   my $reportSummary = shift;
   my $summaryType = shift;
   my $fieldType = shift;

   my $returnValue;
   my $name;

   $name = $fieldType;
   $name =~ s/::.*//;
   $name .= "##\L$summaryType";

   $returnValue = $reportSummary->tellValue($name);

   return $returnValue;
}


#
#------------------------------------------------------------------------------
#
#  method to format summary
#
#  ARGS:
#
#     1  -  summary type
#
#  RETURNS:  a string with line created by formatting summary file info

sub formatSummary
{
   my $self = shift;
   my $summaryType = shift;

   my $returnStr;
   my @formattedValues;

   @formattedValues = $self->formatSummaryFieldValueList($summaryType,
                            $self->tellSummaryFieldValueList(
			                $$self{'report-summary'},$summaryType));

   $formattedValues[0] = $summaryType;

   $returnStr = $self->formatLine(@formattedValues);

   return $returnStr;
}


#------------------------------------------------------------------------------
#  return 1 for require
1;


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
