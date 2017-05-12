# -*- perl -*-

use strict;

use Wizard::State ();
use Wizard::SaveAble ();
use Wizard::Examples::Apache::Server ();
use File::Spec ();
use File::Path ();
use Socket ();
use Symbol ();


package Wizard::Examples::Apache::Host;

@Wizard::Examples::Apache::Host::ISA = qw(Wizard::Examples::Apache);
$Wizard::Examples::Apache::Host::VERSION = '0.01';

sub init {
    my $self = shift; 
    return $self->SUPER::init(1) unless shift;
    my $item = $self->{'host'} || die "Missing host";
    ($self->SUPER::init(1), $item);
}

sub GetKey { 'host';};

sub getFileDir {
    my($self, $name, $class)= @_;
    $class ||= (ref($self) || $self); my $meth = $class . '::_superFileDir';
    my($ofile, $odir) = $self->$meth('');
    my $key = $class->GetKey();
    $name ||= $self->{$key}->{'apache-' . $key . '-name'} if ref($self);
    my $file = File::Spec->catfile($odir, "$name.cfg");
    my $dir = File::Spec->catdir($odir, $name);
    wantarray ? ($file, $dir, $odir) : $file;
}

sub _superFileDir {
    Wizard::Examples::Apache::getFileDir(shift, shift, 'Wizard::Example::Apache');
}

sub Load {
    my ($self, $wiz, $class) = @_;
    $class ||= (ref($self) || $self);
    my $key = $class->GetKey();
    my $meth = $class . '::init'; $self->$meth();
    my $item =  $wiz->param('apache-' . $key) or die "Missing $key specification";
    $meth = $class . '::getFileDir'; 
    my $file = $self->$meth($item);
    $item = $self->{$key} = Wizard::SaveAble->new($file);
    $self->Store($wiz);
}

sub ShowMe {
    my($self, $wiz, $host) = @_;
    (['Wizard::Elem::Title',
      'value' => $host->CreateMe() ?
          'Apache Wizard: Create a new host' :
          'Apache Wizard: Edit an existing host'],
     ['Wizard::Elem::Link'],
     ['Wizard::Elem::Text', 'name' => 'apache-host-name',
      'value' => $host->{'apache-host-name'},
      'descr' => 'Hosts short, descriptive name'],
     ['Wizard::Elem::Text', 'name' => 'apache-host-descr',
      'value' => $host->{'apache-host-descr'},
      'descr' => 'Hosts long, informative description'],
     ['Wizard::Elem::Text', 'name' => 'apache-host-arch',
      'value' => $host->{'apache-host-arch'},
      'descr' => 'Hosts architecture'],
     ['Wizard::Elem::Text', 'name' => 'apache-host-ip',
      'value' => $host->{'apache-host-ip'},
      'descr' => 'Hosts DNS name or IP address'],
     ['Wizard::Elem::Submit', 'name' => 'Action_HostSave',
      'value' => 'Save these settings', 'id' => 1],
     ['Wizard::Elem::Submit', 'name' => 'Action_Reset',
      'value' => 'Return to host menu', 'id' => 98],
     ['Wizard::Elem::Submit', 'name' => 'Wizard::Examples::Apache::Action_Reset',
      'value' => 'Return to top menu', 'id' => 99]);
}

*Action_CreateHost = \&Action_CreateItem;

sub Action_CreateItem {
    my($self, $wiz, $notshow) = @_;
    $self->init(); my $key = $self->GetKey();

    $self->{$key} = Wizard::SaveAble->new();
    $self->{$key}->CreateMe(1);
    $self->Store($wiz);
    $self->ShowMe($wiz, $self->{$key}) unless $notshow;
}

sub Action_HostSave {
    my($self, $wiz) = @_;
    my ($prefs, $basedir, $host) = $self->init(1);
    
    my $old_name = $host->{'apache-host-name'};
    foreach my $opt (qw(apache-host-name apache-host-descr apache-host-arch
                        apache-host-ip)) {
	$host->{$opt} = $wiz->param($opt) if defined($wiz->param($opt));
    }

    # Verify the new settings
    my $errors = '';
    my $name = $host->{'apache-host-name'} || '';
    $errors .= "Missing host name.\n" unless $name;
    my $ip = $host->{'apache-host-ip'}
	or  ($errors .= "Missing host ip.\n");
    my $arch = $host->{'apache-host-arch'}
	or  ($errors .= "Missing host architecture.\n");

    my($file, $dir, $odir) = $self->getFileDir();
    unless ($name) {
	if ($host->CreateMe()  or  $name ne $old_name) {
	    $errors .= "A host $name already exists: $file.\n" if -e $file;
	    $errors .= "A host $name already exists: $dir.\n" if -e $dir;
	}
    }
    if ($ip) {
	$errors .= "Cannot resolve IP address $ip.\n"
	    unless Socket::inet_aton($ip);
    }
    die $errors if $errors;

    if (!$host->CreateMe()  and  ($name ne $old_name)) {
	my $old_file = File::Spec->catfile($odir, "$old_name.cfg");
	my $old_dir = File::Spec->catdir($odir, "$old_name");
	rename($old_file, $file) 
	    or die "Failed to rename $old_file to $file: $!";
	rename($old_dir, $dir) 
	    or die "Failed to rename $old_dir to $dir: $!";
    }
    $host->File($file);
    if ($host->CreateMe()) {
        File::Path::mkpath([$dir],0, 0777);
	die "Couldn't create directory $dir: $!" unless -d $dir;
    }
    $host->Modified(1);
    $self->Store($wiz, 1);
    $self->Action_Reset($wiz);
}

sub Action_Reset {
    my($self, $wiz) = @_;
    my ($prefs, $basedir) = $self->init();

    delete $self->{'host'};
    $self->Store($wiz);

    # Return the initial menu.
    (['Wizard::Elem::Title', 'value' => 'Apache Wizard Host Menu'],
     ['Wizard::Elem::Submit', 'value' => 'Create a new host',
      'name' => 'Action_CreateHost',
      'id' => 1],
     ['Wizard::Elem::Submit', 'value' => 'Modify an existing host',
      'name' => 'Action_ModifyHost',
      'id' => 2],
     ['Wizard::Elem::Submit', 'value' => 'Server Menu',
      'name' => 'Action_ServerMenu', 'id' => 3],
     ['Wizard::Elem::Submit', 'value' => 'Delete an existing host',
      'name' => 'Action_DeleteHost',
      'id' => 4],
     ['Wizard::Elem::BR'],
     ['Wizard::Elem::Submit', 'value' => 'Return to Top Menu',
      'name' => 'Wizard::Examples::Apache::Action_Reset',
      'id' => 98],
     ['Wizard::Elem::Submit', 'value' => 'Exit Apache Wizard',
      'id' => 99]);
}


sub Action_EditItem {
    my $self = shift; my $wiz = shift;
    my $key = $self->GetKey();
    $self->Load($wiz);
    $self->ShowMe($wiz, $self->{$key});
}

*Action_EditHost = \&Action_EditItem;

sub ItemList {
    my $self = shift;  my $basedir = shift;
    my $fh = Symbol::gensym();
    opendir($fh, $basedir) || die "Failed to open directory $basedir: $!";
    my @items = map { (/^(.*)\.cfg$/  and  -f File::Spec->catfile($basedir, $_))
			  ? $1 : () } readdir($fh);
    closedir($fh);
    @items;
}

sub Action_ModifyItem {
    my $self = shift; my $wiz = shift; my $button = shift; 
    my $action = shift; my $descr = shift; my $key = shift; 
    $key ||= $self->GetKey(); 
    $self->init();
    my @ret = $self->getFileDir();

    my @items = $self->ItemList($ret[2]);
    return $self->Action_Reset($wiz) unless @items;
    # Return the initial menu.
    (['Wizard::Elem::Title', 'value' => "Apache $descr Selection"],
     ['Wizard::Elem::Select', 'options' => \@items, 'name' => 'apache-' . $key,
      'descr' => 'Select a directory'],
     ['Wizard::Elem::Submit', 'value' => $button, 'name' => $action,
      'id' => 1]);
    
}

sub Action_ModifyHost {
    my $self = shift;
    $self->Action_ModifyItem(shift, shift || 'Modify host',
			     shift || 'Action_EditHost', 'Host');
}

sub Action_DeleteHost {
    my($self, $wiz) = @_;
    $self->Action_ModifyHost($wiz, 'Delete this host', 'Action_DeleteHost2');
}

sub Action_ServerMenu {
    my($self, $wiz) = @_;
    $self->Action_ModifyHost($wiz, 'Manage servers on this host',
			     'Wizard::Examples::Apache::Server::Action_Enter');
}

sub Action_DeleteHost2 {
    my $self = shift; my $wiz = shift;
    my ($prefs, $basedir) = $self->init();
    $self->Load($wiz);
    my $host = $self->{'host'};
    my ($file, $dir, $odir) = $self->getFileDir();

    (['Wizard::Elem::Title', 'value' => 'Deleting an Apache host'],
     ['Wizard::Elem::Link', 'action'=> 'DeleteHost'],
     ['Wizard::Elem::Data', 'descr' => 'Host name',
      'value' => $host->{'apache-host-name'}],
     ['Wizard::Elem::Data', 'descr' => 'Host description',
      'value' => $host->{'apache-host-descr'}],
     ['Wizard::Elem::Data', 'descr' => 'Host architecture',
      'value' => $host->{'apache-host-arch'}],
     ['Wizard::Elem::Data', 'descr' => 'Hosts DNS name',
      'value' => $host->{'apache-host-ip'}],
     ['Wizard::Elem::Submit', 'value' => 'Yes, delete it',
      'id' => 1, 'name' => 'Action_DeleteHost3'],
     (-d $dir ? ['Wizard::Elem::Submit',
		 'value' => 'Yes, delete it, including data directory',
		 'id' => 2, 'name' => 'Action_DeleteHost4'] : ()),
     ['Wizard::Elem::Submit', 'value' => 'Return to Host Menu',
      'id' => 98, 'name' => 'Action_Reset'],
     ['Wizard::Elem::Submit', 'value' => 'Return to Top Menu',
      'id' => 99, 'name' => 'Wizard::Examples::Apache::Action_Reset']);
}

sub DeleteItem {
    my $self = shift; my $wiz = shift; my $dirs = shift;
    $self->init(1); my $key = $self->GetKey();
    my($file, $dir) = $self->getFileDir();
    my $item = delete $self->{$key} or die "Missing $key";
    unlink $file or die "Failed to remove $file: $!";
    if (-d $dir and $dirs) {
	require File::Path;
	File::Path::rmtree([$dir]);
	die "Failed to remove directory $dir: $!" if -d $dir;
    }
    $self->Store($wiz);
}

sub Action_DeleteHost3 {
    my($self, $wiz) = @_;
    $self->DeleteItem($wiz);
    $self->Action_Reset($wiz);
}

sub Action_DeleteHost4 {
    my($self, $wiz) = @_;
    $self->DeleteItem($wiz, 1);
    $self->Action_Reset($wiz);
}

