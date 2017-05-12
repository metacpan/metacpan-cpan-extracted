# -*- perl -*-

use Socket ();
use Wizard ();
use Wizard::State ();
use Wizard::SaveAble();
use Wizard::LDAP::Config ();

package Wizard::LDAP;

@Wizard::LDAP::ISA = qw(Wizard::State);
$Wizard::LDAP::VERSION = '0.1008';

sub init {
    my $self = shift; 
    my $item = $self->{'prefs'} || die "Missing prefs";
    my $admin = { 'ldap-admin-dn' => $item->{'ldap-prefs-adminDN'},
		  'ldap-admin-password' => $item->{'ldap-prefs-adminPassword'} };
    ($item, $admin);
}

sub Action_Reset {
    my($self, $wiz) = @_;

    # Load prefs, if required.
    unless ($self->{'prefs'}) {
	my $cfg = $Wizard::LDAP::Config::config;
	my $file = $cfg->{'ldap-prefs-file'};
	$self->{'prefs'} = Wizard::SaveAble->new('file' => $file, 'load' => 1);
    }
    $self->Store($wiz);

    # Return the initial menu.
    (['Wizard::Elem::Title', 'value' => 'LDAP Wizard Menu '],
     ['Wizard::Elem::Submit', 'value' => 'User Menu',
      'name' => 'Wizard::LDAP::User::Action_Reset',
      'id' => 1],
     ['Wizard::Elem::Submit', 'value' => 'Net Menu',
      'name' => 'Wizard::LDAP::Net::Action_Reset',
      'id' => 2],
     ['Wizard::Elem::BR'],
     ['Wizard::Elem::Submit', 'value' => 'LDAP Wizard preferences',
      'name' => 'Action_Preferences',
      'id' => 3],
     ['Wizard::Elem::BR'],
     ['Wizard::Elem::Submit', 'value' => 'Exit LDAP Wizard',
      'id' => 99]);
}

sub Action_Preferences {
    my($self, $wiz) = @_;
    my ($prefs, $admin)  = $self->init();

    # Return a list of input elements.
    (['Wizard::Elem::Title', 'value' => 'LDAP Wizard Preferences'],
     ['Wizard::Elem::Text', 'name' => 'ldap-prefs-serverip',
      'value' => $prefs->{'ldap-prefs-serverip'},
      'descr' => 'Server DNS name or IP Adress of the LDAP Server'],
     ['Wizard::Elem::Text', 'name' => 'ldap-prefs-serverport',
      'value' => $prefs->{'ldap-prefs-serverport'},
      'descr' => 'Server Port of the LDAP Server (default LDAP port on 0)'],
     ['Wizard::Elem::Text', 'name' => 'ldap-prefs-adminDN',
      'value' => $prefs->{'ldap-prefs-adminDN'},
      'descr' => 'Distinguished name of the admin object we bind as ' .
                 'to the server'],
     ['Wizard::Elem::Text', 'name' => 'ldap-prefs-adminPassword',
      'value' => $prefs->{'ldap-prefs-adminPassword'},
      'descr' => 'Password of the admin object'],
     ['Wizard::Elem::Text', 'name' => 'ldap-prefs-nextuid',
      'value' => $prefs->{'ldap-prefs-nextuid'} || '500',
      'descr' => 'Next UID that will be assigned (increased automatically'],
     ['Wizard::Elem::Text', 'name' => 'ldap-prefs-gid',
      'value' => $prefs->{'ldap-prefs-gid'} || '500',
      'descr' => 'Group ID of the group the users will belong to'],
     ['Wizard::Elem::Text', 'name' => 'ldap-prefs-home',
      'value' => $prefs->{'ldap-prefs-home'} || '/home',
      'descr' => 'Homedir prefix'],
     ['Wizard::Elem::Text', 'name' => 'ldap-prefs-userbase',
      'value' => $prefs->{'ldap-prefs-userbase'} || 'dc=ispsoft, c=de',
      'descr' => 'LDAP base for user administration'],
     ['Wizard::Elem::Text', 'name' => 'ldap-prefs-netbase',
      'value' => $prefs->{'ldap-prefs-netbase'} || 'dc=ispsoft, c=de',
      'descr' => 'LDAP base for net administration'],
     ['Wizard::Elem::Text', 'name' => 'ldap-prefs-domain',
      'value' => $prefs->{'ldap-prefs-domain'} || '',
      'descr' => 'Default domain for user administration'],
     ['Wizard::Elem::Text', 'name' => 'ldap-prefs-prefschange',
      'value' => $prefs->{'ldap-prefs-prefschange'} || '',
      'descr' => 'Shell command after the prefs have been changed'],
     ['Wizard::Elem::Text', 'name' => 'ldap-prefs-hostchange',
      'value' => $prefs->{'ldap-prefs-hostchange'} || '',
      'descr' => 'Shell command after Hosts have been changed'],
     ['Wizard::Elem::Text', 'name' => 'ldap-prefs-netchange',
      'value' => $prefs->{'ldap-prefs-netchange'} || '',
      'descr' => 'Shell command after Nets have been changed'],
     ['Wizard::Elem::Text', 'name' => 'ldap-prefs-userchange-new',
      'value' => $prefs->{'ldap-prefs-userchange-new'} || '',
      'descr' => 'Shell command after an user has been created'],
     ['Wizard::Elem::Text', 'name' => 'ldap-prefs-userchange-modify',
      'value' => $prefs->{'ldap-prefs-userchange-modify'} || '',
      'descr' => 'Shell command after an user has been modified'],
     ['Wizard::Elem::Text', 'name' => 'ldap-prefs-userchange-delete',
      'value' => $prefs->{'ldap-prefs-userchange-delete'} || '',
      'descr' => 'Shell command after an user has been deleted'],
     ['Wizard::Elem::Submit', 'name' => 'Action_PreferencesSave',
      'value' => 'Save these settings', 'id' => 1],
     ['Wizard::Elem::Submit', 'name' => 'Action_PreferencesReset',
      'value' => 'Reset this form', 'id' => 98],
     ['Wizard::Elem::Submit', 'name' => 'Action_Reset',
      'value' => 'Return to top menu', 'id' => 99]);
}


#
# universal method, that is supposed to be used by subclasses
#
sub ItemList {
    my($self, $prefs, $admin, $base, $key) = @_;

    my $ldap = Net::LDAP->new($prefs->{'ldap-prefs-serverip'},
			      (($prefs->{'ldap-prefs-serverport'} >0) ?
			       (port => $prefs->{'ldap-prefs-serverport'}) : ()));
    die "Could not create LDAP object, maybe connecting is currently not "
	. "possible , probable cause: $@" 
	    unless ref($ldap);

    my $dn = $admin->{'ldap-admin-dn'};
    my $password = $admin->{'ldap-admin-password'};
    $ldap->bind(dn      => $dn,	password => $password)
	|| die "Cannot bind to LDAP server $@";
    my $mesg = $ldap->search(base => $base,
			     filter => $key . '=*',
			     scope => 1);
    die ("Following error occured while searching for $base: code=",
	 $mesg->code, ", error=", $mesg->error)  if $mesg->code;

    my @items = map { ($_->get($key)) } $mesg->entries;
    $ldap->unbind();
    wantarray ? @items : $mesg;
}


sub Action_PreferencesSave {
    my($self, $wiz) = @_;
    my ($prefs, $admin) = $self->init();
    foreach my $opt ($wiz->param()) {
	$prefs->{$opt} = $wiz->param($opt) 
	    if (($opt =~ /^ldap\-prefs/) && (defined($wiz->param($opt))));
    }

    my $errors = '';
    my $ip = $prefs->{'ldap-prefs-serverip'} 
        or ($errors .= "Missing Server IP or DNS name.\n");
    my $adminDN = $prefs->{'ldap-prefs-adminDN'}
        or ($errors .= "Missing admin DN.\n");
    my $port = $prefs->{'ldap-prefs-serverport'};
    my $uid = $prefs->{'ldap-prefs-nextuid'};
    my $gid = $prefs->{'ldap-prefs-gid'};
    my $home = $prefs->{'ldap-prefs-home'};
    if($ip) {
	unless(Socket::inet_aton($ip)) {
	    $errors .= "Unresolveable server DNS name $ip.\n";
	}
    }
    $port = 0 if $port eq '';
    $errors .= "Invalid port $port.\n" unless $port =~ /^[\d]*$/;
    $errors .= "Invalid UID $uid" unless $uid =~ /^[\d]+$/;
    $errors .= "Invalid GID $gid" unless $gid =~ /^[\d]+$/;
    if ($home =~ /^((\/[^\/]+)+)\/?$/) {
	$prefs->{'ldap-prefs-home'} = $home = $1;
    } else {
	$errors .= "Invalid home $home";
    }
    die $errors if $errors;
    $prefs->Modified(1);
    $self->Store($wiz, 1);
    $self->OnChange('prefs');
    $self->Action_Reset($wiz);
}

sub Action_PreferencesReset {
    my($self, $wiz) = @_;
    $self->Action_Reset($wiz);
    $self->Action_Preferences($wiz);
}

sub OnChange {
    my $self = shift; my $topic = shift;
    my $mode = shift || '';
    my $subst = shift || {};
    my($prefs) = $self->init();
    my $cmd = $prefs->{'ldap-prefs-' . $topic . 'change' . $mode};
    my ($k, $s);
    while(($k, $s) = each %$subst) {
	$cmd =~ s/\$$k/$s/g;
    }
    my $file = $cmd; $file =~ s/\ .*//g;
    `$cmd` if(-f $file);
}


1;


__END__

=pod

=head1 NAME

Wizard::LDAP - Administration interface for your LDAP server


=head1 SYNOPSIS

  # From the shell:
  ldapWizard

  # Or, from the WWW:
  <a href="ldap.ep">LDAP administraton</a>


=head1 DESCRIPTION

This is a package for administration of an LDAP server. It allows to
feed users, hosts and networks into the server.


=head1 INSTALLATION

First of all, you have to install the prerequisites. There are lots
of:

=over

=item An LDAP Server

You need some LDAP server. We are using the OpenLDAP server, see

  http://www.openldap.org/

In theory any other LDAP server should do, but the servers configuration
might be different.

A source RPM for Red Hat Linux is available on demand.

To configure the LDAP server, edit the file F<topics.ldif> from the
distribution. Currently it looks like

  dn: topic=user, dc=ispsoft, dc=de
  name: user 
  objectclass: topic

  dn: topic=net, dc=ispsoft, dc=de
  name: net 
  objectclass: topic

Change "dc=ispsoft, dc=de" to reflect your local settings. For example,
if you are using the mail domain "mycompany.com", then you might choose

  dc=mycompany, dc=com

Import the file into your LDAP server by using the command

  ldif2ldbm -i topics.ldif

(The above command will trash an existing LDAP database! Use ldapadd
if you want to avoid this.)

Append the files F<slapd.at.conf.APPEND> and F<slapd.oc.conf.APPEND>
to your F</etc/openldap/slapd.at.conf> and F</etc/openldap/slapd.oc.conf>
and restart the OpenLDAP server.

=item IO::AtomicFile

This is a Perl package for atomic operations on important files.

=item HTML::EP

If you like to use the WWW administration interface, you need the
embedded Perl system HTML::EP.

=item Wizard

Another Perl module, available at the same place.

=item Convert::BER

=item Net::LDAP

To talk to the LDAP server, we use Graham Barr's Net::LDAP package.
It is written in 100% Perl, no underlying C library required.

=item Net::Netmask

Used to determine conformance of host IP´s to a network.

=back

All the above packages are available on any CPAN mirror, for example

  ftp://ftp.funet.fi/pub/languages/perl/CPAN/authors/id

or perhaps at the same place where you found this file. :-)

Note that some of the packages have their own requirements. For
example, HTML::EP depends on libwww and the MailTools. If so, you
will be told while installing the modules. See below for the
installation of the Perl modules.


=head2 Installing the Perl modules

Installing a Perl module is always the same:

  gzip -cd Wizard-LDAP-0.1005.tar.gz | tar xf -
  cd Wizard-LDAP-0.1005
  perl Makefile.PL
  make
  make test
  make install

Alternatively you might try using the automatic installation that the
CPAN module offers you:

  perl -MCPAN -e shell
  install Bundle::Wizard::LDAP

Note that some of the modules, in particular HTML::EP, need additional
configuration tasks, for example modifying the web servers configuration
files.


=head2 Some final tasks

You have to create a directory F</etc/Wizard-LDAP> and make it owned
by the httpd user, so that CGI binaries can write into this directory.

Copy the file F<ldap.ep> into your web servers root directory. (I
choose F</home/httpd/html/admin/ldap.ep> on my Red Hat Linux box.)

Point your browser too the corresponding location, for example

  http://localhost/admin/ldap.ep

Start with modifying the preferences.


=head1 AUTHORS AND COPYRIGHT

This module is

  Copyright (C) 1999     Jochen Wiedmann
                         Am Eisteich 9
                         72555 Metzingen
                         Germany

                         Email: joe@ispsoft.de

                 and     Amarendran R. Subramanian
                         Grundstr. 32
                         72810 Gomaringen
                         Germany

                         Email: amar@ispsoft.de

All Rights Reserved.

You may distribute under the terms of either the GNU
General Public License or the Artistic License, as
specified in the Perl README file.


=head1 SEE ALSO

L<Wizard(3)>, L<ldapWizard(1)>, L<HTML::EP(3)>, L<Net::LDAP(3)>

=cut
