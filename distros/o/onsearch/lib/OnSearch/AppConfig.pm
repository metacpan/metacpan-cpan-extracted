package OnSearch::AppConfig; 

#$Id: AppConfig.pm,v 1.8 2005/07/24 07:57:21 kiesling Exp $

require Exporter;
require DynaLoader;
use OnSearch::Utils;

our (@ISA, @EXPORT_OK);
@ISA = qw(Exporter DynaLoader);
@EXPORT_OK = (qw/webidx_prefs_val new DESTROY/);

=head1 NAME

OnSearch::AppConfig - Configuration library for OnSearch search engine.

=head1 DESCRIPTION

OnSearch::AppConfig provides an object oriented configuration library 
that dynmaically manages the configuration of an operating search engine.  

The libraries provide subroutines and methods to retrieve settings
from the configuration file F<onsearch.cfg> and manage user preferences.

=head1 EXPORTS

=head2 new (I<ref>);

This is the OnSearch::AppConfig constructor.

=head2 DESTROY (I<ref>);

Perl calls the DESTROY method to delete unused OnSearch::AppConfig
objects.

=head1 METHODS

=cut

my $Config = {};

my $http_referer = $ENV{HTTP_REFERER};

=head2 $cfg -> defaultvolume ();

If F<onsearch.cfg> does not define any volumes, B<defaultvolume ()>
returns the hash for the volume, "Default," which is normally the
directory value of, "SearchRoot."

=cut

###
### Config's SearchRoot, server's DocumentRoot otherwise.
###
sub defaultvolume {
    my $self = $_[0];
    
    my %volhash;

    $dir = ($Config->{SearchRoot}) ? $Config->{SearchRoot}[0] : 
	$ENV{DOCUMENT_ROOT};
    my @vol;
    $volhash{Default} = $dir;
    push @vol, (\%volhash);
    return @vol;
}

=head2 $cfg -> WebLogDir ();

Returns the name of OnSearch's Web log directory.

=cut

sub WebLogDir {
    my $self = shift;
    return ${$Config -> {WebLogDir}}[0];
}

=head2 $cfg -> have_config ();

Returns 1 if F<onsearch.cfg> has been read and processed, or undef.

=cut

sub have_config {
    my $self = shift;
    return 1 if $Config -> {SearchRoot};
    return undef;
}

=head2 $cfg -> read_config (I<file_name>);

Read the OnSearch settings from the file name given as the argument.

=cut

###
### Also returns config to $OnSearch::CONFIG when "use OnSearch;" is given.
###
sub read_config {
    my $self = shift;
    my $configname = shift;
    my ($l, $v);

    open CFG, "$configname" or warn "OnSearch: read_config($configname): $!\n";
    LINE: while (defined ($l = <CFG>)) {
	next LINE if ($l =~ /^#/) || ($l =~ /^\s*\n/);
	$l =~ s/\n//g;

        my ($key, $val) = split /\s+/, $l, 2;
	$Config->{key} = OnSearch::Utils::new_array_ref () 
		      unless $Config->{key};
        push @{$Config -> {$key}}, ($val);
    }

    close CFG;
	return $Config;
}

###
###  In general, run-time changes cannot be made to OnSearch's
###  pathnames or permissions, and they are not recognized here.
###
###  We should not need to re-write global prefs anyway, because
###  the user settings are stored in the cookies.
### 
###sub write_pref {
###    my $label = $_[0];
###    my $value1 = $_[1];
###    my $value2 = $_[2];
###    my $line;
###    my $app_dir = $ENV{DOCUMENT_ROOT} . '/' . 
###	OnSearch::AppConfig -> str ('OnSearchDir');
###    my $cfgpath = "$app_dir/onsearch.cfg";
###    my $newcfgpath = "$app_dir/onsearch.cfg.new";
###
###    open OLDCONFIG, "$cfgpath" || die "$cfgpath: $!\n";
###    open NEWCONFIG, ">$newcfgpath" || die "$newcfgpath: $!\n"; 
###
###    while (defined ($line = <OLDCONFIG>)) {
###	# Multiples, so append
###	if (($label =~ /ExcludeDir|
###	     ExcludeWord|
###	     ExcludeGlob/x) && 
###	    ($line =~ m"^$label")) {
###	    print NEWCONFIG "$label $value1\n";
###	}
###    
###	# One entry only, so replace
###	if (($label =~ /DigitsOnly|
###	    SearchContext|
###	    PartialWordMatch|
###	    BackupIndexes|
###	    IndexInterval/x) && 
###	    ($line =~ m"^$label")){
###	    print NEWCONFIG "$label $value1\n";
###	    next;
###	}
###
###	# Special case because there are two parameters.
###	if (($label =~ /PlugIn/) && ($line =~ m"^$label")){
###	    print NEWCONFIG "$label $value1 $value2\n";
###	}
###	print NEWCONFIG $line;
###    }
###
###    close NEWCONFIG;
###    close OLDCONFIG;
###    rename ($newcfgpath, $cfgpath);
###}

=head2 $cfg -> prefs_val (I<query_object>);

Formats and encodes the value of a search preferences cookie from the 
OnSearch::CGIQuery object given as the argument.

=cut

sub prefs_val {
    my $ref = $_[0];
    my $q = $_[1];

    my $prefs_str = "<prefs>\n" .
"  <param name=\"matchcase\">" . $q->param_value('matchcase') . "</param>\n" .
"  <param name=\"matchtype\">" . $q->param_value('matchtype') . "</param>\n" .
"  <param name=\"partword\">".$q->param_value('partword')."</param>\n" .
"  <param name=\"pagesize\">".$q->param_value('pagesize')."</param>\n" .
"  <param name=\"nresults\">".$q->param_value('nresults')."</param>\n" .
"</prefs>\n";

    $prefs_str = OnSearch::Base64::encode_base64 ($prefs_str);
    $prefs_str =~ s/\n/!!/gm;
    return $prefs_str;
}

=head2 webidx_prefs_val (I<query_object>);

Formats the value of the Web index cookie from the values in
the OnSearch::CGIQuery object given as the argument.

=cut

sub webidx_prefs_val {
    my $self = $_[0];
    my $q = $_[1];

    $prefs_str ='<prefs>' . "\n" . 
'<param name="targetscope">'.$q -> param_value('targetscope').'</param>'."\n". 
'</prefs>' . "\n";
    $prefs_str = OnSearch::Base64::encode_base64 ($prefs_str);
    $prefs_str =~ s/\n/!!/gm;
    return $prefs_str;
}

=head2 $cfg -> vols_prefs_val (I<query_object>);

Formats the value of the volume preferences cookie from the values in
the argument's OnSearch::CGIQuery object

=cut

sub vols_prefs_val {
    my $self = $_[0];
    my $volref = $_[1];

    my $volumes = join ',', @{$volref};
    my $volumes_str = OnSearch::Base64::encode_base64 ($volumes);
    $volumes_str =~ s/\n/!!/gm;
    return $volumes_str;
}

=head2 $cfg -> get_prefs (I<value>);

Return the preferences from the cookie value given in the argument.

=cut

sub get_prefs {
    my $self = $_[0];
    my $val = $_[1];
    $val =~ s/!!/\n/g;
    return OnSearch::Base64::decode_base64 ($val);
}

=head2 $cfg -> parse_prefs (I<str>);

Return a hash of preference key/value pairs.

=cut

sub parse_prefs {
    my $self = $_[0];
    my $prefs_str = $_[1];
    my %prefs_hash;
    return undef if $prefs_str =~ /none/;

    my @prefs_list = split /\n/, $prefs_str;
    my ($attrib, $val);
    
    foreach my $p (@prefs_list) {
	next if $p !~ /\s*<param/;
	($attrib, $val) = 
	    $p =~ /\s*<param name="(.*)">(.*)</;
	$prefs_hash{$attrib} = $val;
    }
    return %prefs_hash;
}

=head2 $cfg -> Volumes ();

Return a hash of the volumes configured in F<onsearch.cfg.>

=cut

sub Volumes {
    my $self = $_[0];
    my (%vols, $v);
    if ($Config && defined @{$Config -> {Volume}}) {
	foreach $v (@{$Config -> {Volume}}) {
	    my ($key, $val) = split /\s+/, $v;
	    $vols{$key} = $val;
	}
    } else {
	$vols{Default} = @{$Config -> {SearchRoot}}[0];
    }
    return %vols;
}

=head2 $cfg -> lst (I<key>);

Return the list of configuration values for the setting given as the 
argument.

=cut

sub lst {
    my $ref = $_[0];
    if ( $Config && exists $Config -> {$_[1]}) {
	return @{$Config -> {$_[1]}};
    }
    return undef;
}

=head2 $cfg -> str (I<key>);

Return the value of the F<onsearch.cfg> setting given as the argument.

=cut

sub str {
    my $self = $_[0];
    if ( $Config && defined @{$Config -> {$_[1]}}[0]) {
	return ${$Config -> {$_[1]}}[0];
    }
    return undef;
}

=head2 $cfg -> on (I<key>);

Returns 1 if the value of the F<onsearch.cfg> setting given as 
the argument is non-zero, or undef otherwise.

=cut

sub on {
    my $self = $_[0];
    if ( $Config && defined @{$Config -> {$_[1]}}[0]) {
	return 1 if @{$Config -> {$_[1]}}[0] ne '0';
    }
    return undef;
}

=head2 $cfg -> CONFIG ();

Return the $Config hash reference.

=cut

sub CONFIG {
    my $self = $_[0];
    return $Config;
}

=head2 new (I<classref>);

This is the OnSearch::AppConfig constructor.

=cut

sub new {
    my $class = shift || __PACKAGE__;
    my $obj = {};
    bless $obj, $class;
    return $obj;
}

=head2 $cfg -> DESTROY ();

The OnSearch::AppConfig class destructor.  Perl also calls DESTROY to 
delete unused OnSearch::AppConfig ojbects.

=cut

sub DESTROY {
    my ($self) = @_;
    undef %{$self};
}

=head2 $cfg -> is_symlink (I<file_name>);

Returns 1 if the file name given as the argument is a symlink, or 
undef otherwise.

=cut

sub is_symlink {
    my $self = $_[0];
    my $fn = $_[1];
    return (-l $fn) ? 1 : undef;
}

1;

__END__

=head1 VERSION AND CREDITS

$Id: AppConfig.pm,v 1.8 2005/07/24 07:57:21 kiesling Exp $

Written by Robert Kiesling <rkies@cpan.org> and licensed under the
same terms as Perl.  Refer to the file, "Artistic," for information.

=head1 SEE ALSO

L<OnSearch(3)>

=cut

