package ERG::page_manager;

#  version:  1.13
#  date:     7/2/98

#  this package is a page manager class.
#
#  the page manager writes lines and handles page breaks.  optional
#  header and trailer lines are written at the top and bottom of
#  the pages.  (no header is printed on the first page.)
#
#  page break handling can be tailored by over-riding method pageBreak.
#  output can be sent somewhere other than STDOUT by over-riding
#  method writeLinesToFileWithCount.  the format of the page number
#  can be changed by over-riding the formatPageNumber method.

#  the package includes:
#
#      new
#	  creates page manager
#      close
#	  close method
#      setPageNumber
#         set the page number
#      tellPageNumber
#         tell the page number
#      formatPageNumber
#         formats the page number
#      setLineCount
#         set the line count
#      tellLineCount
#         tell the line count
#      tellMaxLineCount
#         tell the maximum line count
#      writeLines
#         write lines
#      pageBreak
#         handle page break
#      newPageCounts
#         handle counts for a new page
#      writePageHeader
#         write a header
#      writePageTrailer
#         write a trailer
#      writePageCountLine
#         write line with page count
#      writeLinesToFile
#         write lines to file
#      writeLinesToFileWithCount
#         write lines to file (number of lines is specified)
#      incrementLineCount
#         increment line count for lines being written to file
#
#  s. luebking   phoenixL@aol.com

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
#     1  -  maximum line count
#     2  -  header string
#	    (can be undef to be ignored)
#	    (if starts with 'count-format:', string will be used as
#	    a format to write a page count.  a format spec like '*' should
#	    be specified)
#     3  -  trailer string
#	    (can be undef to be ignored)
#	    (if starts with 'count-format:', string will be used as
#	    a format to write a page count.  a format spec like '*' should
#	    be specified)
#
#  RETURNS:  new object

sub new
{
   my $this = shift;
   my $maxLineCount = shift;
   my $headerStr = shift;
   my $trailerStr = shift;

   my $class = ref($this) || $this;

   my $self = bless {}, $class;

   my @lines;

   $$self{'max-line-count'} = $maxLineCount;
   $$self{'page-number'} = 1;
   $$self{'line-count'} = 0;


   if(! defined $headerStr)
   {
      $$self{'header-line'} = undef;
   }
   elsif($headerStr =~ /^(count[-]*format:*\s*)/i)
   {
      $$self{'header-line'} = ERG::line_formatter->new(substr($headStr,length($1)));
   }
   else
   {
      $$self{'header-line'} = $headerStr;
   }


   if(! defined $trailerStr)
   {
      $$self{'trailer-line'} = undef;
      $$self{'trailer-line-count'} = 0;
   }
   elsif($trailerStr =~ /^(count[-]*format:*\s*)/i)
   {
      $$self{'trailer-line'} = ERG::line_formatter->new(substr($trailerStr,length($1)));

      @lines = split(/\n/,$trailerStr);
      $$self{'trailer-line-count'} = $#lines + 1;
   }
   else
   {
      $$self{'trailer-line'} = $trailerStr;

      @lines = split(/\n/,$trailerStr);
      $$self{'trailer-line-count'} = $#lines + 1;
   }

   return $self;
}


#
#------------------------------------------------------------------------------
#
#  method to close
#
#  ARGS:
#
#     none
#
#  RETURNS:  none

sub close
{
   my $self = shift;

}


#
#------------------------------------------------------------------------------
#
#  method to set the page number
#
#  ARGS:
#
#     1  -  page number
#
#  RETURNS:  none

sub setPageNumber
{
   my $self = shift;
   my $pageNumber = shift;

   $$self{'page-number'} = $pageNumber;
}


#
#------------------------------------------------------------------------------
#
#  method to tell the page number
#
#  ARGS:
#
#     none
#
#  RETURNS:  current page number

sub tellPageNumber
{
   my $self = shift;

   my $returnStr;

   $returnStr = $$self{'page-number'};

   return $returnStr;
}


#
#------------------------------------------------------------------------------
#
#  method to format the page number
#
#  ARGS:
#
#     none
#
#  RETURNS:  formatted current page number

sub formatPageNumber
{
   my $self = shift;

   my $returnStr;

   $returnStr = $self->tellPageNumber();

   return $returnStr;
}


#
#------------------------------------------------------------------------------
#
#  method to set the current line count
#
#  ARGS:
#
#     1  -  line count
#
#  RETURNS:  none 

sub setLineCount
{
   my $self = shift;
   my $lineCount = shift;

   $$self{'line-count'} = $lineCount;
}


#
#------------------------------------------------------------------------------
#
#  method to tell the current line count
#
#  ARGS:
#
#     none
#
#  RETURNS:  current line count

sub tellLineCount
{
   my $self = shift;

   my $returnStr;

   $returnStr = $$self{'line-count'};

   return $returnStr;
}


#
#------------------------------------------------------------------------------
#
#  method to tell the maximum line count
#
#  ARGS:
#
#     none
#
#  RETURNS:  maximum line count

sub tellMaxLineCount
{
   my $self = shift;

   my $returnStr;

   $returnStr = $$self{'max-line-count'};

   return $returnStr;
}


#
#------------------------------------------------------------------------------
#
#  method to write lines
#
#  ARGS:
#
#     1  -  string with lines.  (a line-feed will be appended to the string)
#
#  RETURNS:  none

sub writeLines
{
   my $self = shift;
   my $lines = shift;

   my @lines;

   @lines = split(/\n/,$lines);

   if( ($self->tellLineCount() + $#lines + 1 + $$self{'trailer-line-count'})
   		> $self->tellMaxLineCount())
   {
      $self->pageBreak();
   }

   $self->writeLinesToFileWithCount($lines,($#lines+1));
}


#
#------------------------------------------------------------------------------
#
#  method to handle page break
#
#  ARGS:
#
#     none
#
#  RETURNS:  none

sub pageBreak
{
   my $self = shift;

   $self->writePageTrailer();

   $self->newPageCounts();

   $self->writePageHeader();
}


#
#------------------------------------------------------------------------------
#
#  method to handle new page counts
#
#  ARGS:
#
#     none
#
#  RETURNS:  none

sub newPageCounts
{
   my $self = shift;

   $self->setPageNumber($self->tellPageNumber() + 1);
   $self->setLineCount(0);
}


#
#------------------------------------------------------------------------------
#
#  method to write header
#
#  ARGS:
#
#     none
#
#  RETURNS:  none

sub writePageHeader
{
   my $self = shift;

   if(! defined $$self{'header-line'})
   {
   }
   elsif(ref($$self{'header-line'}))
   {
      $self->writePageCountLine($$self{'header-line'});
   }
   else
   {
      $self->writeLinesToFile($$self{'header-line'});
   }
}


#
#------------------------------------------------------------------------------
#
#  method to write trailer
#
#  ARGS:
#
#     none
#
#  RETURNS:  none

sub writePageTrailer
{
   my $self = shift;

   if(! defined $$self{'trailer-line'})
   {
   }
   elsif(ref($$self{'trailer-line'}))
   {
      $self->writePageCountLine($$self{'trailer-line'});
   }
   else
   {
      $self->writeLinesToFile($$self{'trailer-line'});
   }
}


#
#------------------------------------------------------------------------------
#
#  method to write page count line
#
#  ARGS:
#
#     1  -  formatter for page count line
#
#  RETURNS:  none

sub writePageCountLine
{
   my $self = shift;
   my $pageCountLineFormatter = shift;

   if(defined $pageCountLineFormatter)
   {
      $self->writeLinesToFile($pageCountLineFormatter->formatLine($self->formatPageNumber()));
   }
}


#
#------------------------------------------------------------------------------
#
#  method to write lines to file
#
#  ARGS:
#
#     1  -  string with lines.
#
#  RETURNS:  none

sub writeLinesToFile
{
   my $self = shift;
   my $lines = shift;
   my $lineCount = shift;

   my @lines;

   @lines = split(/\n/,$lines);

   $self->writeLinesToFileWithCount($lines,($#lines+1));
}


#
#------------------------------------------------------------------------------
#
#  method to write lines to file
#
#  ARGS:
#
#     1  -  string with lines.
#     2  -  number of lines
#
#  RETURNS:  none
#
#  a line feed is automatically added

sub writeLinesToFileWithCount
{
   my $self = shift;
   my $lines = shift;
   my $lineCount = shift;

   print $lines . "\n";
   $self->incrementLineCount($lineCount);
}


#
#------------------------------------------------------------------------------
#
#  method to increment line count
#
#  ARGS:
#
#     1  -  line count
#
#  RETURNS:  none

sub incrementLineCount
{
   my $self = shift;
   my $lineCount = shift;

   $self->setLineCount($self->tellLineCount() + $lineCount);
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
