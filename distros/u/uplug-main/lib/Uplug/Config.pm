#-*-perl-*-
#####################################################################
#
# $Author$
# $Id$
#
#---------------------------------------------------------------------------
# Copyright (C) 2004 Jörg Tiedemann  <joerg@stp.ling.uu.se>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
#---------------------------------------------------------------------------

=head1 NAME

Uplug::Config - process Uplug configuration files

=head1 SYNOPSIS

 # name of a Uplug module
 $module = 'pre/basic';

 # find the local file for a given module
 $file = FindConfig( $module );
 # read the configuration of a given module
 $config = ReadConfig( $module );
 # write a config hash to a file
 WriteConfig( 'newfile.txt', $config );

 # print information about a specific module
 PrintConfigInfo( $module );
 # list all available modules
 ListAvailableModules();
 # list all available modules within a certain sub category
 ListAvailableModules( 'pre' );

 # find a program (look into various possible dir's)
 $program = find_executable( $program_name );

 # Uplug-specific directories
 $dir = shared_home;           # home of all shared files
 $dir = shared_bin;            # home of distributed binaries
 $dir = shared_systems;        # home of Uplug module configurations

=head1 DESCRIPTION

This module handles Uplug configuration files. Configuration files are usually stored in the global shared folder 'system' for the Uplug libraries. Local files with relative paths and absolute paths are also accepted. Configuration files need to conform the norms of the Uplug libraries and use a perlish format (complex hashs dumped to file using L<Data::Dumper>).

When reading configuration files, certain variables are expanded (see below in C<ExpandVar>).

=head2 The Structure of Uplug configuration files

A Uplug module is specified by its configuration file. A config file is basically a perlish data structure representing a reference to a hash. A typical module configuration looks like this:

 {

  ##--------------------------------------------------------
  ## module describes the actual program to be executed
  ## - stdin/stdin specifies which data stream will be used
  ##   to read from / write to STDIN/STDOUT
  ##--------------------------------------------------------

  'module' => {
    'name' => 'module name',
    'program' => 'executable',
    'location' => '/path/to/bin/dir',
    'stdin' => 'input stream name',
    'stdout' => 'output stream name',
  },

  ##--------------------------------------------------------
  ## description can be any string describing the module
  ##--------------------------------------------------------

  'description' => 'description of the module',

  ##--------------------------------------------------------
  ## 'input' can be any number of named data streams
  ## to read from
  ##--------------------------------------------------------

  'input' => {
     'input stream name' => {
        'format' => 'input format',
     },
   },

  ##--------------------------------------------------------
  ## 'output' can be any number of named data streams
  ## to write to, 'write_mode' = 'overwrite' forces Uplug
  ## to overwrite existing files (default = do not do that)
  ##--------------------------------------------------------

  'output' => {
     'output stream name' => {
        'format' => 'output format',
        'write_mode' => 'overwrite'
     }
  },

  ##--------------------------------------------------------
  ## 'parameter' may contain any kind of parameter
  ## (even in deep, nested structures)
  ##--------------------------------------------------------

  'parameter' => {
     'name' => {
        'key' => value,
        ...
     }
  },

  ##--------------------------------------------------------
  ## 'arguments' can be used to describe command-line arg's
  ## using the key-value pairs in 'shortcuts':
  ## - the key is the flag to be used (with additional '-')
  ## - the value describes the path to the key to be set
  ##   with the command line argument (separated by ':')
  ##   example: 'f' => 'input:text:format' is used to enable
  ##            the command line flag '-f format' which sets
  ##            the format key in config->input->text
  ##--------------------------------------------------------

  'arguments' => {
    'shortcuts' => {
       'command-line-flag1' => 'parameter:name:key',
       'command-line-flag2' => 'input:input stream name:format',
       ...
    }
  }
 }


Config files may include the following variables to refer to standard locations within the Uplug toolbox. They will be expanded when reading the configuration before executing the commands.

 $UplugHome ..... environment ($UPLUGHOME) or /path/to/uplug
 $UplugSystem ... environment ($UPLUGCONFIG) or /UPLUGSHARE/systems
 $UplugBin ...... /path/to/uplug/bin
 $UplugIni ...... /UPLUGSHARE/ini
 $UplugLang ..... /UPLUGSHARE/lang
 $UplugData ..... data

C</UPLUGSHARE/> is the path to the global shared directory (if Uplug is installed properly) or the path to the local directory C<share> in your local copy of Uplug (if you don't use the makefile to install Uplug globally). See further down for more information on environment variables and default locations in Uplug.

Uplug modules may also point to a sequence of sub-modules. Add the following structures to the config-hash within the 'module' structure:


 {
  'module' => {
    'name' => 'module name',

    ##--------------------------------------------------------
    ## submodules are lists of Uplug config files
    ## (make sure that they exist and that Uplug can find them)
    ## - submodule names can be used to describe them
    ## - do not specify programs at the same time!
    ##--------------------------------------------------------

    'submodules' => [
        'config1',
        'config2',
        ...
    ],
    'submodule names' => [
        'name of sub-module 1 (config1)',
        'name of sub-module 2 (config2)',
        ...
    ],

    ##--------------------------------------------------------
    ## You can define loops over sub-sequences of sub-modules
    ## You can only define one loop per config file!
    ## The example below defines a loop over 
    ## sub-module 1 and 2 which will be run 3 times
    ## (start counting with 1)
    ##--------------------------------------------------------

    'loop' => '1:2',
    'iterations' => '4'
  }
 }

Look at the pre-defined configuration files to see more examples of possible configuration structures.

=cut


package Uplug::Config;

require 5.004;

use strict;
use vars qw(@ISA @EXPORT);
use vars qw(%NamedIO);

use FindBin qw/$Bin $Script/;
# use File::ShareDir qw/dist_dir/;
use Exporter qw/import/;
use Data::Dumper;

our @EXPORT   = qw/FindConfig ReadConfig WriteConfig 
                   PrintConfigInfo
                   ListAvailableModules
                   CheckParameter GetNamedIO
	           CheckParam GetParam SetParam
                   find_executable 
                      shared_home 
                      shared_bin 
                      shared_ini 
                      shared_lib 
                      shared_lang
                      shared_systems/;

=head1 Public variables

 $SHARED_HOME  # home of shared files       (get with C<shared_home>)
 $SHARED_BIN   # home of binary files       (get with C<shared_bin>)
 $SHARED_SYS   # home of config-files       (get with C<shared_system>)
 $SHARED_INI   # global configuration       (get with C<shared_ini>)
 $SHARED_LANG  # language-specific files    (get with C<shared_lang>)
 $SHARED_LIB   # home of external libraries (get with C<shared_lib>)

 $OS_TYPE      # type of operating system     (uname -s)
 $MACHINE_TYPE # type of machine architecture (uname -m)

C<$SHARED_HOME> is the global directory of shared files for Uplug (if properly installed) or the directory set in the environment variable UPLUGSHARE. 

If you start a local copy of C<uplug> (not the globally installed one): Uplug tries to find local directories of shared files ('share') relative to the location of the startup script (C</path/to/script/share> or C</path/to/script/../share>) or relative to the environment variable UPLUGHOME (if set). Note that the environment variable UPLUGSHARE overwrites these settings again.

=cut

# try to find the shared files for Uplug
# - the global Uplug shared files dir
# - overwrite with UPLUGSHARE (if set in environment)
# - take local Uplug 'share' folders if we start a local copy of uplug

## local shared folder

my $SHARED_LOCAL_HOME;
$SHARED_LOCAL_HOME = $Bin.'/../share' if (-d  $Bin.'/../share');
$SHARED_LOCAL_HOME = $Bin.'/share'    if (-d  $Bin.'/share');

## global shared folder

my $SHARED_HOME;
eval{ 
    require File::ShareDir; 
    $SHARED_HOME = File::ShareDir::dist_dir('Uplug'); 
};
unless (-d $SHARED_HOME){
    if ((defined $ENV{UPLUGHOME}) && (-d $ENV{UPLUGHOME}.'/share')){
	$SHARED_HOME = $ENV{UPLUGHOME}.'/share';
    }
}
if ((defined $ENV{UPLUGSHARE}) && (-d $ENV{UPLUGSHARE})){
    $SHARED_HOME = $ENV{UPLUGSHARE};
}
$SHARED_HOME = $SHARED_LOCAL_HOME unless (-d $SHARED_HOME);



## other global locations

our $SHARED_BIN  = $SHARED_HOME . '/bin';
our $SHARED_INI  = $SHARED_HOME . '/ini';
our $SHARED_LANG = $SHARED_HOME . '/lang';
our $SHARED_LIB  = $SHARED_HOME . '/lib';
our $SHARED_SYS  = $SHARED_HOME . '/systems';

our $OS_TYPE      = $ENV{OS_TYPE} || `uname -s`;
our $MACHINE_TYPE = $ENV{MACHINE_TYPE} || `uname -m`;

chomp($OS_TYPE);
chomp($MACHINE_TYPE);


## local files

my $SHARED_LOCAL_BIN  = $SHARED_LOCAL_HOME . '/bin';
my $SHARED_LOCAL_INI  = $SHARED_LOCAL_HOME . '/ini';
my $SHARED_LOCAL_LANG = $SHARED_LOCAL_HOME . '/lang';
my $SHARED_LOCAL_LIB  = $SHARED_LOCAL_HOME . '/lib';
my $SHARED_LOCAL_SYS  = $SHARED_LOCAL_HOME . '/systems';


=head1 Pre-defined data streams

There are two configuration files that contain information about pre-defined data streams. They are expected to be in C<$SHARED_INI>. These two files are read by default:

 DataStreams.ini
 UserDataStreams.ini

=cut

## "named" IO streams are stored in %NamedIO
## read them from the files below (in ENV{UPLUGHOME}/ini)

&ReadNamed('DataStreams.ini');          # default "IO streams"
&ReadNamed('UserDataStreams.ini');      # user "IO streams"



sub shared_home   { return defined($_[0]) ? $SHARED_HOME = $_[0] : $SHARED_HOME; }
sub shared_bin    { return defined($_[0]) ? $SHARED_BIN = $_[0] : $SHARED_BIN; }
sub shared_ini    { return defined($_[0]) ? $SHARED_INI = $_[0] : $SHARED_INI; }
sub shared_lang   { return defined($_[0]) ? $SHARED_LANG = $_[0] : $SHARED_LANG; }
sub shared_lib    { return defined($_[0]) ? $SHARED_LIB = $_[0] : $SHARED_LIB; }
sub shared_systems{ return defined($_[0]) ? $SHARED_SYS = $_[0] : $SHARED_SYS; }

=head1 Functions

=head2 C<find_executable>

 $program_name = 'GIZA++';
 $program = find_executable( $program_name );

Tries to find the executable program on your local system. It first looks in your global path. Thereafter, it checks the shared home of binaries bundled in this package. It uses C<$OS_TYPE> and C<$MACHINE_TYPE> to identify the appropriate binary.

=cut


sub find_executable{
  my $name = shift;

  # try to find in the path

  my $path = `which $name`;
  chomp($path);
  return $path if (-e $path);

  # try to find it in the shared tools dir (local and global)

  return join('/',$SHARED_LOCAL_BIN,$OS_TYPE,$MACHINE_TYPE,$name) 
      if (-e join('/',$SHARED_LOCAL_BIN,$OS_TYPE,$MACHINE_TYPE,$name) );
  return join('/',$SHARED_LOCAL_BIN,$OS_TYPE,$name) 
      if (-e join('/',$SHARED_LOCAL_BIN,$OS_TYPE,$name) );
  return $SHARED_LOCAL_BIN.'/'.$name if (-e $SHARED_LOCAL_BIN.'/'.$name);

  return join('/',$SHARED_BIN,$OS_TYPE,$MACHINE_TYPE,$name) 
      if (-e join('/',$SHARED_BIN,$OS_TYPE,$MACHINE_TYPE,$name) );
  return join('/',$SHARED_BIN,$OS_TYPE,$name) 
      if (-e join('/',$SHARED_BIN,$OS_TYPE,$name) );
  return $SHARED_BIN.'/'.$name if (-e $SHARED_BIN.'/'.$name);

  # try to find it

  $path = `find -name '$name' $SHARED_BIN`;
  chomp($path);
  return $path if (-x $path);

  return $name;
}

=head2 C<CheckParameter>

 CheckParameter ( $config, $param, $module );

Reads configuration for a given module, merges this with the (default) configuration hash in $config and sets additional parameters given in C<$param>. The global configuration of C<$module> overwrites the default configuration of C<$config> and parameters in C<param> overwrite this merged configuration.

C<$param> can be a reference to an array (actually containing key-value pairs) or a string of space-separated key-value pairs. These are usually the command-line arguments given when starting a specific module using the Uplug startup scripts. This means that command-line short-cuts as specified in the configuration file will be expanded to set the appropriate key in the deep data structure of the config-hash. (see also C<CheckParam>)

=cut

#------------------------------------------------------------------------
# CheckParameter($config,$param,$file)
#   * config .... pointer to hash with default config
#   * param ..... command-line parameters (usually a pointer ot an ARRAY)
#   * file ...... config-file (replaces default config options)

sub CheckParameter{
    my ($config,$param,$file)=@_;

    if (ref($config) ne 'HASH'){$config={};}
    my @arg;
    if (ref($param) eq 'ARRAY'){@arg=@$param;}
    elsif($param=~/\S\s\S/){@arg=split(/\s+/,$param);}

    if (-e $file){
	my $new=&ReadConfig($file);
	$config=&MergeConfig($config,$new);
    }
    for (0..$#arg){                            # special treatment for the
	if ($arg[$_] eq '-i'){                 # -i argument --> config file
	    my $new=&ReadConfig($arg[$_+1]);
	    $config=&MergeConfig($config,$new);
	}
    }
    &CheckParam($config,@arg);

    return $config;
}


# $config = MergeConfig($config1,$config2)
#    copy all keys from $config2 to $config1 and return $config1

sub MergeConfig{
    my ($conf1,$conf2)=@_;
    if (ref($conf1) ne 'HASH'){return $conf1;}
    if (ref($conf2) ne 'HASH'){return $conf1;}
    for (keys %{$conf2}){
	$conf1->{$_}=$conf2->{$_};
    }
    return $conf1;
}

=head2 C<FindConfig>

 $file = FindConfig( $module );

Look for the physical configuration file for a given module. This function checks C<$SHARED_SYS>, C<$SHARED_INI>, C<$UPLUGHOME>, C<$UPLUGHOME/systems> and C<$UPLUGHOME/ini> in that order.

=cut

sub FindConfig{
    my $file=shift;

    return $file if (-f $file);

    ## take local files first

    if (-f "$SHARED_LOCAL_SYS/$file"){
	return "$SHARED_LOCAL_SYS/$file";
    }
    elsif (-f "$SHARED_LOCAL_INI/$file"){
	return "$SHARED_LOCAL_INI/$file";
    }

    ## look for global files

    if (-f "$SHARED_SYS/$file"){
	return "$SHARED_SYS/$file";
    }
    elsif (-f "$SHARED_INI/$file"){
	return "$SHARED_INI/$file";
    }
    elsif ((defined $ENV{UPLUGHOME}) && 
	   (-f "$ENV{UPLUGHOME}/$file")){
	return "$ENV{UPLUGHOME}/$file";
    }
    elsif ((defined $ENV{UPLUGHOME}) && 
	   (-f "$ENV{UPLUGHOME}/systems/$file")){
	return "$ENV{UPLUGHOME}/systems/$file";
    }
    elsif ((defined $ENV{UPLUGHOME}) && 
	   (-f "$ENV{UPLUGHOME}/ini/$file")){
	return "$ENV{UPLUGHOME}/ini/$file";
    }

    print STDERR "cannot find file '$file'!\n";
    return $file;
}


=head2 C<ReadConfig>

 $config = ReadConfig( $module, @params );

Read the configuration of a given module, expand 'named data streams' (the ones defined in C<DataStreams.ini> and C<UserDataStreams.ini>) and Uplug variables (see below) and set parameters specified in C<@{params}>.

=cut

#------------------------------------------------------------------------
# read configuration files
#    - essentially this restores a Perl hash from a hash dump
#    - some variables are expanded before restoring (see ExpandVar)
#    - "named" IO streams are replaced with their expanded specifications
#    - command line arguments are expanded and set in the config hash 


sub ReadConfig{
    my $file=shift;
    my @param=@_;

    $file = FindConfig($file);
    warn "# Uplug::Config: config file '$file' not found!\n"
	unless (-f $file);

    open F,"<$file" || die "# Uplug::Config: cannot open file '$file'!\n";
    my @lines=<F>;
    my $text=join '',@lines;
    close F;
    $text=&ExpandVar($text);
    my $config=eval $text;
    &ExpandNamed($config);
    &CheckParam($config,@param);
    return $config;
}

=head2 C<WriteConfig>

 WriteConfig( $file, $config )

Dump the configuration hash in C<$config> to file C<$file>.

=cut

#------------------------------------------------------------------------
# write configuration file
#    dump a perl hash into a text file (nothing else)

sub WriteConfig{
    my $file=shift;
    my $config=shift;

    if ($file){
	open F,">$file" || die "# Config: cannot open '$file'!\n";
    }

    $Data::Dumper::Indent=1;
    $Data::Dumper::Terse=1;
    $Data::Dumper::Purity=1;
    if ($file){
	print F Dumper($config);
	close F;
    }
    else{
	print Dumper($config);    # stdout if no file is given
    }
}

=head2 C<ExpandVar>

 ExpandVar( $config_string );

Expand Uplug variables in a given configuration string.

 $UplugHome   - Uplug home directory
 $UplugLang   - default directory for language specific data
 $UplugSystem - default directory for module configuration files
 $UplugData   - default directory for data files (= ./data)
 $UplugIni    - default directory for initalization files
 $UplugBin    - default directory for Uplug scripts (called by modules)

=cut

sub ExpandVar{
    my $configtext=shift;

    # make sure that UPLUGHOME is defined
    $ENV{UPLUGHOME} = $Bin unless (defined $ENV{UPLUGHOME});

    $configtext=~s/\$UplugHome/$ENV{UPLUGHOME}/gs;
    $configtext=~s/\$UplugLang/$SHARED_LANG/gs;
    if (defined $ENV{UPLUGCONFIG}){
	$configtext=~s/\$UplugSystem/$ENV{UPLUGCONFIG}/gs;
    }
    else{
	$configtext=~s/\$UplugSystem/$SHARED_SYS/gs;
    }
    $configtext=~s/\$UplugData/data/gs;
    $configtext=~s/\$UplugIni/$SHARED_INI/gs;
    $configtext=~s/\$UplugBin/$ENV{UPLUGHOME}\/bin/gs;
    return $configtext;
}

=head2 C<ExpandVar>

 ExpandNamed( $config );

Expand 'named data streams' in a given configuration hash.

=cut

#------------------------------------------------------------------------
# ExpandNamed .... expand "named" IO streams
#
#   some input/output specifications are stored in ini/DataStreams.ini
#   this provides a shorthand for some standard I/O
#   (use attribute 'stream name' to point to one of the defined IO streams)
#
# ExpandNamed substitutes these shorthands in "input" and "output" in a 
# module configuration hash with the actual specifications
#

sub ExpandNamed{
    my $config=shift;
    my $input=GetParam($config,'input');
    if (ref($input) eq 'HASH'){
	for my $i (keys %$input){
	    if (ref($input->{$i}) eq 'HASH'){
		if (exists $input->{$i}->{'stream name'}){
		    $input->{$i}=&GetNamedIO($input->{$i});
		}
	    }
	}
    }
    my $output=GetParam($config,'output');
    if (ref($output) eq 'HASH'){
	for my $i (keys %$output){
	    if (ref($output->{$i}) eq 'HASH'){
		if (exists $output->{$i}->{'stream name'}){
		    $output->{$i}=&GetNamedIO($output->{$i});
		}
	    }
	}
    }
    return $config;
}

#------------------------------------------------------------------------
# GetNamedIO ... return specifications of a "named" IO stream

sub GetNamedIO{
    my $name=shift;
    my $spec={};
    if (ref($name) eq 'HASH'){
	$spec=$name;
	$name=$name->{'stream name'};
    }
    if (exists $NamedIO{$name}){
	my $conf=eval $NamedIO{$name};
	if (ref($conf) eq 'HASH'){
	    for (keys %$conf){
		if (exists $spec->{$_}){next;}
		$spec->{$_}=$conf->{$_};
	    }
	    delete $spec->{'stream name'};
	}
    }
    return $spec;
}

=head2 C<CheckParam>

 CheckParam( $config, @params );

Check command line parameters and modify the config hash according to the given parameters C<@params>. Possible command line arguments are specified in the config hash, in either of the following: 

 { arguments => { shortcuts => { ... } } }
 { arguments => { optons => { ... } } }
 { options => { ... } }

Example: define an option '-in file-name' for setting the file-name (=file)
of the input stream called 'text' with the following code:

  { 'arguments' => {
       'shortcuts' => {
          'in' => 'input:text:file'
       }
  }

If you use the flag '-in' its argument (e.g. 'my-file.txt') will be moved to

  { input => { text => { file => my-file.txt } } }

in the config hash.

=cut

sub CheckParam{
    my $config=shift;

    if ((@_ == 1) && ($_[0]=~/\S\s\S/)){    # if next argument is a string with
	my @params=split(/\s+/,$_[0]);      # spaces: split it into an array
	return CheckParam($config,@params); #         and try again
    }

    my $flags=GetParam($config,'arguments','shortcuts');
    if (ref($flags) ne 'HASH'){
	$flags=GetParam($config,'arguments','options');
    }
    if (ref($flags) ne 'HASH'){
	$flags=GetParam($config,'options');
    }
#    return if (ref($flags) ne 'HASH');
    while (@_){
	my $f=shift;                        # flag name
	my @attr=();
	if ($f=~/^\-/){                     # if it is a short-cut flag:
	    $f=~s/^\-//;                    # delete leading '-'
	    if (exists $flags->{$f}){
		@attr=split(/:/,$flags->{$f});
	    }
	}
	else{                               # otherwise: long paramter type
	    @attr=split(/:/,$f);
	}
	my $val=1;                          # value = 1
	if ((@_) and ($_[0]!~/^\-/)){       # ... or next argument if it exists
	    $val=shift;
	}
	SetParam($config,$val,@attr);       # finally set the parameter!
    }
    return $config;
}    

#------------------------------------------------------------------------
# SetParam($config,@attr,$value) ... set a parameter in a config hash
#
#  $config is a pointer to hash
#  @attr   is a sequence of attribute names (refer to nested hash structures)
#  $value  is the value to be set

sub SetParam{
    my $config=shift;
    my $value=shift;    # value
    my $attr=pop(@_);   # attribute name

    if (ref($config) ne 'HASH'){$config={};}
    foreach (@_){
	if (ref($config->{$_}) ne 'HASH'){
	    $config->{$_}={};
	}
	$config=$config->{$_};
    }
    $config->{$attr}=$value;
}

#------------------------------------------------------------------------
# GetParam(config,@attr) ... get the value of a (nested attribute)

sub GetParam{
    my $config=shift;
    my $attr=pop(@_);
    foreach (@_){
	if (ref($config) eq 'HASH'){
	    $config=$config->{$_};
	}
	else{return undef;}
    }
    return $config->{$attr};
}


#------------------------------------------------------------------------
# ReadNamed .... read pre-defined IO streams from a file and store
#                the specifications in the global NamedIO hash

sub ReadNamed{
    my $file=shift;
    if (! -f $file){
	if (-f 'ini/'.$file){
	    $file='ini/'.$file;
	}
	elsif (-f $SHARED_HOME.'/ini/'.$file){
	    $file=$SHARED_HOME.'/ini/'.$file;
	}
	elsif ((defined $ENV{UPLUGHOME}) && (-f $ENV{UPLUGHOME}.'/'.$file)){
	    $file=$ENV{UPLUGHOME}.'/'.$file;
	}
	elsif ((defined $ENV{UPLUGHOME}) && (-f $ENV{UPLUGHOME}.'/ini/'.$file)){
	    $file=$ENV{UPLUGHOME}.'/ini/'.$file 
	} 
    }
    if (! -f $file){return 0;}
    my $config=&ReadConfig($file);
    if (ref($config) eq 'HASH'){
	$Data::Dumper::Indent=1;
	$Data::Dumper::Terse=1;
	$Data::Dumper::Purity=1;
	for (keys %$config){
	    $NamedIO{$_}=Dumper($config->{$_});
	}
    }
    return 1;
}

=head2 C<ListAvailableModules>

 ListAvailableModules( 'category' )

List all available modules within a specific module category. List all modules if no category is given.

=cut


sub ListAvailableModules{
    my $dir = shift || $SHARED_SYS;
    unless (-d $dir){
	$dir = $SHARED_SYS.'/'.$dir;
    }
    system("find $dir -type f | sed 's#^$dir/##' | sort");
}

=head2 C<PrintConfigInfo>

 PrintConfigInfo( $module );

Print information about a given module (taken from its configuration file).

=cut

sub PrintConfigInfo{
    my $config = &ReadConfig(@_);
    return 0 unless (ref($config) eq 'HASH');
    if (ref($$config{module}) eq 'HASH'){
	print "Module Name: ",$$config{module}{name},"\n\n";
    }
    print $$config{description},"\n\n";
    if (ref($$config{arguments}) eq 'HASH'){
	if (ref($$config{arguments}{shortcuts}) eq 'HASH'){
	    print "Command-line arguments:\n\n";
	    foreach (sort keys %{$$config{arguments}{shortcuts}}){
		printf "  -%-10s %s\n",$_,$$config{arguments}{shortcuts}{$_};
	    }
	}
    }
    if (ref($$config{module}) eq 'HASH'){
	if (ref($$config{module}{submodules}) eq 'ARRAY'){
	    print "\nSub-modules:\n\n";
	    foreach (@{$$config{module}{submodules}}){
		printf "  %s\n",$_;
	    }
	}
    }

    if (ref($$config{input}) eq 'HASH'){
	print "\nINPUT:\n";
	foreach (sort keys %{$$config{input}}){
	    printf "  %-20s format: %s\n",$_,$$config{input}{$_}{format};
	}
    }
    if (ref($$config{output}) eq 'HASH'){
	print "\nOUTPUT:\n";
	foreach (sort keys %{$$config{output}}){
	    printf "  %-20s format: %s\n",$_,$$config{output}{$_}{format};
	}
    }


    if (ref($$config{module}) eq 'HASH'){
	print "\n";
	if (exists $$config{module}{stdin}){
	    print "Can read from STDIN (input:$$config{module}{stdin})\n";
	}
	if (exists $$config{module}{stdout}){
	    print "May write to STDOUT (output:$$config{module}{stdout})\n";
	}
    }
    print "\nMore details? Print the config file with\n";
    print "  uplug -p $_[0]\n";
}




## return a true value

1;


__END__

