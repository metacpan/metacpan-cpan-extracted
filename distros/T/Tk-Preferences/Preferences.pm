###################################################
## (Tk::Preferences)    Preferences.pm
## Andrew N. Hicox  <andrew@hicox.com>
## http://www.hicox.com
##
## a module for applying a set of font/color prefs
## to all children of a perl/Tk widget.
###################################################


## Global Stuff ###################################
package Tk::Preferences;
$VERSION = '0.2';


#pollute the namespace of Tk ...
*Tk::SetPrefs = \&Tk::Preferences::SetPrefs;


## SetPrefs #######################################
sub SetPrefs {
    my ($parent, %p) = @_;
   #required options
    exists($p{'-prefs'}) || do {
        $errstr = "-prefs is a required option to SetPrefs";
        warn ($errstr) if $p{'-debug'};
        return (undef);
    };
   #set the palette if defined
    if (exists($p{'-prefs'}->{'Palette'})){
        warn ("setting palette: $p{'-prefs'}->{'Palette'}") if $p{'-debug'};
        $parent->setPalette($p{'-prefs'}->{'Palette'});
    }
   #set prefs in all child widgets
    $parent->Walk(
        sub { $_[0]->Tk::Preferences::ApplyWidget(\%p); }
    );
   #'tis all good
    return (1);
}


## ApplyWidget ####################################
sub ApplyWidget {
    my ($widget, $p) = @_;
    my ($class,$type) = split (/::/,ref($widget));
   #if it's a user defined meta type ...
    foreach (keys %{$p->{'-prefs'}}){ if ($widget->{$_}){ $type = $_; last; } }
   #if there's a user defined callback for this type do that instead of configure
    if ((exists($p->{"-$type"})) && (ref($p->{"-$type"}) eq "CODE")){
        warn ("executing callback for $type") if $p->{'-debug'};
        &{$p->{"-$type"}}( @_ );
    }else{
       #configure widget with given -prefs
        warn ("configuring $type") if $p->{'-debug'};
        $widget->configure(%{$p->{'-prefs'}->{$type}}) if exists($p->{'-prefs'}->{$type});
    }
}