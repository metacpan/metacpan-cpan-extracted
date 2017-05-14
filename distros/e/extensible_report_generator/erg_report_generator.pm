package ERG::report_generator_base;

#  version:  1.13
#  date:     7/2/98

#  this package is a basic report generator class.
#
#  a report generator is created using a specification string which
#  describes the field types, formats, headings and positions in a report line.
#
#  a report generator can be used to create three types of formatted lines
#  for a report.  the types of lines are:
#
#      lines with fields
#      lines with field headings
#      lines with field summary information
#
#  each line is created by first formatting each field, field heading
#  or field summary value into a string.  then the strings are formatted
#  into a line.  the methods formatFieldValue, formatFieldHeading
#  formatSummaryFieldVale can be over-ridden to tailor the formatting
#  of field value, field headings or summary field values for the
#  particular report.  (if the format method for field summary values is
#  not over-ridden, the method just calls the format method for field values.)
#
#  methods are provided for processing information for summaries in a report.
#  the methods processSummaryFieldValue and tellSummaryFieldValue
#  can be over-ridden to tailor the processing for the particular report.
#
#  some general formatting functions for time, date and numbers are provided.
#
#  if additional tailored specs are desired, the specToFormat method
#  can be over-ridden to handle these specs .   most of the time,
#  there is enough flexibility by over-riding the various other methods
#  that the specToFormat method does not need to be over-ridden.  (if the
#  specToFormat method is over-ridden, remember that the the scanner
#  only scans specs of the form s1's2' where s1 is a string with
#  no white-space or commas or quotes and s2 is any string.  (The quote
#  can be ', " or ` .)  s1 and s2 are both optional.  however, if s2
#  is specified, it must be surrounded by quotes.)

#  the package includes:
#
#      new
#	  creates report generator
#      scanSpecs
#         scan a string for specs
#      buildFormat
#         build a format from list of specs
#      specToFormat
#         convert a spec to format info
#      tellUnknownSpecs
#         return string with unknown specs
#      addFieldFormat
#         add a field format
#      tellFieldFormats
#         tell string with field formats
#      addFieldType
#         add a field type
#      tellFieldTypes
#         tell list of field types
#      addFieldHeading
#         add a field heading
#      tellFieldHeadings
#         tell list of field headings
#      setLineFormatter
#         set the line formatter
#      setLineFormatterByname
#         set the line formatter by name
#      tellLineFormatter
#         tell the line formatter
#      formatLine
#         format a line
#      formatFieldValueList
#	  format a list of field values
#      formatFieldValue
#	  format a field value
#      formatFieldHeadings
#         format field headings
#      formatFieldHeading
#         format field heading
#      processSummaryFieldValueList
#	  perform summary process on a list of field values
#      processSummaryFieldValue
#	  perform summary process on a field value
#      tellSummaryFieldValueList
#	  tell list of summary field values
#      tellSummaryFieldValue
#	  tell a summary field value
#      formatSummaryFieldValueList
#	  format a list of summary field values
#      formatSummaryFieldValue
#	  format a summary field value
#      timeStr
#	  convert time to 24 hour format
#      dateStr
#	  convert time to date format  mm/dd/yy
#      weekDay
#	  convert time to three letter week day
#      generalNumberFormatter
#         a general method for formatting numbers.  pretty useful for localizing
#	  when formatting numbers
#
#  s. luebking  phoenixL@aol.com

$VERSION = "1.13";

require "erg_line_formatter.pm";
require 5.000;

#
#------------------------------------------------------------------------------
#
#  BEGIN function
#

BEGIN
{
   $symbolCount = 0;
}


#
#------------------------------------------------------------------------------
#
#  END function
#

END
{
}


#
#------------------------------------------------------------------------------
#
#  new method
#
#  ARGS:
#
#     1  -  spec string
#	    each spec is format[|field[|heading]]
#	    (in this notation, the '|' means vertical bar.)
#
#	    the field and heading parts are optional.
#	    if a field is specified without a format, e.g. |name,
#	    the '*' format is assumed
#	    the heading can be a string surrounded by quotes.
#
#           known field formats:
#              \d+                     -   left justified
#              r\d* , \d*r             -   right justified (default width is 1)
#              c\d* , \d*c             -   centered (default width is 1)
#              b\d* , \d*b             -   field of blanks (default width is 1)
#					   (cannot be used with a field type)
#              *                       -   use entire field as is
#              " ... " , ' ... '       -   use string between quotes
#					   a count can immediately preceed
#					   the string
#					   (cannot be used with a field type)
#
#              (if a format has more than one version listed, all versions
#              of the format are equivalent.)
#
#              format specs can be separated by spaces, tabs or commas (,)
#
#  RETURNS:  new object

sub new
{
   my $this = shift;
   my $specStr = shift;

   my $class = ref($this) || $this;

   my $self = bless {}, $class;

   my $fieldListName;
   my $fieldHeadingListName;
   my @specList;

   $fieldListName = $self->uniqueSymbolName();
   $$self{'field-list-name'} = $fieldListName;

   $fieldHeadingListName = $self->uniqueSymbolName();
   $$self{'field-heading-list-name'} = $fieldHeadingListName;

   $$self{'error-specs'} = "";
   $$self{'line-formatter'} = undef;
   $$self{'field-formats'} = "";


#  get various specs out of spec string.  extract constants surrounded by quotes

   @specList = $self->scanSpecs($specStr);


#  get format info from spec list

   $self->buildFormat(@specList);

   return $self;
}


#
#------------------------------------------------------------------------------
#
#  method to scan specs from a string
#
#  ARGS:
#
#     1  -  spec string
#
#  RETURNS:  a list of strings containing specs
#
#  this scanner will handle strings starting with ' " OR `

sub scanSpecs
{
   my $self = shift;
   my $specStr = shift;

   my @returnList;
   my $tempStr;
   my $tempStr2; 


#  get various specs out of spec string.  extract constants surrounded by quotes

   @returnList = ();

   $tempStr = $specStr;
   $tempStr =~ s/^[\s,]*//;

   while(($tempStr =~ /^([^"'`]*[\s,]+)[^\s,"'`]*["'`]/)
          || ($tempStr =~ /^([\s,]*)[^\s,"'`]*["'`]/))
   {
      $tempStr2 = $1;
      $tempStr = substr($tempStr,length($tempStr2));

      $tempStr2 =~ s/[\s,]*$//;
      if($tempStr2 !~ /^[\s,]*$/)
      {
         push(@returnList,split(/[\s,]+/,$tempStr2));
      }

      if($tempStr =~ /^([^\s,"'`]*'[^']*')/)
      {
         $tempStr = substr($tempStr,length($1));
         push(@returnList,$1);
      }
      elsif($tempStr =~ /^([^\s,"'`]*"[^"]*")/)
      {
         $tempStr = substr($tempStr,length($1));
         push(@returnList,$1);
      }
      elsif($tempStr =~ /^([^\s,"'`]*`[^`]*`)/)
      {
         $tempStr = substr($tempStr,length($1));
         push(@returnList,$1);
      }
      else
      {
         push(@returnList,$tempStr);
	 $tempStr = "";
      }

      $tempStr =~ s/^[\s,]*//;
   }

   $tempStr =~ s/[\s,]*$//;

   if($tempStr !~ /^[\s,]*$/)
   {
      push(@returnList,split(/[\s,]+/,$tempStr));
   }

   return @returnList;
}


#
#------------------------------------------------------------------------------
#
#  method to build format from spec list
#
#  ARGS:
#
#     spec list
#
#  RETURNS:  none

sub buildFormat
{
   my $self = shift;

   my @returnList;
   my @specList;
   my $specReturn;

   @specList = @_;

   foreach $spec (@specList)
   {
      $specReturn = $self->specToFormat($spec);

      if( $specReturn eq "")
      {
         $$self{'error-specs'} .= "$spec ";
      }
   }
}


#
#------------------------------------------------------------------------------
#
#  method to convert a spec to format info
#
#  ARGS:
#
#     1  -  spec
#
#  RETURNS:  a boolean indicating if spec is known or not

sub specToFormat
{
   my $self = shift;
   my $spec = shift;

   my $returnBool;
   my @specInfo;

   $returnBool = "";

   if($spec =~ /^\d*['"`]/)
   {
      $self->addFieldFormat($spec);

      $returnBool = "t";
   }
   elsif($spec eq "*")
   {
   }
   elsif(($spec =~ /^(b\d*)[|]/i) || ($spec =~ /^(\d*b)[|]/i))
   {
      $self->addFieldFormat($1);

      $returnBool = "t";
   }
   else
   {
      @specInfo = split(/[|]/,$spec,3);

      if($#specInfo >= 0)
      {
         $self->addFieldFormat(($specInfo[0] =~ /^\s*$/) ? "*" : $specInfo[0]);
      }

      if($#specInfo >= 1)
      {
         $self->addFieldType($specInfo[1] . "::" . (($specInfo[0] =~ /^\s*$/) ? "*" : $specInfo[0]));

         if($#specInfo >= 2)
         {
            $self->addFieldHeading($specInfo[2]);
         }
	 else
	 {
            $self->addFieldHeading("");
	 }
      }

      $returnBool = "t";
   }


   return $returnBool;
}


#
#------------------------------------------------------------------------------
#
#  method to return string of unknown specs
#
#  ARGS:
#
#     none
#
#  RETURNS:  a string listing the unknown specified specs

sub tellUnknownSpecs
{
   my $self = shift;

   my $returnStr;

   $returnStr = $$self{'error-specs'};

   $returnStr =~ s/\s*$//;

   return $returnstr;
}


#
#------------------------------------------------------------------------------
#
#  method to add a field format to field format string
#
#  ARGS:
#
#     1  -  field format
#
#  RETURNS:  none

sub addFieldFormat
{
   my $self = shift;
   my $fieldFormat = shift;

   $$self{'field-formats'} .= " " . $fieldFormat;
}


#
#------------------------------------------------------------------------------
#
#  method to tell string with field formats
#
#  ARGS:
#
#     none
#
#  RETURNS:  a string of formats for line formatter

sub tellFieldFormats
{
   my $self = shift;

   my $returnStr;

   $returnStr = $$self{'field-formats'};

   return $returnStr;
}


#
#------------------------------------------------------------------------------
#
#  method to add a field type
#
#  ARGS:
#
#     1  -  field type
#
#  RETURNS:  none

sub addFieldType
{
   my $self = shift;
   my $fieldType = shift;

   my $fieldListName;

   $fieldListName = $$self{'field-list-name'};
   push(@$fieldListName,$fieldType);
}


#
#------------------------------------------------------------------------------
#
#  method to tell list of field types
#
#  ARGS:
#
#     none
#
#  RETURNS:  a list of strings containing the field types

sub tellFieldTypes
{
   my $self = shift;

   my $fieldListName;
   my $returnList;

   $fieldListName = $$self{'field-list-name'};
   @returnList = @$fieldListName;

   return @returnList;
}


#
#------------------------------------------------------------------------------
#
#  method to add a field heading
#
#  ARGS:
#
#     1  -  field heading
#
#  RETURNS:  none

sub addFieldHeading
{
   my $self = shift;
   my $fieldHeading = shift;

   my $fieldHeadingListName;
   my $fieldHeadingLen;

   if($fieldHeading =~ /^['"`]/)
   {
      $fieldHeadingLen = length($fieldHeading);

      if(substr($fieldHeading,0,1) eq substr($fieldHeading,($fieldHeadingLen-1)))
      {
         $fieldHeading = substr($fieldHeading,1,($fieldHeadingLen-2));
      }
      else
      {
         $fieldHeading =~ s/^['"`]//;
      }
   }

   $fieldHeadingListName = $$self{'field-heading-list-name'};
   push(@$fieldHeadingListName,$fieldHeading);
}


#
#------------------------------------------------------------------------------
#
#  method to tell list of field headings
#
#  ARGS:
#
#     none
#
#  RETURNS:  a list of strings containing field headings

sub tellFieldHeadings
{
   my $self = shift;

   my $fieldHeadingListName;
   my $returnList;

   $fieldHeadingListName = $$self{'field-heading-list-name'};
   @returnList = @$fieldHeadingListName;

   return @returnList;
}


#
#------------------------------------------------------------------------------
#
#  method to set the line formatter
#
#  ARGS:
#
#     1  -  line formatter
#
#  RETURNS:  the current line formatter

sub setLineFormatter
{
   my $self = shift;
   my $lineFormatter = shift;

   my $returnFormatter;

   $returnFormatter = $$self{'line-formatter'};
   $$self{'line-formatter'} = $lineFormatter;

   return $returnFormatter;
}


#
#------------------------------------------------------------------------------
#
#  method to set the line formatter by name
#
#  ARGS:
#
#     1  -  line formatter name
#
#  RETURNS:  the current line formatter

sub setLineFormatterByName
{
   my $self = shift;
   my $lineFormatterName = shift;

   my $returnFormatter;

   $returnFormatter = $self->setLineFormatter($lineFormatterName->new($self->tellFieldFormats()));

   return $returnFormatter;
}


#
#------------------------------------------------------------------------------
#
#  method to tell the line formatter
#
#  ARGS:
#
#     none
#
#  RETURNS:  the current line formatter
#
#  if no line formatter has been created yet, a new one is automatically
#  created

sub tellLineFormatter
{
   my $self = shift;

   my $returnFormatter;

   if( ! defined $$self{'line-formatter'})
   {
      $self->setLineFormatterByName("ERG::line_formatter");
   }

   $returnFormatter = $$self{'line-formatter'};

   return $returnFormatter;
}


#
#------------------------------------------------------------------------------
#
#  method to format a line
#
#  ARGS:
#
#     args to pass to line formater
#
#  RETURNS:  a string containing line created by formatting the args
#            passed to the function

sub formatLine
{
   my $self = shift;

   my $returnStr;
   my @strArgs;

   @strArgs = @_;

   $returnStr = $self->tellLineFormatter()->formatLine(@strArgs);

   return $returnStr;
}


#
#------------------------------------------------------------------------------
#
#  method to format field value list
#
#  ARGS:
#
#     1  -  field value
#     2  -  field value
#        .
#        .
#        .
#
#  RETURNS:  a list of strings containing formatted field values

sub formatFieldValueList
{
   my $self = shift;

   my @values;
   my @fieldTypes;
   my $maxEntry;
   my @returnList;

   @values = @_;
   @fieldTypes = $self->tellFieldTypes();

   @returnList = ();

   $maxEntry = (($#values <= $#fieldTypes) ? $#values : $#fieldTypes);


#  format each field value

   for($i=0; ($i <= $maxEntry); $i++)
   {
      push(@returnList,$self->formatFieldValue($fieldTypes[$i],$values[$i]));
   }

   for($i=($maxEntry+1); ($i <= $#fieldTypes); $i++)
   {
      push(@returnList,$self->formatFieldValue($fieldTypes[$i],undef));
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
#  RETURNS:  a string containing formatted field value

sub formatFieldValue
{
   my $self = shift;
   my $fieldType = shift;
   my $fieldValue = shift;

   my $returnStr;

   $returnStr = $fieldValue;

   return $returnStr;
}


#
#------------------------------------------------------------------------------
#
#  method to format field headings
#
#  ARGS:
#
#     1  -  type
#
#  RETURNS:  a string containing a line created by formatting field headings
#            of the type specified

sub formatFieldHeadings
{
   my $self = shift;
   my $type = shift;

   my $returnStr;
   my @formattedHeadings;

   @formattedHeadings = ();

   foreach $heading ($self->tellFieldHeadings())
   {
      push(@formattedHeadings,$self->formatFieldHeading($heading,$type));
   }

   $returnStr = $self->formatLine(@formattedHeadings);

   return $returnStr;
}


#
#------------------------------------------------------------------------------
#
#  method to format field heading
#
#  ARGS:
#
#     1  -  field heading
#     2  -  type
#
#  RETURNS:  a string with a formatted field heading of type specified

sub formatFieldHeading
{
   my $self = shift;
   my $fieldHeading = shift;
   my $type = shift;

   my $returnStr;

   $returnStr = $fieldHeading;

   return $returnStr;
}


#
#------------------------------------------------------------------------------
#
#  method to process summary field value list
#
#  ARGS:
#
#     1  -  report summary object
#     2  -  summary type
#     3  -  field value
#     4  -  field value
#        .
#        .
#        .
#
#  RETURNS:  none

sub processSummaryFieldValueList
{
   my $self = shift;
   my $reportSummary = shift;
   my $summaryType = shift;

   my @values;
   my @fieldTypes;
   my $maxEntry;

   @values = @_;
   @fieldTypes = $self->tellFieldTypes();

   $maxEntry = (($#values <= $#fieldTypes) ? $#values : $#fieldTypes);


#  process each field value

   for($i=0; ($i <= $maxEntry); $i++)
   {
      $self->processSummaryFieldValue($reportSummary,$summaryType,$fieldTypes[$i],$values[$i]);
   }

}


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

}


#
#------------------------------------------------------------------------------
#
#  method to tell summary field value list
#
#  ARGS:
#
#     1  -  report summary object
#     2  -  summary type
#
#  RETURNS:  returns a list of summary field values of type specified

sub tellSummaryFieldValueList
{
   my $self = shift;
   my $reportSummary = shift;
   my $summaryType = shift;

   my @returnList;

   @returnList = ();

#  tell each field value

   foreach $fieldType ($self->tellFieldTypes())
   {
      push(@returnList,$self->tellSummaryFieldValue($reportSummary,$summaryType,$fieldType));
   }

   return @returnList;
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
   my $fieldName;

   $returnValue = undef;

   return $returnValue;
}


#
#------------------------------------------------------------------------------
#
#  method to format summary field value list
#
#  ARGS:
#
#     1  -  summary type
#     2  -  summary field value
#     3  -  summary field value
#        .
#        .
#        .
#
#  RETURNS:  a list of strings containing formatted summary values

sub formatSummaryFieldValueList
{
   my $self = shift;
   my $summaryType = shift;

   my @values;
   my @fieldTypes;
   my $maxEntry;
   my @returnList;

   @values = @_;
   @fieldTypes = $self->tellFieldTypes();

   @returnList = ();

   $maxEntry = (($#values <= $#fieldTypes) ? $#values : $#fieldTypes);


#  format each field value

   for($i=0; ($i <= $maxEntry); $i++)
   {
      push(@returnList,$self->formatSummaryFieldValue($summaryType,$fieldTypes[$i],$values[$i]));
   }

   for($i=($maxEntry+1); ($i <= $#fieldTypes); $i++)
   {
      push(@returnList,$self->formatSummaryFieldValue($summaryType,$fieldTypes[$i],undef));
   }

   return @returnList;

}


#
#------------------------------------------------------------------------------
#
#  method to format summary field value
#
#  ARGS:
#
#     1  -  summary type
#     2  -  field type
#     3  -  field value  (can be undef if there was no summary value)
#
#  RETURNS:  a string containing formatted summary field value

sub formatSummaryFieldValue
{
   my $self = shift;
   my $summaryType = shift;
   my $fieldType = shift;
   my $fieldValue = shift;

   my $returnStr;

   $returnStr = "";

   if( defined $fieldValue)
   {
      $returnStr = $self->formatFieldValue($fieldType,$fieldValue);
   }

   return $returnStr;
}


#
#------------------------------------------------------------------------------
#
#  method to format a time str for a time
#
#  ARGS:
#
#     1  -  time
#
#  RETURNS:  a string with time in format hh:mm:ss

sub timeStr
{
   my $self = shift;
   my $time = shift;

   my $returnStr;
   my @timeInfo;


#  Time values:  ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)

   @timeInfo = localtime($time);


   $returnStr = (($timeInfo[2] <= 9) ? ("0" . $timeInfo[2]) : $timeInfo[2])
		  . ":" . (($timeInfo[1] <= 9) ? ("0" . $timeInfo[1]) : $timeInfo[1])
		  . ":" . (($timeInfo[0] <= 9) ? ("0" . $timeInfo[0]) : $timeInfo[0]) ;
   
#  ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)

   return $returnStr;
}


#
#------------------------------------------------------------------------------
#
#  method to format a date string for a time
#
#  ARGS:
#
#     1  - time
#
#  RETURNS:  a string with date specified as mm/dd/yy

sub dateStr
{
   my $self = shift;
   my $time = shift;

   my $returnStr;
   my @timeInfo;
   my $month;


#  Time values:  ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)

   @timeInfo = localtime($time);


   $month = $timeInfo[4]  + 1;

   $returnStr = (($month <= 9) ? ("0" . $month) : $month)
                  . "/" . (($timeInfo[3] <= 9) ? ("0" . $timeInfo[3]) : $timeInfo[3])
		  . "/" . (($timeInfo[5] <= 9) ? ("0" . $timeInfo[5]) : $timeInfo[5]);

   return $returnStr;
}


#
#------------------------------------------------------------------------------
#
#  method to format a week day for a time
#
#  ARGS:
#
#     1  -  time
#
#  RETURNS:  a string with day of the week consisting of three letters

sub weekDay
{
   my $self = shift;
   my $time = shift;

   my $returnStr;
   my @timeInfo;

   @timeInfo = localtime($time);
   $returnStr = ("Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat")[$timeInfo[6]];
   
#  ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)

   return $returnStr;
}


#
#------------------------------------------------------------------------------
#
#  method to format a number into form like  44,356.657
#
#  ARGS:
#
#     1  -  number
#     2  -  maximum length of a digit sub-sequence
#     3  -  separator between digit sub-sequences
#     4  -  decimal point character
#     5  -  number of decimal places
#
#  RETURNS:  a string with the formatted number
#
#  a negative number starts with '-'.  a fraction will have a '0'
#  before the decimal point.

sub generalNumberFormatter
{
   my $self = shift;
   my $number = shift;
   my $maxDigitSubSequence = shift;
   my $subSequenceSeparator = shift;
   my $decimalPointChar = shift;
   my $numberOfDecimalPlaces = shift;

   my $returnStr;
   my $tempNum;
   my $tempStr;
   my $fractionStr;

   $tempNum = (($number < 0) ? -$number : $number);
   $tempNum = int(($tempNum * (10 ** $numberOfDecimalPlaces)) + 0.5);



   if($numberOfDecimalPlaces <= 0)
   {
      $fractionStr = "";
   }
   else
   {
      $tempStr = ('0' x $numberOfDecimalPlaces ) . $tempNum;
      $fractionStr = $decimalPointChar
                    . substr($tempStr,(length($tempStr)-$numberOfDecimalPlaces),
   			    length($tempStr));
   }


   $tempNum = substr($tempNum,0,(length($tempNum)-$numberOfDecimalPlaces));

   $tempNum = (($tempNum eq "") ? "0" : $tempNum);

   $returnStr = "";

   $lastChar = length($tempNum);

   for(; ($lastChar > $maxDigitSubSequence); $lastChar -= $maxDigitSubSequence)
   {
      $returnStr = $subSequenceSeparator
		   . substr($tempNum,($lastChar-$maxDigitSubSequence),$lastChar)
		   . $returnStr;
   }

   $returnStr = substr($tempNum,0,$lastChar) . $returnStr;

   $returnStr = (($number < 0) ? "-" : "") . $returnStr . $fractionStr;

   return $returnStr;
}


#
#------------------------------------------------------------------------------
#
#  uniqueSymbolName method
#
#  returns a unique symbol name
#      
#  RETURNS:  a string with a new symbol name

sub uniqueSymbolName
{
   my $self = shift;

   my $returnName;

   $symbolCount++;

   $returnName = "ERG::report_generator_base::symbol_" . $symbolCount;

   return $returnName;
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
