# -*- perl -*-

use strict;

use Wizard::State ();
use Wizard::SaveAble ();
use Wizard::Examples::Apache ();
use Wizard::Examples::Apache::Host ();
use Wizard::Examples::Apache::Server ();
use Wizard::Examples::Apache::VirtualServer ();
use Wizard::Examples::Apache::Config ();


package Wizard::Examples::Apache::Directory;

@Wizard::Examples::Apache::Directory::ISA     = qw(Wizard::Examples::Apache::VirtualServer);
$Wizard::Examples::Apache::Directory::VERSION = '0.01';


sub createDefault {
    my $self = shift || die "Missing state";
    my $sbasedir = shift || die "Missing basedir of virtualserver";
    my $name = '_';

    my $dirc = bless({'apache-directory-name' => $name,
	             'apache-directory-pathname' => '/',
		     'apache-directory-user' => 'www',
		     'apache-directory-group' => 'www',
		     'apache-directory-isdefault' => 1},
		    'Wizard::SaveAble');
    my $file = File::Spec->catfile($sbasedir, "$name.cfg");
    my $dir = File::Spec->catdir($sbasedir, $name);
    File::Path::mkpath([$dir],0, 0777);
    die "Couldn't create directory $dir: $!" unless -d $dir;
    $dirc->CreateMe(1);
    $dirc->File($file);
    $dirc->Modified(1);
    $self->{'directory'} = $dirc;
}

sub GetKey { 'directory'; };

sub init {
    my $self = shift; 
    return $self->SUPER::init(1) unless shift;
    my $item = $self->{'directory'} || die "Missing directory";
    ($self->SUPER::init(1), $item);
}

sub _superFileDir {
    Wizard::Examples::Apache::Host::getFileDir(shift, shift, 
					       'Wizard::Examples::Apache::VirtualServer');
}

sub ShowMe {
    my ($self, $wiz, $dir) = @_;
    (['Wizard::Elem::Title',
      'value' => $dir->CreateMe() ?
          'Apache Wizard: Create directory configuration' :
          'Apache Wizard: Edit an existing directory configuration'],
     ['Wizard::Elem::Text', 'name' => 'apache-directory-pathname',
      'value' => $dir->{'apache-directory-pathname'} || '/tmp',
      'descr' => 'Directory pathname (root is the virtualserver root)'],
     ['Wizard::Elem::Text', 'name' => 'apache-directory-redirecturl',
      'value' => $dir->{'apache-directory-redirecturl'} || '',
      'descr' => 'Directory redirect url (if any)' ],
     ['Wizard::Elem::Text', 'name' => 'apache-directory-user',
      'value' => $dir->{'apache-directory-user'} || 'www',
      'descr' => 'User who owns that directory'],
     ['Wizard::Elem::Text', 'name' => 'apache-directory-group',
      'value' => $dir->{'apache-directory-group'} || 'www',
      'descr' => 'Group that owns that directory'],
     ['Wizard::Elem::BR'],
     ['Wizard::Elem::Submit', 'name' => 'Action_DirectorySave',
      'value' => 'Save these settings', 'id' => 1],
     ['Wizard::Elem::Submit', 'value' => 'Return to Directory Menu',
      'name' => 'Wizard::Examples::Apache::VirtualServer::Action_Reset',
      'id' => 94],
     ['Wizard::Elem::Submit', 'value' => 'Return to Virtual WWW Server Menu',
      'name' => 'Wizard::Examples::Apache::VirtualServer::Action_Reset',
      'id' => 95],
     ['Wizard::Elem::Submit', 'value' => 'Return to Server Menu',
      'name' => 'Wizard::Examples::Apache::Server::Action_Reset',
      'id' => 96],
     ['Wizard::Elem::Submit', 'value' => 'Return to Host Menu',
      'name' => 'Wizard::Examples::Apache::Host::Action_Reset',
      'id' => 97],
     ['Wizard::Elem::Submit', 'value' => 'Return to Top Menu',
      'name' => 'Wizard::Examples::Apache::Action_Reset',
      'id' => 98],
     ['Wizard::Elem::Submit', 'value' => 'Exit Apache Wizard',
      'id' => 99]);

}

sub Action_Enter {
    my($self, $wiz) = @_;
    $self->SUPER::Load($wiz, 'Wizard::Examples::Apache::VirtualServer'); 
    $self->Action_Reset($wiz);
}

sub Action_Reset {
    my($self, $wiz) = @_;
    my($prefs, $basedir, $host, $server, $vserver) = $self->init();
    
    delete $self->{'directory'};
    $self->Store($wiz);
    (['Wizard::Elem::Title', 'value' => 'Apache Wizard Directory Configuration Menu'],
     ['Wizard::Elem::Submit', 'value' => 'Create a new Directory Config.',
      'name' => 'Action_CreateDirectory',
      'id' => 1],
     ['Wizard::Elem::Submit', 'value' => 'Modify an existing Directory Config.',
      'name' => 'Action_ModifyDirectory',
      'id' => 2],
#     ['Wizard::Elem::Submit', 'value' => 'Manage password protection of directories.',
#      'name' => 'Action_DirectoryMenu',
#      'id' => 3],
     ['Wizard::Elem::Submit', 'value' => 'Delete an existing directory Config.',
      'name' => 'Action_DeleteDirectory',
      'id' => 4],
     ['Wizard::Elem::BR'],
     ['Wizard::Elem::Submit', 'value' => 'Return to Virtual WWW Server Menu',
      'name' => 'Wizard::Examples::Apache::VirtualServer::Action_Reset',
      'id' => 95],
     ['Wizard::Elem::Submit', 'value' => 'Return to Server Menu',
      'name' => 'Wizard::Examples::Apache::Server::Action_Reset',
      'id' => 96],
     ['Wizard::Elem::Submit', 'value' => 'Return to Host Menu',
      'name' => 'Wizard::Examples::Apache::Host::Action_Reset',
      'id' => 97],
     ['Wizard::Elem::Submit', 'value' => 'Return to Top Menu',
      'name' => 'Wizard::Examples::Apache::Action_Reset',
      'id' => 98],
     ['Wizard::Elem::Submit', 'value' => 'Exit Apache Wizard',
      'id' => 99]);    
}

*Action_CreateDirectory = \&Wizard::Examples::Apache::Host::Action_CreateItem;

sub Action_DirectorySave {
    my($self, $wiz) = @_;
    my ($prefs, $basedir, $host, $server, $vserver, $dirc) = $self->init(1);
    
    my $old_name = $dirc->{'apache-directory-name'};
    foreach my $opt ($wiz->param()) {
	$dirc->{$opt} = $wiz->param($opt) 
	    if (($opt =~ /^apache\-directory/) && (defined($wiz->param($opt))));
    }

    # Verify the settings
    my $errors = '';
    my $pname = $dirc->{'apache-directory-pathname'} || die "Missing directory pathname";
    my $redirect = $dirc->{'apache-directory-redirecturl'};
    my $name = $pname;
    $name =~ s/\//\_/g;
    $dirc->{'apache-directory-name'} = $name;
    my $user='';
    if ($redirect) {
	$user = $dirc->{'apache-directory-user'} 
	      || die "Missing user.\n" ;
    }
    my ($file, $dir, $odir) = $self->getFileDir();
    if($dirc->CreateMe() or $old_name ne $name) {
	$errors .= "A directory $pname already exists: $file.\n" if -e $file;
	$errors .= "A directory $pname already exists: $dir.\n" if -e $dir;
    }
    die $errors if $errors;

    if(!$dirc->CreateMe() and $name ne $old_name) {
	my $old_file = File::Spec->catfile($odir, "$old_name.cfg");
	my $old_dir = File::Spec->catdir($odir, $old_name);
	rename($old_file, $file) 
	    or die "Failed to rename $old_file to $file: $!";
	rename($old_dir, $dir) 
	    or die "Failed to rename $old_dir to $dir: $!";
    }
    $dirc->File($file);
    if ($dirc->CreateMe()) {
        File::Path::mkpath([$dir], 0, 0777);
	die "Couldn't create directory $dir" unless -d $dir;
    }
    $dirc->Modified(1);
    $self->Store($wiz, 1);
    $self->Action_Reset($wiz);
}

sub Action_EditDirectory {
   my($self, $wiz) = @_; 
   my $name = $wiz->param('apache-directory') || die "Missing directory name";
   $name =~ s/\//\_/g;
   $wiz->param('apache-directory', $name);
   $self->Action_EditItem($wiz);
} 

sub ItemList {
    my $self = shift;  my $basedir = shift;
    my $fh = Symbol::gensym();
    opendir($fh, $basedir) || die "Failed to open directory $basedir: $!";
    my @items = map { if((/^(.*)\.cfg$/  and  
			  -f File::Spec->catfile($basedir, $_))) {
	                  $a = $1; $a =~ s/\_/\//g;
			  $a;
		      } else { 
			  ();
		      }
		  } readdir($fh);
    closedir($fh);
    @items;
}


sub Action_ModifyDirectory {
    shift->Action_ModifyItem(shift, shift || 'Modify Directory configuration',
			     shift || 'Action_EditDirectory',
			     'Directory configuration');
}

sub Action_DeleteDirectory {
    shift->Action_ModifyServer(shift, 'Delete this directory', 
			       'Action_DeleteDirectory2'); 
}

sub Action_DeleteDirectory2 {
    my($self, $wiz) = @_;
    my ($prefs, $basedir, $host, $server, $vserver) = $self->init();
    my $name = $wiz->param('apache-directory') || die "Missing directory name";
    $name =~ s/\//\_/g;
    $wiz->param('apache-directory', $name);   
    $self->Load($wiz);
    my $dirc = $self->{'dir'};
    my ($file, $dir) = $self->getFileDir();

    if ($dirc->{'apache-directory-isdefault'}) {
	return (['Wizard::Elem::Data', 'descr' => 'ERROR: ', 
		 'value' => 'Root directory can not be deleted'], 
		$self->Action_Reset($wiz));
    }	    

    (['Wizard::Elem::Title', 'value' => 'Deleting an Apache Directory configuration'],
     ['Wizard::Elem::Data', 'descr' => 'Directory path',
      'value' => $dirc->{'apache-directory-pathname'}],
     ['Wizard::Elem::Data', 'descr' => 'Directory owning user',
      'value' => $dirc->{'apache-directory-user'}],
     ['Wizard::Elem::Data', 'descr' => 'Server root',
      'value' => $dirc->{'apache-server-root'}],
     ['Wizard::Elem::Data', 'descr' => 'Directory owning group',
      'value' => $dirc->{'apache-directory-group'}],
     ['Wizard::Elem::Submit', 'value' => 'Yes, delete it',
      'id' => 1, 'name' => 'Action_DeleteDirectory3'],
     (-d $dir ? ['Wizard::Elem::Submit',
		 'value' => 'Yes, delete it, including data directory',
		 'id' => 2, 'name' => 'Action_DeleteDirectory4'] : ()),
     ['Wizard::Elem::BR'],
     ['Wizard::Elem::Submit', 'value' => 'Return to Directory Menu',
      'name' => 'Wizard::Examples::Apache::VirtualServer::Action_Reset',
      'id' => 94],
     ['Wizard::Elem::Submit', 'value' => 'Return to Virtual WWW Server Menu',
      'name' => 'Wizard::Examples::Apache::VirtualServer::Action_Reset',
      'id' => 95],
     ['Wizard::Elem::Submit', 'value' => 'Return to Server Menu',
      'name' => 'Wizard::Examples::Apache::Server::Action_Reset',
      'id' => 96],
     ['Wizard::Elem::Submit', 'value' => 'Return to Host Menu',
      'name' => 'Wizard::Examples::Apache::Host::Action_Reset',
      'id' => 97],
     ['Wizard::Elem::Submit', 'value' => 'Return to Top Menu',
      'name' => 'Wizard::Examples::Apache::Action_Reset',
      'id' => 98],
     ['Wizard::Elem::Submit', 'value' => 'Exit Apache Wizard',
      'id' => 99]);
}

sub Action_DeleteDirectory3 {
    my($self, $wiz) = @_;
    $self->DeleteItem($wiz);
    $self->Action_Reset($wiz);
}

sub Action_DeleteDirectory4 {
    my($self, $wiz) = @_;
    $self->DeleteItem($wiz,1);
    $self->Action_Reset($wiz);
}


