# -*- perl -*-

use strict;

use Wizard::State ();
use Wizard::SaveAble ();
use Wizard::Examples::ISDN::Config ();


package Wizard::Examples::ISDN;

@Wizard::Examples::ISDN::ISA     = qw(Wizard::Examples);
$Wizard::Examples::ISDN::VERSION = '0.01';


sub GetKey { 'prefs'; };

sub init {
    my $self = shift;
    my $prefs = $self->{'prefs'} || die "Missing preferences";
    return ($prefs) unless shift;
    my $cfile = $prefs->{'isdn-prefs-cfile'} || die "Missing config file";
    wantarray ? ($prefs, $cfile) : $prefs;
}


sub Action_Reset {
    my($self, $wiz) = @_;

    # Load prefs, if required.
    unless ($self->{'prefs'}) {
	my $cfg = $Wizard::Examples::ISDN::Config::config;
	my $file = $cfg->{'isdn-prefs-file'};
	$self->{'prefs'} = Wizard::SaveAble->new('file' => $file, 'load' => 1);
	$self->Store($wiz);
    }

    # Return the initial menu.
    (['Wizard::Elem::Title', 'value' => 'ISDN Wizard Menu'],
     ['Wizard::Elem::Submit', 'value' => 'ISDN Wizard preferences',
      'name' => 'Wizard::Examples::ISDN::Action_Preferences',
      'id' => 1],
     ['Wizard::Elem::Submit', 'value' => 'ISDN Settings Wizard',
      'name' => 'Wizard::Examples::ISDN::Settings::Action_Reset',
      'id' => 2],
     ['Wizard::Elem::BR'],
     ['Wizard::Elem::Submit', 'value' => 'Return to Wizard Examples',
      'name' => 'Wizard::Examples::Action_Reset',
      'id' => 98],
     ['Wizard::Elem::Submit', 'value' => 'Exit ISDN Wizard',
      'id' => 99]);
}


sub Action_Preferences {
    my($self, $wiz) = @_;
    my $prefs = $self->init();

    # Return a list of input elements.
    (['Wizard::Elem::Title', 'value' => 'ISDN Wizard Preferences'],
     ['Wizard::Elem::Text', 'name' => 'isdn-prefs-cfile',
      'value' => $prefs->{'isdn-prefs-cfile'},
      'descr' => 'ISDN Configfile'],
     ['Wizard::Elem::Text', 'name' => 'isdn-prefs-updatecmd',
      'value' => $prefs->{'isdn-prefs-updatecmd'},
      'descr' => 'Command that will be executed on update'],
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
    foreach my $opt (qw(isdn-prefs-cfile isdn-prefs-updatecmd)) {
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

