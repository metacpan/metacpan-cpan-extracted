# PVCS.pm - super class for VCS::PVCS::Project
#
# Copyright (c) 1998  Bill Middleton
#
#

require 5.003;
$VERSION = "0.01";

=head1 NAME

VCS::PVCS - Global configuration class for for VCS::PVCS::*.  

=head1 SYNOPSIS

  use VCS::PVCS::Project;  # preferred
  $project = new VCS::PVCS::Project("ProjectName");

=head1 DESCRIPTION

The VCS::PVCS class simply parses the PVCS global configuration files, 
including pvcsproj.pub and MASTER.CFG, found in PVCSPROJ.  
The resulting object is then included in the VCS::PVCS::Project 
object as it's "CONFIG".  The class members are used at various
times in other subclasses, as needed.

NOTE: This module may require some configuration.  If your
scripts wont run, you may need to hardwire some of the global
parameters, including $ISLVINI, $PVCSPROJ, $NFSMAP, $PVCS_BINDIR and
possibly others.  You should inspect the module before installing
it, to verify the settings will work.

This module also exports several GLOBAL variables, which are 
used in various places throughout it's children, and can be
used in scripts which load the B<VCS::PVCS::Project> class.
These variables include, but may not always be limited to:

=over 5

=item B<$PVCSERR>

PVCSERR is set to the current value of B<$?> after each command.

=item B<$PVCSDEBUG>

PVCSDEBUG can be turned on to see copious (sometimes useful) debugging
output as the module is configuring itself, and running.

=item B<$PVCSOUTPUT>

PVCSOUTPUT is all of the output from the current method, when it
executes a pvcs command.  If the command was executed on a folder
or project-wide basis, then PVCSOUTPUT contains ALL of the output
for all archives.

=item B<$PVCSCURROUTPUT>

PVCSCURROUTPUT is ONLY the output for the most recent command sent
to the shell.

=item B<$PVCSSHOWMODE>

PVCSSHOWMODE is turned on to see, and not execute, commands.

=item B<$PVCS_BINDIR>

PVCS_BINDIR is set in the environment or in VCS::PVCS.pm to be
the location of the PVCS binaries, B<get>, B<put>, B<vlog>, B<vcs>,
B<vdiff>, etc.

=item B<$PVCSMASTERCFG>

PVCSMASTERCFG is the path to the master configuration file.  This
variable is not exported to the world through VCS::PVCS::Project,
but only intended for internal use.

=item B<$PVCSCURRPROJCFG>

PVCSCURRPROJCFG is the location of the current projects' Config file.
This variable is not exported to the world through VCS::PVCS::Project,
but only intended for internal use.

=item B<$PVCSMULTIPLATFORM>

PVCSMULTIPLATFORM tells the modules whether to make certain path
translations when operating on something other than WIN.  Turn
this on if you are using PVCS in a multiplatform environment.

B<This variable is turned on automatically if an NFSMAP is found>

=item B<$PVCSPROJ>

PVCSPROJ is the base directory for all PVCS control files.

=back

Ordinarily, this class wont be used directly.  Rather, it 
is in the @ISA for VCS::PVCS::Project.  When creating a new 
VCS::PVCS::Project object, this module's new() method is 
invoked automatically.  

=head1 AUTHOR

Bill Middleton, wjm@metronet.com

=head1 COPYRIGHT

The PVCS module is Copyright (c) 1998 Bill Middleton.
All rights reserved.

You may distribute under the terms of either the GNU General Public
License or the Artistic License, as specified in the Perl README file.

=head1 SUPPORT / WARRANTY

The VCS::PVCS modules are free software. 

B<THEY COME WITHOUT WARRANTY OF ANY KIND.>

Commercial support agreements for Perl can be arranged via 
The Perl Clinic. See http://www.perl.co.uk/tpc for more details.

=head1 SEE ALSO

perl(1), VCS::PVCS::Project

=cut

package VCS::PVCS;
use strict;
use Carp;
require Exporter;
use vars qw($PVCSDEBUG $USESQL @ISA @EXPORT $VERSION $PVCSPROJ $PVCSDONTSAVE
$PVCSPRIV $NFSMAP $PVCSERR $PVCSOUTPUT $PVCSCURROUTPUT $ISLVINI $PVCS_BINDIR 
$PVCSMASTERCFG $PVCSSHOWMODE $PVCSCURRPROJCFG %NFSMAP $PVCSMULTIPLATFORM);
@ISA = qw(Exporter);
@EXPORT = qw(translatePath2Win translatePath2Unix );
$VERSION = "0.01";
$PVCSDEBUG= 0;
$PVCSSHOWMODE = 0;


####################################################################
# Configuration Defaults extracted from ISLVINI
####################################################################

$USESQL =0;
$PVCSDEBUG = 0;  # Set this to get debug output for all PVCS modules

$PVCSDONTSAVE = 1;  # Save config files when VCSDIR changes.
                    # change this if you dont use conditional directives
                    # in your config files for pvcs
if($ENV{'ISLVINI'}){
    $ISLVINI = $ENV{'ISLVINI'};
}
elsif($^O eq "MSWin32"){
    if(-e "$ENV{'WINDIR'}/islv.ini"){
	$ISLVINI = $ENV{'WINDIR'}.'/islv.ini';
    }
}
elsif(-e  "$ENV{'HOME'}/.islvrc"){
    $ISLVINI = $ENV{'HOME'}.'/.islvrc';
}
else{
    print "$ENV{'HOME'}/.islvrc\n";
    croak "Cannot find the ISLVINI file\n";
}

# Better change these!

if($ENV{'PVCS_BINDIR'}){
    $PVCS_BINDIR = $ENV{'PVCS_BINDIR'};
    if(! ((-e "$PVCS_BINDIR/vcs") or (-e "$PVCS_BINDIR/vcs.exe"))){
	croak "Cant find PVCS Binaries. Set PVCS_BINDIR in PVCS.pm or ENV.\n";
    }
}
elsif($^O eq "MSWin32"){  # There is probably a better way to do this on WIN
    $PVCS_BINDIR = "N:\\pvcs6.0\\nt";
    if(! (-e "$PVCS_BINDIR/vcs.exe")){
	croak "Cant find PVCS Binaries. Set PVCS_BINDIR in PVCS.pm or ENV.\n";
    }
    $ENV{'PVCS_BINDIR'} = $PVCS_BINDIR;
}
else{  # unix
    $PVCS_BINDIR = "/usr/pvcs";
    if(! (-e "$PVCS_BINDIR/vcs")){
	croak "Cant find PVCS Binaries. Set PVCS_BINDIR in PVCS.pm or ENV.\n";
    }
    $ENV{'PVCS_BINDIR'} = $PVCS_BINDIR;
}
$PVCSERR = $PVCSOUTPUT= $PVCSCURROUTPUT = $PVCSPROJ = "";
$PVCSMULTIPLATFORM = 0;  # Assume were in a heterogeneous environment
                         # unless we find an nfsmap

push(@EXPORT,"\$PVCSERR");
push(@EXPORT,"\$PVCSDEBUG");
push(@EXPORT,"\$PVCSOUTPUT");
push(@EXPORT,"\$PVCSCURROUTPUT");
push(@EXPORT,"\$PVCSSHOWMODE");
push(@EXPORT,"\$PVCS_BINDIR");
push(@EXPORT,"\$PVCSMASTERCFG");
push(@EXPORT,"\$PVCSCURRPROJCFG");
push(@EXPORT,"\$PVCSMULTIPLATFORM");
push(@EXPORT,"\$PVCSPROJ");

####################################################################
sub new{
    my $proto = shift;
    my $self  = {};
    open(ISLVINI,$ISLVINI) || croak "Cant open ISLVINI: $ISLVINI\n";
    while(<ISLVINI>){
	chomp;
	next unless (/^(PVCSPROJ|PVCSPRIV|NFSMAP)=(.*)/);
	eval "\${$1}= \$2";
    }
    (croak "Your PVCSPROJ AND PVCSPRIV directories are not defined in $ISLVINI\n")
	unless (length($PVCSPROJ) && length($PVCSPRIV));

    readMasterProjFile($self);
    if(-e "$PVCSPROJ/MASTER.CFG"){  # Um, you may need to change this too.
	$PVCSMASTERCFG = "$PVCSPROJ/MASTER.CFG";
	readMasterConfigFile($self);
    }
    else{
	croak "No MASTER.CFG config file found in $PVCSPROJ\n";
    }
    if(-e "$NFSMAP/nfsmap"){
	readNFSMap($self);
    }
    bless($self,"VCS::PVCS");
}

sub readMasterConfigFile{
my($self) = shift;
my($key,$value)=();
my(@tmp);
# Eventually, this'll be replaced with API call
# Right now the only thing we're interested in is VCSDIR,
# since the command line tools will read them for themselves.

(croak "Cant find your Master Config file, $PVCSMASTERCFG")
    unless (-e "$PVCSMASTERCFG");
open(MASTER, "$PVCSMASTERCFG") || 
    croak "cant open $PVCSMASTERCFG";
while(<MASTER>){
    chop;chop; # icky but ok
    ($key,$value) = split(/\s+[= 	]+\s*/,$_);
    next unless (defined($key));
    next unless ($key =~ s/.*(VCSDIR).*/$1/);
    $value =~s/^\s*\"//;
    $value =~s/\"\s*$//;
    @{$self->{'VCSDIR'}} =  split(/\"\;\"/,$value);
    last;
}
}


sub readMasterProjFile{
my($self) = shift;
my($nextline,$project);
(croak "Cant find your Master Project file, $PVCSPROJ/pvcsproj.pub")
    unless (-e "$PVCSPROJ/pvcsproj.pub");
    open(MASTER, $PVCSPROJ."/pvcsproj.pub") || croak "cant open ";
    while(<MASTER>){
	chomp;
	next unless (/^\[Project=(.*)\]/);
	$project = $1;
	for(1 .. 4){
	    chomp($nextline = scalar(<MASTER>));
	    $nextline =~ /^(CFG|DIR|ARDIR|WKDIR)=([^\015]*)/;
	    $self->{'projects'}->{$project}->{$1} = $2;
	}
	$self->{'projects'}->{$project}->{'NAME'} = $project;
    }
}

sub readNFSMap{
my($self) = shift;
my($key,$value);
open(MASTER,"$NFSMAP/nfsmap");
$PVCSMULTIPLATFORM = 1;
while(<MASTER>){
    chomp;
    next if /^[\s#]/;
    ($key,$value) = split(' ',$_);
    $NFSMAP{$key} = $value;
}
}

sub translatePath2Unix{
my($pathref) = shift;
my($key,$path);
foreach $key (keys %NFSMAP){
    if($$pathref =~ s#$key:\\#$NFSMAP{$key}/#){
	last;
    }
}
$$pathref =~ s/\\/\//g;
}

sub translatePath2Win{
my($pathref) = shift;
my($key,$value,$path);
foreach $key (keys %NFSMAP){
    $value = $NFSMAP{$key};
    if($$pathref =~ s#$value/#$key:\\#){
	last;
    }
}
$$pathref =~ s/\//\\/g;
}


1;
__END__

