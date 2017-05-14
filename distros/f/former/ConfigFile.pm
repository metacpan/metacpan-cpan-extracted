  
package ConfigFile;
  

# $Log: ConfigFile.pm,v $
# Revision 1.3  1996/02/15 17:45:49  hickey
# + added POD documentation.
#
# Revision 1.2  1996/02/14 14:58:51  hickey
# + Got rid of whitespace at the end of section headers and
#   definitions.
# + Added the _cleanup procedure
#
# Revision 1.1  1996/02/13 16:55:05  hickey
# Initial revision
#

$ConfigFile::rcsid = '$Id: ConfigFile.pm,v 1.3 1996/02/15 17:45:49 hickey Exp $';

=head1 NAME

ConfigFile.pm -- Perl module to read and write Windows-like config files

=head1 SYSNOPSIS

 use ConfigFile;
 $config = new ConfigFile "config_file_path";
 $val = $config->Parameter ($section, $parameter);
 $config->Parameter ($section, $parameter, $val);

=head1 DESCRIPTION

This module provides an easy and standard way for accessing configuration
files from Perl. Its structure is meant to be very simple and extendable. 
The module reads and writes configuration files that are simular to 
Microsoft Windows INI files. 

The Windows INI file format was chosen because of its simplicity, 
the ability to have multiple sections, and the wide spread use in many 
hundreds of applications. The file format consists of
three types of lines: section declarations, definitions, and comments. 

=item * Section declarations
Section declarations simply mark the start of another section in the
configuration file. It is easily recognizable because of the square
brackets ([]) that surround the section name. Any white space that
is placed on this line--before, inside, or after the square 
brackets--is ignored. Any white space within the section name is
squeezed down to a single space.

=item * Section definitions
Section definitions are the actual settings. The section definitions
consists of key and value pairs that are seperated by an equal
sign (=). Any white space that is before or after the key or value 
is ignored. White space in the key portion is left intact and is
squeezed down to one space. The value portion is treated the same
as a key unless it is surrounded by double quotes ("), in which
case the white space remains as is and the double quotes are 
removed from the value portion.

=item * Comments
Comments are totally ignored. Comment lines begin with either
a semicolon (;) or a pound sign (#). White space is allowed
before the semicolon and pound sign. A comment can not be on 
the same line as a section definition. 

=back

=head2 Configuration File Example

	; Mail configuration 

	[ Mail ]
	
	User = hickey
	Connection Type = imap

=head1 AUTHOR

Gerard Hickey
hickey@ctron.com

=cut

use Carp;
use strict;

sub new 
{
  my ($class, $file) = @_;
  my ($self);

  $self = { File 	=>  $file,
  	    Config	=>  &_readfile ($file)
	  };
	 
  bless $self, $class;
}

	       

sub Section
{
  my ($self, $sect) = @_;
  					       
  # looking to get a list of all sections
  return (keys %{$self->{Config}}) if (! $sect);
  
  return ($self->{Config}->{$sect});
}


sub CreateSection
{
  my ($self, $sect) = @_;
  
  $self->{Config}->{$sect} = {};
}


sub Parameter 
{
  my ($self, $sect, $param, $val) = @_;

  if (! ($sect && $param))  
    { croak "Section and parameter not specified to Parameter method." };
    
  if ($val)
    { $self->{Config}->{$sect}->{$param} = $val };
    
  $self->{Config}->{$sect}->{$param};
}


sub Write
{
  my ($self) = @_;
  my ($tmpfile) = "/tmp/.conf.$$";
  my ($sect);
  
  # prepare to write the configuration file  
  open (CONF, "< $self->{File}") || carp ("Can not read from configuration file: $self->{File}");
  open (TMP, "> $tmpfile") || carp ("Can not write to temporary configuration file: $tmpfile");
  
  while (<CONF>)
  { 
    # process a comment or blank line
    if (/^\s*[#;]/ || /^\s*$/)
    {  print TMP $_; next };
    		
    # Is this a section header?
    /^\s*\[\s*(.+)\s*\].*$/ && do
    {
      $sect = $1;
      print TMP $_;
      next;
    };
    
    # process definition
    /^\s*(.+)\s*=\s*(.+)\s*$/ && do
    {
      print TMP "$1 = $self->{Config}->{$sect}->{$1}\n";
      delete $self->{Config}->{$sect}->{$1};
    };
  };
    
  close (TMP);
  close (CONF);

  # backup the group file and copy the temp file into place
  system ("/bin/cp $tmpfile $self->{File}");
  unlink ($tmpfile);
  
};


sub Version 
{
  my ($self) = @_;
  
  $ConfigFile::rcsid;
}













sub _readfile
{ 
  my ($file) = @_;
  my ($config, $section, $term, $def);
  
  $config = {};

  open (CONFIG, "<$file") || carp "Can not open configuration file ($file)\n";
  while (<CONFIG>)
  { 			 
    chomp;		# get rid of newline
   
    # blank lines and comments			 
    next if (/^\s*$/o);
    next if (/^\s*[#;]/);
    	      
    # special note about next two regular expressions.
    #
    #  We want to extract the text without any whitespace at the end. 
    #  But we could have white space in the text (so \S+ does not work).
    #  The (.+\S) accepts any formation of characters that is terminated
    #  by any other character other than white space.
    #
    #  Works great--trust me....
    #
    
    # Section declaration
    /^\s*\[\s*(.+\S)\s*\]/ && do 
    { 
      $section = &_cleanup ($1); 
    };
     
    # Section description			   
    /^\s*(.+\S)\s*=\s*(.+\S)\s*$/ && do
    {
      $term = &_cleanup ($1);
      $def = &_cleanup ($2);
      
#      $def = 1 if ($def =~ /on|true/io);
      
      
      $config->{$section}->{$term} = $def;
    };
  
  };			      
  close (CONFIG);
   
  $config;
}


 
# 
# The _cleanup procedure takes an argument, and does some data
# santizing checks on the argument.
#

sub _cleanup
{
  my ($str) = @_;
  				     
  # If the string has quotes around it, do nothing other than remove the quotes.
  $str =~ /^"(.+)"$/o && return ($1);
  
  $str =~ s/\s/ /og;  		# make sure there are only spaces.
  $str =~ tr/ / /s;		# squeeze whitespace into one character.
  
  return ($str);
}
