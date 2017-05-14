package ERG::line_formatter;

#  version:  1.13
#  date:     7/2/98

#  this package is a line formatter class.
#
#  a line formatter is created with a string specifying a format.
#  the line formatter creates a line by formatting a list of values
#  according to the format specified.
#
#  the types of specs the line formatter will handle can be expanded
#  by over-riding the specToCode and processCode methods.  (if the
#  specToCode method is over-ridden, remember that the the scanner
#  only scans specs of the form s1's2' where s1 is a string with
#  no white-space or commas or quotes and s2 is any string.  (The quote
#  can be ', " or ` .)  s1 and s2 are both optional.  however, if s2
#  is specified, it must be surrounded by quotes.)

#  the package includes:
#
#      new
#	  creates line formatter
#      scanSpecs
#         scan a string for specs
#      buildCodeList
#         build a code list from list of specs
#      specToCode
#         convert a spec to a code
#      tellUnknownFormats
#         return string with unknown specs
#      formatLine
#         format a line using code list and string arguements
#      getCodeList
#          get a code list
#      processCode
#          process a code
#
#  s. luebking  phoenixL@aol.com


$VERSION = "1.13";

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
#     1  -  format string
#           known formats:
#              \d+                     -   left justified
#              r\d* , \d*r             -   right justified (default width is 1)
#              c\d* , \d*c             -   centered (default width is 1)
#              b\d* , \d*b             -   field of blanks (default width is 1)
#              *                       -   use entire arguement as is
#              -                       -   skip arguement
#              " ... " , ' ... '       -   use string between quotes
#					   a count can immediately preceed
#					   the string
#
#              (if a format has more than one version listed, all versions
#              of the format are equivalent.)
#
#              format specs can be separated by spaces, tabs, commas (,) ,
#	       or vertical bars (|)
#
#  RETURNS:  new object

sub new
{
   my $this = shift;
   my $formatStr = shift;

   my $class = ref($this) || $this;

   my $self = bless {}, $class;

   my $codeListName;
   my @specList;

   $codeListName = $self->uniqueSymbolName();
   $$self{'code-list-name'} = $codeListName;
   $$self{'error-formats'} = "";
   $$self{'linefeed-count'} = 0;


#  get various specs out of spec string.  extract constants surrounded by quotes

   @specList = $self->scanSpecs($formatStr);


#  build code list from spec list

   @$codeListName = $self->buildCodeList(@specList);

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
#  RETURNS:  a list of strings with specs
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
   $tempStr =~ s/^[\s,|]*//;

   while(($tempStr =~ /^([^"'`]*[\s,|]+)[^\s,|"'`]*["'`]/)
          || ($tempStr =~ /^([\s,|]*)[^\s,|"'`]*["'`]/))
   {
      $tempStr2 = $1;
      $tempStr = substr($tempStr,length($tempStr2));

      $tempStr2 =~ s/[\s,|]*$//;
      if($tempStr2 !~ /^[\s,|]*$/)
      {
         push(@returnList,split(/[\s,|]+/,$tempStr2));
      }

      if($tempStr =~ /^([^\s,|"'`]*'[^']*')/)
      {
         $tempStr = substr($tempStr,length($1));
         push(@returnList,$1);
      }
      elsif($tempStr =~ /^([^\s,|"'`]*"[^"]*")/)
      {
         $tempStr = substr($tempStr,length($1));
         push(@returnList,$1);
      }
      elsif($tempStr =~ /^([^\s,|"'`]*`[^`]*`)/)
      {
         $tempStr = substr($tempStr,length($1));
         push(@returnList,$1);
      }
      else
      {
         push(@returnList,$tempStr);
	 $tempStr = "";
      }

      $tempStr =~ s/^[\s,|]*//;
   }

   $tempStr =~ s/[\s,|]*$//;

   if($tempStr !~ /^[\s,|]*$/)
   {
      push(@returnList,split(/[\s,|]+/,$tempStr));
   }

   return @returnList;
}


#
#------------------------------------------------------------------------------
#
#  method to build code list from spec list
#
#  ARGS:
#
#     spec list
#
#  RETURNS:  a list of strings containing codes

sub buildCodeList
{
   my $self = shift;

   my @returnList;
   my @specList;
   my $code;

   @returnList = ();

   @specList = @_;

   foreach $spec (@specList)
   {
      $code = $self->specToCode($spec);

      if( ! defined $code)
      {
         $$self{'error-formats'} .= "$spec ";
      }
      elsif($code ne "")
      {
         push(@returnList,$code);
      }
   }

   return @returnList;
}


#
#------------------------------------------------------------------------------
#
#  method to convert a spec to a code
#
#  ARGS:
#
#     1  -  spec
#
#  RETURNS:  a string with code, a null string or 'undef' if spec is unknown

sub specToCode
{
   my $self = shift;
   my $spec = shift;

   my $returnCode;
   my $string;
   my $count;
   my $stringLen;

   $returnCode = undef;

   if($spec eq "*")
   {
      $returnCode = "full-string";
   }
   elsif($spec eq "-")
   {
      $returnCode = "skip";
   }
   elsif($spec =~ /^(\d+)$/)
   {
      $width = (($1 <= 0) ? 1 : $1);
      $returnCode = "left:$width";
   }
   elsif($spec =~ /^r(\d*)$/i)
   {
      $width = (($1 eq "") ? 1 : $1);
      $width = (($width <= 0) ? 1 : $width);

      $returnCode = "right:$width";
   }
   elsif($spec =~ /^(\d*)r$/i)
   {
      $width = (($1 eq "") ? 1 : $1);
      $width = (($width <= 0) ? 1 : $width);

      $returnCode = "right:$width";
   }
   elsif($spec =~ /^c(\d*)$/i)
   {
      $width = (($1 eq "") ? 1 : $1);
      $width = (($width <= 0) ? 1 : $width);

      $returnCode = "center:$width";
   }
   elsif($spec =~ /^(\d*)c$/i)
   {
      $width = (($1 eq "") ? 1 : $1);
      $width = (($width <= 0) ? 1 : $width);

      $returnCode = "center:$width";
   }
   elsif($spec =~ /^b(\d*)$/i)
   {
      $width = (($1 eq "") ? 1 : $1);
      $width = (($width <= 0) ? 1 : $width);

      $returnCode = "blanks:$width";
   }
   elsif($spec =~ /^(\d*)b$/i)
   {
      $width = (($1 eq "") ? 1 : $1);
      $width = (($width <= 0) ? 1 : $width);

      $returnCode = "blanks:$width";
   }
   elsif($spec =~ /^(\d*)["'`]/)
   {
      $string = substr($spec,length($1));
      $count = (($1 eq "") ? 1 : $1);


      if($count <= 0)
      {
         $returnCode = "";
      }
      else
      {
	 $stringLen = length($string);

         if(substr($string,0,1) eq substr($string,($stringLen-1)))
         {
            $returnCode = "string:${count}:" . substr($string,1,($stringLen-2));
         }
         else
         {
            $returnCode = "string:${count}:" . substr($string,1);
         }
      }
   }

   return $returnCode;
}


#
#------------------------------------------------------------------------------
#
#  method to return string of unknown formats
#
#  ARGS:
#
#     none
#
#  RETURNS:  a string containing unknown formats specified

sub tellUnknownFormats
{
   my $self = shift;

   my $returnStr;

   $returnStr = $$self{'error-formats'};

   $returnStr =~ s/\s*$//;

   return $returnstr;
}


#
#------------------------------------------------------------------------------
#
#  method to format line
#
#  ARGS:
#
#     1  -  arg string 1
#     2  -  arg string 2
#     3  -  arg string 3
#        .
#        .
#        .
#
#  RETURNS:  a string containing formatted line

sub formatLine
{
   my $self = shift;

   my $returnStr;
   my $argStr;
   my @strings;
   my $argCount;
   my $formatStr;
   my $argStrBool;
   my @codeList;

   @strings = @_;


#  build return string by processing the codes.  if more codes than string
#  arguements, null strings are used

   $returnStr = "";

   $argCount = 0;
   @codeList = $self->getCodeList(@strings);

   foreach $code (@codeList )
   {
      $argStr = (($argCount <= $#strings) ? $strings[$argCount] : "");

      ($formatStr,$argStrBool) = $self->processCode($code,$argStr);

      $returnStr .= $formatStr;

      if($argStrBool ne "")
      {
         $argCount++;
      }

   }

   return $returnStr;
}


#
#------------------------------------------------------------------------------
#
#  method to get list of codes
#
#  ARGS:
#
#     arg list for formatLine
#
#  RETURNS:  a list of strings containing codes

sub getCodeList
{
   my $self = shift;

   my @returnCodes;
   my $codeListName;

   $codeListName = $$self{'code-list-name'};
   @returnCodes = @$codeListName;

   return @returnCodes;
}


#
#------------------------------------------------------------------------------
#
#  method to process a code
#
#  ARGS:
#
#     1  -  code
#     2  -  arg string
#
#  RETURNS:  a list of two values.  first value is string with formatted output.
#            the second value is a boolean indicating if the arguement string
#            was used or not

sub processCode
{
   my $self = shift;
   my $code = shift;
   my $argStr = shift;

   my $returnStr;
   my $returnBool;
   my $width;
   my $tempStr;

   $returnStr = "";
   $returnBool = "t";

   if($code eq "full-string")
   {
      $returnStr = $argStr;
   }
   elsif($code =~ /^blanks:(.*)/)
   {
      $returnStr = " " x $1;

      $returnBool = "";
   }
   elsif($code =~ /^left:(.*)/)
   {
      $returnStr = substr(($argStr . (" " x $1)), 0, ($1-1));
   }
   elsif($code =~ /^right:(.*)/)
   {
      $returnStr = substr(((" " x $1) . $argStr), length($argStr), (length($argStr) + $1-1));
   }
   elsif($code =~ /^center:(.*)/)
   {
      $width = $1;
      $tempStr = "";

      if((length($argStr)+1) < $width)
      {
         $tempStr .= (" " x int(($width - length($argStr))/2));
      }

      $tempStr .= $argStr;
      $returnStr = substr(($tempStr . (" " x $width)), 0, ($width-1));
   }
   elsif($code =~ /^string:(\d)+:/)
   {
      $returnStr = substr($code,length("string:$1:")) x $1;

      $returnBool = "";
   }
   elsif($code eq "no-op")
   {
      $returnBool = "";
   }
   elsif($code eq "skip")
   {
   }

   return ($returnStr, $returnBool);
}


#
#------------------------------------------------------------------------------
#
#  uniqueSymbolName method
#
#  ARGS:
#
#     none
#      
#  RETURNS:  a string with a new symbol name

sub uniqueSymbolName
{
   my $self = shift;

   my $returnName;

   $symbolCount++;

   $returnName = "ERG::line_formatter::symbol_" . $symbolCount;

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
