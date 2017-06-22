package urpm::mirrors;


use strict;
use urpm::util qw(cat_ find output_safe reduce_pathname);
use urpm::msg;
use urpm::download;


=head1 NAME

urpm::mirrors - Mirrors routines for urpmi

=head1 SYNOPSIS

=head1 DESCRIPTION

=over

=item try($urpm, $medium, $try)

$medium fields used: mirrorlist, with-dir

=cut

#- side-effects: $medium->{url}
#-   + those of _pick_one ($urpm->{mirrors_cache})
sub try {
    my ($urpm, $medium, $try) = @_;

    for (my $nb = 1; $nb < $urpm->{options}{'max-round-robin-tries'}; $nb++) {
	my $url = _pick_one($urpm, $medium->{mirrorlist}, $nb == 1, '') or return;
	$urpm->{info}(N("trying again with mirror %s", $url)) if $nb > 1;
	$medium->{url} = _add__with_dir($url, $medium->{'with-dir'});
	$try->() and return 1;
	black_list($urpm, $medium->{mirrorlist}, $url);
    }
    0;
}

=item try_probe($urpm, $medium, $try)

Similar to try() above, but failure is "normal" (useful when we lookup
a file)

$medium fields used: mirrorlist, with-dir

=cut

#- side-effects: $medium->{url}
#-   + those of list_urls ($urpm->{mirrors_cache})
sub try_probe {
    my ($urpm, $medium, $try) = @_;

    my $nb = 0;
    foreach my $mirror (map { @$_ } list_urls($urpm, $medium, '')) {
	$nb++ < $urpm->{options}{'max-round-robin-probes'} or last;
	my $url = $mirror->{url};
	$nb > 1 ? $urpm->{info}(N("trying again with mirror %s", $url)) 
	        : $urpm->{log}("using mirror $url");
	$medium->{url} = _add__with_dir($url, $medium->{'with-dir'});
	$try->() and return 1;
    }
    0;
}

#- side-effects: none
sub _add__with_dir {
    my ($url, $with_dir) = @_;
    reduce_pathname($url . ($with_dir ? "/$with_dir" : ''));
}

#- side-effects: $medium->{url}
#-   + those of _pick_one ($urpm->{mirrors_cache})
sub pick_one {
    my ($urpm, $medium, $allow_cache_update) = @_;   

    my $url = _pick_one($urpm, $medium->{mirrorlist}, 'must_succeed', $allow_cache_update);
    $medium->{url} = _add__with_dir($url, $medium->{'with-dir'});
}

#- side-effects:
#-   + those of _pick_one_ ($urpm->{mirrors_cache})
sub list_urls {
    my ($urpm, $medium, $allow_cache_update) = @_;

    my @l = split(' ', $medium->{mirrorlist});
    map { 
	my $cache = _pick_one_($urpm, $_, $allow_cache_update, $_ ne $l[-1]);
	$cache ? $cache->{list} : [];
    } @l;
}

#- side-effects: $urpm->{mirrors_cache}
sub _pick_one {
    my ($urpm, $mirrorlists, $must_succeed, $allow_cache_update) = @_;   

    my @l = split(' ', $mirrorlists);
    foreach my $mirrorlist (@l) {
	if (my $cache = _pick_one_($urpm, $mirrorlist, $allow_cache_update, $mirrorlist ne $l[-1])) {

	    if ($cache->{nb_uses}++) {
		$urpm->{debug} and $urpm->{debug}("using mirror $cache->{chosen}");
	    } else {
		$urpm->{log}("using mirror $cache->{chosen}");
	    }

	    return $cache->{chosen};
	}
    }
    $must_succeed and $urpm->{fatal}(10, N("Could not find a mirror from mirrorlist %s", $mirrorlists));
    undef;
}

#- side-effects: $urpm->{mirrors_cache}
sub _pick_one_ {
    my ($urpm, $mirrorlist, $allow_cache_update, $set_network_mtime) = @_;

    my $cache = _cache__may_clean_if_outdated($urpm, $mirrorlist, $allow_cache_update);

    if (!$cache->{chosen}) {
	if (!$cache->{list}) {
	    if (_is_only_one_mirror($mirrorlist)) {
		$cache->{list} = [ { url => $mirrorlist } ];
	    } else {
		$cache->{list} = [ _list($urpm, $mirrorlist) ];
	    }
	    $cache->{time} = time();

	    # the cache will be deemed outdated if network_mtime is more recent than the cache's
	    $cache->{network_mtime} = _network_mtime() if $set_network_mtime;
	    $cache->{product_id_mtime} = _product_id_mtime(); 
	}

	if (-x '/usr/bin/rsync') {
	    $cache->{chosen} = $cache->{list}[0]{url};
	} else {
	    my $m = find { $_->{url} !~ m!^rsync://! } @{$cache->{list}};
	    $cache->{chosen} = $m->{url};
	}
	$cache->{chosen} or return;
	_save_cache($urpm);
    }
    $cache;
}
#- side-effects: $urpm->{mirrors_cache}
sub black_list {
    my ($urpm, $mirrorlists, $url) = @_;
    foreach my $mirrorlist (split ' ', $mirrorlists) {
	my $cache = _cache($urpm, $mirrorlist);

	if ($cache->{list}) {
	    @{$cache->{list}} = grep { $_->{url} ne $url } @{$cache->{list}};
	}
	delete $cache->{chosen};
    }
}

sub _trigger_cache_update {
    my ($urpm, $cache, $o_is_upgrade) = @_;

    my $reason = $o_is_upgrade ? "reason=upgrade" : "reason=update";
    $urpm->{log}("URPMI_ADDMEDIA_REASON $reason");
    $ENV{URPMI_ADDMEDIA_REASON} = $reason;
    %$cache =  ();
}

#- side-effects:
#-   + those of _cache ($urpm->{mirrors_cache})
sub _cache__may_clean_if_outdated {
    my ($urpm, $mirrorlist, $allow_cache_update) = @_;

    my $cache = _cache($urpm, $mirrorlist);

    if ($allow_cache_update) {
	if ($cache->{network_mtime} && _network_mtime() > $cache->{network_mtime}) {
	    $urpm->{log}("not using cached mirror list $mirrorlist since network configuration changed");
	    _trigger_cache_update($urpm, $cache);
	} elsif ($cache->{time} &&
		   time() > $cache->{time} + 24*60*60 * $urpm->{options}{'days-between-mirrorlist-update'}) {
	    $urpm->{log}("not using outdated cached mirror list $mirrorlist");
	    _trigger_cache_update($urpm, $cache);
	} elsif (!$cache->{product_id_mtime}) {
	    $urpm->{log}("cached mirror list uses an old format, invalidating it");
	    _trigger_cache_update($urpm, $cache, 1);
	} elsif ($cache->{product_id_mtime} && _product_id_mtime() != $cache->{product_id_mtime}) {
	    $urpm->{log}("not using cached mirror list $mirrorlist since product id file changed");
	    _trigger_cache_update($urpm, $cache, 1);
	}
    }
    $cache;
}

#- side-effects: $urpm->{mirrors_cache}
sub _cache {
    my ($urpm, $mirrorlist) = @_;
    my $full_cache = $urpm->{mirrors_cache} ||= _load_cache($urpm);
    $full_cache->{$mirrorlist} ||= {};
}
sub cache_file {
    my ($urpm) = @_;
    "$urpm->{cachedir}/mirrors.cache";
}
sub _load_cache {
    my ($urpm) = @_;
    my $cache;
    if (-e cache_file($urpm)) {
	$urpm->{debug} and $urpm->{debug}("loading mirrors cache");
	$cache = eval(cat_(cache_file($urpm)));
	$@ and $urpm->{error}("failed to read " . cache_file($urpm) . ": $@");
	$_->{nb_uses} = 0 foreach values %$cache;
    }
    if ($ENV{URPMI_ADDMEDIA_PRODUCT_VERSION} && delete $cache->{'$MIRRORLIST'}) {
	$urpm->{log}('not using cached mirror list $MIRRORLIST since URPMI_ADDMEDIA_PRODUCT_VERSION is set');
    }
    $cache || {};
}
sub _save_cache {
    my ($urpm) = @_;
    require Data::Dumper;
    my $s = Data::Dumper::Dumper($urpm->{mirrors_cache});
    $s =~ s/.*?=//; # get rid of $VAR1 = 
    output_safe(cache_file($urpm), $s);
}

#- side-effects: none
sub _list {
    my ($urpm, $mirrorlist) = @_;

    my @mirrors = _mirrors_filtered($urpm, _expand($mirrorlist));
    add_proximity_and_sort($urpm, \@mirrors);
    @mirrors;
}

sub _expand {
    my ($mirrorlist) = @_;

    # expand the variables
    
    if ($mirrorlist eq '$MIRRORLIST') {
	_MIRRORLIST();
    } else {
	require urpm::cfg;
	urpm::cfg::expand_line($mirrorlist);
    }
}

#- side-effects: $mirrors
sub add_proximity_and_sort {
    my ($urpm, $mirrors) = @_;

    my ($latitude, $longitude, $country_code);

    require Time::ZoneInfo;
    if (my $zone = Time::ZoneInfo->current_zone) {
	if (my $zones = Time::ZoneInfo->new) {
	    if (($latitude, $longitude) = $zones->latitude_longitude_decimal($zone)) {
		$country_code = $zones->country($zone);
		$urpm->{log}(N("found geolocalisation %s %.2f %.2f from timezone %s", $country_code, $latitude, $longitude, $zone));
	    }
	}
    }
    defined $latitude && defined $longitude or return;

    foreach (@$mirrors) {
	$_->{latitude} || $_->{longitude} or next;
	my $PI = 3.14159265358979;
	my $x = $latitude - $_->{latitude};
	my $y = ($longitude - $_->{longitude}) * cos($_->{latitude} / 180 * $PI);
	$_->{proximity} = sqrt($x * $x + $y * $y);
    }
    my ($best) = sort { $a->{proximity} <=> $b->{proximity} } @$mirrors;

    foreach (@$mirrors) {
	$_->{proximity_corrected} = $_->{proximity} * _random_correction();
	$_->{proximity_corrected} *= _between_country_correction($country_code, $_->{country}) if $best;
	$_->{proximity_corrected} *= _between_continent_correction($best->{continent}, $_->{continent}) if $best;
    }
    # prefer http mirrors by sorting them to the beginning
    @$mirrors = sort { ($b->{url} =~ m!^http://!) <=> ($a->{url} =~ m!^http://!)
		       || $a->{proximity_corrected} <=> $b->{proximity_corrected} } @$mirrors;
}

# add +/- 5% random
sub _random_correction() {
    my $correction = 0.05;
    1 + (rand() - 0.5) * $correction * 2;
}

sub _between_country_correction {
    my ($here, $mirror) = @_;
    $here && $mirror or return 1;
    $here eq $mirror ? 0.5 : 1;
}
sub _between_continent_correction {
    my ($here, $mirror) = @_;
    $here && $mirror or return 1;
    $here eq $mirror ? 0.5 : # favor same continent
      $here eq 'SA' && $mirror eq 'NA' ? 0.9 : # favor going "South America" -> "North America"
	1;
}

sub _mirrors_raw {
    my ($urpm, $url) = @_;

    $urpm->{log}(N("getting mirror list from %s", $url));
    my @l = urpm::download::get_content($urpm, $url, disable_metalink => 1) or $urpm->{error}("mirror list not found");
    @l;
}

sub _mirrors_filtered {
    my ($urpm, $mirrorlist) = @_;

    grep {
	$_->{type} eq 'distrib'; # type=updates seems to be history, and type=iso is not interesting here
    } map { chomp; parse_LDAP_namespace_structure($_) } _mirrors_raw($urpm, $mirrorlist);
}

sub _MIRRORLIST() {
    my $product_id = parse_LDAP_namespace_structure(cat_('/etc/product.id'));
    _mageia_mirrorlist($product_id);
}
sub _mageia_mirrorlist {
    my ($product_id, $o_arch) = @_;

    #- contact the following URL to retrieve the list of mirrors.
    #- http://wiki.mandriva.com/en/Product_id
    my $_product_type = lc($product_id->{type}); $product_id =~ s/\s//g;
    my $arch = $o_arch || $product_id->{arch};

    my @para = grep { $_ } $ENV{URPMI_ADDMEDIA_REASON};
    my $product_version = $ENV{URPMI_ADDMEDIA_PRODUCT_VERSION} || $product_id->{version};

    #"http://mirrors.mageia.org/api/$product_type.$product_version.$arch.list"
    "http://mirrors.mageia.org/api/mageia.$product_version.$arch.list"
      . (@para ? '?' . join('&', @para) : '');
}

#- heuristic to detect wether it is really a mirrorlist or a simple mirror url:
sub _is_only_one_mirror {
    my ($mirrorlist) = @_;
    _expand($mirrorlist) !~ /\.list(\?|$)/;
}

sub _network_mtime() { (stat('/etc/resolv.conf'))[9] }
sub _product_id_mtime() { (stat('/etc/product.id'))[9] }

sub parse_LDAP_namespace_structure {
    my ($s) = @_;
    my %h = map { /(.*?)=(.*)/ ? ($1 => $2) : @{[]} } split(',', $s);
    \%h;
}

1;


=back

=head1 COPYRIGHT

Copyright (C) 2005 MandrakeSoft SA

Copyright (C) 2005-2010 Mandriva SA

Copyright (C) 2011-2017 Mageia

=cut
