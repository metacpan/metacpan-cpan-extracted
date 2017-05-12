# -*- perl -*-

use strict;

use Net::LDAP ();
use Socket ();
use Wizard ();
use Wizard::State ();
use Wizard::SaveAble ();
use Wizard::SaveAble::LDAP ();
use Wizard::LDAP ();
use Wizard::LDAP::Config ();

@Wizard::LDAP::User::ISA = qw(Wizard::LDAP);
$Wizard::LDAP::User::VERSION = '0.01';

package Wizard::LDAP::User;

my $RESOLVE_SHELL = { 'mail' => '/bin/mailonly', 'ftp' => '/bin/ftp_mail', 
		      'admin' => '/bin/bash'};

sub init {
    my $self = shift; 
    return ($self->SUPER::init(1)) unless shift;
    my $item = $self->{'user'} || die "Missing user";
    ($self->SUPER::init(1), $item);
}


sub ShowMe {
    my($self, $wiz, $prefs, $user) = @_;
    (['Wizard::Elem::Title',
      'value' => $user->CreateMe() ?
          'LDAP Wizard: Create a new user' :
          'LDAP Wizard: Edit an existing user'],
     ['Wizard::Elem::Data',
      'value' => $user->{'ldap-user-uidnumber'},
      'descr' => 'Users UID'],
     ['Wizard::Elem::Data', 
      'value' => $user->{'ldap-user-gidnumber'},
      'descr' => 'Users GID'],
     ['Wizard::Elem::Data', 
      'value' => $user->{'ldap-user-homedirectory'},
      'descr' => 'Users home directory'],
     ['Wizard::Elem::Text', 'name' => 'ldap-user-uid',
      'value' => $user->{'ldap-user-uid'},
      'descr' => 'Users login'],
     ['Wizard::Elem::Text', 'name' => 'ldap-user-userpassword',
      'value' => $user->{'ldap-user-userpassword'},
      'descr' => 'Users password'],
     ['Wizard::Elem::Text', 'name' => 'ldap-user-cn',
      'value' => $user->{'ldap-user-cn'},
      'descr' => 'Users real name'],
     ['Wizard::Elem::Text', 'name' => 'ldap-user-description',
      'value' => $user->{'ldap-user-description'},
      'descr' => 'A single-line description of the user'],
     ['Wizard::Elem::Text', 'name' => 'ldap-user-mail',
      'value' => $user->{'ldap-user-mail'},
      'descr' => 'Users email adress'],
     ['Wizard::Elem::Text', 'name' => 'ldap-user-mailforward',
      'value' => $user->{'ldap-user-mailforward'},
      'descr' => 'Users email forward address'],
     ['Wizard::Elem::Select', 'name' => 'ldap-user-mailforwardtype',
      'value' => $user->{'ldap-user-mailforwardtype'} || 'always',
      'options' => ['after 1 day', 'after 2 days', 'after 3 days',
		    'after 4 days', 'after 5 days', 'always'],
      'descr' => 'Users email forward type'],
     ['Wizard::Elem::Text', 'name' => 'ldap-user-pop3box',
      'value' => $user->{'ldap-user-pop3box'},
      'descr' => 'External POP3 box to fetch mail from'],
     ['Wizard::Elem::Text', 'name' => 'ldap-user-pop3password',
      'value' => $user->{'ldap-user-pop3password'},
      'descr' => 'Password of the external POP3 box'],
     ['Wizard::Elem::Select', 'name' => 'ldap-user-status',
      'value' => $user->{'ldap-user-status'},
      'options' => ['mail', 'ftp', 'admin'],
      'descr' => 'Users status'],
     ['Wizard::Elem::Submit', 'name' => 'Action_UserSave',
      'value' => 'Save these settings', 'id' => 1],
     ['Wizard::Elem::BR'],
     ['Wizard::Elem::Submit', 'name' => 'Action_Reset',
      'value' => 'Return to User menu', 'id' => 98],
     ['Wizard::Elem::Submit', 'name' => 'Wizard::LDAP::Action_Reset',
      'value' => 'Return to top menu', 'id' => 99]);
}


sub Action_Reset {
    my($self, $wiz) = @_;
    $self->init();

    delete $self->{'user'};
    $self->Store($wiz);

    # Return the initial menu.
    (['Wizard::Elem::Title', 'value' => 'LDAP Wizard User Menu'],
     ['Wizard::Elem::Submit', 'value' => 'Create a new user',
      'name' => 'Action_CreateUser',
      'id' => 1],
     ['Wizard::Elem::Submit', 'value' => 'Modify an existing user',
      'name' => 'Action_ModifyUser',
      'id' => 2],
     ['Wizard::Elem::Submit', 'value' => 'Delete an existing user',
      'name' => 'Action_DeleteUser',
      'id' => 3],
     ['Wizard::Elem::BR'],
     ['Wizard::Elem::Submit', 'value' => 'Return to Top Menu',
      'name' => 'Wizard::LDAP::Action_Reset',
      'id' => 98],
     ['Wizard::Elem::Submit', 'value' => 'Exit LDAP Wizard',
      'id' => 99]);
}

sub Action_CreateUser {
    my($self, $wiz) = @_;
    my ($prefs, $admin) = $self->init();
    my $attr = { 'ldap-user-uidnumber' => $prefs->{'ldap-prefs-nextuid'},
		 'ldap-user-gidnumber' => $prefs->{'ldap-prefs-gid'},
		 'ldap-user-homedirectory' => $prefs->{'ldap-prefs-home'} . '/<login>'};
    my $user = Wizard::SaveAble::LDAP->new('adminDN' => $admin->{'ldap-admin-dn'},
					   'adminPassword' => $admin->{'ldap-admin-password'},
					   'prefix' => 'ldap-user-',
					   'serverip' => $prefs->{'ldap-prefs-serverip'},
					   'serverport' => $prefs->{'ldap-prefs-serverport'},
					   %$attr);
    $user->CreateMe(1);
    $self->{'user'} = $user;
    $self->Store($wiz);
    $self->ShowMe($wiz, $prefs, $user);
}

sub Action_UserSave {
    my($self, $wiz) = @_;
    my ($prefs, $admin, $user) = $self->init(1);
    my $base = $prefs->{'ldap-prefs-userbase'};
    my $oldlogin = $user->{'ldap-user-uid'} || '';

    foreach my $opt ($wiz->param()) {
	$user->{$opt} = $wiz->param($opt) 
	    if (($opt =~ /^ldap\-user/) && (defined($wiz->param($opt))));
    }

    # Verify settings
    my $errors = '';
    my $login = $user->{'ldap-user-uid'} 
       or ($errors .= "Missing user login.\n");
    my $pwd = $user->{'ldap-user-userpassword'};
    $errors .= "Empty user password.\n"
	if $pwd eq '' && $prefs->{'ldap-prefs-passwordcheck'};
    my $uid = $user->{'ldap-user-uidnumber'} 
       or ($errors .= "Missing user UID (internal error).\n");
    my $gid = $user->{'ldap-user-gidnumber'} 
       or ($errors .= "Missing user GID (internal error).\n");
    my $home = $user->{'ldap-user-homedirectory'} 
       or ($errors .= "Missing user home (internal error).\n");
    my $name = $user->{'ldap-user-cn'} 
       or ($errors .= "Missing users name.\n");
    my $status = $user->{'ldap-user-status'} 
       or ($errors .= "Missing users status.\n");
    my $mail = $user->{'ldap-user-mail'} 
       or ($errors .= "Missing users email adress.\n");
    $mail .= $prefs->{'ldap-prefs-domain'} unless $mail =~ /\@/;
    my $mailforward = $user->{'ldap-user-mailforward'};
    my $mailforwardtype = $user->{'ldap-user-mailforwardtype'};
    $user->{'ldap-user-objectClass'} = 'posixAccount';
    $errors .= "Invalid login name: $login.\n"
	unless ($login =~ /^[\d\w]{1,8}$/);
    $errors .= "Invalid status: $status.\n"
	unless exists($RESOLVE_SHELL->{$status});
    die $errors if $errors;
    $user->{'ldap-user-maildrop'} = $login;
    $user->{'ldap-user-maildrop'} = $mailforward
	if(($mailforwardtype eq 'always') && ($mailforward ne ''));

    $user->{'ldap-user-gecos'} = $name;
    $user->{'ldap-user-loginshell'} = $RESOLVE_SHELL->{$status};
    $user->{'ldap-user-homedirectory'} = $prefs->{'ldap-prefs-home'} . '/' . $login;
    $user->AttrScalar2Ref('mail', 'mailforward', 'maildrop');

    my $cmd;
    if ($user->CreateMe()) {
	$prefs->{'ldap-prefs-nextuid'} = $uid + 1;
	$prefs->Modified(1);
	$cmd = $prefs->{'ldap-prefs-userchange-new'};
    } else {
	$cmd = $prefs->{'ldap-prefs-userchange-modify'};
    }
    $user->DN('cn=' . $login . ', ' . $base);

    $cmd =~ s/\$olduid\b/$oldlogin/g;
    $cmd =~ s/\$(\w+)/$user->{"ldap-user-$1"}/g;
    my $opts = delete $user->{'_options'} || {};
    my $opt = delete $user->{'ldap-user-chooseopt'} || '';
    $opt = $opts->{$opt} if exists($opts->{$opt});
    my $program = $cmd;
    $program =~ s/\s.*//;
    print STDERR "LDAP wizard: Running command $cmd\n";
    my $str = `$cmd 2>&1` if -x $program;
    if (defined($str)) {
	my $opts = $user->{'_options'} = {};
	my $items = [];
	my $msg = '';
	foreach my $line (split(/\n/, $str)) {
	    next if $line =~ /^\s*$/;
	    if ($line =~ /^Message:\s*(.*)$/) {
		$msg .= "$1<br>\n";
	    } elsif ($line =~ /^Option\:\s*(.*)=(.*?)\s*$/) {
		$opts->{$2} = "--$1";
		push(@$items, $2);
	    } else {
		die "Executing command $cmd failed:\n$str\n";
	    }
	}
	if (@$items) {
	    $self->Store($wiz);
	    return $self->ChooseMenu($wiz, $items, $msg) if @$items;
	}
    }

    $user->Modified(1);
    $self->Store($wiz, 1);
    $self->Action_Reset($wiz);
}

sub ChooseMenu {
    my($self, $wiz, $items, $msg) = @_; 
    (['Wizard::Elem::Title', 'value' => "LDAP Wizard User: Decision required"],
     ['Wizard::Elem::Message', 'msg' => $msg],
     ['Wizard::Elem::Select', 'options' => [@$items],
      'name' => 'ldap-user-chooseopt',
      'descr' => 'Select how to proceed'],
     ['Wizard::Elem::Submit', 'value' => 'Proceed',
      'name' => 'Action_UserSave',
      'id' => 1]);
}


sub Action_ModifyUser {
    my $self = shift; my $wiz = shift; 
    my $button = shift || 'Modify User';
    my $action = shift || 'Action_EditUser'; 
    my ($prefs, $admin) = $self->init();
    my $base = $prefs->{'ldap-prefs-userbase'};

    my @items = $self->ItemList($prefs, $admin,
				$prefs->{'ldap-prefs-userbase'}, 'uid');
    return $self->Action_Reset($wiz) unless @items;
    if(@items == 1) {
	$wiz->param('ldap-user', $items[0]);
	return $self->$action($wiz);
    }
    @items = sort @items;
    
    # Return the initial menu.
    (['Wizard::Elem::Title', 'value' => "LDAP Wizard User Selection"],
     ['Wizard::Elem::Select', 'options' => \@items, 'name' => 'ldap-user',
      'descr' => 'Select an user'],
     ['Wizard::Elem::Submit', 'value' => $button, 'name' => $action,
      'id' => 1]);
}

sub Load {
    my($self, $wiz, $prefs, $admin, $dn) = @_;
    my $user = Wizard::SaveAble::LDAP->new('adminDN' => $admin->{'ldap-admin-dn'},
					   'adminPassword' => $admin->{'ldap-admin-password'},
					   'prefix' => 'ldap-user-',
					   'serverip' => $prefs->{'ldap-prefs-serverip'},
					   'serverport' => $prefs->{'ldap-prefs-serverport'},
					   'dn' => $dn, 'load' => 1);
    $user->DN($dn);
    $self->{'user'} = $user;
    $self->Store($wiz);
    $user->AttrRef2Scalar('mail', 'mailforward');
    $user;
}


sub Action_EditUser {
    my($self, $wiz) = @_;
    my($prefs, $admin) = $self->init();
    my $login = $wiz->param('ldap-user') || die "Missing login.";
    my $dn = "cn=$login, " . $prefs->{'ldap-prefs-userbase'};
    my $user = $self->Load($wiz, $prefs, $admin, $dn);
    $self->ShowMe($wiz, $prefs, $user);
}

sub Action_DeleteUser {
    shift->Action_ModifyUser(shift, 'Delete user', 'Action_DeleteUser2');
}

sub Action_DeleteUser2 {
    my ($self, $wiz) = @_;
    my($prefs, $admin) = $self->init();
    my $login = $wiz->param('ldap-user') || die "Missing login.";
    my $dn = "cn=$login, " . $prefs->{'ldap-prefs-userbase'};
    my $user = $self->Load($wiz, $prefs, $admin, $dn);
    
    (['Wizard::Elem::Title', 'value' => 'Deleting an LDAP user'],
     ['Wizard::Elem::Data', 'descr' => 'Users login',
      'value' => $user->{'ldap-user-uid'}],
     ['Wizard::Elem::Data', 
      'value' => $user->{'ldap-user-userpassword'},
      'descr' => 'Users password'],
     ['Wizard::Elem::Data', 
      'value' => $user->{'ldap-user-uidnumber'},
      'descr' => 'Users UID'],
     ['Wizard::Elem::Data', 
      'value' => $user->{'ldap-user-gidnumber'},
      'descr' => 'Users GID'],
     ['Wizard::Elem::Data', 
      'value' => $user->{'ldap-user-homedirectory'},
      'descr' => 'Users home'],
     ['Wizard::Elem::Data', 
      'value' => $user->{'ldap-user-cn'},
      'descr' => 'Users name'],
     ['Wizard::Elem::Data', 
      'value' => $user->{'ldap-user-description'},
      'descr' => 'Users logical group'],
     ['Wizard::Elem::Data', 
      'value' => $user->{'ldap-user-mail'},
      'descr' => 'Users email adress'],
     ['Wizard::Elem::Data', 
      'value' => $user->{'ldap-user-mailforwardtype'},
      'descr' => 'Users email forward type'],
     ['Wizard::Elem::Data', 
      'value' => $user->{'ldap-user-mailforward'},
      'descr' => 'Users email forward adress'],
     ['Wizard::Elem::Data',
      'value' => $user->{'ldap-user-pop3box'},
      'descr' => 'External POP3 box to fetch mail from'],
     ['Wizard::Elem::Data',
      'value' => $user->{'ldap-user-pop3password'},
      'descr' => 'Password of the external POP3'],
     ['Wizard::Elem::Data', 
      'value' => $user->{'ldap-user-status'},
      'descr' => 'Users status'],
     ['Wizard::Elem::Data', 
      'value' => $user->{'ldap-user-loginshell'},
      'descr' => 'Users login shell'],
     ['Wizard::Elem::Submit', 'value' => 'Yes, delete it',
      'id' => 1, 'name' => 'Action_DeleteUser3'],
     ['Wizard::Elem::Submit', 'value' => 'Return to User Menu',
      'id' => 98, 'name' => 'Action_Reset'],
     ['Wizard::Elem::Submit', 'value' => 'Return to Top Menu',
      'id' => 99, 'name' => 'Wizard::LDAP::Action_Reset']);
}

sub Action_DeleteUser3 {
    my($self, $wiz) = @_;
    my($prefs, $admin, $user) = $self->init(1);
    $user->Delete();
    $self->OnChange('user', '-delete', {'user' => $user->{'ldap-user-uid'}, 'options' => 
''});
    $self->Action_Reset($wiz);
}
