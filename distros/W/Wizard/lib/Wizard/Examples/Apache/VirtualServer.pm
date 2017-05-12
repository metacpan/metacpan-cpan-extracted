# -*- perl -*-

use strict;

use Wizard::State ();
use Wizard::SaveAble ();
use Wizard::Examples::Apache ();
use Wizard::Examples::Apache::Host ();
use Wizard::Examples::Apache::Server ();
use Wizard::Examples::Apache::Directory ();
use Wizard::Examples::Apache::Config ();


package Wizard::Examples::Apache::VirtualServer;

@Wizard::Examples::Apache::VirtualServer::ISA = qw(Wizard::Examples::Apache::Server);
$Wizard::Examples::Apache::VirtualServer::VERSION = '0.01';

my $allModes = {'http' => 1, 'https' => 1, 'both' => 1};
my $isHttps = {'https' => 1, 'both' => 1};
my $isHttp = {'http' => 1, 'both' => 1};

sub createDefault {
    my $self = shift || die "Missing state";
    my $name = shift || die "Missing server name";
    my $defroot = shift || die "Missing default root directory";
    my $sbasedir = shift || die "Missing basedir of server";
    my $vs = bless({'apache-virtualserver-admin' => 'webmaster@' . $name,
		    'apache-virtualserver-enable-ep' => '',
		    'apache-virtualserver-options' => '',
		    'apache-virtualserver-isdefault' => 'yes',
		    'apache-virtualserver-interface' => '',
		    'apache-virtualserver-http-mode' => 'http',
		    'apache-virtualserver-http-port' => '80',
		    'apache-virtualserver-https-port' => '443',
		    'apache-virtualserver-http-version' => 'HTTP/1.1',
		    'apache-virtualserver-enable-pcgi' => '',
		    'apache-virtualserver-index' => '',
		    'apache-virtualserver-sslcrtfile' => '',
		    'apache-virtualserver-sslkeyfile' => '',
		    'apache-virtualserver-name' => $name,
		    'apache-virtualserver-enable-ssi' => '',
		    'apache-virtualserver-http_mode' => 'http',
		    'apache-virtualserver-http_port' => 80,
		    'apache-virtualserver-root' => File::Spec->catdir($defroot, $name),
		}, 'Wizard::SaveAble' );
    $self->{'virtualserver'} = $vs;
    my $file = File::Spec->catfile($sbasedir, "$name.cfg");
    my $dir = File::Spec->catdir($sbasedir, $name);
    File::Path::mkpath([$dir],0, 0777);
    die "Couldn't create directory $dir: $!" unless -d $dir;
    $vs->CreateMe(1);
    $vs->File($file);
    $vs->Modified(1);
    Wizard::Examples::Apache::Directory::createDefault($self, $dir);
}

sub GetKey { 'virtualserver';};

sub init {
    my $self = shift; 
    return $self->SUPER::init(1) unless shift;
    my $item = $self->{'virtualserver'} || die "Missing virtualserver";
    ($self->SUPER::init(1), $item);
}

sub _superFileDir {
    Wizard::Examples::Apache::Host::getFileDir(shift, shift, 
					       'Wizard::Examples::Apache::Server');
}

sub ShowMe {
    my($self, $wiz, $vs) = @_;
    my $server = $self->{'server'} || die "Missing server";
    my $defvsroot = $self->{'server'}->{'apache-server-vserver-root'} || die "Missing default root dir for virtual servers";
    my $name = $vs->{'apache-virtualserver-name'} 
        or die "Missing virtual WWWserver name";
    my $https = $isHttps->{$vs->{'apache-virtualserver-http-mode'}} || '';
    my $http = $isHttp->{$vs->{'apache-virtualserver-http-mode'}} || '';

    my $http_only = $http && !$https;
    my $domain = $name; 
    if($domain =~ /^([^\.]\.)*([^\.]\.[^\.])$/) {
	$domain = $2;
    } 
    my $vsroot = File::Spec->catfile($defvsroot, $name);
    (['Wizard::Elem::Title',
      'value' => $vs->CreateMe() ?
            'Apache Wizard: Create a new virtual WWWserver' :
            'Apache Wizard: Edit an existing virtual WWWserver'],
     ['Wizard::Elem::Text', 
      'name' => 'apache-virtualserver-root',
      'value' => $vs->{'apache-virtualserver-root'} || $vsroot,
      'descr' => 'Virtual WWW server root directory'], 
     ['Wizard::Elem::Text', 'name' => 'apache-virtualserver-admin',
      'value' => $vs->{'apache-virtualserver-admin'} || "webmaster\@$domain",
      'descr' => 'Virtual WWW server admin'],
     ['Wizard::Elem::Text', 'name' => 'apache-virtualserver-http-port',
      'value' => $vs->{'apache-virtualserver-http-port'} || '',
      'descr' => 'Virtual WWW server HTTP port (if left empty the HTTP port of the server will be assumed)'],
         ($https ? (   ['Wizard::Elem::Text', 'name' => 'apache-virtualserver-https-port',
			'value' => $vs->{'apache-virtualserver-https-port'} || '',
			'descr' => 'Virtual WWW server HTTPS port (if left empty ' 
			. ' the HTTPS port of the server will be assumed)'],
		       ['Wizard::Elem::Text', 'name' => 'apache-virtualserver-sslkeyfile',
			'value' => $vs->{'apache-virtualserver-sslkeyfile'} || 
		         File::Spec->catfile($vsroot, "$name.key"),
			'descr' => 'Private key file'],
		       ['Wizard::Elem::Text', 'name' => 'apache-virtualserver-sslcrtfile',
			'value' => $vs->{'apache-virtualserver-sslcrtfile'} || 
		         File::Spec->catfile($vsroot, "$name.crt"),
			'descr' => 'Certificate file']) : ()),
        ($http_only ? (['Wizard::Elem::Select', 'name' => 'apache-virtualserver-http-version',
			'options' => ['HTTP/1.0', 'HTTP/1.1'], 
			'value' => $vs->{'apache-virtualserver-http-version'} || 'HTTP/1.1', 
			'descr' => 'Virtual WWW server HTTP version']) : ()),
     ['Wizard::Elem::Text', 'name' => 'apache-virtualserver-interface',
      'value' => $vs->{'apache-virtualserver-interface'},
      'descr' => 'Virtual WWW server interface number'],
     ['Wizard::Elem::Text', 'name' => 'apache-virtualserver-index',
      'value' => $vs->{'apache-virtualserver-index'},
      'descr' => 'Virtual WWW server DirectoryIndex'],
     ['Wizard::Elem::Text', 'name' => 'apache-virtualserver-options',
      'value' => $vs->{'apache-virtualserver-options'},
      'descr' => 'Virtual WWW server Options'],
     ['Wizard::Elem::CheckBox', 'name' => 'apache-virtualserver-enable-pcgi',
      'value' => $vs->{'apache-virtualserver-enable-pcgi'},
      'descr' => 'Enable PCGI'],
     ['Wizard::Elem::CheckBox', 'name' => 'apache-virtualserver-enable-ep',
      'value' => $vs->{'apache-virtualserver-enable-ep'},
      'descr' => 'Enable EP'],
     ['Wizard::Elem::CheckBox', 'name' => 'apache-virtualserver-enable-ssi',
      'value' => $vs->{'apache-virtualserver-enable-ssi'},
      'descr' => 'Enable Server Side Includes'],
     ['Wizard::Elem::Submit', 'name' => 'Action_VServerSave',
      'value' => 'Save these settings', 'id' => 1],
     ['Wizard::Elem::BR'],
     ['Wizard::Elem::Submit', 'value' => 'Return to Virtual WWW server Menu',
      'name' => 'Action_Reset',
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
    $self->SUPER::Load($wiz, 'Wizard::Examples::Apache::Server'); 
    $self->Action_Reset($wiz);
}

sub Action_Reset {
    my($self, $wiz) = @_;
    my($prefs, $basedir, $host, $server) = $self->init();

    delete $self->{'virtualserver'};
    $self->Store($wiz);

    # Return the initial menu.
    (['Wizard::Elem::Title', 'value' => 'Apache Wizard Virtual WWWserver Menu'],
     ['Wizard::Elem::Submit', 'value' => 'Create a new virtual WWWserver',
      'name' => 'Action_CreateVServer',
      'id' => 1],
     ['Wizard::Elem::Submit', 'value' => 'Modify an existing virtual WWWserver',
      'name' => 'Action_ModifyVServer',
      'id' => 2],
     ['Wizard::Elem::Submit', 'value' => 'Directory Menu',
      'name' => 'Action_DirectoryMenu',
      'id' => 3],
     ['Wizard::Elem::Submit', 'value' => 'Delete an existing virtual WWWserver',
      'name' => 'Action_DeleteVServer',
      'id' => 4],
     ['Wizard::Elem::BR'],
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

sub FirstParams {
    my $self = shift; my $wiz = shift;
    my $vs = shift;
    my $button = shift || "Continue creation";
    my $action = shift || "Action_FirstParamsVServer";

    (['Wizard::Elem::Title', 'value' => 'Virtual WWW server'],
     ['Wizard::Elem::Text', 'name' => 'apache-virtualserver-name',
      'value' => $vs->{'apache-virtualserver-name'}, 
      'descr' => 'Virtual WWW server DNS name or IP address'],
     ['Wizard::Elem::Select', 'name' => 'apache-virtualserver-http-mode',
      'options' => ['http', 'https', 'both'], 
      'value' => $vs->{'apache-virtualserver-http-mode'}, 
      'descr' => 'Choose a server type'],
     ['Wizard::Elem::Submit', 'name' => $action, 'value' => $button,
      'id' => 1],
     ['Wizard::Elem::BR'],
     ['Wizard::Elem::Submit', 'name' => 'Action_Reset',
      'value' => 'Return to Virtual WWW Server menu ',
      'id' => '95'],
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

sub GetIfaces {
    my $self = shift;
    my ($prefs, $basedir, $host, $server) = $self->init();
    my $hname = $host->{'apache-host-name'};
    my ($fileo, $diro) = $self->getFileDir('', 'Wizard::Examples::Apache::Host');
    my $tdir;

    my $fho = Symbol::gensym();
    my $fh = Symbol::gensym();
    my $maxkey=0;
    my $ifaces = {};
    opendir($fho, $diro) || die "Failed to open directory $diro: $!";
    while($tdir=readdir($fho)) {
	my $dir = File::Spec->catdir($diro, $tdir);
	next unless (-d $dir) && ($dir !~ /^[\.]{1,2}$/);
	opendir($fh, $dir) || die "Failed to open directory $dir: $!";
	$ifaces = { %$ifaces, 
		    map { if(/\.cfg$/) {
	                    my $vs = do File::Spec->catfile($dir, $_);
			    $maxkey = $vs->{'apache-virtualserver-interface'}
			       if $vs->{'apache-virtualserver-interface'} > $maxkey;
			    (defined($vs->{'apache-virtualserver-interface'})) ?
				($vs->{'apache-virtualserver-interface'} => File::Spec->catfile($tdir,$vs->{'apache-virtualserver-name'}))
			   : ();
			} else {
			    ();
			}
		      } readdir($fh) };
	closedir($fh);
    }
    closedir($fho);
    $ifaces->{'_max'} = $maxkey;
    return $ifaces;
}

sub Action_CreateVServer {
    my $self = shift;
    $self->Action_CreateItem(@_, 1);
    return $self->FirstParams(shift, $self->{'virtualserver'});
}

sub AssignFirstParams {
    my($self, $wiz, $vs) = @_;
    my($prefs, $basedir, $host, $server) = $self->init();
    my $errors = '';
    my $old_name = $vs->{'apache-virtualserver-name'} || '';
    my $name = $wiz->param('apache-virtualserver-name') 
       or ($errors .= "Missing virtual WWW server name.\n");
    my $http_mode = $wiz->param('apache-virtualserver-http-mode') 
       or ($errors .= "Missing virtual WWW server http mode.\n");
    $errors .= "Invalid http mode.\n" unless defined($allModes->{$http_mode});

    my $ifaces = $self->GetIfaces();
    my $iface = $vs->{'apache-virtualserver-interface'};

    $vs->{'apache-virtualserver-name'} = $name;
    $vs->{'apache-virtualserver-http-version'} = 'HTTP/1.0' if $isHttps->{$http_mode};
    $vs->{'apache-virtualserver-http-mode'} = $http_mode;
    if (($vs->{'apache-virtualserver-http-version'} eq 'HTTP/1.0') && ($iface !~ /^[\d]+$/)) {
	$vs->{'apache-virtualserver-interface'} = $ifaces->{'_max'}+1 ;
    }
    my($file, $dir) =$self->getFileDir();

    $vs->{'_virtualserver_old_name'} = $old_name;


    if ($name) {
	$errors .= "Cannot resolve IP address or DNS name.\n"
	    unless Socket::inet_aton($name);
	if($vs->CreateMe() or $name ne $old_name) {
	    $errors .= "A virtual server $name already exists: $file.\n" if -e $file;
	    $errors .= "A virtual server $name already exists: $dir.\n" if -e $dir;
	}
    }

    die $errors if $errors;
}

sub Action_FirstParamsVServer {
    my($self, $wiz) = @_;
    my $vs = $self->{'virtualserver'};

    $self->AssignFirstParams($wiz, $vs);
    $self->Store($wiz);
    $self->ShowMe($wiz, $vs);
}

sub Action_VServerSave {
    my $self=shift; my $wiz = shift;
    my($prefs, $basedir, $host, $server, $vs) = $self->init(1);
    
    my $name = $vs->{'apache-virtualserver-name'};
    my $old_name = delete $vs->{'_virtualserver_old_name'} || '';

    foreach my $opt ($wiz->param()) {
	$vs->{$opt} = $wiz->param($opt) 
	    if (($opt =~ /^apache\-virtualserver/) 
		&& (defined($wiz->param($opt))));
    }
    
    # Verify the new settings
    my $errors = '';
    my $admin = $vs->{'apache-virtualserver-admin'}
       or ($errors .= "Missing virtual WWW server admin.\n");
    my $dohttps = $isHttps->{$vs->{'apache-virtualserver-http-mode'}} || '';
    my $dohttp = $isHttp->{$vs->{'apache-virtualserver-http-mode'}} || '';
    my $doiface = 0;
    my $httpver;

    $httpver = (($vs->{'apache-virtualserver-http-version'} =~ /^HTTP\/1\.[\d]$/) ? 
		   $vs->{'apache-virtualserver-http-version'} : '') 
	or ($errors .= "Invalid HTTP version.\n");

    $httpver = $vs->{'apache-virtualserver-http-version'} = 'HTTP/1.0' if $dohttps;
    $doiface = 1 if $httpver eq 'HTTP/1.0';

    my $vsroot = $vs->{'apache-virtualserver-root'}
          or ($errors .= "Missing virtual WWW server root dir.\n");
    if($dohttps) {
	my $sslkey = $vs->{'apache-virtualserver-sslkeyfile'}
	   or ($errors .= "Missing SSL key file.\n");
	my $sslcrt = $vs->{'apache-virtualserver-sslcrtfile'}
	   or ($errors .= "Missing SSL certificate file.\n");
    }
    my $sname = $server->{'apache-server-name'};
    if($doiface) {
	my $ifaces = $self->GetIfaces();
	my $iface = $vs->{'apache-virtualserver-interface'};
	if($iface =~ /^[\d]+$/) {
	    $errors .=  "Interface already in use by " . $ifaces->{$iface} . ".\n" 
		if (defined($ifaces->{$iface})) && ($ifaces->{$iface} ne $sname . '/' .  $old_name);
	} else {
	    $errors .= "Missing interface number.\n";
	}
    } else {
	$vs->{'apache-virtualserver-interface'} = '';
    }
    die $errors if $errors;

    my($file, $dir, $odir) = $self->getFileDir();
    
    if(!$vs->CreateMe() and $name ne $old_name) {
	my $old_file = File::Spec->catfile($odir, "$old_name.cfg");
	my $old_dir = File::Spec->catdir($odir, $old_name);
	rename($old_file, $file) 
	    or die "Failed to rename $old_file to $file: $!";
	rename($old_dir, $dir) 
	    or die "Failed to rename $old_dir to $dir: $!";
    }
    $vs->File($file);
    if($vs->CreateMe()) {
        File::Path::mkpath([$dir], 0, 0777);
	die "Couldn't create directory $dir: $!" unless -d $dir;
	Wizard::Examples::Apache::Directory::createDefault($self, $dir);
    }
    $vs->Modified(1);
    $self->Store($wiz, 1);
    $self->Action_Reset($wiz);
}


sub Action_ModifyVServer {
    my $self = shift;
    $self->Action_ModifyItem(shift, shift || 'Modify virtual server',
			     shift || 'Action_EditVServer', 'Virtual WWW server');
}

sub Action_EditVServer {
    my $self = shift; my $wiz = shift;
    $self->Load($wiz);
    $self->FirstParams($wiz, $self->{'virtualserver'}, "Continue editing");
}

sub Action_DeleteVServer {
    shift->Action_ModifyVServer(shift, 'Delete this virtual server',
				'Action_DeleteVServer2');
}

sub Action_DirectoryMenu { 
    shift->Action_ModifyVServer(shift, 'Manage directory configurations on this virtual server', 
			       'Wizard::Examples::Apache::Directory::Action_Enter'); 
}


sub Action_DeleteVServer2 {
    my $self = shift; my $wiz = shift;
    my($prefs, $basedir, $host, $server) = $self->init();
    my $hname = $host->{'apache-host-name'};
    my $sname = $server->{'apache-server-name'};
    my $name = $wiz->param('apache-virtualserver') || die "Missing virtual WWW server name";
    my $file = File::Spec->catfile($basedir, $hname, $sname, "$name.cfg");
    my $dir = File::Spec->catdir($basedir, $hname, $sname, $name);
    my $vserver = Wizard::SaveAble->new($file);

    if ($vserver->{'apache-virtualserver-isdefault'}) {
	return (['Wizard::Elem::Data', 'descr' => 'ERROR: ', 
		 'value' => 'Default virtual server can not be deleted'], 
		$self->Action_Reset($wiz));
    }	    

    $self->{'virtualserver'}=$vserver;
    $self->Store($wiz);
    my $https = $isHttps->{$vserver->{'apache-virtualserver-http_mode'}} || '';

    (['Wizard::Elem::Title', 'value' => 'Deleting an Apache server'],
     ['Wizard::Elem::Data', 'descr' => 'Virtual WWW server name',
      'value' => $vserver->{'apache-virtualserver-name'}],
     ['Wizard::Elem::Data', 'descr' => 'Virtual WWW server root',
      'value' => $vserver->{'apache-virtualserver-root'}],
     ['Wizard::Elem::Data', 'descr' => 'Virtual WWW server admin',
      'value' => $vserver->{'apache-virtualserver-admin'}],
     ['Wizard::Elem::Data', 'descr' => 'Virtual WWW server HTTP port',
      'value' => $vserver->{'apache-virtualserver-http-port'}],
     ($https ? (['Wizard::Elem::Data', 'descr' => 'Virtual WWW server HTTPS port',
		'value' => $vserver->{'apache-virtualserver-https-port'}],
               ['Wizard::Elem::Data', 'descr' => 'Virtual WWW Server key file',
                'value' => $vserver->{'apache-virtualserver-sslkeyfile'}],
               ['Wizard::Elem::Data', 'descr' => 'Virtual WWW Server certificate file',
                'value' => $vserver->{'apache-virtualserver-sslcrtfile'}]) : ()),
     ['Wizard::Elem::Submit', 'value' => 'Yes, delete it',
      'id' => 1, 'name' => 'Action_DeleteVServer3'],
     (-d $dir ? ['Wizard::Elem::Submit',
		 'value' => 'Yes, delete it, including data directory',
		 'id' => 2, 'name' => 'Action_DeleteVServer4'] : ()),
     ['Wizard::Elem::BR'],
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


sub Action_DeleteVServer3 {
    my($self, $wiz) = @_;
    $self->DeleteItem($wiz);
    $self->Action_Reset($wiz);
}

sub Action_DeleteVServer4 {
    my($self, $wiz) = @_;
    $self->DeleteItem($wiz,1);
    $self->Action_Reset($wiz);
}
