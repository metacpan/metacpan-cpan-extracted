# -*- perl -*-

use strict;

use Wizard::State ();
use Wizard::SaveAble ();
use Wizard::Examples::Apache::Config ();


package Wizard::Examples::Apache;

@Wizard::Examples::Apache::ISA     = qw(Wizard::Examples);
$Wizard::Examples::Apache::VERSION = '0.01';


sub GetKey { 'prefs'; };

sub init {
    my $self = shift;
    my $prefs = $self->{'prefs'} || die "Missing preferences";
    return ($prefs) unless shift;
    my $basedir = $prefs->{'apache-prefs-basedir'} || die "Missing basedir";
    wantarray ? ($prefs, $basedir) : $prefs;
}

sub getFileDir {
    my($self, $wiz) = @_;
    my $basedir = $self->{'prefs'}->{'apache-prefs-basedir'};
    wantarray ? ($basedir, $basedir) : $basedir;
}

sub Action_Reset {
    my($self, $wiz) = @_;

    # Load prefs, if required.
    unless ($self->{'prefs'}) {
	my $cfg = $Wizard::Examples::Apache::Config::config;
	my $file = $cfg->{'apache-prefs-file'};
	$self->{'prefs'} = Wizard::SaveAble->new('file' => $file, 'load' => 1);
	$self->Store($wiz);
    }

    # Return the initial menu.
    (['Wizard::Elem::Title', 'value' => 'Apache Wizard Menu'],
     ['Wizard::Elem::Submit', 'value' => 'Host Menu',
      'name' => 'Wizard::Examples::Apache::Host::Action_Reset',
      'id' => 1],
     ['Wizard::Elem::BR'],
     ['Wizard::Elem::Submit', 'value' => 'Apache Wizard preferences',
      'name' => 'Action_Preferences',
      'id' => 2],
     ['Wizard::Elem::BR'],
     ['Wizard::Elem::Submit', 'value' => 'Return to Wizard Examples',
      'name' => 'Wizard::Examples::Action_Reset',
      'id' => 98],
     ['Wizard::Elem::BR'],
     ['Wizard::Elem::Submit', 'value' => 'Exit Apache Wizard',
      'id' => 99]);
}


sub Action_Preferences {
    my($self, $wiz) = @_;
    my $prefs = $self->init();

    # Return a list of input elements.
    (['Wizard::Elem::Title', 'value' => 'Apache Wizard Preferences'],
     ['Wizard::Elem::Text', 'name' => 'apache-prefs-basedir',
      'value' => $prefs->{'apache-prefs-basedir'},
      'descr' => 'Base Directory of the Apache Wizard'],
     ['Wizard::Elem::Submit', 'name' => 'Action_PreferencesSave',
      'value' => 'Save these settings', 'id' => 1],
     ['Wizard::Elem::Submit', 'name' => 'Action_PreferencesReset',
      'value' => 'Reset this form', 'id' => 98],
     ['Wizard::Elem::Submit', 'name' => 'Action_Reset',
      'value' => 'Return to top menu', 'id' => 99]);
}


sub Action_PreferencesSave {
    my($self, $wiz) = @_;
    my $prefs = $self->init();
    foreach my $opt (qw(apache-prefs-basedir)) {
	$prefs->{$opt} = $wiz->param($opt) if defined($wiz->param($opt));
    }
    $prefs->Modified(1);
    $self->Store($wiz, 1);
    $self->Action_Reset($wiz);
}


sub Action_PreferencesReset {
    my($self, $wiz) = @_;
    $self->Action_Reset($wiz);
    $self->Action_Preferences($wiz);
}


1;
