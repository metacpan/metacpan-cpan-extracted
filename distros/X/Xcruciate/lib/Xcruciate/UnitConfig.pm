package Xcruciate::UnitConfig;

use Exporter;
@ISA    = ('Exporter');
@EXPORT = qw();
our $VERSION = 0.21;

use strict;
use warnings;
use Carp;
use Xcruciate::Utils 0.21;

=head1 NAME

Xcruciate::UnitConfig - OO API for reading xacerbate/xteriorize unit config files.

=head1 SYNOPSIS

my $config=Xcruciate::UnitConfig->new('unit.conf');

my $cm=$config->chime_multiplier;

my @mdf=$config->modifiable_data_files;


=head1 DESCRIPTION

Xcruciate::UnitConfig is part of the Xcruciate project (F<http://www.xcruciate.co.uk>). It provides an
OO interface to an xacerbate/xteriorize unit configuration file.

Accessor functions return scalars for <scalar/> entry types and lists for <list/> entry types.
The values returned are those found in the config file, with the exception of yes_no datatypes
which are converted into perlish boolean values (1 or 0).

All xte*() methods will return an undefined value unless the xte_start entry is set.

The entry() method can be used to access any entry including unofficial extensions. However,
it is safer to use the named methods where possible, to avoid inventing unofficial extensions through typos.

=head1 AUTHOR

Mark Howe, E<lt>melonman@cpan.orgE<gt>

=head2 EXPORT

None

=cut

#Records fields:
#  scalar/list
#  Optional? (1 means 'yes')
#  data type
#  data type specific fields:
#     min, max for numbers
#     required permissions for files/directories

my $xac_settings = {
    'accept_from',
    [ 'scalar', 1, 'word' ],
    'access_log_path',
    [ 'scalar', 0, 'abs_create', 'rw' ],
    'backup_path',
    [ 'scalar', 1, 'abs_create', 'rw' ],
    'boot_log_path',
    [ 'scalar', 0, 'abs_create', 'rw' ],
    'chime_multiplier',
    [ 'scalar', 0, 'integer', 2 ],
    'clean_states_path',
    [ 'scalar', 0, 'path' ],
    'config_type',
    [ 'scalar', 0, 'word' ],
    'current_states_path',
    [ 'scalar', 0, 'path' ],
    'debug_level',
    [ 'scalar', 0, 'debug_list' ],
    'debug_log_path',
    [ 'scalar', 0, 'abs_create', 'rw' ],
    'error_log_path',
    [ 'scalar', 0, 'abs_create', 'rw' ],
    'log_file_paths',
    [ 'list', 1, 'abs_create', 'rw' ],
    'max_buffer_size',
    [ 'scalar', 0, 'integer', 1 ],
    'max_connections',
    [ 'scalar', 0, 'integer', 1 ],
    'max_input_length',
    [ 'scalar', 0, 'integer', 1 ],
    'modifiable_data_files',
    [ 'list', 1, 'abs_file', 'r', 'xml', 'clean_states_path' ],
    'modifiable_transform_files',
    [ 'list', 1, 'abs_file', 'r', 'xml', 'clean_states_path' ],
    'path',
    [ 'scalar', 1, 'abs_dir', 'r' ],
    'peel_multiplier',
    [ 'scalar', 0, 'integer', 2 ],
    'persistent_modifiable_files',
    [ 'list', 1, 'abs_file', 'r', 'xml', 'clean_states_path' ],
    'port',
    [ 'scalar', 0, 'integer', 1, 65535 ],
    'server_ip',
    [ 'scalar', 0, 'ip' ],
    'start_xte',
    [ 'scalar', 0, 'yes_no' ],
    'startup_commands',
    [ 'list', 1, 'abs_file', 'r', 'xml', 'startup_files_path' ],
    'startup_files_path',
    [ 'scalar', 1, 'path' ],
    'tick_interval',
    [ 'scalar', 0, 'duration' ],
    'transform_xsl',
    [ 'scalar', 0, 'abs_file', 'r', 'xsl' ],
    'very_persistent_modifiable_files',
    [ 'list', 1, 'abs_file', 'r', 'xml', 'clean_states_path' ],
};

my $xte_settings = {
    'xte_captcha_bgcolors',           [ 'list',   0, 'hexbyte' ],
    'xte_captcha_colors',             [ 'list',   0, 'hexbyte' ],
    'xte_captcha_height',             [ 'scalar', 0, 'integer', 10, 512 ],
    'xte_captcha_max_angle',          [ 'scalar', 0, 'integer', 0, 90 ],
    'xte_captcha_max_line_thickness', [ 'scalar', 0, 'integer', 1, 10 ],
    'xte_captcha_max_lines',          [ 'scalar', 0, 'integer', 1, 10 ],
    'xte_captcha_min_line_thickness', [ 'scalar', 0, 'integer', 1, 10 ],
    'xte_captcha_min_lines',          [ 'scalar', 0, 'integer', 0, 10 ],
    'xte_captcha_particle_count',     [ 'scalar', 0, 'integer', 0, 1000 ],
    'xte_captcha_particle_size',      [ 'scalar', 0, 'integer', 1, 10 ],
    'xte_captcha_styles',             [ 'list',   0, 'captchastyle' ],
    'xte_captcha_ttfont_size',        [ 'scalar', 0, 'integer', 8, 72 ],
    'xte_captcha_ttfonts',   [ 'list',   0, 'abs_file', 'r' ],
    'xte_captcha_width',     [ 'scalar', 0, 'integer',  20, 1024 ],
    'xte_check_for_waiting', [ 'scalar', 1, 'integer',  0 ],
    'xte_cidr_allow',            [ 'list',   1, 'cidr' ],
    'xte_cidr_deny',             [ 'list',   1, 'cidr' ],
    'xte_docroot',               [ 'scalar', 0, 'abs_dir', 'rw' ],
    'xte_enable_captcha',        [ 'scalar', 1, 'yes_no' ],
    'xte_enable_email',          [ 'scalar', 1, 'yes_no' ],
    'xte_enable_file_writing',   [ 'scalar', 1, 'yes_no' ],
    'xte_enable_fop',            [ 'scalar', 1, 'yes_no' ],
    'xte_enable_json',           [ 'scalar', 1, 'yes_no' ],
    'xte_enable_mxmlc',          [ 'scalar', 1, 'yes_no' ],
    'xte_enable_static_serving', [ 'scalar', 1, 'yes_no' ],
    'xte_enable_uploads',        [ 'scalar', 1, 'yes_no' ],
    'xte_enable_xmlroff',        [ 'scalar', 1, 'yes_no' ],
    'xte_error_i18n',            [ 'scalar', 0, 'abs_file', 'r' ],
    'xte_from_address',          [ 'scalar', 0, 'email' ],
    'xte_gateway_auth',          [ 'scalar', 0, 'word' ],
    'xte_group',                 [ 'scalar', 1, 'word' ],
    'xte_image_sizes',           [ 'list',   0, 'imagesize' ],
    'xte_i18n_list',             [ 'list',   1, 'abs_file', 'r', 'xml' ],
    'xte_server_ip',             [ 'scalar', 0, 'ip' ],
    'xte_log_file', [ 'scalar', 1, 'abs_create', 'rw' ],
    'xte_log_level', [ 'scalar', 1, 'integer', 0, 4 ],
    'xte_max_image_size',    [ 'scalar', 1, 'imagesize' ],
    'xte_max_requests',      [ 'scalar', 1, 'integer', 1 ],
    'xte_max_servers',       [ 'scalar', 1, 'integer', 1 ],
    'xte_max_spare_servers', [ 'scalar', 1, 'integer', 1 ],
    'xte_max_upload_size',   [ 'scalar', 1, 'integer', 1 ],
    'xte_mimetype_path',     [ 'scalar', 1, 'abs_file', 'r' ],
    'xte_min_servers',       [ 'scalar', 1, 'integer', 1 ],
    'xte_min_spare_servers', [ 'scalar', 1, 'integer', 1 ],
    'xte_port',              [ 'scalar', 0, 'integer', 1, 65535 ],
    'xte_post_max', [ 'scalar', 0, 'integer', 1 ],
    'xte_report_benchmarks', [ 'scalar', 1, 'yes_no' ],
    'xte_site_language',     [ 'scalar', 0, 'language' ],
    'xte_smtp_charset',      [ 'scalar', 0 ],
    'xte_smtp_encoding',     [ 'scalar', 0 ],
    'xte_smtp_host',         [ 'scalar', 0, 'ip' ],
    'xte_smtp_port', [ 'scalar', 0, 'integer', 1, 65535 ],
    'xte_static_directories',  [ 'list',   1, 'word' ],
    'xte_splurge_input',       [ 'scalar', 1, 'yes_no' ],
    'xte_splurge_output',      [ 'scalar', 1, 'yes_no' ],
    'xte_temporary_file_path', [ 'scalar', 0, 'abs_create', 'rw' ],
    'xte_user',                [ 'scalar', 1, 'word' ],
    'xte_use_xca',             [ 'scalar', 0, 'yes_no' ],
    'xte_xac_timeout',         [ 'scalar', 0, 'duration' ]
};

my $xca_settings = {
    'xca_captcha_timeout',
    [ 'scalar', 0, 'duration' ],
    'xca_castes',
    [ 'list', 1, 'word' ],
    'xca_confirmation_timeout',
    [ 'scalar', 0, 'duration' ],
    'xca_date_formats',
    [ 'list', 1, 'dateformat' ],
    'xca_datetime_formats',
    [ 'list', 1, 'dateformat' ],
    'xca_default_email_contact',
    [ 'scalar', 0, 'yes_no' ],
    'xca_default_pm_contact',
    [ 'scalar', 0, 'yes_no' ],
    'xte_enable_captcha',
    [ 'scalar', 1, 'yes_no' ],
    'xte_enable_email',
    [ 'scalar', 1, 'yes_no' ],
    'xte_enable_file_writing',
    [ 'scalar', 1, 'yes_no' ],
    'xte_enable_fop',
    [ 'scalar', 1, 'yes_no' ],
    'xte_enable_json',
    [ 'scalar', 1, 'yes_no' ],
    'xte_enable_mxmlc',
    [ 'scalar', 1, 'yes_no' ],
    'xte_enable_xmlroff',
    [ 'scalar', 1, 'yes_no' ],
    'xca_favicon',
    [ 'scalar', 0, 'url' ],
    'xca_failed_login_lockout',
    [ 'scalar', 0, 'integer' ],
    'xca_failed_login_lockout_reset',
    [ 'scalar', 0, 'duration' ],
    'xca_from_address',
    [ 'scalar', 0, 'email' ],
    'xca_gateway_authenticate_timeout',
    [ 'scalar', 0, 'duration' ],
    'xca_http_domain',
    [ 'scalar', 0, 'word' ],
    'xca_manual_registration_activation',
    [ 'scalar', 0, 'yes_no' ],
    'xca_path',
    [ 'scalar', 0, 'abs_dir', 'r' ],
    'xca_profile_template_path',
    [ 'scalar', 0, 'abs_file', 'r', 'xml' ],
    'xca_script_debug_caste',
    [ 'scalar', 0, 'word' ],
    'xca_session_timeout',
    [ 'scalar', 0, 'duration' ],
    'xca_site_path',
    [ 'scalar', 0, 'abs_dir', 'rw' ],
    'xca_time_offset',
    [ 'scalar', 0, 'timeoffset' ],
    'xca_unique_registration_email',
    [ 'scalar', 0, 'yes_no' ]
};

my $stop_settings = {
    'server_ip'     => 1,
    'port'          => 1,
    'start_xte'     => 1,
    'xte_server_ip' => 1,
    'xte_port'      => 1
};

=head1 CREATOR METHODS

=head2 new(config_file_path,verbose,stop_only [,lax])

Creates and returns an Xcruciate::UnitConfig object which can then be queried.
If the optional verbose argument is perlishly true it  will show its working to STDOUT. If
the stop_only argument is perlishly true it will only bother about the information needed
to stop processes (ie hosts and ports).

By default it looks for configuration errors and die noisily if it finds any.
This is useful behaviour for management scripts - continuing to set up server daemons
on the basis of broken configurations is not best practice. If the fourth argument (lax) is
perlishly true, errors will be signalled but the possibly broken object will be created anyway.
This is useful behaviour for development purposes, especially when changing config options, but
should not be used in a production setting. Note that even the lax version of new() will die
if the config file does not look anything like a config file.

=cut

sub new {
    my $class                = shift;
    my $path                 = shift;
    my $verbose              = shift || 0;
    my $stop_only            = shift;
    my $stop_only_parse_text = "";
    $stop_only_parse_text = " (hosts and ports only)" if $stop_only;
    my $lax = shift || 0;
    my $self = {};

    # Check that there's a file at the end of the config file option
    local_croak(
        Xcruciate::Utils::check_path( 'unit config file', $path, 'r', 1 ) );

    # Parse config file
    print "Attempting to parse unit config file$stop_only_parse_text... "
      if $verbose;
    my $parser  = XML::LibXML->new();
    my $xac_dom = $parser->parse_file($path);
    print "done\n" if $verbose;

    #Bail out if config file isn't even close to what is expected
    my @config = $xac_dom->findnodes("/config/scalar");
    croak
"Config file doesn't look anything like a config file - 'xcruciate file_help' for some clues"
      unless $config[0];
    my @config_type =
      $xac_dom->findnodes("/config/scalar[\@name='config_type']/text()");
    croak "config_type entry not found in unit config file"
      unless $config_type[0];
    my $config_type = $config_type[0]->toString;
    croak
"config_type in unit config file is '$config_type' (should be 'unit') - are you confusing xcruciate and unit config files?"
      unless $config_type eq 'unit';
    my @config_path =
      $xac_dom->findnodes("/config/scalar[\@name='path']/text()");
    my $config_path = $config_path[0];
    $config_path = $config_path->toString if $config_path;

    # Work through config options in config file
    my @errors = ();
    foreach my $entry (
        $xac_dom->findnodes(
            "/config/*[(local-name() = 'scalar') or (local-name() = 'list')]")
      )
    {

        # Does it have a name attribute?
        push @errors,
          sprintf( "No name attribute for element '%s'", $entry->nodeName )
          unless $entry->hasAttribute('name');
        my $entry_record =
             $xac_settings->{ $entry->getAttribute('name') }
          || $xte_settings->{ $entry->getAttribute('name') }
          || $xca_settings->{ $entry->getAttribute('name') };

        #Skip checks if stop_only and this entry isn't needed to stop
        next
          if ( $stop_only
            and not( $stop_settings->{ $entry->getAttribute('name') } ) );

        # Warn about entries in config file that are not defined, but continue.
        if ( not defined $entry_record ) {
            carp "WARNING: Unknown unit config entry '"
              . ( $entry->getAttribute('name') ) . "'";
        }
        elsif ( not( $entry->nodeName eq $entry_record->[0] ) ) {

            # Is it a scalar or list as expected?
            push @errors,
              sprintf(
                "Entry called %s should be a %s not a %s",
                $entry->getAttribute('name'),
                $entry_record->[0], $entry->nodeName
              );
        }
        elsif ( ( not $entry->textContent )
            and
            ( ( not $entry_record->[1] ) or $entry->textContent !~ /^\s*$/s ) )
        {

            #Entry, but value missing and not optional
            push @errors,
              sprintf( "Entry called %s requires a value",
                $entry->getAttribute('name') );
        }
        elsif (
                ( $entry->nodeName eq 'scalar' )
            and $entry_record->[2]
            and (  ( not $entry_record->[1] )
                or $entry->textContent !~ /^\s*$/s
                or $entry->textContent )
          )
        {

            #Produce path for this field
            my $entry_path = $config_path;
            if ( ( $entry_record->[2] eq 'abs_file' ) and $entry_record->[5] ) {
                my @entry_config_path = $xac_dom->findnodes(
                    "/config/*[\@name='$entry_record->[5]']/text()");
                $entry_path .= '/' . $entry_config_path[0]->toString
                  if $entry_config_path[0];
            }

            #Entry is a scalar - type check
            push @errors,
              Xcruciate::Utils::type_check( $entry_path,
                $entry->getAttribute('name'),
                $entry->textContent, $entry_record );
        }
        elsif ( ( $entry->nodeName eq 'list' ) and $entry_record ) {

            #Entry is a list...

            #Non-optional list entries require at least one item
            my @items = $entry->findnodes('item/text()');
            push @errors,
              sprintf( "Entry called %s requires at least one item",
                $entry->getAttribute('name') )
              if ( ( not $entry_record->[2] ) and ( not @items ) );

            #Produce path for this field
            my $entry_path = $config_path;
            if ( ( $entry_record->[2] eq 'abs_file' ) and $entry_record->[5] ) {
                my @entry_config_path = $xac_dom->findnodes(
                    "/config/*[\@name='$entry_record->[5]']/text()");
                $entry_path .= '/' . $entry_config_path[0]->toString
                  if $entry_config_path[0];
            }

            # Type check each item in list
            my $count = 1;
            foreach my $item (@items) {
                push @errors,
                  Xcruciate::Utils::type_check( $entry_path,
                    $entry->getAttribute('name'),
                    $item->textContent, $entry_record, $count );
                $count++;
            }
        }

        # Duplicate entries not allowed
        push @errors,
          sprintf( "Duplicate entry called %s", $entry->getAttribute('name') )
          if defined $self->{ $entry->getAttribute('name') };

        # Add entry value to object hash
        if ( $entry->nodeName eq 'scalar' ) {
            $self->{ $entry->getAttribute('name') } = $entry->textContent;
        }
        else {
            $self->{ $entry->getAttribute('name') } = []
              unless defined $self->{ $entry->getAttribute('name') };
            foreach my $item ( $entry->findnodes('item/text()') ) {
                push @{ $self->{ $entry->getAttribute('name') } },
                  $item->textContent;
            }
        }
    }

    # Report missing entries
    foreach my $entry ( keys %{$xac_settings} ) {
        next if ( $stop_only and not( $stop_settings->{$entry} ) );
        push @errors, sprintf( "No xacerbate entry called %s", $entry )
          unless ( ( defined $self->{$entry} )
            or ( $xac_settings->{$entry}->[1] ) );
    }
    if ( ( defined $self->{start_xte} ) and ( $self->{start_xte} eq "yes" ) ) {
        foreach my $entry ( keys %{$xte_settings} ) {
            next if ( $stop_only and not( $stop_settings->{$entry} ) );
            push @errors, sprintf( "No xteriorize entry called %s", $entry )
              unless ( ( defined $self->{$entry} )
                or ( $xte_settings->{$entry}->[1] ) );
        }
        if (    ( defined $self->{xte_use_xca} )
            and ( $self->{xte_use_xca} eq "yes" ) )
        {
            foreach my $entry ( keys %{$xca_settings} ) {
                next if ( $stop_only and not( $stop_settings->{$entry} ) );
                push @errors, sprintf( "No xcathedra entry called %s", $entry )
                  unless ( ( defined $self->{$entry} )
                    or ( $xca_settings->{$entry}->[1] ) );
            }
        }
    }

    # And the final scores are...
    if ( @errors and $lax ) {
        if ($verbose) {
            foreach (@errors) {
                print "ERROR: $_\n";
            }
        }
        carp
"WARNING: Errors in unit config file, but lax flag set, so proceeding anyway. This could be exciting...\n";
        bless( $self, $class );
        return $self;
    }
    elsif (@errors) {
        foreach (@errors) {
            print "ERROR: $_\n";
        }
        croak
"Errors in unit config file - cannot continue (force at your own risk using --lax flag)";
    }
    else {
        bless( $self, $class );
        return $self;
    }
}

=head1 UTILITY METHODS

=head2 xac_file_format_description()

Returns multi-lined human-friendly description of the xac config file

=cut

sub xac_file_format_description {
    my $self = shift;
    my $ret  = '';
    foreach my $entry (
        sort ( keys %{$xac_settings}, keys %{$xte_settings},
            keys %{$xca_settings} ) )
    {
        my $record =
             $xac_settings->{$entry}
          || $xte_settings->{$entry}
          || $xca_settings->{$entry};
        $ret .= "$entry (";
        $ret .= "optional " if $record->[1];
        $ret .= "$record->[0])";
        if ( not $record->[2] ) {
        }
        elsif ( ( $record->[2] eq 'integer' ) or ( $record->[2] eq 'float' ) ) {
            $ret .= " - $record->[2]";
            $ret .= " >= $record->[3]" if defined $record->[3];
            $ret .= " and <= $record->[4]" if defined $record->[4];
        }
        elsif ( $record->[2] eq 'ip' ) {
            $ret .= " - ip address";
        }
        elsif ( $record->[2] eq 'word' ) {
            $ret .= " - word (ie no whitespace)";
        }
        elsif ( $record->[2] eq 'path' ) {
            $ret .= " - path (currently a word)";
        }
        elsif ( $record->[2] eq 'cidr' ) {
            $ret .= " - an ip range in CIDR format";
        }
        elsif ( $record->[2] eq 'dateformat' ) {
            $ret .= " - date format";
        }
        elsif ( $record->[2] eq 'url' ) {
            $ret .= " - url (starts with http or /)";
        }
        elsif ( $record->[2] eq 'duration' ) {
            $ret .= " - duration in XML Schema format";
        }
        elsif ( $record->[2] eq 'timeoffset' ) {
            $ret .= " - timezone offset (-11 to 12)";
        }
        elsif ( $record->[2] eq 'xml_leaf' ) {
            $ret .= " - filename with an xml suffix";
        }
        elsif ( $record->[2] eq 'xsl_leaf' ) {
            $ret .= " - filename with an xsl suffix";
        }
        elsif ( $record->[2] eq 'yes_no' ) {
            $ret .= " - 'yes' or 'no'";
        }
        elsif ( $record->[2] eq 'email' ) {
            $ret .= " - email address";
        }
        elsif ( $record->[2] eq 'debug_list' ) {
            $ret .=
              " - comma-separated list of debugging options (or 'all'/'none')";
        }
        elsif ( $record->[2] eq 'abs_dir' ) {
            $ret .= " - absolute directory path with $record->[3] permissions";
        }
        elsif ( $record->[2] eq 'abs_file' ) {
            $ret .= " - absolute file path with $record->[3] permissions";
        }
        elsif ( $record->[2] eq 'abs_create' ) {
            $ret .=
" - absolute file path with $record->[3] permissions for directory";
        }
        else { $ret .= " - UNKNOWN TYPE $record->[2]" }
        $ret .= "\n";
    }
    return $ret;
}

=head1 ACCESSOR METHODS

=head2 accept_from()

Returns the ip range from which connections are accepted.

=cut

sub accept_from {
    my $self = shift;
    return $self->{accept_from};
}

=head2 access_log_path()

Returns the path to the access log.

=cut

sub access_log_path {
    my $self = shift;
    return $self->{access_log_path};
}

=head2 backup_path()

Returns the path to which the backup zip file should be written.

=cut

sub backup_path {
    my $self = shift;
    return $self->{backup_path};
}

=head2 boot_log_path()

Returns the path to the boot log.

=cut

sub boot_log_path {
    my $self = shift;
    return $self->{boot_log_path};
}

=head2 chime_multiplier()

Returns the number of ticks per chime

=cut

sub chime_multiplier {
    my $self = shift;
    return $self->{chime_multiplier};
}

=head2 clean_states_path()

Returns the path to the directory containing clean versions of modifiable files.

=cut

sub clean_states_path {
    my $self = shift;
    return $self->{clean_states_path};
}

=head2 config_type()

Returns the type of config file, which in this case should always be 'unit'.

=cut

sub config_type {
    my $self = shift;
    return $self->{config_type};
}

=head2 current_states_path()

Returns the path to the directory containing current versions of modifiable files.

=cut

sub current_states_path {
    my $self = shift;
    return $self->{current_states_path};
}

=head2 debug_level()

Returns the xacerbate debug level.

=cut

sub debug_level {
    my $self = shift;
    return $self->{debug_level};
}

=head2 debug_log_path()

Returns the path to the xacerbate debug log.

=cut

sub debug_log_path {
    my $self = shift;
    return $self->{debug_log_path};
}

=head2 entry(name)

Returns the entry called name. Lists will be returned by reference. Use named methods in preference to this one where possible.

=cut

sub entry {
    my $self = shift;
    my $name = shift;
    return $self->{$name};
}

=head2 error_log_path()

Returns the path to the xacerbate error log.

=cut

sub error_log_path {
    my $self = shift;
    return $self->{error_log_path};
}

=head2 log_file_paths()

Returns a list of locations to which xacerbate application code can write logs.

=cut

sub log_file_paths {
    my $self = shift;
    return @{ $self->{log_file_paths} || [] };
}

=head2 max_buffer_size()

Returns the maximum buffer size allowed for any one connection.

=cut

sub max_buffer_size {
    my $self = shift;
    return $self->{max_buffer_size};
}

=head2 max_connections()

Returns the maximum number of connections accepted by xacerbate.

=cut

sub max_connections {
    my $self = shift;
    return $self->{max_connections};
}

=head2 max_input_length()

Returns the maximum character length of each XML document.

=cut

sub max_input_length {
    my $self = shift;
    return $self->{max_input_length};
}

=head2 modifiable_data_files()

Returns a list of modifiable data filenames.

=cut

sub modifiable_data_files {
    my $self = shift;
    return @{ $self->{modifiable_data_files} || [] };
}

=head2 modifiable_transform_files()

Returns a list of modifiable XSL filenames.

=cut

sub modifiable_transform_files {
    my $self = shift;
    return @{ $self->{modifiable_transform_files} || [] };
}

=head2 path()

Returns the path that is prefixed by xacerbate to various other settings.

=cut

sub path {
    my $self = shift;
    return $self->{path};
}

=head2 peel_multiplier()

Returns the number of chimes per peel.

=cut

sub peel_multiplier {
    my $self = shift;
    return $self->{peel_multiplier};
}

=head2 port()

Returns the port used by xacerbate.

=cut

sub port {
    my $self = shift;
    return $self->{port};
}

=head2 persistent_modifiable_files()

Returns a list of modifiable files that should persist from session to session, ie they are not overwritten from clean on startup.

=cut

sub persistent_modifiable_files {
    my $self = shift;
    return @{ $self->{persistent_modifiable_files} || [] };
}

=head2 prepend_to_path(path)

Expects an absolute or relative path. If the path is relative, and if there was a path entry in the config file, the path entry is prepended to the relative path. Otherwise the supplied path is returned unchanged.

=cut

sub prepend_to_path {
    my $self          = shift;
    my $supplied_path = shift;
    my $config_path   = $self->path;
    if ( $config_path and $supplied_path !~ m!^/! ) {
        return "$config_path/$supplied_path";
    }
    else {
        return $supplied_path;
    }
}

=head2 server_ip()

Returns the address on which xacerbate listens.

=cut

sub server_ip {
    my $self = shift;
    return $self->{server_ip};
}

=head2 start_xte()

Returns start_xte value (true or false), ie whether xteriorize should be started alongside xacerbate.

=cut

sub start_xte {
    my $self = shift;
    if ( lc( $self->{start_xte} ) eq 'yes' ) {
        return 1;
    }
    else { return 0 }
}

=head2 startup_commands()

Returns a list of startup command filenames.

=cut

sub startup_commands {
    my $self = shift;
    return @{ $self->{startup_commands} || [] };
}

=head2 startup_files_path()

Returns the path to the startup command files.

=cut

sub startup_files_path {
    my $self = shift;
    return $self->{startup_files_path};
}

=head2 tick_interval()

Returns the interval between ticks (or twice the interval between a tick and a tock).

=cut

sub tick_interval {
    my $self = shift;
    return $self->{tick_interval};
}

=head2 transform_xsl()

Returns the name of the main transform file used by xacerbate.

=cut

sub transform_xsl {
    my $self = shift;
    return $self->{transform_xsl};
}

=head2 very_persistent_modifiable_files()

Returns a list of modifiable files that should persist from session to session, even when xcruciate is reset (they will still be reinitialised by a factory reset).

=cut

sub very_persistent_modifiable_files {
    my $self = shift;
    return @{ $self->{very_persistent_modifiable_files} || [] };
}

=head2 xca_captcha_timeout()

Returns the time limit after which captchas time out

=cut

sub xca_captcha_timeout {
    my $self = shift;
    if (    ( lc( $self->{start_xte} ) eq 'yes' )
        and ( lc( $self->{xte_use_xca} ) eq 'yes' ) )
    {
        return $self->{xca_captcha_timeout};
    }
    else {
        return undef;
    }
}

=head2 xca_castes()

Returns a list of site-specific castes, in ascending order of rights.

=cut

sub xca_castes {
    my $self = shift;
    if (    ( lc( $self->{start_xte} ) eq 'yes' )
        and ( lc( $self->{xte_use_xca} ) eq 'yes' ) )
    {
        return @{ $self->{xca_castes} || [] };
    }
    else {
        return undef;
    }
}

=head2 xca_confirmation_timeout()

Returns the time limit after which confirmation codes time out.

=cut

sub xca_confirmation_timeout {
    my $self = shift;
    if (    ( lc( $self->{start_xte} ) eq 'yes' )
        and ( lc( $self->{xte_use_xca} ) eq 'yes' ) )
    {
        return $self->{xca_confirmation_timeout};
    }
    else {
        return undef;
    }
}

=head2 xca_date_formats()

Returns a list of date formats.

=cut

sub xca_date_formats {
    my $self = shift;
    if ( lc( ( $self->{start_xte} ) eq 'yes' )
        and ( lc( $self->{xte_use_xca} ) eq 'yes' ) )
    {
        return @{ $self->{xca_date_formats} || [] };
    }
    else {
        return undef;
    }
}

=head2 xca_datetime_formats()

Returns a list of datetime formats.

=cut

sub xca_datetime_formats {
    my $self = shift;
    if (    ( lc( $self->{start_xte} ) eq 'yes' )
        and ( lc( $self->{xte_use_xca} ) eq 'yes' ) )
    {
        return @{ $self->{xca_datetime_formats} || [] };
    }
    else {
        return undef;
    }
}

=head2 xca_default_email_contact()

Returns a flag signifying whether, by default, users accept contact via email.

=cut

sub xca_default_email_contact {
    my $self = shift;
    if (    ( lc( $self->{start_xte} ) eq 'yes' )
        and ( lc( $self->{xte_use_xca} ) eq 'yes' )
        and ( lc( $self->{xca_default_email_contact} ) eq 'yes' ) )
    {
        return 1;
    }
    else {
        return 0;
    }
}

=head2 xca_default_pm_contact()

Returns a flag signifying whether, by default, users accept contact via pm.

=cut

sub xca_default_pm_contact {
    my $self = shift;
    if (    ( lc( $self->{start_xte} ) eq 'yes' )
        and ( lc( $self->{xte_use_xca} ) eq 'yes' )
        and ( lc( $self->{xca_default_pm_contact} ) eq 'yes' ) )
    {
        return 1;
    }
    else {
        return 0;
    }
}

=head2 xca_failed_login_lockout()

Returns the number of failed logins after which an account will be locked.

=cut

sub xca_failed_login_lockout {
    my $self = shift;
    if (    ( lc( $self->{start_xte} ) eq 'yes' )
        and ( lc( $self->{xte_use_xca} ) eq 'yes' ) )
    {
        return $self->{xca_failed_login_lockout};
    }
    else {
        return undef;
    }
}

=head2 xca_failed_login_lockout_reset()

Returns the time delay after which a locked account will be unlocked.

=cut

sub xca_failed_login_lockout_reset {
    my $self = shift;
    if (    ( lc( $self->{start_xte} ) eq 'yes' )
        and ( lc( $self->{xte_use_xca} ) eq 'yes' ) )
    {
        return $self->{xca_failed_login_lockout_reset};
    }
    else {
        return undef;
    }
}

=head2 xca_favicon()

Returns the url of the site favicon (either a fully-qualified url or a local, absolute url).

=cut

sub xca_favicon {
    my $self = shift;
    if ( lc( ( $self->{start_xte} ) eq 'yes' )
        and ( lc( $self->{xte_use_xca} ) eq 'yes' ) )
    {
        return $self->{xca_favicon};
    }
    else {
        return undef;
    }
}

=head2 xca_from_address()

Returns the email address used for outgoing mail.

=cut

sub xca_from_address {
    my $self = shift;
    if (    ( lc( $self->{start_xte} ) eq 'yes' )
        and ( lc( $self->{xte_use_xca} ) eq 'yes' ) )
    {
        return $self->{xca_from_address};
    }
    else {
        return undef;
    }
}

=head2 xca_gateway_authenticate_timeout()

Returns the timeout for Xteriorize gateways authenticating with Xcathedra.

=cut

sub xca_gateway_authenticate_timeout {
    my $self = shift;
    if (    ( lc( $self->{start_xte} ) eq 'yes' )
        and ( lc( $self->{xte_use_xca} ) eq 'yes' ) )
    {
        return $self->{xca_gateway_authenticate_timeout};
    }
    else {
        return undef;
    }
}

=head2 xca_http_domain()

Returns the website domain.

=cut

sub xca_http_domain {
    my $self = shift;
    if (    ( lc( $self->{start_xte} ) eq 'yes' )
        and ( lc( $self->{xte_use_xca} ) eq 'yes' ) )
    {
        return $self->{http_domain};
    }
    else {
        return undef;
    }
}

=head2 xca_manual_registration_activation()

Returns a flag signifying whether manual admin approval of new user accounts is currently activated.

=cut

sub xca_manual_registration_activation {
    my $self = shift;
    if (    ( lc( $self->{start_xte} ) eq 'yes' )
        and ( lc( $self->{xte_use_xca} ) eq 'yes' )
        and ( lc( $self->{xca_manual_registration_activation} ) eq 'yes' ) )
    {
        return 1;
    }
    else {
        return 0;
    }
}

=head2 xca_path()

Returns the path to the directory containing xcathedra (if defined).

=cut

sub xca_path {
    my $self = shift;
    if (    ( lc( $self->{start_xte} ) eq 'yes' )
        and ( lc( $self->{xte_use_xca} ) eq 'yes' ) )
    {
        return $self->{xca_path};
    }
    else {
        return undef;
    }
}

=head2 xca_profile_template_path()

Returns the path to the site-specific template for user profiles.

=cut

sub xca_profile_template_path {
    my $self = shift;
    if (    ( lc( $self->{start_xte} ) eq 'yes' )
        and ( lc( $self->{xte_use_xca} ) eq 'yes' ) )
    {
        return $self->{xca_profile_template_path};
    }
    else {
        return undef;
    }
}

=head2 xca_script_debug_caste()

Returns the minimum caste which will see extended script error diagnostics.

=cut

sub xca_script_debug_caste {
    my $self = shift;
    if (    ( lc( $self->{start_xte} ) eq 'yes' )
        and ( lc( $self->{xte_use_xca} ) eq 'yes' ) )
    {
        return $self->{xca_script_debug_caste};
    }
    else {
        return undef;
    }
}

=head2 xca_session_timeout()

Returns the delay after which a session will time out.

=cut

sub xca_session_timeout {
    my $self = shift;
    if (    ( lc( $self->{start_xte} ) eq 'yes' )
        and ( lc( $self->{xte_use_xca} ) eq 'yes' ) )
    {
        return $self->{xca_session_timeout};
    }
    else {
        return undef;
    }
}

=head2 xca_site_path()

Returns the path to the directory containing the site-specific files.

=cut

sub xca_site_path {
    my $self = shift;
    if (    ( lc( $self->{start_xte} ) eq 'yes' )
        and ( lc( $self->{xte_use_xca} ) eq 'yes' ) )
    {
        return $self->{xca_site_path};
    }
    else {
        return undef;
    }
}

=head2 xca_time_offset()

Returns the default time zone offset.

=cut

sub xca_time_offset {
    my $self = shift;
    if (    ( lc( $self->{start_xte} ) eq 'yes' )
        and ( lc( $self->{xte_use_xca} ) eq 'yes' ) )
    {
        return $self->{xca_time_offset};
    }
    else {
        return undef;
    }
}

=head2 xca_unique_registration_email()

Returns a flag signifying whether each user must use a unique email to register.

=cut

sub xca_unique_registration_email {
    my $self = shift;
    if (    ( lc( $self->{start_xte} ) eq 'yes' )
        and ( lc( $self->{xte_use_xca} ) eq 'yes' )
        and ( lc( $self->{xca_unique_registration_email} ) eq 'yes' ) )
    {
        return 1;
    }
    else {
        return 0;
    }
}

=head2 xte_captcha_bgcolors()

Returns a list of hex bytes (00 to FF) to be used to construct captcha background RGB values.

=cut

sub xte_captcha_bgcolors {
    my $self = shift;
    if ( ( lc( $self->{start_xte} ) eq 'yes' )
        and $self->{xte_captcha_bgcolors} )
    {
        return @{ $self->{xte_captcha_bgcolors} };
    }
    else {
        return ();
    }
}

=head2 xte_captcha_colors()

Returns a list of hex bytes (00 to FF) to be used to construct captcha foreground RGB values.

=cut

sub xte_captcha_colors {
    my $self = shift;
    if ( ( lc( $self->{start_xte} ) eq 'yes' ) and $self->{xte_captcha_colors} )
    {
        return @{ $self->{xte_captcha_colors} };
    }
    else {
        return ();
    }
}

=head2 xte_captcha_height()

Returns the pixel height of captchas.

=cut

sub xte_captcha_height {
    my $self = shift;
    if ( lc( $self->{start_xte} ) eq 'yes' ) {
        return $self->{xte_captcha_height};
    }
    else {
        return undef;
    }
}

=head2 xte_captcha_max_angle()

Returns the maximum angle by which TrueType text will be rotated in a captcha.

=cut

sub xte_captcha_max_angle {
    my $self = shift;
    if ( lc( $self->{start_xte} ) eq 'yes' ) {
        return $self->{xte_captcha_max_angle};
    }
    else {
        return undef;
    }
}

=head2 xte_captcha_max_line_thickness()

Returns the maximum thickness of captcha lines.

=cut

sub xte_captcha_max_line_thickness {
    my $self = shift;
    if ( lc( $self->{start_xte} ) eq 'yes' ) {
        return $self->{xte_captcha_max_line_thickness};
    }
    else {
        return undef;
    }
}

=head2 xte_captcha_max_lines()

Returns the maximum number of lines to draw on a captcha.

=cut

sub xte_captcha_max_lines {
    my $self = shift;
    if ( lc( $self->{start_xte} ) eq 'yes' ) {
        return $self->{xte_captcha_max_lines};
    }
    else {
        return undef;
    }
}

=head2 xte_captcha_min_line_thickness()

Returns the minimum line thickness to use in captchas.

=cut

sub xte_captcha_min_line_thickness {
    my $self = shift;
    if ( lc( $self->{start_xte} ) eq 'yes' ) {
        return $self->{xte_captcha_min_line_thickness};
    }
    else {
        return undef;
    }
}

=head2 xte_captcha_min_lines()

Returns the minimum number of lines to draw on a captcha.

=cut

sub xte_captcha_min_lines {
    my $self = shift;
    if ( lc( $self->{start_xte} ) eq 'yes' ) {
        return $self->{xte_captcha_min_lines};
    }
    else {
        return undef;
    }
}

=head2 xte_captcha_particle_count()

Returns the number of particles to add to a captcha.

=cut

sub xte_captcha_particle_count {
    my $self = shift;
    if ( lc( $self->{start_xte} ) eq 'yes' ) {
        return $self->{xte_captcha_particle_count};
    }
    else {
        return undef;
    }
}

=head2 xte_captcha_particle_size()

Returns the size of particles added to a captcha.

=cut

sub xte_captcha_particle_size {
    my $self = shift;
    if ( lc( $self->{start_xte} ) eq 'yes' ) {
        return $self->{xte_captcha_particle_size};
    }
    else {
        return undef;
    }
}

=head2 xte_captcha_styles()

Returns a list of GD:SecurityImage captcha styles.

=cut

sub xte_captcha_styles {
    my $self = shift;
    if ( ( lc( $self->{start_xte} ) eq 'yes' ) and $self->{xte_captcha_styles} )
    {
        return @{ $self->{xte_captcha_styles} };
    }
    else {
        return ();
    }
}

=head2 xte_captcha_ttfont_size()

Returns the point size for TrueType captcha text.

=cut

sub xte_captcha_ttfont_size {
    my $self = shift;
    if ( lc( $self->{start_xte} ) eq 'yes' ) {
        return $self->{xte_captcha_ttfont_size};
    }
    else {
        return undef;
    }
}

=head2 xte_captcha_ttfonts()

Returns a list of TrueType fonts for captchas.

=cut

sub xte_captcha_ttfonts {
    my $self = shift;
    if ( ( lc( $self->{start_xte} ) eq 'yes' )
        and $self->{xte_captcha_ttfonts} )
    {
        return @{ $self->{xte_captcha_ttfonts} };
    }
    else {
        return ();
    }
}

=head2 xte_captcha_width()

Returns the pixel width of captchas.

=cut

sub xte_captcha_width {
    my $self = shift;
    if ( lc( $self->{start_xte} ) eq 'yes' ) {
        return $self->{xte_captcha_width};
    }
    else {
        return undef;
    }
}

=head2 xte_check_for_waiting()

Returns the xte_check_for_waiting value (time to wait before revising number of child processes).

=cut

sub xte_check_for_waiting {
    my $self = shift;
    if ( lc( $self->{start_xte} ) eq 'yes' ) {
        return $self->{xte_check_for_waiting};
    }
    else {
        return undef;
    }
}

=head2 xte_cidr_allow()

Returns a list of allowed ip ranges for xteriorize

=cut

sub xte_cidr_allow {
    my $self = shift;
    if ( ( lc( $self->{start_xte} ) eq 'yes' ) and $self->{xte_cidr_allow} ) {
        return @{ $self->{xte_cidr_allow} };
    }
    else {
        return ();
    }
}

=head2 xte_cidr_deny()

Returns a list of denied ip ranges for xteriorize

=cut

sub xte_cidr_deny {
    my $self = shift;
    if ( ( lc( $self->{start_xte} ) eq 'yes' ) and $self->{xte_cidr_deny} ) {
        return @{ $self->{xte_cidr_deny} };
    }
    else {
        return ();
    }
}

=head2 xte_docroot()

Returns the docroot used by xteriorize.

=cut

sub xte_docroot {
    my $self = shift;
    if ( lc( $self->{start_xte} ) eq 'yes' ) {
        return $self->{xte_docroot};
    }
    else {
        return undef;
    }
}

=head2 xte_enable_captcha()

Returns true if captcha serving is enabled.

=cut

sub xte_enable_captcha {
    my $self = shift;
    if (    ( lc( $self->{start_xte} ) eq 'yes' )
        and $self->{xte_enable_captcha}
        and ( lc( $self->{xte_enable_captcha} ) eq 'yes' ) )
    {
        return 1;
    }
    else {
        return 0;
    }
}

=head2 xte_enable_email()

Returns true if is email sending is enabled.

=cut

sub xte_enable_email {
    my $self = shift;
    if (    ( lc( $self->{start_xte} ) eq 'yes' )
        and $self->{xte_enable_email}
        and ( lc( $self->{xte_enable_email} ) eq 'yes' ) )
    {
        return 1;
    }
    else {
        return 0;
    }
}

=head2 xte_enable_file_writing()

Returns true if is writing and deleting files is enabled.

=cut

sub xte_enable_file_writing {
    my $self = shift;
    if (    ( lc( $self->{start_xte} ) eq 'yes' )
        and $self->{xte_enable_file_writing}
        and ( lc( $self->{xte_enable_file_writing} ) eq 'yes' ) )
    {
        return 1;
    }
    else {
        return 0;
    }
}

=head2 xte_enable_fop()

Returns true if PDF output via Apache FOP is enabled.

=cut

sub xte_enable_fop {
    my $self = shift;
    if (    ( lc( $self->{start_xte} ) eq 'yes' )
        and $self->{xte_enable_fop}
        and ( lc( $self->{xte_enable_fop} ) eq 'yes' ) )
    {
        return 1;
    }
    else {
        return 0;
    }
}

=head2 xte_enable_json()

Returns true if output via XML::GenericJSON is enabled.

=cut

sub xte_enable_json {
    my $self = shift;
    if (    ( lc( $self->{start_xte} ) eq 'yes' )
        and $self->{xte_enable_json}
        and ( lc( $self->{xte_enable_json} ) eq 'yes' ) )
    {
        return 1;
    }
    else {
        return 0;
    }
}

=head2 xte_enable_mxmlc()

Returns true if output via the Flex 3 compiler mxmlc is enabled.

=cut

sub xte_enable_mxmlc {
    my $self = shift;
    if (    ( lc( $self->{start_xte} ) eq 'yes' )
        and $self->{xte_enable_mxmlc}
        and ( lc( $self->{xte_enable_mxmlc} ) eq 'yes' ) )
    {
        return 1;
    }
    else {
        return 0;
    }
}

=head2 xte_enable_static_serving()

Returns true if direct static file serving (ie without xacerbate) is enabled.

=cut

sub xte_enable_static_serving {
    my $self = shift;
    if (    ( lc( $self->{start_xte} ) eq 'yes' )
        and $self->{xte_enable_static_serving}
        and ( lc( $self->{xte_enable_static_serving} ) eq 'yes' ) )
    {
        return 1;
    }
    else {
        return 0;
    }
}

=head2 xte_enable_uploads()

Returns true if HTTP file uploading is enabled.

=cut

sub xte_enable_uploads {
    my $self = shift;
    if (    ( lc( $self->{start_xte} ) eq 'yes' )
        and $self->{xte_enable_uploads}
        and ( lc( $self->{xte_enable_uploads} ) eq 'yes' ) )
    {
        return 1;
    }
    else {
        return 0;
    }
}

=head2 xte_enable_xmlroff()

Returns true if PDF output via xmlroff is enabled.

=cut

sub xte_enable_xmlroff {
    my $self = shift;
    if (    ( lc( $self->{start_xte} ) eq 'yes' )
        and $self->{xte_enable_xmlroff}
        and ( lc( $self->{xte_enable_xmlroff} ) eq 'yes' ) )
    {
        return 1;
    }
    else {
        return 0;
    }
}

=head2 xte_from_address()

Returns the from address for emails sent by xteriorize

=cut

sub xte_from_address {
    my $self = shift;
    if ( lc( $self->{start_xte} ) eq 'yes' ) {
        return $self->{xte_from_address};
    }
    else {
        return undef;
    }
}

=head2 xte_gateway_auth()

Returns the from code expected by xacerbate to authorize gateway connections.

=cut

sub xte_gateway_auth {
    my $self = shift;
    if ( lc( $self->{start_xte} ) eq 'yes' ) {
        return $self->{xte_gateway_auth};
    }
    else {
        return undef;
    }
}

=head2 xte_group()

Returns the un*x group to use for xteriorize child processes. May be undefined.

=cut

sub xte_group {
    my $self = shift;
    if ( lc( $self->{start_xte} ) eq 'yes' ) {
        return $self->{xte_group};
    }
    else {
        return undef;
    }
}

=head2 xte_i18n_list()

Returns a list of i18n files.

=cut

sub xte_i18n_list {
    my $self = shift;
    if ( lc( $self->{start_xte} ) eq 'yes' ) {
        return @{ $self->{xte_i18n_list} || [] };
    }
    else {
        return undef;
    }
}

=head2 xte_image_sizes()

Returns a list of sizes (eg 123x456) to which images will be scaled/cropped.

=cut

sub xte_image_sizes {
    my $self = shift;
    if ( lc( $self->{start_xte} ) eq 'yes' ) {
        return @{ $self->{xte_image_sizes} || [] };
    }
    else {
        return undef;
    }
}

=head2 xte_log_file()

Returns the path to the xte log file.

=cut

sub xte_log_file {
    my $self = shift;
    if ( lc( $self->{start_xte} ) eq 'yes' ) {
        return $self->{xte_log_file};
    }
    else {
        return undef;
    }
}

=head2 xte_log_level()

Returns the xteriorize log level.

=cut

sub xte_log_level {
    my $self = shift;
    if ( lc( $self->{start_xte} ) eq 'yes' ) {
        return $self->{xte_log_level};
    }
    else {
        return undef;
    }
}

=head2 xte_max_image_size()

Returns the maximum dimensions (eg 123x456) beyond which an uploaded image will be cropped.

=cut

sub xte_max_image_size {
    my $self = shift;
    if ( lc( $self->{start_xte} ) eq 'yes' ) {
        return $self->{xte_max_image_size};
    }
    else {
        return undef;
    }
}

=head2 xte_max_servers()

Returns the Net::Prefork max_servers value for xteriorize.

=cut

sub xte_max_servers {
    my $self = shift;
    if ( lc( $self->{start_xte} ) eq 'yes' ) {
        return $self->{xte_max_servers};
    }
    else {
        return undef;
    }
}

=head2 xte_max_requests()

Returns the Net::Prefork max_requests value for xteriorize.

=cut

sub xte_max_requests {
    my $self = shift;
    if ( lc( $self->{start_xte} ) eq 'yes' ) {
        return $self->{xte_max_requests};
    }
    else {
        return undef;
    }
}

=head2 xte_max_spare_servers()

Returns the Net::Prefork max_spare_servers value for xteriorize.

=cut

sub xte_max_spare_servers {
    my $self = shift;
    if ( lc( $self->{start_xte} ) eq 'yes' ) {
        return $self->{xte_max_spare_servers};
    }
    else {
        return undef;
    }
}

=head2 xte_max_upload_size()

Returns the maximum permitted size in kb of file uploads.

=cut

sub xte_max_upload_size {
    my $self = shift;
    if ( lc( $self->{start_xte} ) eq 'yes' ) {
        return $self->{xte_max_upload_size};
    }
    else {
        return undef;
    }
}

=head2 xte_mimetype_path()

Returns the path to the mimetype lookup table for direct static file serving.

=cut

sub xte_mimetype_path {
    my $self = shift;
    if ( lc( $self->{start_xte} ) eq 'yes' ) {
        return $self->{xte_mimetype_path};
    }
    else {
        return undef;
    }
}

=head2 xte_min_servers()

Returns the Net::Prefork min_servers value for xteriorize.

=cut

sub xte_min_servers {
    my $self = shift;
    if ( lc( $self->{start_xte} ) eq 'yes' ) {
        return $self->{xte_min_servers};
    }
    else {
        return undef;
    }
}

=head2 xte_min_spare_servers()

Returns the Net::Prefork min_spare_servers value for xteriorize.

=cut

sub xte_min_spare_servers {
    my $self = shift;
    if ( lc( $self->{start_xte} ) eq 'yes' ) {
        return $self->{xte_min_spare_servers};
    }
    else {
        return undef;
    }
}

=head2 xte_port()

Returns the port used by xteriorize.

=cut

sub xte_port {
    my $self = shift;
    if ( lc( $self->{start_xte} ) eq 'yes' ) {
        return $self->{xte_port};
    }
    else {
        return undef;
    }
}

=head2 xte_post_max()

Returns the maximum character size of an http request received by xteriorize.

=cut

sub xte_post_max {
    my $self = shift;
    if ( lc( $self->{start_xte} ) eq 'yes' ) {
        return $self->{xte_post_max};
    }
    else {
        return undef;
    }
}

=head2 xte_report_benchmarks()

Returns true if timings for various aspects of Xcruciate processing are being output.

=cut

sub xte_report_benchmarks {
    my $self = shift;
    if ( not( lc( $self->{start_xte} ) eq 'yes' ) ) {
        return undef;
    }
    elsif ( lc( $self->{xte_report_benchmarks} ) eq 'yes' ) {
        return 1;
    }
    else { return 0 }
}

=head2 xte_server_ip()

Returns the ip on which xteriorize will listen.

=cut

sub xte_server_ip {
    my $self = shift;
    if ( lc( $self->{start_xte} ) eq 'yes' ) {
        return $self->{xte_server_ip};
    }
    else {
        return undef;
    }
}

=head2 xte_site_language()

Returns the site language in 2-character format.

=cut

sub xte_site_language {
    my $self = shift;
    if ( lc( $self->{start_xte} ) eq 'yes' ) {
        return $self->{xte_site_language};
    }
    else {
        return undef;
    }
}

=head2 xte_smtp_charset()

Returns the charset used for smtp by xteriorize.

=cut

sub xte_smtp_charset {
    my $self = shift;
    if ( lc( $self->{start_xte} ) eq 'yes' ) {
        return $self->{xte_smtp_charset};
    }
    else {
        return undef;
    }
}

=head2 xte_smtp_encoding()

Returns the encoding used for smtp by xteriorize.

=cut

sub xte_smtp_encoding {
    my $self = shift;
    if ( lc( $self->{start_xte} ) eq 'yes' ) {
        return $self->{xte_smtp_encoding};
    }
    else {
        return undef;
    }
}

=head2 xte_smtp_host()

Returns the host used for smtp by xteriorize.

=cut

sub xte_smtp_host {
    my $self = shift;
    if ( lc( $self->{start_xte} ) eq 'yes' ) {
        return $self->{xte_smtp_host};
    }
    else {
        return undef;
    }
}

=head2 xte_smtp_port()

Returns the port used for smtp by xteriorize.

=cut

sub xte_smtp_port {
    my $self = shift;
    if ( lc( $self->{start_xte} ) eq 'yes' ) {
        return $self->{xte_smtp_port};
    }
    else {
        return undef;
    }
}

=head2 xte_splurge_input()

Returns true if xte_splurge_input is enabled (copies XML sent from xteriorize to xacerbate to STDERR).

=cut

sub xte_splurge_input {
    my $self = shift;
    if ( not( lc( $self->{start_xte} ) eq 'yes' ) ) {
        return undef;
    }
    elsif ( lc( $self->{xte_splurge_input} ) eq 'yes' ) {
        return 1;
    }
    else { return 0 }
}

=head2 xte_splurge_output()

Returns true if xte_splurge_output is enabled (copies XML sent from xacerbate to xteriorize to STDERR).

=cut

sub xte_splurge_output {
    my $self = shift;
    if ( not( lc( $self->{start_xte} ) eq 'yes' ) ) {
        return undef;
    }
    elsif ( lc( $self->{xte_splurge_output} ) eq 'yes' ) {
        return 1;
    }
    else { return 0 }
}

=head2 xte_static_directories()

Returns a list of directories under docroot from which files will be served directly by Xteriorized.

=cut

sub xte_static_directories {
    my $self = shift;
    if ( lc( $self->{start_xte} ) eq 'yes' ) {
        return @{ $self->{xte_static_directories} || [] };
    }
    else {
        return undef;
    }
}

=head2 xte_temporary_file_path()

Returns a directory to be used for temporary files, eg for output filters

=cut

sub xte_temporary_file_path {
    my $self = shift;
    if ( lc( $self->{start_xte} ) eq 'yes' ) {
        return $self->{xte_temporary_file_path};
    }
    else {
        return undef;
    }
}

=head2 xte_user()

Returns the un*x user to use for xteriorize child processes. May be undefined.

=cut

sub xte_user {
    my $self = shift;
    if ( lc( $self->{start_xte} ) eq 'yes' ) {
        return $self->{xte_user};
    }
    else {
        return undef;
    }
}

=head2 xte_use_xca()

Returns a flag according to whether or not xcathedra is used.

=cut

sub xte_use_xca {
    my $self = shift;
    if (    ( lc( $self->{start_xte} ) eq 'yes' )
        and ( lc( $self->{xte_use_xca} ) eq 'yes' ) )
    {
        return 1;
    }
    elsif ( $self->{start_xte} eq 'yes' ) {
        return 0;
    }
    else {
        return undef;
    }
}

=head2 xte_xac_timeout()

Returns the delay for a response to xteriorize by xacerbate, after which xteriorize will issue a 504 ('gateway time-out') error.

=cut

sub xte_xac_timeout {
    my $self = shift;
    if ( lc( $self->{start_xte} ) eq 'yes' ) {
        return $self->{xte_xac_timeout};
    }
    else {
        return undef;
    }
}

=head2 local_croak()

Function for croaking

=cut

sub local_croak {
    my $message = shift;
    croak $message if $message;
}

=head1 BUGS

The best way to report bugs is via the Xcruciate bugzilla site (F<http://www.xcruciate.co.uk/bugzilla>).

=head1 PREVIOUS VERSIONS

=over

B<0.01>: First upload

B<0.03>: First upload including module

B<0.04>: Changed minimum perl version to 5.8.8

B<0.05>: Added debug_list data type. Warn about unknown entries

B<0.06>: Added stop_only option to new(), added some comments

B<0.07>: Revised config file entry names. Check server_ip as well as port on start/stop. Attempt to put all Xcruciate modules in one PAUSE tarball.

B<0.08>: Added xte_temporary_file_path. Added lax option to proceed despite config errors.

B<0.09>: Use Carp for errors.

B<0.10>: Prepend path entry to relative paths

B<0.11>: Remove transform_xsl_path

B<0.12>: Resolve modifiable file paths, attempt to parse XML and XSLT files

B<0.14>: Global update

B<0.15>: Added xte_splurge_output

B<0.16>: Added support for xca entries. Added very_persistent_modifiable_files and xte_i18n_files. Distinquish warnings and errors in output.

B<0.17>: use warnings.

B<0.18>: Removed xca_time_display_function. Made v0.16 additions optional. Added nine new xca entries. Added new types to file format reporting.

B<0.19>: Use duration type for durations. Added xca_gateway_authenticate_timeout (previously a global in Xcathedra code). Got name of xte_use_xca right. Got missing xca entry testing in right loop.

B<0.20>: Added backup_path, xte_site_language, xte captcha entries and xte_enable entries, xca_image_sizes entries.

=back

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 - 2009 by SARL Cyberporte/Menteith Consulting

This library is distributed under the BSD licence (F<http://www.xcruciate.co.uk/licence-code>).

=cut

1;
