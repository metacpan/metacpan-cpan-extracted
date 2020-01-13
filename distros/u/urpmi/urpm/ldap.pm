package urpm::ldap;


use strict;
use warnings;
use urpm;
use urpm::util qw(cat_ output_safe);
use urpm::msg 'N';
use urpm::media;

our $LDAP_CONFIG_FILE = '/etc/ldap.conf';
my @per_media_opt = (@urpm::media::PER_MEDIA_OPT, qw(md5sum ftp-proxy http-proxy));

# TODO
# use srv dns record ?
# complete the doc

=head1 NAME

urpm::ldap - routines to handle configuration with ldap

=head1 SYNOPSIS

=head1 DESCRIPTION

=over

=item write_ldap_cache($urpm,$medium)

Writes the value fetched from ldap, in case of server failure. This should not
be used to reduce the load of the ldap server, as fetching is still needed, and
therefore, caching is useless if server is up.

=cut

sub write_ldap_cache($$) {
    my ($urpm, $medium) = @_;
    my $ldap_cache = "$urpm->{cachedir}/ldap";
    # FIXME what perm for cache ?
    -d $ldap_cache or mkdir $ldap_cache
	or die N("Cannot create ldap cache directory");
    output_safe("$ldap_cache/$medium->{name}",
		join("\n",
		     "# internal cache file for disconnect ldap operation, do not edit",
		     map { "$_ = $medium->{$_}" } grep { $medium->{$_} } keys %$medium
		)
	) or die N("Cannot write cache file for ldap\n");
    return 1;
}


=item check_ldap_medium($medium)

Checks if the ldap medium has all required attributes.

=cut

sub check_ldap_medium($) {
    my ($medium) = @_;
    return $medium->{name} && $medium->{url};
}

sub get_vars_from_sh {
    my ($filename) = @_;
    my %l;
    foreach (cat_($filename)) {
	s/#.*//; s/^\s*//; s/\s*$//;
	my ($key, $val) = /^(\w+)=(.*)/ or next;
	$val =~ s/^(["'])(.*)\1$/$2/;
	$l{$key} = $val;
    }
    %l;
}

=item read_ldap_cache($urpm)

Reads the cache created by the C<write_ldap_cache> function. Should be called
if the ldap server doesn't answer (upgrade, network problem, mobile user, etc.)

=cut

sub read_ldap_cache {
    my ($urpm) = @_;
    foreach (glob("$urpm->{cachedir}/ldap/*")) {
	! -f $_ and next;
	my %medium = get_vars_from_sh($_);
	next if !check_ldap_medium(\%medium);
	urpm::media::add_existing_medium($urpm, \%medium, 'nocheck');
    }
}

=item clean_ldap_cache($urpm)

Cleans the ldap cache, removes all files in the directory.

=cut

#- clean the cache, before writing a new one
sub clean_ldap_cache($) {
    my ($urpm) = @_;
    unlink glob("$urpm->{cachedir}/ldap/*");
}


=item get_ldap_config()

parse the system LDAP configuration file and return its config values

=cut

sub get_ldap_config() {
    return get_ldap_config_file($LDAP_CONFIG_FILE);
}

=item get_ldap_config_file($file)

parse a given LDAP configuration file and return its config values

=cut

sub get_ldap_config_file {
    my ($file) = @_;
    my %config;
    foreach (cat_($file)) {
	s/#.*//;
	s/^\s*//;
	s/\s*$//;
	s/\s{2}/ /g;
	/^$/ and next;
	/^(\S*)\s*(\S*)/ && $2 or next;
	$config{$1} = $2;
    }
    return %config && \%config;
}


=item get_ldap_config_dns()

Not implemented yet.

=cut

sub get_ldap_config_dns() {
    # TODO
    die "not implemented yet\n";
}

my %ldap_changed_attributes = (
    'source-name' => 'name',
    'with-hdlist' => 'with_hdlist',
    'http-proxy' => 'http_proxy',
    'ftp-proxy' => 'ftp_proxy',
    'media-info-dir' => 'media_info_dir',
);

=item load_ldap_media($urpm)

Loads urpmi media configuration from ldap.

=cut

sub load_ldap_media {
    my ($urpm) = @_;

    my $config = get_ldap_config() or return;

    $config->{ssl} = 'off';

    # try first urpmi_foo and then foo
    foreach my $opt (qw(base uri filter host ssl port binddn passwd scope)) {
        if (!defined $config->{$opt} && defined $config->{"urpmi_$opt"}) {
            $config->{$opt} = $config->{"urpmi_$opt"};
        }
    }

    die N("No server defined, missing uri or host") if !(defined $config->{uri} || defined $config->{host});
    die N("No base defined") if !defined $config->{base};

    if (! defined $config->{uri}) {
        $config->{uri} = "ldap" . ($config->{ssl} eq 'on' ? "s" : "") . "://" .
	    $config->{host} . ($config->{port} ? ":" . $config->{port} : "") . "/";
    }

    eval {
        require Net::LDAP;
        my $ldap = Net::LDAP->new($config->{uri})
            or die N("Cannot connect to ldap uri:"), $config->{uri};

        $ldap->bind($config->{binddn}, $config->{password})
            or die N("Cannot connect to ldap uri:"), $config->{uri};
        #- base is mandatory
        my $result = $ldap->search(
            base   => $config->{base},
            filter => $config->{filter} || '(objectClass=urpmiRepository)',
            scope  => $config->{scope} || 'sub',
        );

        $result->code and die $result->error;
        # FIXME more than one server ?
        clean_ldap_cache($urpm);

        foreach my $entry ($result->all_entries) {
            my $medium = {};

	    foreach my $opt (@per_media_opt, keys %ldap_changed_attributes) {
		my $v = $entry->get_value($opt);
		defined $v and $medium->{$opt} = $v;
	    }

            #- name is not valid for the schema ( already in top )
            #- and _ are forbidden in attributes names

            foreach (keys %ldap_changed_attributes) {
                $medium->{$ldap_changed_attributes{$_}} = $medium->{$_};
                delete $medium->{$_};
            }
            #- add ldap_ to reduce collision
            #- TODO check if name already defined ?
            $medium->{name} = "ldap_" . $medium->{name};
            $medium->{ldap} = 1;
            next if !check_ldap_medium($medium);
            urpm::media::add_existing_medium($urpm, $medium, 'nocheck');
            write_ldap_cache($urpm,$medium); 
        }
    };
    if ($@) {
        $urpm->{log}($@);
        read_ldap_cache($urpm);
    }

}

1;


=back

=head1 COPYRIGHT

Copyright (C) 2005 MandrakeSoft SA

Copyright (C) 2005-2010 Mandriva SA

Copyright (C) 2011-2020 Mageia

=cut
