package WWW::phpBB::Mod::Installer;

use 5.008008;
use strict;
use warnings;

use Carp;
use File::Basename;
use Data::Dumper;
use Cwd 'abs_path';
use File::Copy;
use XML::Xerces;
use DBI;


our $VERSION = '0.03';


require Exporter;

our @ISA = qw(Exporter);

our %EXPORT_TAGS = ( 'all' => [ qw() ] );
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
our @EXPORT = qw(uninstall_phpbb_mod
                 install_phpbb_mod
);


use constant ERROR => 'ERROR';
use constant DEBUG => 'DEBUG';
use constant AUDIT => 'AUDIT';

use constant INSTALL   => 'INSTALL';
use constant UNINSTALL => 'UNINSTALL';

use constant DEFAULT_LANG    => 'en';
use constant DEFAULT_STYLE   => 'prosilver';
use constant DEFAULT_VERSION => 0;


my $script_absolute_path;
my $install_absolute_path;
my $install_absolute_file;
my $web_root_absolute_path;
my $backup_dir;
my $config_file;
my %log_handles;
my %headers;
my $phpbb_config_ref;
my $dbh;
my $phpbb_version;
my $style;
my $lang;


###############################
# TODO
# 1. Support the uninstall command
# which will remove any edits made
# and also delete files copied as part of the install
# It will not modify the database.
#
##############################

sub uninstall_phpbb_mod{
    my %args = shift;
    $args{OPERATION} = UNINSTALL;
    install_mod(%args);
}

sub install_phpbb_mod{
    my %args = (@_);
    my $install_file = $args{INSTALL_FILE};
    my $web_root     = $args{WEB_ROOT};
    my $tmp_style    = $args{STYLE};
    my $tmp_lang     = $args{LANG};
    my $operation    = $args{OPERATION} || INSTALL;
    
    _setup();
    
    unless (-f $install_file) {
        _write_log_entry(ERROR, "The install file '$install_file' does not exist.");
        croak "\n\nThe install file '$install_file' does not exist.\n\n";
    }
    unless (-d $web_root) {
        _write_log_entry(ERROR, "The phpbb web root directory '$web_root' does not exist.");
        croak "\n\nThe phpbb web root directory '$web_root' does not exist.\n\n";
    }

    $install_absolute_path  = abs_path( dirname($install_file) );
    if ($install_absolute_path =~ /^(.*)\/templates$/){
        $install_absolute_path = $1;
    }
    _write_log_entry(DEBUG, "Install root path: $install_absolute_path");
    $install_absolute_file  = abs_path($install_file);
    _write_log_entry(DEBUG, "Install file: $install_absolute_file");
    $web_root_absolute_path = abs_path( $web_root);
    _write_log_entry(DEBUG, "phpBB web root: $web_root_absolute_path");
    $config_file            = "$web_root_absolute_path/config.php";
    _write_log_entry(DEBUG, "phpBB config file: $config_file");
    
    unless (-f $config_file) {
        _write_log_entry(ERROR, "The phpbb web root directory '$web_root_absolute_path' does not contain a config.php");
        croak "\n\nThe phpbb web root directory '$web_root_absolute_path' does not contain a config.php\n\n";
    }

    $phpbb_config_ref = _read_phpbb_config();
    eval {my $dbh = _mysql_connect();};
    $phpbb_version = _get_phpbb_version();
    $lang = $tmp_lang || _get_phpbb_lang();
    _write_log_entry(AUDIT, "Language: '$lang'");
    $style = $tmp_style || _get_phpbb_style();
    _write_log_entry(AUDIT, "Style: '$style'");
    
    _write_log_entry(AUDIT, "Initialisation complete, processing installation file '$install_absolute_file'");
    my $doc = _load_install_file($install_absolute_file);
    my $instruction_ref = _process_document($doc);
    _write_log_entry(DEBUG, 'Instruction list: ' . Data::Dumper->Dump([$instruction_ref]));
    
    if ($headers{target_version} ne $phpbb_version){
        warn "\nWARNING: This mod is intended for a different version of phpbb\n" . 
             "\tBoard Version $phpbb_version\n" .
             "\tMod written for version $headers{target_version}\n\n";
    }
    
    if ($operation eq INSTALL){
        _write_log_entry(AUDIT, "Beginning installation for mod $headers{title} " .
                                "version $headers{version_major}.$headers{version_minor}".
                                ".$headers{version_revision}$headers{version_release} " .
                                "by $headers{author}");
        _process_instructions($instruction_ref, $backup_dir);
    }
    elsif($operation eq UNINSTALL){
        _write_log_entry(AUDIT, "Beginning uninstall for mod $headers{title} " .
                                "version $headers{version_major}.$headers{version_minor}".
                                ".$headers{version_revision}$headers{version_release} " .
                                "by $headers{author}");
        _process_uninstall($instruction_ref, $backup_dir);
    }
    else{
        _write_log_entry(ERROR, "Unsupported operation '$operation'.\n");
        croak "Unsupported operation '$operation'.\n" . 
              "Only\n\tOPERATION => 'INSTALL'\n\tOPERATION => 'UNINSTALL'\n" .
              "are supported.\n";
    }
    
    _write_log_entry(AUDIT, 'Complete');
    _tear_down();
}


sub _setup{
    $script_absolute_path   = abs_path( dirname($0) );
    
    $backup_dir = _create_backup_dirs($script_absolute_path);
    
    my $log_dir = "$script_absolute_path/logs";
    if (!-d $log_dir){
        _create_dir_recursive($log_dir);
    }
    
    open(my $error_handle, '>>', "$log_dir/error.log") 
        or croak "Can't open error log file $log_dir/error.log: $!\n";
    open(my $debug_handle, '>>', "$log_dir/debug.log") 
        or croak "Can't open debug log file $log_dir/debug.log: $!\n";
    open(my $audit_handle, '>>', "$log_dir/audit.log") 
        or croak "Can't open audit log file $log_dir/audit.log: $!\n";
    
    $log_handles{ERROR} = $error_handle;
    $log_handles{DEBUG} = $debug_handle;
    $log_handles{AUDIT} = $audit_handle;
}

sub _tear_down{
    $dbh->disconnect() if $dbh;
    foreach my $handle (keys %log_handles){
        close $log_handles{$handle};
    }
}

sub _get_phpbb_version{
    my $version;
    if ($dbh){
        my $sql = "select * from " . $phpbb_config_ref->{table_prefix} . 
                    "config where config_name = 'version'" ;
        my $res ;
        #selectall_hashref causes warnings from File::Copy under windows
        #eval{$res = $dbh->selectall_hashref($sql, 'config_name') } ;
        eval{$res = $dbh->selectall_arrayref($sql) } ;
        $version = $res->[0]->[1];
        _write_log_entry(AUDIT, "phpBB version: $version");
    }
    else{
        _write_log_entry(AUDIT, 'No database connection, cannot get phpBB version');
    }
    
    if (!$version){
        $version = DEFAULT_VERSION;
    }
    
    return $version;
}

sub _get_phpbb_lang{
    my $lang;
    if ($dbh){
        my $sql = "select config_value from " . $phpbb_config_ref->{table_prefix} . 
                    "config where config_name = 'default_lang'" ;
        my $res ;
        #selectall_hashref causes warnings from File::Copy under windows
        #eval{$res = $dbh->selectall_hashref($sql, 'config_name') } ;
        eval{$res = $dbh->selectall_arrayref($sql) } ;
        $lang = $res->[0]->[0];
        _write_log_entry(DEBUG, "phpBB default lang: $lang");
    }
    else{
        _write_log_entry(AUDIT, 'No database connection, cannot get phpBB language');
    }
    
    if (!$lang){
        $lang = DEFAULT_LANG;
    }
    
    return $lang;
}

sub _get_phpbb_style{
    my $style;
    if ($dbh){
        my $sql = "select template_path from " . $phpbb_config_ref->{table_prefix} .
                  "styles_template where template_id = " .
                    "(select template_id from " . $phpbb_config_ref->{table_prefix} .
                    "styles where style_id = " .
                        "(select config_value from " . $phpbb_config_ref->{table_prefix} .
                        "config where config_name = 'default_style'))" ;
        my $res ;
        #selectall_hashref causes warnings from File::Copy under windows
        #eval{$res = $dbh->selectall_hashref($sql, 'config_name') } ;
        eval{$res = $dbh->selectall_arrayref($sql) } ;
        $style = $res->[0]->[0];
        _write_log_entry(DEBUG, "phpBB default style path: $style");
    }
    else{
        _write_log_entry(AUDIT, 'No database connection, cannot get phpBB style');
    }
    
    if (!$style){
        $style = DEFAULT_STYLE;
    }
    
    return $style;
}

sub _mysql_connect {

    if ($phpbb_config_ref->{dbms} eq 'mysql'){
        $dbh = DBI->connect(
            'DBI:mysql:database=' . $phpbb_config_ref->{dbname} .';host=' . $phpbb_config_ref->{dbhost},
            $phpbb_config_ref->{dbuser},
            $phpbb_config_ref->{dbpasswd},
            {   RaiseError => 1,
                AutoCommit => 1,
            }
        );
    }
    else{
        _write_log_entry(AUDIT, 'Only mysql databases are supported, database updates are not possible');
    }

    return $dbh;
}

sub _read_phpbb_config{
    my %phpbb_config;
    open IN, '<', $config_file or croak "Can't open phpbb config file: $!\n";
    while(<IN>) {
        my $line=$_;
        if ($line =~ /^\s*\$(\w+)\s*=\s*'(\w*)'\;\s*$/) {
            $phpbb_config{$1} = $2;
        }
        elsif ($line =~ /^\s*\@define\('(\w+)',\s*(\w+)\);\s*$/){
            $phpbb_config{$1} = $2;
        }
    }
    close (IN);
    _write_log_entry(DEBUG, "phpBB Config: " . Data::Dumper->Dump([\%phpbb_config]));
    
    return \%phpbb_config;
}

sub _load_install_file {
    my $install_filename = shift;
    
    #create a parser and attempt to parse the XML document
    my $dom = XML::Xerces::XercesDOMParser->new();
    my $error_handler = XML::Xerces::PerlErrorHandler->new();
    $dom->setErrorHandler($error_handler);
    eval{$dom->parse($install_filename)};
    croak("Couldn't parse file: $install_filename\n$@") if $@;

    #the parse was successful, we have a well formed xml instance
    my $doc = $dom->getDocument();
    
    return $doc;
}

sub _write_log_entry{
    my $type = shift;
    my $message = shift;
    
    my ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst)
        = localtime(time);
    my $curr_time = sprintf "%4d-%02d-%02d %02d:%02d:%02d", $year+1900,$mon+1,$mday,$hour,$min,$sec;
    my $log_line = "$curr_time - $message\n";

    my $file_handle = $log_handles{$type};
    if ($file_handle){
        print $file_handle $log_line;
    }
    else{
        warn $log_line;
    }
}

sub _process_document {
    my $install_doc = shift;
    
    my @instruction_list;
    my $root = $install_doc->getDocumentElement();
    
    if ($root->hasChildNodes()) {
        ROOT: foreach my $child ($root->getChildNodes) {
            my $child_name = $child->getNodeName();
            if ($child->isa('XML::Xerces::DOMElement')){
                if ($child_name eq 'action-group'){
                    #process this node
                    if ($child->hasChildNodes()) {
                        foreach my $action ($child->getChildNodes) {
                            my $action_name = $action->getNodeName();
                            if ($action->isa('XML::Xerces::DOMElement')){
                                if ($action_name eq 'copy'){
                                    my $copy_ref = _process_copy($action);
                                    push (@instruction_list, $copy_ref);
                                }
                                elsif ($action_name eq 'sql'){
                                    my $sql_ref = _process_sql($action);
                                    push (@instruction_list, $sql_ref);
                                }
                                elsif ($action_name eq 'open'){
                                    my $open_ref = _process_open($action);
                                    push (@instruction_list, $open_ref);
                                }
                                elsif ($action_name eq 'diy-instructions'){
                                    my $diy_ref = _process_diy_instructions($action);
                                    push (@instruction_list, $diy_ref);
                                }
                            }
                        }
                    }
                    else{
                        #no actions
                        croak "No actions to perform\n";
                    }
                }
                elsif ($child_name eq 'header'){
                    _process_header($child);
                }
                else{
                    _write_log_entry(DEBUG, "Found additional first level child '$child_name' - skipping....");
                }
            }
        }
    }
    else{
        croak "Empty document nothing to process\n";
    }
    
    return \@instruction_list;
}

sub _process_header{
    my $header = shift;

    foreach my $child ($header->getChildNodes) {
        my $child_name = $child->getNodeName();
        if ($child->isa('XML::Xerces::DOMElement')){
            if ($child_name eq 'title'){
                $headers{title} = $headers{title} || $child->getTextContent();
                my %child_attrs = $child->getAttributes();
                foreach my $attr_name (keys %child_attrs) {
                    if ($attr_name eq 'lang'){
                        if ($child_attrs{$attr_name} eq $lang){
                            $headers{title} = $child->getTextContent();
                        }
                    }
                }
            }
            elsif ($child_name eq 'description'){
                $headers{description} = $headers{description} || $child->getTextContent();
                my %child_attrs = $child->getAttributes();
                foreach my $attr_name (keys %child_attrs) {
                    if ($attr_name eq 'lang'){
                        if ($child_attrs{$attr_name} eq $lang){
                            $headers{description} = $child->getTextContent();
                        }
                    }
                }
            }
            elsif ($child_name eq 'author-group'){
                foreach my $ag_child($child->getChildNodes) {
                    my $ag_name = $ag_child->getNodeName();
                    if ($ag_child->isa('XML::Xerces::DOMElement')){
                        if ($ag_name eq 'author'){
                            foreach my $author_child($ag_child->getChildNodes) {
                                my $author_name = $author_child->getNodeName();
                                if ($author_child->isa('XML::Xerces::DOMElement')){
                                    if ($author_name eq 'realname'){
                                        $headers{author} = $author_child->getTextContent();
                                    }
                                    elsif ($author_name eq 'username'){
                                        $headers{author_username} = $author_child->getTextContent();
                                    }
                                }
                            }
                        }
                    }
                }
            }
            elsif ($child_name eq 'mod-version'){
                foreach my $mv_child($child->getChildNodes) {
                    my $mv_name = $mv_child->getNodeName();
                    if ($mv_child->isa('XML::Xerces::DOMElement')){
                        if ($mv_name eq 'major'){
                            $headers{version_major} = $mv_child->getTextContent();
                        }
                        elsif ($mv_name eq 'minor'){
                            $headers{version_minor} = $mv_child->getTextContent();
                        }
                        elsif ($mv_name eq 'revision'){
                            $headers{version_revision} = $mv_child->getTextContent();
                        }
                        elsif ($mv_name eq 'release'){
                            $headers{version_release} = $mv_child->getTextContent();
                        }
                    }
                }
            }
            elsif ($child_name eq 'installation'){
                foreach my $i_child($child->getChildNodes) {
                    my $i_name = $i_child->getNodeName();
                    if ($i_child->isa('XML::Xerces::DOMElement')){
                        if ($i_name eq 'target-version'){
                            foreach my $tv_child($i_child->getChildNodes) {
                                my $tv_name = $tv_child->getNodeName();
                                if ($tv_child->isa('XML::Xerces::DOMElement')){
                                    if ($tv_name eq 'target-primary'){
                                        $headers{target_version} = $tv_child->getTextContent();
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    foreach my $nv_name(qw{author author_username version_major 
                            version_minor version_revision 
                            version_release title description}){
        if (!defined $headers{$nv_name}){
            $headers{$nv_name} = '';
        }
    }
    _write_log_entry(DEBUG, "Install file header values: " . Data::Dumper->Dump([\%headers]));
}

sub _process_copy{
    my $copy_node = shift;

    my %return_hash;
    my @file_array;
    $return_hash{action} = 'copy';
    
    foreach my $child ($copy_node->getChildNodes) {
        my $child_name = $child->getNodeName();
        if ($child->isa('XML::Xerces::DOMElement')){
            if ($child_name eq 'file'){
                my %file_hash;
                my %file_attrs = $child->getAttributes();
                foreach my $attr_name (keys %file_attrs) {
                    $file_hash{$attr_name} = $file_attrs{$attr_name};
                }
                push (@file_array, \%file_hash);
            }
        }
    }
    
    $return_hash{files} = \@file_array;
    return \%return_hash;
}

sub _process_open{
    my $open_node = shift;
    my %return_hash;
    my @edits;
    $return_hash{action} = 'open';

    my %open_attrs = $open_node->getAttributes();
    foreach my $attr_name (keys %open_attrs) {
        if ($attr_name eq 'src'){
            $return_hash{src} = $open_attrs{$attr_name};
        }
    }
    foreach my $child ($open_node->getChildNodes) {
        my $child_name = $child->getNodeName();
        if ($child->isa('XML::Xerces::DOMElement')){
            if ($child_name eq 'edit'){
                my %edit_hash;
                foreach my $edit_child ($child->getChildNodes) {
                    my $edit_child_name = $edit_child->getNodeName();
                    if ($edit_child->isa('XML::Xerces::DOMElement')){
                        if ($edit_child_name eq 'find'){
                            $edit_hash{find} = $edit_child->getTextContent();
                            my %find_attrs = $edit_child->getAttributes();
                            foreach my $attr_name (keys %find_attrs) {
                                if ($attr_name eq 'type'){
                                    $edit_hash{find_type} = $find_attrs{$attr_name};
                                }
                            }
                        }
                        elsif ($edit_child_name eq 'action'){
                            my %action_attrs = $edit_child->getAttributes();
                            foreach my $attr_name (keys %action_attrs) {
                                if ($attr_name eq 'type'){
                                    my $type_name = $action_attrs{$attr_name};
                                    if ($type_name eq 'after-add'){
                                        $edit_hash{action_after_add} = $edit_child->getTextContent();
                                    }
                                    elsif ($type_name eq 'before-add'){
                                        $edit_hash{action_before_add} = $edit_child->getTextContent();
                                    }
                                    elsif ($type_name eq 'replace-with'){
                                        $edit_hash{action_replace_with} = $edit_child->getTextContent();
                                    }
                                }
                            }
                        }
                        elsif ($edit_child_name eq 'inline-edit'){
                            foreach my $ie_child ($edit_child->getChildNodes) {
                                my $ie_name = $ie_child->getNodeName();
                                if ($ie_child->isa('XML::Xerces::DOMElement')){
                                    if ($ie_name eq 'inline-find'){
                                        $edit_hash{inline_find} = $ie_child->getTextContent();
                                        my %find_attrs = $ie_child->getAttributes();
                                        foreach my $attr_name (keys %find_attrs) {
                                            if ($attr_name eq 'type'){
                                                $edit_hash{find_type} = $find_attrs{$attr_name};
                                            }
                                        }
                                    }
                                    elsif ($ie_name eq 'inline-action'){
                                        my %action_attrs = $ie_child->getAttributes();
                                        foreach my $attr_name (keys %action_attrs) {
                                            if ($attr_name eq 'type'){
                                                my $type_name = $action_attrs{$attr_name};
                                                if ($type_name eq 'after-add'){
                                                    $edit_hash{inline_action_after_add} = $ie_child->getTextContent();
                                                }
                                                elsif ($type_name eq 'before-add'){
                                                    $edit_hash{inline_action_before_add} = $ie_child->getTextContent();
                                                }
                                                elsif ($type_name eq 'replace-with'){
                                                    $edit_hash{inline_action_replace_with} = $ie_child->getTextContent();
                                                }
                                            }
                                        }                                        
                                    }
                                }
                            }
                        }
                    }
                }
                push (@edits, \%edit_hash);
            }
        }
    }    
    
    $return_hash{edits} = \@edits;
    
    return \%return_hash;
}

sub _process_sql{
    my $sql_node = shift;
    my %return_hash;

    my %sql_attrs = $sql_node->getAttributes();
    foreach my $attr_name (keys %sql_attrs) {
        if ($attr_name eq 'dbms'){
            $return_hash{dbms} = $sql_attrs{$attr_name};
        }
    }
    $return_hash{action} = 'sql';
    $return_hash{sql} = $sql_node->getTextContent();
    
    #process everything as mysql
    #if (defined $return_hash{dbms}){
    #    if ($return_hash{dbms} ne 'mysql'){
    #        _write_log_entry(ERROR, "The only supported database is mysql, can't process SQL statement");
    #        croak "Can't process SQL statement only mysql is supported\n";
    #    }
    #    elsif ($return_hash{dbms} ne $phpbb_config_ref->{dbms}){
    #        _write_log_entry(ERROR, "php DBMS type is different to the SQL statement DBMS type");
    #        croak "php DBMS type is different to the SQL statement DBMS type\n";
    #    }
    #}
    
    return \%return_hash;
}

sub _process_diy_instructions{
    my $diy_node = shift;

    my %return_hash;
    $return_hash{action} = 'diy-instructions';
    $return_hash{instruction} = $return_hash{instruction} || $diy_node->getTextContent();

    my %child_attrs = $diy_node->getAttributes();
    foreach my $attr_name (keys %child_attrs) {
        if ($attr_name eq 'lang'){
            if ($child_attrs{$attr_name} eq $lang){
                $return_hash{instruction} = $diy_node->getTextContent();
            }
        }
    }
    
    return \%return_hash;
}

sub _process_uninstall{
    my $instructions_ref = shift;
    my $backup_dir = shift;

    warn ("WARNING: Uninstall not yet implemented\n\n");
    return;
    
    foreach my $instruction_ref (@{$instructions_ref}){
        if ($instruction_ref->{action} eq 'copy'){
            #phpbb_uninstall_copy_file($instruction_ref, $backup_dir);
        }
        elsif ($instruction_ref->{action} eq 'sql'){
            #phpbb_uninstall_run_sql($instruction_ref);
        }
        elsif ($instruction_ref->{action} eq 'open'){
            #phpbb_uninstall_open_file($instruction_ref);
        }
        elsif ($instruction_ref->{action} eq 'diy-instructions'){
            #phpbb_uninstall_diy_instructions($instruction_ref);
        }
    }    
}


sub _process_instructions{
    my $instructions_ref = shift;
    my $backup_dir = shift;
    
    foreach my $instruction_ref (@{$instructions_ref}){
        if ($instruction_ref->{action} eq 'copy'){
            _phpbb_copy_file($instruction_ref, $backup_dir);
        }
        elsif ($instruction_ref->{action} eq 'sql'){
            _phpbb_run_sql($instruction_ref);
        }
        elsif ($instruction_ref->{action} eq 'open'){
            _phpbb_open_file($instruction_ref);
        }
        elsif ($instruction_ref->{action} eq 'diy-instructions'){
            _phpbb_diy_instructions($instruction_ref);
        }
    }
}

sub _phpbb_copy_file{
    my $instruction_ref = shift;
    my $backup_dir = shift;

    foreach my $file_ref (@{$instruction_ref->{files}}){
        my $to = $file_ref->{to};
        if ( (defined $style) && ($to =~ /^(.*)prosilver(.*)$/) ){
            $to = $1 . $style . $2;
        }
        elsif ( (defined $style) && ($to =~ /^(.*)subsilver2(.*)$/) ){
            $to = $1 . $style . $2;
        }

        my $source      = "$install_absolute_path/" . $file_ref->{from};
        my $destination = "$web_root_absolute_path/" . $to;
        if (index($destination, '*') >= 0){
            $destination = dirname ($destination);
        }
        _write_log_entry(AUDIT, "Copy file: $source to $destination");
        if (-f $destination){
            my $backup_filename = "$backup_dir/" . $to;
            _create_dir_recursive( dirname ($backup_filename) );
            _write_log_entry(DEBUG, "Backup file: $destination to $backup_filename");
            copy ($destination, $backup_filename)
                or croak "Failed to backup $destination\n";
        }
        _create_dir_recursive( dirname ($destination) );
        copy ($source, $destination)
            or croak "Copy failed from $source to $destination\n";
    }
}

sub _phpbb_run_sql{
    my $instruction_ref = shift;
    if ($dbh){
        my $sql = $instruction_ref->{sql};
        $sql =~ s/phpbb_/$phpbb_config_ref->{table_prefix}/g;
        my @statements = split /;/, $sql;
        foreach my $statement (@statements){
            $statement = _trim($statement);
            if (length($statement) > 0){
                _write_log_entry(AUDIT, "Updating database: $statement");
                my $sth;
                eval{$sth = $dbh->prepare($statement)};
                eval{$sth->execute();};
                if ($@){
                    _write_log_entry(ERROR, "Unable to run SQL: '$statement' : " . $dbh->err . " : $@");
                    carp "Database error trying to run SQL. $@\n";
                }
            }
        }
    }
    else{
        _write_log_entry(ERROR, "Cannot update database, no database connection");
        croak "Can't update database, no connection\n";
    }
}

sub _phpbb_open_file{
    my $instruction_ref = shift;
    
    my $src = $instruction_ref->{src};
    if ( (defined $style) && ($src =~ /^(.*)prosilver(.*)$/) ){
        $src = $1 . $style . $2;
    }
    if ( (defined $style) && ($src =~ /^(.*)subsilver2(.*)$/) ){
        $src = $1 . $style . $2;
    }

    my $file_to_open = "$web_root_absolute_path/$src";
    if (!-f $file_to_open){
        _write_log_entry(ERROR, "File to open '$file_to_open' doesn't exist");
        warn "WARNING: File to open '$file_to_open' doesn't exist\n";
    }
    _write_log_entry(AUDIT, "Opening file '$file_to_open'");
    my $backup_filename = "$backup_dir/" . $src;
    _create_dir_recursive( dirname ($backup_filename) );
    _write_log_entry(DEBUG, "Backup file: $file_to_open to $backup_filename");
    copy ($file_to_open, $backup_filename)
        or croak "Failed to backup $file_to_open\n";
    
    {
        local( $/, *FH ) ;
        open( FH, '<', $file_to_open ) or croak "Couldn't open file for editing: $!\n";
        my $file_text = <FH>;
        close (FH);
        
        foreach my $edit_ref (@{$instruction_ref->{edits}}){
            my $find_start = index($file_text, $edit_ref->{find});
            if($find_start >= 0){
                my $find_text = $edit_ref->{find};
                my $pre_text = substr $file_text, 0, $find_start;
                my $post_text = substr $file_text, $find_start + length($find_text);
                
                if (defined $edit_ref->{inline_find}){
                    my $inline_find_start = index($find_text, $edit_ref->{inline_find});
                    if($inline_find_start >= 0){
                        my $inline_find_text = $edit_ref->{inline_find};
                        my $inline_pre_text = substr $find_text, 0, $inline_find_start;
                        my $inline_post_text = substr $find_text, $inline_find_start + length($inline_find_text);

                        my $already_installed = 0;
                        if (defined $edit_ref->{inline_action_after_add}){
                            if (index($file_text, $inline_find_text . $edit_ref->{inline_action_after_add}) >= 0){
                                $already_installed = 1;
                            }
                        }
                        if (defined $edit_ref->{inline_action_before_add}){
                            if (index($file_text, $edit_ref->{inline_action_before_add} . $inline_find_text) >= 0){
                                $already_installed = 1;
                            }
                        }                        
                        if($already_installed){
                            _write_log_entry(ERROR, "It looks like the mod has already been applied to $file_to_open");
                            croak "It looks like the mod has already been applied to $file_to_open\n";
                        }
                        
                        if (defined $edit_ref->{inline_action_replace_with}){
                            $inline_find_text = $edit_ref->{inline_action_replace_with};
                        }
                        if (defined $edit_ref->{inline_action_after_add}){
                            $inline_find_text = $inline_find_text . $edit_ref->{inline_action_after_add};
                        }
                        if (defined $edit_ref->{inline_action_before_add}){
                            $inline_find_text = $edit_ref->{inline_action_before_add} . $inline_find_text;
                        }
                        $find_text = $inline_pre_text . $inline_find_text . $inline_post_text;
                    }
                    else{
                        _write_log_entry(ERROR, "Couldn't find the required inline edit: $edit_ref->{inline_find}");
                        warn "WARNING: Inline edit find failed, it must be dealt with manually. $edit_ref->{inline_find}\n";
                    }
                }
                if (defined $edit_ref->{action_replace_with} || 
                    defined $edit_ref->{action_before_add} || 
                    defined $edit_ref->{action_after_add}){
                    
                    #check if the mod has already been applied
                    my $already_installed = 0;
                    if (defined $edit_ref->{action_before_add}){
                        my $action_start = index($file_text, $edit_ref->{action_before_add});
                        if ($action_start >= 0){
                            $already_installed = 1;
                        }
                    }
                    if (defined $edit_ref->{action_after_add}){
                        my $action_start = index($file_text, $edit_ref->{action_after_add});
                        if ($action_start >= 0){
                            $already_installed = 1;
                        }
                    }
                    if($already_installed){
                        _write_log_entry(ERROR, "It looks like the mod has already been applied to $file_to_open");
                        croak "It looks like the mod has already been applied to $file_to_open\n";
                    }
                    
                    if (defined $edit_ref->{action_replace_with}){
                        $find_text = $edit_ref->{action_replace_with};
                    }
                    if (defined $edit_ref->{action_after_add}){
                        $find_text = $find_text . "\n\n" . $edit_ref->{action_after_add} . "\n";
                    }
                    if (defined $edit_ref->{action_before_add}){
                        $find_text = "\n" . $edit_ref->{action_before_add} . "\n\n" . $find_text;
                    }
                }
                $file_text = $pre_text . $find_text . $post_text;
                
                open (OUT, '>', $file_to_open) or croak "Unable to rewrite file '$file_to_open': $!\n";
                binmode OUT;
                print OUT $file_text;
                close (OUT);
            }
            else{
                _write_log_entry(ERROR, "Couldn't find the required edit: $edit_ref->{find}");
                warn "WARNING: Edit find failed, it must be dealt with manually. $edit_ref->{find}\n";
            }
        }
    }    
}

sub _phpbb_diy_instructions{
    my $instruction_ref = shift;
    _write_log_entry(AUDIT, "DIY Instruction: " . $instruction_ref->{instruction});
    print STDOUT "\n\nDIY Instructions:\n" . $instruction_ref->{instruction} . "\n\n";
}


sub _create_dir_recursive{
    my $complete_dir = shift;
    
    my @file_parts = split /\//, $complete_dir;
    my $curr_dir = '';
    foreach my $file_part (@file_parts){
        $curr_dir .= "$file_part/";
        if (!-d $curr_dir){
            mkdir ($curr_dir) or croak "mkdir failed for '$curr_dir'\n";
        }
    }
}


sub _create_backup_dirs{
    my $working_dir = shift;
    
    my $backup_dir = "$working_dir/backups";
    
    if (!-d $backup_dir){
        mkdir ($backup_dir)
            or croak "Can't create backup directory '$backup_dir'\n";
    }
    
    my ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst)
        = localtime(time);
    my $curr_time = sprintf "%4d-%02d-%02d_%02d-%02d-%02d", $year+1900,$mon+1,$mday,$hour,$min,$sec;
    my $current_backup_dir = "$backup_dir/$curr_time";
    
    if (!-d $current_backup_dir){
        mkdir ($current_backup_dir)
            or croak "Can't create backup directory '$current_backup_dir'\n";
    }
    
    return $current_backup_dir;
}

sub _trim {
    my $txt=shift;
    $_=$txt;
    $txt =~ s/^\s+|\s+$//g ;
    return $txt
}

1;

__END__

=head1 NAME

WWW::phpBB::Mod::Installer - Perl extension for installing mods onto phpBB.


=head1 SYNOPSIS

  use WWW::phpBB::Mod::Installer;

  install_phpbb_mod(
                    INSTALL_FILE => '/home/user/root/mods/modx_install.xml', 
                    WEB_ROOT     => '/htdocs/phpbb3', 
                    STYLE        => 'prosilver',
                    LANG         => 'en',
                    OPERATION    => 'INSTALL',
                    );


=head1 DESCRIPTION

The installer will read the installation modx XML file which contains the instructions used to install the mod. It will process copy, sql and open instructions.

When called, the directory the calling script is located in will have a logs and a backup directory created.
Any files overwritten or edited will be copied to the backups directory first.
The logs directory will contain a debug, autit and error log which will contain details of what has happened.


=head2 EXPORT

=head3 install_phpbb_mod

This routine will control the installation of the mod. It accepts a hash as input. The following values  can be passed in.
    INSTALL_FILE - The modx XML file. 
    WEB_ROOT     - The directory that phpbb is installed in.
    STYLE        - Optional. The style that any updates should be applied to. Defaults to the board default.
    LANG         - Optional. The language to be used. Defaults to the board default.
    OPERATION    - Optional. Can be 'INSTALL' or 'UNINSTALL', default 'INSTALL'.


=head3 uninstall_phpbb_mod

NOT YET IMPLEMENTED
This routine will uninstall the mod.
The parameters are the same as above but OPERATION is ignored and is always set to 'UNINSTALL'.


=head1 SEE ALSO

Further information can be found at http://www.abc-rallying.co.uk/perl


=head1 AUTHOR

Ian Clark <perl@abc-rallying.co.uk>


=head1 LICENSE AND COPYRIGHT

Copyright (C) 2008 Ian Clark

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.


=cut
