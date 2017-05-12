# -*- perl -*-

use strict;

use Wizard::State ();
use Wizard::SaveAble ();
use Wizard::Examples::Apache::Host ();
use Wizard::Examples::Apache::VirtualServer ();
use Wizard::Examples::Apache::Directory ();
use File::Spec ();
use File::Path ();
use Socket ();
use Symbol ();


package Wizard::Examples::Apache::Server;

@Wizard::Examples::Apache::Server::ISA = qw(Wizard::Examples::Apache::Host);
$Wizard::Examples::Apache::Server::VERSION = '0.01';


sub init {
    my $self = shift; 
    return $self->SUPER::init(1) unless shift;
    my $item = $self->{'server'} || die "Missing server";
    ($self->SUPER::init(1), $item);
}

sub GetKey { 'server';};


sub _superFileDir {
    Wizard::Examples::Apache::Host::getFileDir(shift, shift, 
					       'Wizard::Examples::Apache::Host');
}

sub ShowMe {
    my($self, $wiz, $server) = @_;
    my $hname = $self->{'host'}->{'apache-host-name'};
    my $uwdir = File::Spec->catdir(File::Spec->rootdir(), 'usr','local', 'www');
    (['Wizard::Elem::Title',
      'value' => $server->CreateMe() ?
          'Apache Wizard: Create new server' :
          'Apache Wizard: Edit an existing server'],
     ['Wizard::Elem::Text', 'name' => 'apache-server-name',
      'value' => $server->{'apache-server-name'},
      'descr' => 'Server descriptive name'],
     ['Wizard::Elem::Text', 'name' => 'apache-server-ip',
      'value' => $server->{'apache-server-ip'} || $hname,
      'descr' => 'Server DNS name or ip adress'],
     ['Wizard::Elem::Text', 'name' => 'apache-server-vserver-root',
      'value' => $server->{'apache-server-vserver-root'} || 
                 $uwdir,
      'descr' => 'Default directory for the VirtualServer root dirs'],
#     ['Wizard::Elem::Text', 'name' => 'apache-server-root',
#      'value' => $server->{'apache-server-root'} || 
#                 File::Spec->catfile($uwdir, $hname),
#      'descr' => 'Server root directory'],
     ['Wizard::Elem::Text', 'name' => 'apache-server-admin',
      'value' => $server->{'apache-server-admin'} || 
                 "webmaster\@$hname",
      'descr' => 'Server administrator'],
     ['Wizard::Elem::Text', 'name' => 'apache-server-http-port',
      'value' => $server->{'apache-server-http-port'} || '80',
      'descr' => 'Server HTTP port'],
     ['Wizard::Elem::Text', 'name' => 'apache-server-https-port',
      'value' => $server->{'apache-server-https-port'} || '443',
      'descr' => 'Server HTTPS port'],
#     ['Wizard::Elem::Text', 'name' => 'apache-server-index',
#      'value' => $server->{'apache-server-index'},
#      'descr' => 'Server DirectoryIndex'],
#     ['Wizard::Elem::Text', 'name' => 'apache-server-options',
#      'value' => $server->{'apache-server-options'},
#      'descr' => 'Server Options'],
     ['Wizard::Elem::Submit', 'name' => 'Action_ServerSave',
      'value' => 'Save these settings',
      'id' => '1'],
     ['Wizard::Elem::BR'],
     ['Wizard::Elem::Submit', 'name' => 'Action_Reset',
      'value' => 'Return to Server menu ',
      'id' => '97'],
     ['Wizard::Elem::Submit', 'name' => 'Wizard::Examples::Apache::Host::Action_Reset',
      'value' => 'Return to Host menu ',
      'id' => '97'],
     ['Wizard::Elem::Submit', 'value' => 'Return to Top Menu',
      'name' => 'Wizard::Examples::Apache::Action_Reset',
      'id' => 98],
     ['Wizard::Elem::Submit', 'value' => 'Exit Apache Wizard',
      'id' => 99]);
}

sub Action_Enter {
    my($self, $wiz) = @_;
    $self->Load($wiz, 'Wizard::Examples::Apache::Host'); 
    $self->Action_Reset($wiz);
}

sub Action_Reset {
    my $self = shift; my $wiz=shift;
    my($prefs, $basedir, $host) = $self->init();
    delete $self->{'server'};
    $self->Store($wiz);

    # Return the initial menu.
    (['Wizard::Elem::Title', 'value' => 'Apache Wizard Server Menu'],
     ['Wizard::Elem::Submit', 'value' => 'Create a new server',
      'name' => 'Action_CreateServer', 'id' => 1],
     ['Wizard::Elem::Submit', 'value' => 'Modify an existing server',
      'name' => 'Action_ModifyServer', 'id' => 2],
     ['Wizard::Elem::Submit', 'value' => 'Virtual Server Menu',
      'name' => 'Action_VServerMenu', 'id' => 3],
     ['Wizard::Elem::Submit', 'value' => 'Delete an existing server',
      'name' => 'Action_DeleteServer',
      'id' => 4],
     ['Wizard::Elem::BR'],
     ['Wizard::Elem::Submit', 'value' => 'Return to Top Menu',
      'name' => 'Wizard::Examples::Apache::Action_Reset',
      'id' => 97],
     ['Wizard::Elem::Submit', 'value' => 'Return to Host Menu',
      'name' => 'Wizard::Examples::Apache::Host::Action_Reset',
      'id' => 98],
     ['Wizard::Elem::Submit', 'value' => 'Exit Apache Wizard',
      'id' => 99]);
}

*Action_CreateServer = \&Wizard::Examples::Apache::Host::Action_CreateItem;

sub Action_ServerSave {
    my($self, $wiz) = @_;
    my($prefs, $basedir, $host, $server) = $self->init(1);
    $self->init(1);
    my $hname = $host->{'apache-host-name'};
    
    my $old_name = $server->{'apache-server-name'};
    foreach my $opt ($wiz->param()) {
	$server->{$opt} = $wiz->param($opt) 
	    if (($opt =~ /^apache\-server/) && (defined($wiz->param($opt))));
    }
    
    # Verify the new settings
    my $errors = '';
    my $name = $server->{'apache-server-name'}
       or ($errors .= "Missing server name.\n");
    my $ip = $server->{'apache-server-ip'} 
       or ($errors .= "Missing server ip\n");
    my $http = $server->{'apache-server-http-port'} 
       or ($errors .= "Missing http port\n");
    my $https = $server->{'apache-server-https-port'} 
       or ($errors .= "Missing https port\n");
#    my $sroot = $server->{'apache-server-root'} 
#      or ($errors .= "Missing server root dir\n");
    my $vsroot = $server->{'apache-server-vserver-root'} 
       or ($errors .= "Missing default root dir for the virtual servers\n");
    my $admin = $server->{'apache-server-admin'} 
       or ($errors .= "Missing admin\n");

    my($file, $dir, $odir) = $self->getFileDir();
    unless ($name) {
	if($server->CreateMe() or $name ne $old_name) {
	    $errors .= "A server $name already exists: $file.\n" if -e $file;
	    $errors .= "A server $name already exists: $dir.\n" if -e $dir;
	}
    }
    if ($ip) {
	$errors .= "Cannot resolve IP address or DNS name $ip.\n"
	    unless Socket::inet_aton($ip);
    }
    die $errors if $errors;
    if(!$server->CreateMe() and ($name ne $old_name)) {
	my $old_file = File::Spec->catfile($odir, "$old_name.cfg");
	my $old_dir = File::Spec->catdir($odir, $old_name);
	rename($old_file, $file) 
	    or die "Failed to rename $old_file to $file: $!";
	rename($old_dir, $dir) 
	    or die "Failed to rename $old_dir to $dir: $!";
    }
    $server->File($file);
    if ($server->CreateMe()) {
        File::Path::mkpath([$dir], 0, 0777);
	die "Couldn't create directory $dir" unless -d $dir;
	Wizard::Examples::Apache::VirtualServer::createDefault($self, $name, $vsroot, $dir);
    }
    $server->Modified(1);
    $self->Store($wiz, 1);
    $self->Action_Reset($wiz);
}

*Action_EditServer = \&Wizard::Examples::Apache::Host::Action_EditItem;

sub Action_ModifyServer {
    my $self = shift;
    $self->Action_ModifyItem(shift, shift || 'Modify server',
			     shift || 'Action_EditServer', 'Server');
}

sub Action_DeleteServer { 
    shift->Action_ModifyServer(shift, 'Delete this server', 
			       'Action_DeleteServer2'); 
}

sub Action_VServerMenu { 
    shift->Action_ModifyServer(shift, 'Manage virtual servers on this server', 
			       'Wizard::Examples::Apache::VirtualServer::Action_Enter'); 
}

sub Action_DeleteServer2 {
    my $self = shift; my $wiz = shift;
    my ($prefs, $basedir, $host) = $self->init();
    $self->Load($wiz);
    my $server = $self->{'server'};
    my ($file, $dir) = $self->getFileDir();

    (['Wizard::Elem::Title', 'value' => 'Deleting an Apache server'],
     ['Wizard::Elem::Data', 'descr' => 'Server name',
      'value' => $server->{'apache-server-name'}],
     ['Wizard::Elem::Data', 'descr' => 'Server DNS name',
      'value' => $server->{'apache-server-ip'}],
     ['Wizard::Elem::Data', 'descr' => 'Server root',
      'value' => $server->{'apache-server-root'}],
     ['Wizard::Elem::Data', 'descr' => 'Server admin',
      'value' => $server->{'apache-server-admin'}],
     ['Wizard::Elem::Data', 'descr' => 'Server HTTP port',
      'value' => $server->{'apache-server-http-port'}],
     ['Wizard::Elem::Data', 'descr' => 'Server HTTPS port',
      'value' => $server->{'apache-server-https-port'}],
     ['Wizard::Elem::Submit', 'value' => 'Yes, delete it',
      'id' => 1, 'name' => 'Action_DeleteServer3'],
     (-d $dir ? ['Wizard::Elem::Submit',
		 'value' => 'Yes, delete it, including data directory',
		 'id' => 2, 'name' => 'Action_DeleteServer4'] : ()),
     ['Wizard::Elem::Submit', 'value' => 'Return to Host Menu',
      'id' => 97, 'name' => 'Action_Reset'],
     ['Wizard::Elem::Submit', 'value' => 'Return to Top Menu',
      'id' => 98, 'name' => 'Wizard::Examples::Apache::Host::Action_Reset'],     
     ['Wizard::Elem::Submit', 'value' => 'Exit Apache Wizard',
      'id' => 99]);
    
}


sub Action_DeleteServer3 {
    my($self, $wiz) = @_;
    $self->DeleteItem($wiz);
    $self->Action_Reset($wiz);
}

sub Action_DeleteServer4 {
    my($self, $wiz) = @_;
    $self->DeleteItem($wiz,1);
    $self->Action_Reset($wiz);
}
