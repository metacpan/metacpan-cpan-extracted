# Commands.pm - command interface for Perl PVCS module
#
# Copyright (c) 1998  Bill Middleton
#
#

=head1 NAME

VCS::PVCS::Commands - Command class for for VCS::PVCS

=head1 SYNOPSIS

  use VCS::PVCS::Project;

  $proj = new VCS::PVCS::Project("ProjectName");

# Operate on every member in the project

    $proj->checkout("-V 1.7 -Y");
    $proj->checkin("-A foo,bar,baz -V 1.7");
    $proj->vlog("-BG foo");
    $proj->lock("mylabel");
    $proj->addFloatingVersionLabel("mylabel6");

# OR

# Operate on every archive in each folder

  $proj = new VCS::PVCS::Project("ProjectName");
  $folds = $proj->openFolders(".*");

  foreach $f (@$folds){
    $f->co("-Y -P -V 1.7");
    if(! $PVCSERR){
     $f->put("-A foo,bar,baz -V 1.7");
    }
    else{
      print $PVCSOUTPUT;
    }
    $f->put("-A foo,bar,baz -V 1.7");
    $f->history("-D 071363-091298");
    $f->unlock("1.7" );
    $f->addVersionLabel("mylabel2");
  }

# OR

# Operate on the projects archive objects separately

  $proj = new VCS::PVCS::Project("ProjectName");
  $members = $proj->members(".*");

  foreach $f (@$members){
    $f->co("-Y -P -V 1.7",$f->archive());

    if(! $PVCSERR){
      $f->put("-A foo,bar,baz -V 1.7 /path/to/archive.c_v");
    }
    else{
      print $PVCSOUTPUT;
    }
    $f->put("-A foo,bar,baz -V 1.7",$f->archive());
    $f->history("-D 071363-091298",$f->archive());
    $f->unlock("1.7" ,$f->archive());
    $f->addVersionLabel("mylabel2",$f->archive());
  }

# OR

# Operate on the folder's archive objects separately

  $folds = $proj->openFolders(".*");

  foreach $folder (@$folds){
    $members = $folder->members(".*");
    foreach $f (@$members){
      $f->co("-Y -P -V 1.7",$f->archive());
      if(! $PVCSERR){
        put("-A foo,bar,baz -V 1.7 /path/to/archive.c_v");
      }
      else{
        print $PVCSOUTPUT;
      }
      $f->co("-Y -P -V 1.7",$f->archive());
      $f->put("-A foo,bar,baz -V 1.7",$f->archive());
      $f->history("-D 071363-091298",$f->archive());
      $f->unlock("1.7" ,$f->archive());
      $f->addVersionLabel("mylabel2",$f->archive());
    }
  }


# OR

# Simple use of only this module

  use VCS::PVCS;   # You must still use the master module
  use VCS::PVCS::Commands qw(:all);

# You MUST set these when using Commands by itself
  $VCS::PVCS::PVCSMASTERCFG = "../../MASTER.CFG";
  $VCS::PVCS::PVCSCURRPROJCFG = "../../examples.cfg";

# Note the arguments may be all in one string, or separated by quotes

  checkout("-L","-V 1.7","-Y", "/path/to/archive.c_v");
  if(! $PVCSERR){
    put("-A foo,bar,baz -V 1.7 /path/to/archive.c_v");
  }
  else{
    print $PVCSOUTPUT;
  }


=head1 DESCRIPTION

Each time a command is run, the global values B<$PVCSERR> and
B<$PVCSOUTPUT> get set to errno and output respectively.

This class can be used directly.  But it is intended for use
as an ISA for VCS::PVCS::* classes.  Folder, Project, and 
Archive objects inherit Command methods, and augment them, 
to implement the appropriate actions on each type of object.  

You B<MUST >set the C<$VCS::PVCS::PVCSMASTERCFG> and the 
C<$VCS::PVCS::PVCSCURRPROJCFG> to be the master configuration
file, and the project configuration file, respectively, when
using this module by itself.

If you wish to use this module directly, the Exporter makes most
of the symbols available when you C<use VCS::PVCS>.  You should 
see the test cases and the sample code above for more details.

=head1 METHODS

=over 5

=item B<get>

  get([get opts] file(s));

=item B<checkout>

Convenience routine calls get();

=item B<co>

Convenience routine calls get();

=item B<put>

  put([put opts] file(s));

Checkin the named file.  

=item B<checkin>

Convenience routine calls put();

=item B<ci>

Convenience routine calls put();

=item B<vdiff>

  vdiff([vdiff opts]);

=item B<vlog>

  vlog([vlog opts]);

=item B<log>

Convenience routine calls vlog();

=item B<history>

Convenience routine calls vlog();

=item B<lock>

  lock([vcs opts] files)';

Lock the named archive file(s).

=item B<unlock>

  unlock([$label | $version],[vcs opts],file(s));

Unlock the named files.

=item B<addVersionLabel>

  addVersionLabel(label,[vcs opts],file(s));

Add a version label to the named archive file(s).

=item B<deleteVersionLabel>

  deleteVersionLabel(label,[vcs opts],file(s));

Delete a version label to the named archive file(s).

=item B<replaceVersionLabel>

  replaceVersionLabel($newlabel,$oldlabel,[vcs opts],files);

Delete a version label to the named archive file(s).

=item B<transformVersionLabel>

  transformVersionLabel(label,[vcs opts],file(s));

Transform a version label to floating for the named archive file(s).

=item B<addFloatingVersionLabel>

  addFloatingVersionLabel(label,[vcs opts],file(s));

Create a floating version label for the named archive file(s).

=item B<deletePromoGroup>

  deletePromoGroup($group,[vcs opts],file(s))';

Delete the promotion group from the archive

=item B<addPromoGroup>

  addPromoGroup(group:$rev,[vcs opts],files(s))';

Add the promotion group to the archive (at rev)

=item B<createArchive>

  createArchive([vcs opts],file(s))';

Create a new archive in $file.

=item B<vcs>

  vcs([opts][files])';

Run vcs by itself.

=back

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

VCS::PVCS::Project

=cut


package VCS::PVCS::Commands;
use strict;
use Carp;
use Cwd;
use Getopt::Long;
use Exporter;
use VCS::PVCS;
use vars qw($VERSION %EXPORT_TAGS @EXPORT_OK @ISA);
@ISA = qw(Exporter );
$VERSION = "0.02";

@EXPORT_OK = ();  # populated by export_ok_tags
%EXPORT_TAGS = (
all => [ qw( get checkout co put checkin ci vlog log history lock
unlock addVersionLabel deleteVersionLabel replaceVersionLabel
addFloatingVersionLabel transformVersionLabel deletePromoGroup 
addPromoGroup createArchive changeAccessList vcs vdiff
)]
);
Exporter::export_ok_tags('all');


##############################################################################
# Global options - with a few defaults for safety
##############################################################################

# Global options common to PVCS commands in use
my($globalopts) = {
    '#' => "6",    # pvcs command debug opt
    'C' => "",     # Config file 
    'G' => "",     # promotion group
    'R' => "",     # Revision number 
    'S' => "",     # Specify alternate suffix file
    'V' => "",     # Version label or floating versionlabel with *
    'Y' => "",      # Answer yes in advance to all prompts
    'XO' => "",     # Redirect STDOUT (also STDERR with +E) to FILE
    'XE' => ""     # Redirect STDERR to FILE
};

# GET-specific defaults
my($getopts) = {
    'D' => "",     # checkout latest before Date/Time 
    'L' => "",     # Lock against this revision or version_label
    'P' => "",     # GET to STDOUT
    'Q' => "1",     # Quiet mode AND overwrite
    'QN' => "",   # Quiet mode and DONT overwrite
    'T' => "",     # Assign current timestamp to checkedout files
    'U' => "",     # Checkout only if newer than existing workfile
    'W' => ""      # Checkout a writable workfile
};

# VDIFF-specific defaults
my ($vdiffopts) = {
    'A' => "",     # specify access list
    'B' => "",     # Ignore leading and trailing space when comparing versions
    'D' => "",     # generate a delta script to stdout
    'E' => "",     # expand tabs to given number of characters per column
    'L' => "",     # display the given number of context lines around changes
    'N' => "",     # omit line number information in display
    'Q' => "1",     # Quiet mode and answer YES to any prompt
    'T' => "",     # test for difference only, do not display
};
my ($putopts) = {
    'A' => "",     # specify access list
    'B' => "",     # Ignore leading and trailing space when comparing versions
    'F' => "",     # Force checkin even if no changes
    'FB' => "",    # Force branch even if tip
    'L' => "",     # Force immediete checkout with lock
    'M' => "",     # Default checkin comment 
    'N' => "",    # Answer NO in advance to any prompt
    'Q' => "",     # Quiet mode and answer YES to any prompt
    'QO' => "",   # Quiet mode 
    'T' => "",     # Specify workfile description
    'U' => "",     # Store and immedietly checkout readonly
    'W' => ""      # Checkout a writable workfile
};


# VLOG-specific defaults
my ($vlogopts) = {
    'A' => "",     # specify access list
    'B' => "",     # Ignore leading and trailing space when comparing versions
    'BC' => "",    # Display archives containing Tips != RevNumber|VerLabel
    'BG' => "",    # Display revs containing Tips != RevNumber|VerLabel
    'BL' => "",    # Display archive info for locked by USER
    'BN' => "",    # Display newest rev on branch
    'BR' => "",    # Display info about specified rev
    'BV' => "",    # Display  info about specified version_label
    'D' => "",     # Display revs in within the daterange
    'I' => "",     # Turn off indentation
    'L' => "",     # Display info about archives locked by USER(s)
    'M' => "",     # Display info about archives owned by USER(s)
    'U' => ""     # Display current userID and ID source
};

# VCS-specific defaults
my ($vcsopts) = {
    'A' => "",     # specify access list
    'EC' => "",    # Specify comment prefix
    'EN' => "",    # Specify newline prefix
    'I' => "",     # Create an empty archive with no revisions
    'L' => "",     # Lock this version or ver_label
    'M' => "",     # Default checkin comment 
    'L' => "",     # Force immediete checkout with lock
    'N' => "",    # Answer NO in advance to any prompt
    'O' => "",     # Change Archive owner to this user
    'PC' => "",    # Enable or disable archive compression
    'PD' => "",    # Enable or disable delta compression
    'PE' => "",    # Enable or disable exclusive locking
    'PG' => "",    # Enable or disable delta generation
    'PK' => "",    # Enable or disable keyword expansion
    'PL' => "",    # Enable or disable lock checking
    'PT' => "",    # Enable or disable translation
    'PW' => "",    # Enable or disable archive write-protection
    'Q' => "",     # Quiet mode and answer YES to any prompt
    'QO' => "1",    # Quiet mode 
    'QN' => "",    # Quiet mode and answer NO to any prompt
    'T' => "",     # Specify workfile description
    'U' => "",     # Unlock the revision|user|* for all users
    'W' => ""      # Specify workfile name
};


##############################################################################
# Checkout methods
##############################################################################
#  -C[<file>]      specify a configuration file
#  -D<date/time>   specify a revision by date/time
#  -H              display this text then exit
#  -L[<rev>]       lock the revision with intent to modify it
#  -N              force negative response to all queries
#  -P[<rev>]       pipe revision to stdout
#  -Q[O]           quiet mode; suppress messages and queries
#  -R<rev>         specify a particular revision
#  -S<suffix>      specify a suffix template
#  -T[<rev>]       touch the workfile (set to current time)
#  -U[<date/time>] get only if newer than existing file or date
#  -V<version>     specify a particular version to extract
#  -W[<rev>]       make file writable even if not locked
#  -XO<file>       write output to file
#  -XE<file>       write errors to file
#  -Y              force affirmative response to all queries
#  @[<file>]       specify a file containing more options/files

sub get{
@_ >= 1 or croak 'usage: get([get opts] file(s))';
my($options);
my($input);

$options = _processOptions("get",\@_);
        
$input = "$options ".join(' ',@_);
_execute("get", $input);
($PVCSERR) ? return 0 : return 1;

}

sub checkout{
    get(@_);
}

sub co{
    get(@_);
}

##############################################################################
# Checkin methods
##############################################################################
# -A[<id list>]  specify the access list for a new archive
#   -B             ignore leading and trailing blanks when comparing
#   -C[<file>]     specify a configuration file
#   -F[B]          force PUT even if unchanged or force new branch
#   -H             display this text then exit
#   -L             after PUTting, do a GET with a lock
#   -M[<text>]     specify change description directly or from stdin
#   -N             force negative response to all queries
#   -Q[O]          quiet mode; suppress messages and queries
#   -R<rev>        specify a specific revision number
#   -S<suffix>     specify a suffix template
#   -T[<desc>]     specify workfile description directly or from stdin
#   -U             after PUTting, do a GET without a lock
#   -V<version>    assign version name to the revision

sub put{
@_ >= 1 or croak 'usage: put([put opts] file(s))';
my($options);
my($input);

$options = _processOptions("put",\@_);

$input = $options;
if(defined(@_) && (scalar(@_) > 0)){
    $input .= " ".join(' ',@_);
}

_execute("put", $input);

($PVCSERR) ? return 0 : return 1;
}

sub checkin{
    put(@_);
}

sub ci{
    put(@_);
}

##############################################################################
# diff methods 
##############################################################################

sub vdiff{
@_ >= 1 or croak 'usage: vdiff([vdiff opts])';
my($options);
my($input);

$options = _processOptions("vdiff",\@_);
$input = $options;
if(defined(@_) && (scalar(@_) > 0)){
    $input .= " ".join(' ',@_);
}
_execute("vdiff", $input);
($PVCSERR) ? return 0 : return 1;
}

##############################################################################
# history methods
##############################################################################
sub vlog{
@_ >= 1 or croak 'usage: vlog([vlog opts])';
my($options);
my($input);

$options = _processOptions("vlog",\@_);
$input = $options;
if(defined(@_) && (scalar(@_) > 0)){
    $input .= " ".join(' ',@_);
}
_execute("vlog", $input);
($PVCSERR) ? return 0 : return 1;

}

sub log{
    vlog(@_);
}

sub history{
    vlog(@_);
}

######################################################################
# locking methods
######################################################################

# vcs -L -l[ revision | ver_ label] Lock a revision.
sub lock{
@_ >= 1 or croak 'usage: lock([vcs opts] files)';
my($tmptype) = $vcsopts->{'L'};

my($version) = shift;
$vcsopts->{'L'} = ($version) ? $version : 1;
vcs(@_);
$vcsopts->{'L'} = $tmptype;

}

# -U -u[ revision | ver_label] Unlock a revision by revision number
# or version label.
# -u: user Unlock all locks placed by user.
# -u:* Unlock all locks placed by all users.
sub unlock{
@_ >= 1 or croak 'usage: unlock([$label | $version],[vcs opts],file(s))';
my($tmptype) = $vcsopts->{'U'};

my($version) = shift;
$vcsopts->{'U'} = ($version) ? $version : 1;
vcs(@_);
$vcsopts->{'U'} = $tmptype;

}

######################################################################
# Version label methods
######################################################################


# -v ver_label - Assign a version label to the trunk tip 
# revision of specified archives.
# 
# -v ver_label:rev_number | ver_label - Assign ver_label to the 
# revision associated with rev_number or ver_label.
# 
# -v floating_label:rev_number* - Assign floating_label to rev_number.
# 
# -v floating_label:ver_label* - Assign floating_label to ver_label.
#
sub addVersionLabel{
@_ >= 2 or croak 'usage: addVersionLabel(label,[vcs opts],file(s))';
my($label) = shift;
my($tmpopt) = $globalopts->{'V'};

$globalopts->{'V'} = $label;
vcs(@_);
$globalopts->{'V'} = $tmpopt;
}

# -v ver_label:delete - Delete ver_label.
sub deleteVersionLabel{
@_ >= 2 or croak 'usage: deleteVersionLabel(label,[vcs opts],file(s))';
my($tmpopt) = $globalopts->{'V'};
my($label) = shift;

($label .= ":delete") unless ($label =~ /:delete$/);
$globalopts->{'V'} = $label;
vcs(@_);
$globalopts->{'V'} = $tmpopt;
}

# -v new_ver_label::old_ver_label - Replace old_ver_label with new_ver_label.
sub replaceVersionLabel{
@_ >= 3 or croak 'usage: replaceVersionLabel($newlabel,$oldlabel,[vcs opts],files)';
my($tmpopt) = $globalopts->{'V'};
my($newlabel) = shift;
my($oldlabel) = shift;

$globalopts->{'V'} = "$newlabel\:\:$oldlabel";
vcs(@_);
$globalopts->{'V'} = $tmpopt;
}

# -v ver_ label:* - Transform to floating ver_label 
sub transformVersionLabel{
@_ >= 2 or croak 'usage: transformVersionLabel(label,[vcs opts],file(s))';
my($tmpopt) = $globalopts->{'V'}; # save
my($tmpYopt) = $globalopts->{'Y'}; # save
my($label) = shift;

($label .= ":\\*") unless ($label =~ /:\*$/);
$globalopts->{'V'} = "$label";
$globalopts->{'Y'} = 1;
vcs(@_);
$globalopts->{'V'} = $tmpopt;
$globalopts->{'Y'} = $tmpYopt;
}

# -v ver_ label:* - Add floating ver_label 
sub addFloatingVersionLabel{
@_ >= 2 or croak 'usage: addFloatingVersionLabel(label,[vcs opts],file(s))';
my($tmpopt) = $globalopts->{'V'}; # save
my($label) = shift;

($label .= ":\\*") unless ($label =~ /:\*$/);
$globalopts->{'V'} = "$label";
vcs(@_);
$globalopts->{'V'} = $tmpopt;
}


######################################################################
# Promotion group methods
######################################################################

#  -G<group>:delete  delete a promotion group
sub deletePromoGroup{
@_ >= 2 or croak 'usage: deletePromoGroup($group,[vcs opts],file(s))';
my($tmpopt) = $globalopts->{'G'};
my($label) = shift;
($label .= ":delete") unless ($label =! /:delete$/);

$globalopts->{'G'} = $label;
vcs(@_);
$globalopts->{'G'} = $tmpopt;
}

#  -G<group>[:<rev>] assign a promotion group to a revision
sub addPromoGroup{
@_ >= 2 or croak 'usage: addPromoGroup(group:$rev,[vcs opts],files(s))';
my($tmpopt) = $globalopts->{'G'};
my($label) = shift;

$globalopts->{'G'} = $label;
vcs(@_);
$globalopts->{'G'} = $tmpopt;

}

#  -I create and initialize an archive
sub createArchive{
@_ >= 1 or croak 'usage: createArchive([vcs opts],file(s))';
my($tmpopt) = $vcsopts->{'I'};
$vcsopts->{'I'} = 1;
vcs(@_);
$vcsopts->{'I'} = $tmpopt;
}

##########################################################################
# The all-seeing, all-knowing VCS utility command
##########################################################################
sub vcs{
@_ >= 1 or croak 'usage: vcs([opts][files])';
my($options);
my($input);
$options = _processOptions("vcs",\@_);
$input = $options;
if(defined(@_) && (scalar(@_) > 0)){
    $input .= " ".join(' ',@_);
}
_execute("vcs", $input);
($PVCSERR) ? return 0 : return 1;
}

##########################################################################
# Private methods 
##########################################################################

sub _processOptions{
my($cmd) = shift;
my($opt,$optstring);
my($tmpGlobals)= {};
my($tmpCmd) = {};
my($tmp) = shift;
my(@ARGV) = @{$tmp};
(@ARGV = split(' ',$ARGV[0])) if (scalar(@ARGV) == 1);

Getopt::Long::config( "pass_through");

%{$tmpGlobals} = %{$globalopts};
GetOptions($tmpGlobals, '-Y', '-R:s', '-C=s', '-V=s', '-G=s','-S=s','-XO=s','-XE=s');

foreach $opt (keys(%{$tmpGlobals})){
    if(defined($tmpGlobals->{$opt}) && length($tmpGlobals->{$opt})){
	if($tmpGlobals->{$opt} =~ /^1$/){
	    $optstring .= " -${opt} ";
	    next;
	}
	elsif(length($tmpGlobals->{$opt})){
	    $optstring .= " -".$opt.$tmpGlobals->{$opt}." ";
	    next;
	}
    }
}

if($cmd eq "get"){
   %{$tmpCmd} = %{$getopts};
    GetOptions($tmpCmd, '-P', '-Q', '-U=s', '-W=s', '-T=s', 
	'-L=s', '-D=s', '-QN');
    foreach $opt (keys(%{$tmpCmd})){
	if(defined($tmpCmd->{$opt}) && length($tmpCmd->{$opt})){
	    if($tmpCmd->{$opt} =~ /^1$/){
		$optstring .= " -${opt} ";
		next;
	    }
	    elsif(length($tmpCmd->{$opt})){
		$optstring .= " -".$opt.$tmpCmd->{$opt}." ";
		next;
	    }
	}
    }
}
elsif($cmd eq "put"){
    %{$tmpCmd} = %{$putopts};
    GetOptions($tmpCmd, '-QO', '-FB', '-Q', '-A=s', 
	'-U', '-B', '-W', '-T=s', '-L', '-M=s', '-N', '-F');
    foreach $opt (keys(%{$tmpCmd})){
	if(defined($tmpCmd->{$opt}) && length($tmpCmd->{$opt})){
	    if($tmpCmd->{$opt} =~ /^1$/){
		$optstring .= " -${opt} ";
		next;
	    }
	    elsif(length($tmpCmd->{$opt})){
		$optstring .= " -".$opt.$tmpCmd->{$opt}." ";
		next;
	    }
	}
    }
}
elsif($cmd eq "vdiff"){
    %{$tmpCmd} = %{$vdiffopts};
    GetOptions($tmpCmd, '-D=s', '-Q', '-A', 
	'-E=i', '-H', '-L=i', '-T', '-M=s', '-N', '-Q');
    foreach $opt (keys(%{$tmpCmd})){
	if(defined($tmpCmd->{$opt}) && length($tmpCmd->{$opt})){
	    if($tmpCmd->{$opt} =~ /^1$/){
		$optstring .= " -${opt} ";
		next;
	    }
	    elsif(length($tmpCmd->{$opt})){
		$optstring .= " -".$opt.$tmpCmd->{$opt}." ";
		next;
	    }
	}
    }
}
elsif($cmd eq "vlog"){
    %{$tmpCmd} = %{$vlogopts};
    GetOptions($tmpCmd, '-B', '-BC=s', '-BG=s', '-BL=s','-BN=s',
	'-BR=s', '-BV=s','D=s','-I','-O=s', '-Q', '-A=s', 
	'-U', '-B', '-L=s' );
    foreach $opt (keys(%{$tmpCmd})){
	if(defined($tmpCmd->{$opt}) && length($tmpCmd->{$opt})){
	    if($tmpCmd->{$opt} =~ /^1$/){
		$optstring .= " -${opt} ";
		next;
	    }
	    elsif(length($tmpCmd->{$opt})){
		$optstring .= " -".$opt.$tmpCmd->{$opt}." ";
		next;
	    }
	}
    }
}
elsif($cmd eq "vcs"){
   %{$tmpCmd} = %{$vcsopts};
   ($tmpGlobals->{'Y'}) && ($tmpCmd->{'QN'} = '');
   GetOptions($tmpCmd, '-D','-PC', '-EN=s', '-T=s', 
	'-PD', '-U:s', '-PE', '-W=s', '-PG',
	'-PK', '-PL', '-QN', '-QO', '-A=s', '-PT', 
	'-PW', '-EC=s', '-I', '-L:s', '-M', '-N', '-O=s', '-Q');
    foreach $opt (keys(%{$tmpCmd})){
	if(defined($tmpCmd->{$opt}) && length($tmpCmd->{$opt})){
	    if($tmpCmd->{$opt} =~ /^1$/){
		$optstring .= " -${opt} ";
		next;
	    }
	    elsif(length($tmpCmd->{$opt})){
		$optstring .= " -".$opt.$tmpCmd->{$opt}." ";
		next;
	    }
	}
    }
}

# Restore the callers @_, kinda icky
@{$tmp} = ();
foreach $opt (@ARGV){
    push(@{$tmp},$opt);
}
return ($optstring);
}

sub _execute{
my($command,$options) = @_;
my($output,$error);

if($PVCSSHOWMODE){
    warn "Would have executed:\n	$PVCS_BINDIR/$command -C$PVCSMASTERCFG -C$PVCSCURRPROJCFG $options\n";
}
else{
    if($^O eq "MSWin32"){
	$output = `$PVCS_BINDIR\\$command -C$PVCSMASTERCFG -C$PVCSCURRPROJCFG $options`;
    }else{
	$output = `$PVCS_BINDIR/$command -C$PVCSMASTERCFG -C$PVCSCURRPROJCFG $options`;
    }
    $error = $?;
}
if(! $PVCSSHOWMODE){
$PVCSERR = $error;
$PVCSOUTPUT  .= $output;
$PVCSCURROUTPUT = $output;
}

}
   


1;

__END__

