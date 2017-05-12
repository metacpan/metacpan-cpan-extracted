package Tk::RemoteFileSelect;
# Temp version of CPAN.
$VERSION=0.56;
my $RCSRevKey = '$Revision: 0.56 $';
$RCSRevKey =~ /Revision: (.*?) /;
$VERSION=$1;
use vars qw($VERSION @EXPORT_OK);
@EXPORT_OK = qw(glob_to_re);

=head1 NAME

  RemoteFileSelect.pm--Browse directories with FTP.

=head1 SYNOPSIS 

  require Tk::RemoteFileSelect;

  my $file = $mw -> Tk::RemoteFileSelect( -directory => '.' );

=head1 DESCRIPTION

A RemoteFileSelect contains two listboxes that display subdirectories
and files, a directory entry and a file name entry, and buttons for
each operation, which are labeled with Alt-key accelerators.

When entering a file name, the RemoteFileSelect verifies whether the
file already exists.  If a file is selected in the listbox, the
RemoteFileSelect returns that file's name when the user clicks the
'Accept' button, presses Enter after typing a name in the file entry,
or double clicks on a selection in the file list box.

Additionally, if the Net::FTP module is installed, RemoteFileSelect
will activate an additional "Host" button on the FileSelect widget,
where you can enter the host name, and your user id and password, and
select files on the remote host.

If a file name is selected on the local host, then the
RemoteFileSelect widget returns the path to the file name, the same as
a standard FileSelect widget.

If a file is selected on a remote host, then the RemoteFileSelect
widget returns the name in the form:

  host:/full-pathname-of-file

RemoteFileSelect requires the Net::FTP module to be installed.  If it
cannot find and load Net::FTP, the RemoteFileSelect widget behaves
like a standard FileSelect widget, and the "Host" button is grayed
out.

RemoteFileSelect.pm was developed with the Net::FTP module distributed
with libnet-1.0703, from http://www.cpan.org/.

All other operations function as in a FileSelect widget.  Please refer
to the FileSelect.pm POD documentation.

=head1 VERSION INFO

  First development version.

  $Revision: 0.56 $

=cut

use Tk qw(Ev);
use strict;
use Carp;
use base qw(Tk::Toplevel);
use Tk::widgets qw(LabEntry Button Frame Listbox Scrollbar);
use File::Basename;

my $menufont="*-helvetica-medium-r-*-*-12-*";

Construct Tk::Widget 'RemoteFileSelect';

use vars qw(%error_text);
%error_text = (
	'-r' => 'is not readable by effective uid/gid',
	'-w' => 'is not writeable by effective uid/gid',
	'-x' => 'is not executable by effective uid/gid',
	'-R' => 'is not readable by real uid/gid',
	'-W' => 'is not writeable by real uid/gid',
	'-X' => 'is not executable by real uid/gid',
	'-o' => 'is not owned by effective uid/gid',
	'-O' => 'is not owned by real uid/gid',
	'-e' => 'does not exist',
	'-z' => 'is not of size zero',
	'-s' => 'does not exists or is of size zero',
	'-f' => 'is not a file',
	'-d' => 'is not a directory',
	'-l' => 'is not a link',
	'-S' => 'is not a socket',
	'-p' => 'is not a named pipe',
	'-b' => 'is not a block special file',
	'-c' => 'is not a character special file',
	'-u' => 'is not setuid',
	'-g' => 'is not setgid',
	'-k' => 'is not sticky',
	'-t' => 'is not a terminal file',
	'-T' => 'is not a text file',
	'-B' => 'is not a binary file',
	'-M' => 'has no modification date/time',
	'-A' => 'has no access date/time',
	'-C' => 'has no inode change date/time',
    );

sub import {
    if (defined $_[1] and $_[1] eq 'as_default') {
	local $^W = 0;
	package Tk;
	*FDialog      = \&Tk::RemoteFileSelect::FDialog;
	*MotifFDialog = \&Tk::RemoteFileSelect::FDialog;
    }
}

sub Cancel
{
 my ($cw) = @_;
 $cw->{Selected} = undef;
 my $hostname = $cw -> cget( -hostname );
 if( $hostname ne '' ) {
   my $ftp = $cw -> cget( -ftp );
   $ftp -> quit;
   $cw -> configure( -ftp => undef,
		     -connected => '' );
 }
 $cw->withdraw unless $cw->cget('-transient');
}

sub host {
    my ($cw) = @_;
    my ($hostid, $transcript, $resp);
    my $dlg = $cw->Subwidget('hostdialog');
    return if ( ($resp =  $dlg -> Show ) =~ /Cancel/);
    $hostid = $dlg -> Subwidget( 'hostentry' ) -> get;
    $transcript = $cw -> cget( '-transcript' );
    $cw -> configure( -hostname => $hostid,
		    -transcript => $transcript );
    my $logindlg = $cw -> Subwidget('logindialog');
    return if ( ($resp =  $logindlg -> Show ) =~ /Cancel/);
    $cw -> configure( -userid => ($logindlg -> Subwidget( 'uidentry' ) -> get),
	      -password => ($logindlg -> Subwidget( 'pwdentry' ) -> get) );
    my $ftp = $cw -> remoteLogin( $hostid, 
				  $cw -> cget( -userid ),
				  $cw -> cget( -password ),
				  $transcript );

    if( defined $ftp ) {
      my $dir = $ftp -> pwd();
      $cw -> remoteDirectory( $dir );
    } 
}

sub remoteLogin {
  my ($cw, $hostid, $userid, $password, $transcript) = @_;

  my $ftp = undef;
  my $debug = ( $transcript =~ /1/ ? 1 : 0 );
  $ftp = Net::FTP -> 
    new( $hostid, 
	 Debug => $debug );
  if( ! defined $ftp ) {
    my $edlg = $cw -> Subwidget( 'errormessage' );
    $edlg -> configure( -text => $@ );
    $edlg -> Show;
    $cw -> configure( -hostname => '',
		      -connected => '');
    return;
  }
  if( $ftp -> login( $userid, $password ) ) {
    $cw -> configure( -ftp => $ftp,
		      -connected => '1');
  } else {
    my $edlg = $cw -> Subwidget( 'errormessage' );
    $edlg -> configure( -text => "Error: Could not login to $hostid\." );
    $edlg -> Show;
    $cw -> configure( -ftp => $ftp,
		      -connected => '');
  }
  return $ftp;
}

sub Accept {

    # Accept the file or directory name if possible.
    my ($cw) = @_;

    my($path, $so) = ($cw->cget('-directory'), $cw->SelectionOwner);
    my $ftp = $cw -> cget( -ftp );
    my $leaf = undef;
    my $leaves;

    if (defined $so and
          $so == $cw->Subwidget('dir_list')->Subwidget('listbox')) {
        $leaves = [$cw->Subwidget('dir_list')->getSelected];
        $leaves = [$cw->Subwidget('dir_entry')->get] if !scalar(@$leaves);
    } else {
        $leaves = [$cw->Subwidget('file_list')->getSelected];
        $leaves = [$cw->Subwidget('file_entry')->get] if !scalar(@$leaves);
    }

    foreach $leaf (@$leaves)
    {
      if (defined $leaf and $leaf ne '') {
        if (!$cw->cget('-create') || -e "$path/$leaf")
         {
          foreach (@{$cw->cget('-verify')}) {
              my $r = ref $_;
              if (defined $r and $r eq 'ARRAY') {
                  #local $_ = $leaf; # use strict var problem here
                  return if not &{$_->[0]}($cw, $path, $leaf, @{$_}[1..$#{$_}]);
              } else {
                  my $s = eval "$_ '$path/$leaf'";
                  print $@ if $@;
                  if (not $s) {
                      my $err;
                      if (substr($_,0,1) eq '!')
                       {
                        my $t = substr($_,1);
                        if (exists $error_text{$t})
                         {
                          $err = $error_text{$t};
                          $err =~ s/\b(?:no|not) //;
                         }
                       }
                      $err = $error_text{$_} unless defined $err;
                      $err = "failed '$_' test" unless defined $err;
                      $cw->Error("'$leaf' $err.");
                      return;
                  }
              }
          } # forend
         }
        else
         {
          unless (-w $path)
           {
            $cw->Error("Cannot write to $path");
            return;
           }
         }
	if( ( $cw -> cget( -connected ) ) eq '1' ) {
	  $path = $ftp -> pwd;
	  $leaf = ($cw -> cget( -hostname ) ).":$path/$leaf";
	} else {
	  $leaf = $path . '/' . $leaf;
	}
      } else {
        $leaf =  undef;
      }
    }
    if (scalar(@$leaves))
    {
      my $sm = $cw->Subwidget('file_list')->cget(-selectmode);
      $cw->{Selected} = $leaves;
      my $command = $cw->cget('-command');
      $command->Call(@{$cw->{Selected}}) if defined $command;
    }
} # end Accept

sub Accept_dir
{
 my ($cw,$new) = @_;
 my $dir  = $cw->cget('-directory');
 $cw -> SelectionClear;
 $cw->configure(-directory => "$dir/$new");
}

sub Populate {

    my ($w, $args) = @_;

    require Tk::Listbox;
    require Tk::Button;
    require Tk::Dialog;
    require Tk::DialogBox;
    require Tk::Toplevel;
    require Tk::LabEntry;
    require Cwd;

    my $havenet;
    $havenet = 1 if &requirecond( "Net::FTP" );

    $w->SUPER::Populate($args);
    $w->protocol('WM_DELETE_WINDOW' => ['Cancel', $w ]);

    $w->{'reread'} = 0;
    $w->withdraw;

    # Create directory/filter entry, place at the top.
    my $e = $w->Component(
        LabEntry       => 'dir_entry',
        -textvariable  => \$w->{DirectoryString},
        -labelVariable => \$w->{Configure}{-dirlabel},
    );
    $e->pack(-side => 'top', -expand => 0, -pady => 5, -padx => 5,
	     -fill => 'x');
    $e->bind('<Return>' => [$w => 'validateDir', Ev(['get'])]);

    # Create file entry, place at the bottom.
    $e = $w->Component(
        LabEntry       => 'file_entry',
        -textvariable => \$w->{Configure}{-initialfile},
        -labelVariable => \$w->{Configure}{-filelabel},
    );
    $e->pack(-side => 'bottom', -expand => 0, -pady => 5, -padx => 5,
	     -fill => 'x');
    $e->bind('<Return>' => [$w => 'validateFile', Ev(['get'])]);

    # Create directory scrollbox, place at the left-middle.
    my $b = $w->Component(
        ScrlListbox    => 'dir_list',
        -labelVariable => \$w->{Configure}{-dirlistlabel},
        -scrollbars    => 'se',
    );
    $b -> Subwidget('yscrollbar') -> configure(-width=>10);
    $b -> Subwidget('xscrollbar') -> configure(-width=>10);
    $b->pack(-side => 'left', -expand => 1, -fill => 'both');
    $b->bind('<Double-Button-1>' => [$w => 'Accept_dir', Ev(['getSelected'])]);

    # Add a label.

    my $f = $w->Frame();
    $f->pack(-side => 'right', -fill => 'y', -expand => 0);
    $b = $f->Button('-textvariable' => \$w->{'Configure'}{'-acceptlabel'},
		    -underline => 0,
		     -command => [ 'Accept', $w ],
    );
    $w -> bind( '<Alt-a>', [$w => 'Accept', Ev(['getSelected'])]);

    $b->pack(-side => 'top', -fill => 'x', -expand => 1);
    $b = $f->Button('-textvariable' => \$w->{'Configure'}{'-hostlabel'},
		    -underline => 0,
		     -command => [ 'host', $w ],
		    -state => ($havenet?'normal':'disabled')
    );
    $w -> bind( '<Alt-h>', [$w => 'host', $w]);
    $b->pack(-side => 'top', -fill => 'x', -expand => 1);
    $b = $f->Button('-textvariable' => \$w->{'Configure'}{'-cancellabel'},
		    -underline => 0,
		     -command => [ 'Cancel', $w ],
    );
    $w -> bind( '<Alt-c>', [$w => 'Cancel', $w]);
    $b->pack(-side => 'top', -fill => 'x', -expand => 1);
    $b = $f->Button('-textvariable'  => \$w->{'Configure'}{'-resetlabel'},
		    -underline => 0,
		     -command => [$w => 'configure','-directory','.'],
    );
    $w -> bind( '<Alt-r>', [$w => 'configure','-directory','.']);
    $b->pack(-side => 'top', -fill => 'x', -expand => 1);
    $b = $f->Button('-textvariable'  => \$w->{'Configure'}{'-homelabel'},
		    -underline => 2,
                     -command => [$w => 'configure','-directory',$ENV{'HOME'}],
    );
    $w -> bind( '<Alt-m>', [$w => 'configure','-directory',$ENV{'HOME'}]);
    $b->pack(-side => 'top', -fill => 'x', -expand => 1);

    # Create file scrollbox, place at the right-middle.

    $b = $w->Component(
        ScrlListbox    => 'file_list',
        -labelVariable => \$w->{Configure}{-filelistlabel},
        -scrollbars    => 'se'
    );
    $b -> Subwidget('yscrollbar') -> configure(-width=>10);
    $b -> Subwidget('xscrollbar') -> configure(-width=>10);
    $b->pack(-side => 'right', -expand => 1, -fill => 'both');
    $b->bind('<Double-1>' => [$w => 'Accept']);

    # Create -very dialog.

    my $v = $w->Component(
        Dialog   => 'dialog',
        -title   => 'Verify Error',
        -bitmap  => 'error',
        -buttons => ['Dismiss'],
    );

    # Host dialog
    my $h = $w -> Component(
			     DialogBox => 'hostdialog',
			     -title => 'Select Remote Host',
			     -buttons => [ 'Ok', 'Cancel' ] );
    $h -> Component( Label => 'toplabel',
		     -text => "Enter Name or IP Address of Remote Host:" )
      -> pack( -expand => '1', -fill => 'x' );
    $h -> Component( Entry => 'hostentry',
        -textvariable => \$w -> {'Configure'}{'-hostname'},
    ) -> pack( -expand => '1', -fill => 'x' );

    $h -> Component( Checkbutton => 'transcriptbutton',
		     -text => 'Log Session on Terminal.',
		     -variable => \$w -> {'Configure'}{'-transcript'})
      -> pack( -anchor => 'w' );

    # login user/password dialog
    my $l = $w -> Component(
			     DialogBox => 'logindialog',
			     -title => 'Login',
			     -buttons => [ 'Ok', 'Cancel' ] );
    $l -> Component( Label => 'useridlabel',
		      -text => 'Please enter your User ID and Password:'
		      ) -> pack( -expand => '1', -fill => 'x' );
    $l -> Component ( LabEntry => 'uidentry', 
		      -labelVariable => \$w -> {'Configure'}{'-uidlabel'} )
      -> pack( -anchor => 'w', -expand => '1', -fill => 'x' );
    $l -> Component( LabEntry => 'pwdentry', 
		     -labelVariable => \$w -> {'Configure'}{'-pwdlabel'},
		     -show => '*' )
      -> pack( -anchor => 'w', -expand => '1', -fill => 'x' );

    my $l = $w -> Component( Dialog => 'errormessage',
			      -title =>  "Network Error",
			     -font => $menufont,
			     -bitmap => 'error' );

    $w->ConfigSpecs(
		    -width            => [ ['file_list','dir_list'], undef, undef, 14 ],
        -height           => [ ['file_list','dir_list'], undef, undef, 14 ],
        -directory        => [ 'METHOD', undef, undef, '.' ],
        -initialdir       => '-directory',
        -filelabel        => [ 'PASSIVE', 'fileLabel', 'FileLabel', 
			       'File Name:' ],
        -initialfile      => [ 'PASSIVE', undef, undef, '' ],
        -filelistlabel    => [ 'PASSIVE', undef, undef, 'Files' ],
        -filter           => [ 'METHOD',  undef, undef, undef ],
	-hostname         => [ 'PASSIVE', undef, undef, '' ],
	-transcript       => [ 'PASSIVE', undef, undef, '' ],
	-userid           => [ 'PASSIVE', undef, undef, '' ],
	-ftp              => [ 'PASSIVE', undef, undef, undef ],
	-networkerror     => [ 'PASSIVE', undef, undef, undef ],
	-password         => [ 'PASSIVE', undef, undef, '' ],
        -defaultextension => [ 'METHOD',  undef, undef, undef ],
        -regexp           => [ 'METHOD', undef, undef, undef ],
        -dirlistlabel     => [ 'PASSIVE', undef, undef, 'Directories'],
        -dirlabel         => [ 'PASSIVE', undef, undef, 'Directory:'],
        '-accept'         => [ 'CALLBACK',undef,undef, undef ],
        -command          => [ 'CALLBACK',undef,undef, undef ],
        -transient        => [ 'PASSIVE', undef, undef, 1 ],
        -verify           => [ 'PASSIVE', undef, undef, ['!-d'] ],
        -create           => [ 'PASSIVE', undef, undef, 0 ],
        -acceptlabel      => [ 'PASSIVE', undef, undef, 'Accept'],
        -hostlabel        => [ 'PASSIVE', undef, undef, 'Host'],
        -cancellabel      => [ 'PASSIVE', undef, undef, 'Cancel'],
        -resetlabel       => [ 'PASSIVE', undef, undef, 'Reset'],
        -homelabel        => [ 'PASSIVE', undef, undef, 'Home'],
	-uidlabel         => ['PASSIVE', undef, undef, 'User ID:'],
	-pwdlabel         => ['PASSIVE', undef, undef, 'Password:'],
	-connected        => ['PASSIVE', undef, undef, '' ],
        DEFAULT           => [ 'file_list' ],
    );
    $w->Delegates(DEFAULT => 'file_list');

    return $w;

} # end Populate

sub translate
  {
      my ($bs,$ch) = @_;
      return "\\$ch" if (length $bs);
      return '.*'  if ($ch eq '*');
 return '.'   if ($ch eq '?');
 return "\\."  if ($ch eq '.');
 return "\\/" if ($ch eq '/');
 return "\\\\" if ($ch eq '\\');
 return $ch;
}

sub glob_to_re
{
 my $regex = shift;
 $regex =~ s/(\\?)(.)/&translate($1,$2)/ge;
 return sub { shift =~ /^${regex}$/ };
}

sub filter
{
 my ($cw,$val) = @_;
 my $var = \$cw->{Configure}{'-filter'};
 if (@_ > 1 || !defined($$var))
  {
   $val = '*' unless defined $val;
   $$var = $val;
   $cw->{'match'} = glob_to_re($val)  unless defined $cw->{'match'};
   unless ($cw->{'reread'}++)
    {
     $cw->Busy;
     if( ( $cw -> cget( '-connected' ) ) =~ /1/ ) {
       $cw->afterIdle(['rereadRemote',$cw,$cw->cget('-directory')])
     } else {
       $cw->afterIdle(['reread',$cw,$cw->cget('-directory')])
     }
    }
  }
 return $$var;
}

sub regexp
{
 my ($cw,$val) = @_;
 my $var = \$cw->{Configure}{'-regexp'};
 if (@_ > 1)
  {
   $$var = $val;
   $cw->{'match'} = sub { shift =~ m|^${val}$| };
   unless ($cw->{'reread'}++)
    {
     $cw->Busy;
     $cw->afterIdle(['reread',$cw])
    }
  }
 return $$var;
}

sub defaultextension
{
 my ($cw,$val) = @_;
 if (@_ > 1)
  {
   $val = ".$val" if ($val !~ /^\./);
   $cw->filter("*$val");
  }
 else
  {
   $val = $cw->filter;
   my ($ext) = $val =~ /(\.[^\.]*)$/;
   return $ext;
  }
}

sub remoteDirectory {
  my ($cw, $dir) = @_;
  return if ( ($cw -> cget( -connected ) ) ne '1' );
  my $ftp = $cw -> cget( -ftp );
  return if( ! $ftp );
  my $current = $ftp -> pwd;
  my $ndir;
  if( @_ > 1 && defined $dir ) {
    if( $current eq $dir ) {
      $cw->{Configure}{'-directory'} = "$dir";
      $cw -> rereadRemote;
      return;
    }
    if( ! $ftp -> cwd( "$current/$dir" ) ) {
      $cw -> error( "Cannot cwd to $current/$dir." );
      $cw -> rereadRemote;
      return;
    }
    $ndir = $ftp -> pwd;
    $cw->{Configure}{'-directory'} = "$ndir";
    $cw -> rereadRemote;
  }
}

sub directory
{
 my ($cw,$dir) = @_;
 if( ( $cw -> cget( '-connected' ) ) =~ /1/ ) {
   $cw -> remoteDirectory( $dir );
   return $dir;
 }
 my $var = \$cw->{Configure}{'-directory'};
 if (@_ > 1 && defined $dir)
  {
   if (substr($dir,0,1) eq '~')
    {
     if (substr($dir,1,1) eq '/')
      {
       $dir = $ENV{'HOME'} . substr($dir,1);
      }
     else
      {my ($uid,$rest) = ($dir =~ m#^~([^/]+)(/.*$)#);
       $dir = (getpwnam($uid))[7] . $rest;
      }
    }
   $dir =~ s#([^/\\])[\\/]+$#$1#;
   if (-d $dir)
    {
     unless (Tk::tainting())
      {
       my $pwd = Cwd::getcwd();
       if (chdir( (defined($dir) ? $dir : '') ) )
        {
         my $new = Cwd::getcwd();
         if ($new)
          {
           $dir = $new;
          }
         else
          {
           carp "Cannot getcwd in '$dir'";
          }
         chdir($pwd) || carp "Cannot chdir($pwd) : $!";
         $cw->{Configure}{'-directory'} = $dir;
        }
       else
        {
         $cw->BackTrace("Cannot chdir($dir) :$!");
        }
      }
     $$var = $dir;
     unless ($cw->{'reread'}++)
      {
       $cw->Busy;
       $cw->afterIdle(['reread',$cw])
      }
    }
  }
 return $$var;
}

sub rereadRemote {
  my $w = shift;
  if( ( $w -> cget( -connected ) ) eq '1' ) {
     $w -> Busy;
     my ($name, $filter);
     my $dl = $w->Subwidget('dir_list');
     $dl->delete(0, 'end');
     my $fl = $w->Subwidget('file_list');
     $fl->delete(0, 'end');
     my $ftp = $w -> cget( -ftp );
     my $dir = $ftp -> pwd;
     my @files = $ftp -> dir;
     $dl -> insert( 'end', '..' );
     foreach my $f ( @files ) {
       next if $f =~ /^total/;
       $name = $f;
       if ( $f =~ /^l/ ) {
	 $name =~ s/.* (.*) \-\> .*/\1/; 
       } else {
	 $name =~ s/.* //;
       }
       if( $f =~ /^d/ ) {
	 $dl -> insert( 'end', $name );
       } else { 
	 $fl -> insert( 'end', $name );
       }
     }
     my $host = $w -> cget( '-hostname' );
     $w -> {DirectoryString} = "$host\:$dir" . '/' . $w -> cget( '-filter' );
     $w -> Unbusy;
   }
}

sub reread
{
 my ($w) = @_;
 my $dir = $w->cget('-directory');
 if (defined $dir)
  {
   if (!defined $w->cget('-filter') or $w->cget('-filter') eq '')
    {
     $w->configure('-filter', '*');
    }
   my $dl = $w->Subwidget('dir_list');
   $dl->delete(0, 'end');
   my $fl = $w->Subwidget('file_list');
   $fl->delete(0, 'end');
   local *DIR;
   my $h;
   if( ( $w -> cget( -connected ) ) eq '1' ) {
     return $w -> rereadRemote( $dir ); 
   } else {  # ! $w -> connected
     if (opendir(DIR, $dir)) 
       {
	 my $file = $w->cget('-initialfile');
	 my $seen = 0;
	 my $accept = $w->cget('-accept');
	 foreach my $f (sort(readdir(DIR)))
	   {
	     next if ($f eq '.');
	     my $path = "$dir/$f";
	     if (-d $path)
	       {
		 $dl->insert('end', $f);
	       }
	     else
	       {
		 if (&{$w->{match}}($f))
		   {
		     if (!defined($accept) || $accept->Call($path))
		       {
			 $seen = $fl->index('end') if ($file && $f eq $file);
			 $fl->insert('end', $f)
		       }
		   }
	       }
	   }
	 closedir(DIR);
	 if ($seen)
	   {
	     $fl->selectionSet($seen);
	     $fl->see($seen);
	   }
	 else
	   {
	     $w->configure(-initialfile => undef) unless $w->cget('-create');
	   }
       }
     $w->{DirectoryString} = $dir . '/' . $w->cget('-filter');
   }
   $w->{'reread'} = 0;
   $w->Unbusy;
 }
}

sub validateDir
{
 my ($cw,$name) = @_;
 if( ( $cw -> cget( '-connected' ) ) =~ /1/ ) {
   $name =~ s/^.*\://;
 }
 my ($leaf,$base) = fileparse($name);
 if ($leaf =~ /[*?]/)
  {
   $cw->configure('-directory' => $base,'-filter' => $leaf);
  }
 else
  {
   $cw->configure('-directory' => $name);
  }
}

sub validateFile
{
 my ($cw,$name) = @_;
 my $i = 0;
 my $n = $cw->index('end');
 # See if it is an existing file
 for ($i= 0; $i < $n; $i++)
  {
   my $f = $cw->get($i);
   if ($f eq $name)
    {
     $cw->selection('set',$i);
     $cw->Accept;
    }
  }
 # otherwise allow if -create is set, directory is writable
 # and it passes filter and accept criteria
 if ($cw->cget('-create'))
  {
   my $path = $cw->cget('-directory');
   if (-w $path)
    {
     if (&{$cw->{match}}($name))
      {
       my $accept = $cw->cget('-accept');
       my $full   = "$path/$name";
       if (!defined($accept) || $accept->Call($full))
        {
         $cw->{Selected} = [$full];
         $cw->Callback(-command => @{$cw->{Selected}});
        }
       else
        {
         $cw->Error("$name is not 'acceptable'");
        }
      }
     else
      {
       $cw->Error("$name does not match '".$cw->cget('-filter').'\'');
      }
    }
   else
    {
     $cw->Error("Directory '$path' is not writable");
     return;
    }
  }
}

sub Error
{
 my $cw  = shift;
 my $msg = shift;
 my $dlg = $cw->Subwidget('dialog');
 $dlg->configure(-text => $msg);
 $dlg->Show;
}

sub Show
{
 my ($cw,@args) = @_;
 if ($cw->cget('-transient')) {
   $cw->Popup(@args);
   $cw->focus;
   $cw->waitVariable(\$cw->{Selected});
   $cw->withdraw;
   return defined($cw->{Selected})
     ? (wantarray) ? @{$cw->{Selected}} : $cw->{Selected}[0]
       : undef;
 } else {
   $cw->Popup(@args);
 }
}

sub FDialog
{
 my($cmd, %args) = @_;
 if ($cmd =~ /Save/)
  {
   $args{-create} = 1;
   $args{-verify} = [qw(!-d -w)];
  }
 delete $args{-filetypes};
 delete $args{-force};
 Tk::DialogWrapper('FileSelect',$cmd, %args);
}

sub requirecond {
  my ($modulename) = @_;
  my ($filename, $fullname, $result);
  $filename = $modulename;
  $filename .= '.pm' if $filename !~ /.pm$/;
  $filename =~ s/\:\:/\//;
  foreach my $prefix ( @INC ) {
    $fullname = "$prefix/$filename";
    if( -f $fullname ) { return do $fullname; }
  }
  return 0;
}

1;

__END__


