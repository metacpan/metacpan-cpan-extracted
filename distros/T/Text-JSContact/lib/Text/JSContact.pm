#!/usr/bin/perl -cw

use strict;
use warnings;

package Text::JSContact;

our $VERSION = '0.06';

# vCard <=> JSContact (RFC 9553) conversion, writing JSContact version 2.0
# (RFC 9982); follows RFC 9555 for vCard mapping and RFC 9554 for extensions

use Text::VCardFast qw(vcard2hash);
use Encode qw(decode_utf8 encode_utf8);
use MIME::Base64 qw(decode_base64);
use JSON;
use Scalar::Util qw(looks_like_number refaddr);
use feature 'state';

use Exporter 'import';
our @EXPORT_OK = qw(vcard_to_jscontact jscontact_to_vcard patch_vcard);

###############################################################################
# HELPERS
###############################################################################

sub _first_prop {
  my ($props, $name) = @_;
  my $items = $props->{$name};
  return undef unless $items && @$items;
  return $items->[0];
}

sub _first_value {
  my ($props, $name) = @_;
  my $prop = _first_prop($props, $name);
  return undef unless $prop;
  return $prop->{value};
}

# vCard 4 parameters that a vCard 3 card carries as X- (see _to_v3)
my %X_FALLBACK = map { $_ => 1 } qw(label geo tz cc mediatype sort-as level
  index created author author-name);

sub _param {
  my ($prop, $name) = @_;
  my $val = $prop->{params}{$name};
  $val = $prop->{params}{"x-$name"} if !defined $val && $X_FALLBACK{$name};
  return undef unless defined $val;
  return ref $val eq 'ARRAY' ? $val->[0] : $val;
}

sub _params_list {
  my ($prop, $name) = @_;
  my $val = $prop->{params}{$name};
  return () unless defined $val;
  # Split comma-separated values (e.g. TYPE=work,voice)
  return map { split /,/ } (ref $val eq 'ARRAY' ? @$val : ($val));
}

###############################################################################
# CONVERSION CONTEXT
###############################################################################

# Everything one conversion allocates lives in a context made for that
# call: the ids given to vCard properties without a PROP-ID, and the
# itemN groups that tie an X-ABLabel to its property.  Each allocator is
# seeded with what the vCard already uses, so an allocated id never
# equals an explicit PROP-ID and a new group never takes an existing one.
sub _new_context {
  my (%args) = @_;
  return {
    next_id     => 0,
    used_ids    => {},    # PROP-IDs present in the vCard
    next_group  => 0,
    used_groups => {},    # groups present in the vCard, lower-cased
    %args,
  };
}

# Seed a context with the PROP-IDs and groups of parsed vCard properties
sub _seed_context {
  my ($ctx, $props) = @_;
  for my $item (map { @$_ } values %$props) {
    my $pid = _param($item, 'prop-id');
    $ctx->{used_ids}{$pid} = 1 if defined $pid && $pid ne '';
    $ctx->{used_groups}{lc $item->{group}} = 1 if defined $item->{group} && $item->{group} ne '';
  }
  return $ctx;
}

# TODO(registry): an allocated id is a position in reading order, across
# the whole card.  A vCard without PROP-IDs (every vCard 3 card, which
# patch_vcard keeps free of them, and many vCard 4 ones) therefore keeps
# its ids only while no entry before them is added or removed: patching
# one entry out renumbers every entry read after it.  Counting per map
# would confine that to the one map; stable ids need either PROP-IDs
# written on every line or ids the registry derives some other way.
sub _alloc_id {
  my ($ctx) = @_;
  my $id;
  do { $id = '' . ++$ctx->{next_id} } while $ctx->{used_ids}{$id};
  return $id;
}

sub _alloc_group {
  my ($ctx) = @_;
  my $group;
  do { $group = 'item' . ++$ctx->{next_group} } while $ctx->{used_groups}{$group};
  $ctx->{used_groups}{$group} = 1;
  return $group;
}

sub _prop_id {
  my ($prop, $ctx) = @_;
  my $pid = _param($prop, 'prop-id');
  $pid = _alloc_id($ctx) unless defined $pid && $pid ne '';
  push @{$ctx->{pending}}, [$pid, $prop];
  return $pid;
}

# A vCard read from a CardDAV server is UTF-8 bytes (RFC 6350 S3.1).
# Decode it once, before parsing, so every value is characters; one that
# is not valid UTF-8 is read as Latin-1, a character per byte.  A string
# that is characters already is left alone.
sub _decode_input {
  my ($s) = @_;
  return $s if !defined $s || utf8::is_utf8($s) || $s !~ /[\x80-\xff]/;
  my $bytes = $s;
  my $chars = eval { Encode::decode('UTF-8', $bytes, Encode::FB_CROAK) };
  return defined $chars ? $chars : $s;
}

sub _make_contexts {
  my @types = @_;
  my %ctx;
  for my $t (@types) {
    my $lt = lc $t;
    if ($lt eq 'home') { $ctx{private} = JSON::true }
    elsif ($lt eq 'work') { $ctx{work} = JSON::true }
  }
  return %ctx ? \%ctx : undef;
}

sub _make_pref {
  my $prop = shift;
  # vCard 4: PREF parameter
  my $pref = _param($prop, 'pref');
  if (defined $pref && looks_like_number($pref)) {
    return $pref + 0;
  }
  # vCard 3: TYPE=pref
  for my $t (_params_list($prop, 'type')) {
    return 1 if lc $t eq 'pref';
  }
  return undef;
}

sub _to_utc_datetime {
  my $val = shift;
  return undef unless defined $val;
  # Normalize compact timestamps (e.g. 19940930T143510Z -> 1994-09-30T14:35:10Z)
  if ($val =~ /^(\d{4})-?(\d{2})-?(\d{2})T(\d{2}):?(\d{2}):?(\d{2})/) {
    return "$1-$2-$3T$4:$5:$6Z";
  }
  return $val;
}

sub _set_if {
  my ($hash, $key, $val, $transform) = @_;
  return unless defined $val && $val ne '';
  $val = $transform->($val) if $transform;
  $hash->{$key} = $val if defined $val;
}

# Collect X-ABLabel associations (Apple extension)
sub _collect_labels {
  my $props = shift;
  my %labels;
  for my $lp (@{$props->{'x-ablabel'} // []}) {
    my $group = $lp->{group} or next;
    my $val = $lp->{value} // '';
    $val = $1 if $val =~ m{^_\$\!<([^>]*)>\!\$_$};
    $labels{$group} = $val;
  }
  return \%labels;
}

sub _apply_label {
  my ($obj, $prop, $labels) = @_;
  if (my $group = $prop->{group}) {
    if (my $label = $labels->{$group}) {
      $obj->{label} = $label;
    }
  }
}

sub _convert_vcard_date {
  my $val = shift;
  return undef unless defined $val;

  # vCard 4 compact: YYYYMMDD or --MMDD
  if ($val =~ /^(\d{4}|--)-?(\d{2})-?(\d{2})(?:T|$)/) {
    my ($y, $m, $d) = ($1, $2, $3);
    $y = '0000' if $y eq '--';
    $y = '0000' if $y eq '1604'; # iOS "no year" magic
    return "$y-$m-$d";
  }

  # Already ISO format
  return $val if $val =~ /^\d{4}-\d{2}-\d{2}/;

  return $val;
}

sub _adr_values {
  my ($values, $idx) = @_;
  my $val = $values->[$idx];
  return () unless defined $val;
  if (ref $val eq 'ARRAY') {
    return grep { defined $_ && $_ ne '' } @$val;
  }
  return ($val) if $val ne '';
  return ();
}

###############################################################################
# VCARD -> JSCONTACT
###############################################################################

sub vcard_to_jscontact {
  my ($vcard_string) = @_;
  my ($card) = _read_vcard(_decode_input($vcard_string));
  return $card;
}

# The converters that fill a map of the Card, each with the key it fills:
# the ids a converter allocates are recorded against that key, so a patch
# knows which vCard property each entry came from
my @MAP_CONVERTERS = (
  [ nicknames           => \&_convert_nicknames ],
  [ emails              => \&_convert_emails ],
  [ phones              => \&_convert_phones ],
  [ addresses           => \&_convert_addresses ],
  [ organizations       => \&_convert_organizations ],
  [ titles              => \&_convert_titles ],
  [ anniversaries       => \&_convert_anniversaries ],
  [ notes               => \&_convert_notes ],
  [ onlineServices      => \&_convert_online_services ],
  [ media               => \&_convert_media ],
  [ links               => \&_convert_links ],
  [ calendars           => \&_convert_calendars ],
  [ schedulingAddresses => \&_convert_scheduling_addresses ],
  [ cryptoKeys          => \&_convert_crypto_keys ],
  [ directories         => \&_convert_directories ],
  [ preferredLanguages  => \&_convert_preferred_languages ],
  [ personalInfo        => \&_convert_personal_info ],
);

# Read a vCard given as characters.  Returns the Card, the conversion
# context (whose {sources} maps each Card entry to the vCard properties it
# was read from) and the parsed properties; nothing if it does not parse.
sub _read_vcard {
  my ($vcard_string) = @_;

  my $parsed = eval { vcard2hash($vcard_string, multival => [qw(n adr org)]) };
  return unless $parsed && $parsed->{objects} && @{$parsed->{objects}};

  my $vcard = $parsed->{objects}[0];
  return unless $vcard && $vcard->{type} eq 'vcard';

  my $props = $vcard->{properties};
  my $ctx = _seed_context(_new_context(), $props);

  my $card = {
    '@type' => 'Card',
    version => '2.0',
  };

  # UID: optional since JSContact 2.0 (RFC 9982), which forbids making one
  # up for a vCard that has none -- a protocol that needs a uid (CardDAV,
  # JMAP Contacts) assigns it itself
  _set_if($card, 'uid', _first_value($props, 'uid'));

  # Simple scalar properties
  _set_if($card, 'kind',     _first_value($props, 'kind')
                              // _first_value($props, 'x-addressbookserver-kind'),
                              sub { lc $_[0] });
  _set_if($card, 'prodId',   _first_value($props, 'prodid'));
  _set_if($card, 'updated',  _first_value($props, 'rev'), \&_to_utc_datetime);
  _set_if($card, 'created',  _first_value($props, 'created'), \&_to_utc_datetime);
  _set_if($card, 'language', _first_value($props, 'language'));

  # Complex properties
  _convert_name($card, $props);
  for my $conv (@MAP_CONVERTERS) {
    my ($key, $fn) = @$conv;
    $fn->($card, $props, $ctx);
    _claim_sources($ctx, $key);
  }
  _convert_keywords($card, $props);
  _convert_members($card, $props, $ctx);
  _convert_related($card, $props, $ctx);
  _convert_speak_to_as($card, $props, $ctx);
  _claim_sources($ctx, 'speakToAs');

  return ($card, $ctx, $props);
}

# The ids handed out since the last claim belong to $key
sub _claim_sources {
  my ($ctx, $key) = @_;
  for my $pair (@{$ctx->{pending} // []}) {
    my ($id, $item) = @$pair;
    push @{$ctx->{sources}{$key}{$id}}, $item;
  }
  $ctx->{pending} = [];
}

###############################################################################
# INDIVIDUAL VCARD -> JSCONTACT CONVERTERS
###############################################################################

# FN + N -> name
sub _convert_name {
  my ($card, $props) = @_;
  my $name = {};

  my $fn = _first_value($props, 'fn');
  $name->{full} = $fn if defined $fn;

  my $n_prop = _first_prop($props, 'n');
  if ($n_prop) {
    my $values = $n_prop->{values} || [];
    # N component order: surname, given, given2, title(prefix), credential(suffix), surname2, generation
    my @kind_map = qw(surname given given2 title credential surname2 generation);

    my @components;
    for my $idx (0..$#kind_map) {
      my $raw = $values->[$idx];
      next unless defined $raw;
      # Handle both arrayref and string; split comma-separated values
      my @vals;
      for my $v (ref $raw eq 'ARRAY' ? @$raw : ($raw)) {
        push @vals, split /,/, $v;
      }
      for my $v (@vals) {
        next unless defined $v && $v ne '';
        push @components, {
          '@type' => 'NameComponent',
          kind  => $kind_map[$idx],
          value => $v,
        };
      }
    }

    $name->{components} = \@components if @components;

    # SORT-AS parameter
    my $sort_as_param = _param($n_prop, 'sort-as');
    if ($sort_as_param) {
      my @sa = split /,/, $sort_as_param;
      my %sort_map;
      for my $i (0..$#sa) {
        $sort_map{$kind_map[$i]} = $sa[$i]
          if $i <= $#kind_map && defined $sa[$i] && $sa[$i] ne '';
      }
      $name->{sortAs} = \%sort_map if %sort_map;
    }
  }

  # Apple X-PHONETIC-*-NAME -> phonetic name components
  my $phonFirst = _first_value($props, 'x-phonetic-first-name');
  my $phonLast  = _first_value($props, 'x-phonetic-last-name');
  my $phonMid   = _first_value($props, 'x-phonetic-middle-name');
  if ($phonFirst || $phonLast || $phonMid) {
    my @phon;
    push @phon, { '@type' => 'NameComponent', kind => 'given',   value => $phonFirst, phonetic => 'ipa' } if $phonFirst;
    push @phon, { '@type' => 'NameComponent', kind => 'given2',  value => $phonMid,   phonetic => 'ipa' } if $phonMid;
    push @phon, { '@type' => 'NameComponent', kind => 'surname', value => $phonLast,  phonetic => 'ipa' } if $phonLast;
    $name->{phoneticComponents} = \@phon;
  }

  $card->{name} = $name if %$name;
}

# NICKNAME -> nicknames
sub _convert_nicknames {
  my ($card, $props, $ctx) = @_;
  my $items = $props->{nickname} || return;

  my %map;
  for my $item (@$items) {
    my $val = $item->{value};
    next unless defined $val && $val ne '';
    my $id = _prop_id($item, $ctx);
    my $obj = { '@type' => 'Nickname', name => $val };
    if (my $ctx = _make_contexts(_params_list($item, 'type'))) {
      $obj->{contexts} = $ctx;
    }
    if (my $pref = _make_pref($item)) { $obj->{pref} = $pref }
    $map{$id} = $obj;
  }

  $card->{nicknames} = \%map if %map;
}

# EMAIL -> emails
sub _convert_emails {
  my ($card, $props, $ctx) = @_;
  my $items = $props->{email} || return;
  my $labels = _collect_labels($props);

  my %map;
  for my $item (@$items) {
    my $val = $item->{value};
    next unless defined $val && $val ne '';
    my $id = _prop_id($item, $ctx);
    my $obj = { '@type' => 'EmailAddress', address => $val };
    if (my $ctx = _make_contexts(_params_list($item, 'type'))) {
      $obj->{contexts} = $ctx;
    }
    if (my $pref = _make_pref($item)) { $obj->{pref} = $pref }
    _apply_label($obj, $item, $labels);
    $map{$id} = $obj;
  }

  $card->{emails} = \%map if %map;
}

# TEL -> phones
sub _convert_phones {
  my ($card, $props, $ctx) = @_;
  my $items = $props->{tel} || return;
  my $labels = _collect_labels($props);

  my %tel_feature_map = (
    cell => 'mobile', voice => 'voice', fax => 'fax',
    video => 'video', pager => 'pager', text => 'text',
    textphone => 'textphone',
  );

  my %map;
  for my $item (@$items) {
    my $val = $item->{value};
    next unless defined $val && $val ne '';
    my $id = _prop_id($item, $ctx);
    my $obj = { '@type' => 'Phone', number => $val };

    my @types = _params_list($item, 'type');
    if (my $ctx = _make_contexts(@types)) {
      $obj->{contexts} = $ctx;
    }

    my %features;
    for my $t (@types) {
      my $feat = $tel_feature_map{lc $t};
      $features{$feat} = JSON::true if $feat;
    }
    $obj->{features} = \%features if %features;

    if (my $pref = _make_pref($item)) { $obj->{pref} = $pref }
    _apply_label($obj, $item, $labels);
    $map{$id} = $obj;
  }

  $card->{phones} = \%map if %map;
}

# ADR -> addresses (+ GEO, TZ by group association)
sub _convert_addresses {
  my ($card, $props, $ctx) = @_;
  my $items = $props->{adr} || return;
  my $labels = _collect_labels($props);

  # Collect grouped GEO/TZ for association with ADR
  my %geo_by_group;
  my %tz_by_group;
  for my $geo (@{$props->{geo} // []}) {
    $geo_by_group{$geo->{group}} = $geo->{value} if $geo->{group};
  }
  for my $tz (@{$props->{tz} // []}) {
    $tz_by_group{$tz->{group}} = $tz->{value} if $tz->{group};
  }

  my %map;
  for my $item (@$items) {
    my $id = _prop_id($item, $ctx);
    my $values = $item->{values} || [];
    my $obj = { '@type' => 'Address' };

    # Build components from ADR structured value
    # Indices: 0=POBox 1=Extended 2=Street 3=Locality 4=Region 5=PostCode 6=Country
    my @components;
    for my $v (_adr_values($values, 2)) {
      push @components, { '@type' => 'AddressComponent', kind => 'name', value => $v };
    }
    for my $v (_adr_values($values, 1)) {
      push @components, { '@type' => 'AddressComponent', kind => 'apartment', value => $v };
    }
    for my $v (_adr_values($values, 3)) {
      push @components, { '@type' => 'AddressComponent', kind => 'locality', value => $v };
    }
    for my $v (_adr_values($values, 4)) {
      push @components, { '@type' => 'AddressComponent', kind => 'region', value => $v };
    }
    for my $v (_adr_values($values, 5)) {
      push @components, { '@type' => 'AddressComponent', kind => 'postcode', value => $v };
    }
    for my $v (_adr_values($values, 6)) {
      push @components, { '@type' => 'AddressComponent', kind => 'country', value => $v };
    }
    $obj->{components} = \@components if @components;

    # Parameters
    my $label_param = _param($item, 'label');
    $obj->{full} = $label_param if defined $label_param;

    my $geo = _param($item, 'geo');
    $geo //= $geo_by_group{$item->{group}} if $item->{group};
    $obj->{coordinates} = $geo if defined $geo;

    my $tz = _param($item, 'tz');
    $tz //= $tz_by_group{$item->{group}} if $item->{group};
    $obj->{timeZone} = $tz if defined $tz;

    my $cc = _param($item, 'cc');
    # Apple X-ABADR grouped with ADR
    if (!$cc && $item->{group}) {
      for my $xabadr (@{$props->{'x-abadr'} // []}) {
        if (($xabadr->{group} // '') eq $item->{group}) {
          $cc = $xabadr->{value};
          last;
        }
      }
    }
    $obj->{countryCode} = $cc if defined $cc;

    my @types = _params_list($item, 'type');
    if (my $ctx = _make_contexts(@types)) {
      $obj->{contexts} = $ctx;
    }
    if (my $pref = _make_pref($item)) { $obj->{pref} = $pref }
    _apply_label($obj, $item, $labels);

    $map{$id} = $obj;
  }

  $card->{addresses} = \%map if %map;
}

# ORG -> organizations
sub _convert_organizations {
  my ($card, $props, $ctx) = @_;
  my $items = $props->{org} || return;

  my %map;
  for my $item (@$items) {
    my $id = _prop_id($item, $ctx);
    my $values = $item->{values} || [];
    my $obj = { '@type' => 'Organization' };

    # First component -> name
    my @name_vals = ref $values->[0] eq 'ARRAY' ? @{$values->[0]} : ($values->[0] // ());
    my $org_name = join(' ', grep { defined $_ && $_ ne '' } @name_vals);
    $obj->{name} = $org_name if $org_name ne '';

    # Subsequent components -> units
    my @units;
    for my $i (1..$#$values) {
      my @vals = ref $values->[$i] eq 'ARRAY' ? @{$values->[$i]} : ($values->[$i]);
      for my $v (@vals) {
        next unless defined $v && $v ne '';
        push @units, { '@type' => 'OrgUnit', name => $v };
      }
    }
    $obj->{units} = \@units if @units;

    # SORT-AS
    my $sort_as = _param($item, 'sort-as');
    if (defined $sort_as) {
      my @sa = split /,/, $sort_as;
      $obj->{sortAs} = $sa[0] if defined $sa[0] && $sa[0] ne '';
      for my $i (0..$#units) {
        $units[$i]{sortAs} = $sa[$i+1] if defined $sa[$i+1] && $sa[$i+1] ne '';
      }
    }

    my @types = _params_list($item, 'type');
    if (my $ctx = _make_contexts(@types)) {
      $obj->{contexts} = $ctx;
    }

    $map{$id} = $obj;
  }

  $card->{organizations} = \%map if %map;
}

# TITLE + ROLE -> titles
sub _convert_titles {
  my ($card, $props, $ctx) = @_;

  my %map;
  for my $spec (['title', 'title'], ['role', 'role']) {
    my ($propname, $kind) = @$spec;
    for my $item (@{$props->{$propname} // []}) {
      my $val = $item->{value};
      next unless defined $val && $val ne '';
      my $id = _prop_id($item, $ctx);
      $map{$id} = { '@type' => 'Title', kind => $kind, name => $val };
    }
  }

  $card->{titles} = \%map if %map;
}

# BDAY, ANNIVERSARY, DEATHDATE, X-ABDATE -> anniversaries
sub _convert_anniversaries {
  my ($card, $props, $ctx) = @_;
  my $labels = _collect_labels($props);

  my %map;
  for my $spec (['bday', 'birth'], ['anniversary', 'wedding'], ['deathdate', 'death']) {
    my ($propname, $kind) = @$spec;
    for my $item (@{$props->{$propname} // []}) {
      my $val = $item->{value};
      next unless defined $val && $val ne '';
      my $id = _prop_id($item, $ctx);
      $map{$id} = {
        '@type' => 'Anniversary',
        kind  => $kind,
        date  => _convert_vcard_date($val),
      };
    }
  }

  # Apple X-ABDATE + X-ABLabel -> anniversaries
  for my $item (@{$props->{'x-abdate'} // []}) {
    my $val = $item->{value};
    next unless defined $val && $val ne '';
    my $id = _prop_id($item, $ctx);

    my $kind = 'other';
    if (my $group = $item->{group}) {
      my $label = $labels->{$group};
      if ($label) {
        my $lt = lc $label;
        if ($lt eq 'anniversary') { $kind = 'wedding' }
        elsif ($lt eq 'other') { $kind = 'other' }
        else { $kind = $lt }
      }
    }

    $map{$id} = {
      '@type' => 'Anniversary',
      kind  => $kind,
      date  => _convert_vcard_date($val),
    };
  }

  $card->{anniversaries} = \%map if %map;
}

# NOTE -> notes
sub _convert_notes {
  my ($card, $props, $ctx) = @_;
  my $items = $props->{note} || return;

  my %map;
  for my $item (@$items) {
    my $val = $item->{value};
    next unless defined $val && $val ne '';
    my $id = _prop_id($item, $ctx);
    my $obj = { '@type' => 'Note', note => $val };

    my $created = _param($item, 'created');
    $obj->{created} = _to_utc_datetime($created) if defined $created;

    my $author_name = _param($item, 'author-name');
    my $author_uri  = _param($item, 'author');
    if ($author_name || $author_uri) {
      my $author = {};
      $author->{name} = $author_name if $author_name;
      $author->{uri}  = $author_uri  if $author_uri;
      $obj->{author} = $author;
    }

    $map{$id} = $obj;
  }

  $card->{notes} = \%map if %map;
}

# IMPP, SOCIALPROFILE, X-SOCIALPROFILE -> onlineServices
sub _convert_online_services {
  my ($card, $props, $ctx) = @_;
  my $labels = _collect_labels($props);

  my %map;

  for my $item (@{$props->{impp} // []}) {
    my $val = $item->{value};
    next unless defined $val && $val ne '';
    my $id = _prop_id($item, $ctx);
    my $obj = { '@type' => 'OnlineService' };
    # RFC 9554 SERVICE-TYPE and USERNAME, as _unconvert_online_services
    # writes them, or the older x- forms
    my $service = _param($item, 'service-type') // _param($item, 'x-service-type');
    $obj->{service} = $service if defined $service;
    my $user = _param($item, 'username') // _param($item, 'x-user');
    $obj->{user} = $user if defined $user;
    # a service with only a user name is written with that name as the value
    $obj->{uri} = $val unless defined $user && $val eq $user && $val !~ /^[a-z][a-z0-9+.-]*:/i;
    my @types = _params_list($item, 'type');
    if (my $ctx = _make_contexts(@types)) { $obj->{contexts} = $ctx }
    if (my $pref = _make_pref($item)) { $obj->{pref} = $pref }
    _apply_label($obj, $item, $labels);
    $map{$id} = $obj;
  }

  for my $propname (qw(socialprofile x-socialprofile)) {
    for my $item (@{$props->{$propname} // []}) {
      my $val = $item->{value};
      next unless defined $val && $val ne '';
      my $id = _prop_id($item, $ctx);
      my $obj = { '@type' => 'OnlineService' };

      if ($val =~ m{://}) { $obj->{uri} = $val }
      else                { $obj->{user} = $val }

      my $service = _param($item, 'service-type') // _param($item, 'x-service-type');
      unless ($service) {
        for my $t (_params_list($item, 'type')) {
          my $lt = lc $t;
          if ($lt ne 'home' && $lt ne 'work' && $lt ne 'pref') {
            $service = $lt;
            last;
          }
        }
      }
      $obj->{service} = $service if defined $service;

      my $user = _param($item, 'x-user') // _param($item, 'username');
      $obj->{user} = $user if defined $user && !$obj->{user};

      my @types = _params_list($item, 'type');
      if (my $ctx = _make_contexts(@types)) { $obj->{contexts} = $ctx }
      if (my $pref = _make_pref($item)) { $obj->{pref} = $pref }
      _apply_label($obj, $item, $labels);
      $map{$id} = $obj;
    }
  }

  # Legacy X-service IM properties (Apple/others)
  my %xservice_map = (
    'x-aim'     => 'AIM',
    'x-icq'     => 'ICQ',
    'x-msn'     => 'MSN',
    'x-yahoo'   => 'Yahoo',
    'x-jabber'  => 'Jabber',
    'x-skype'   => 'Skype',
    'x-skype-username' => 'Skype',
    'x-twitter' => 'Twitter',
    'x-google-talk' => 'GoogleTalk',
  );
  for my $propname (sort keys %xservice_map) {
    for my $item (@{$props->{$propname} // []}) {
      my $val = $item->{value};
      next unless defined $val && $val ne '';
      my $id = _prop_id($item, $ctx);
      my $obj = { '@type' => 'OnlineService', user => $val, service => $xservice_map{$propname} };
      my @types = _params_list($item, 'type');
      if (my $ctx = _make_contexts(@types)) { $obj->{contexts} = $ctx }
      if (my $pref = _make_pref($item)) { $obj->{pref} = $pref }
      _apply_label($obj, $item, $labels);
      $map{$id} = $obj;
    }
  }

  $card->{onlineServices} = \%map if %map;
}

# PHOTO, LOGO, SOUND -> media
sub _convert_media {
  my ($card, $props, $ctx) = @_;
  my $labels = _collect_labels($props);

  my %map;
  for my $spec (['photo', 'photo'], ['logo', 'logo'], ['sound', 'sound']) {
    my ($propname, $kind) = @$spec;
    for my $item (@{$props->{$propname} // []}) {
      my $val = $item->{value};
      next unless defined $val && $val ne '';
      my $id = _prop_id($item, $ctx);
      my $obj = { '@type' => 'Media', kind => $kind };

      my $encoding = _param($item, 'encoding');
      if ($encoding && lc($encoding) eq 'b') {
        # vCard 3 inline data (RFC 2426 S3.1.4): TYPE is the format,
        # e.g. TYPE=PNG; media types are case-insensitive, lower-case
        # them as RFC 2045 writes them
        my $mediatype = _param($item, 'mediatype') // _param($item, 'type');
        # TYPE is a list (RFC 2426 S3.1.4 allows one format, but servers
        # merge: Cyrus writes TYPE=PNG,PNG for a vCard 4 PHOTO that had both
        # a MEDIATYPE and a data: URI); the format is its first value
        ($mediatype) = grep { length } split /\s*,\s*/, $mediatype if defined $mediatype;
        $mediatype = ($kind eq 'sound' ? 'audio/' : 'image/') . $mediatype
          if $mediatype && $mediatype !~ m{/};
        $mediatype = lc($mediatype // 'application/octet-stream');
        # the value is the base64 text already: Text::VCardFast does
        # not decode it
        (my $b64 = $val) =~ s/\s+//g;
        $obj->{uri}       = "data:$mediatype;base64,$b64";
        $obj->{mediaType} = $mediatype;
      } else {
        $obj->{uri} = $val;
        my $mt = _param($item, 'mediatype');
        $obj->{mediaType} = $mt if defined $mt;
      }

      if (my $pref = _make_pref($item)) { $obj->{pref} = $pref }
      _apply_label($obj, $item, $labels);
      $map{$id} = $obj;
    }
  }

  $card->{media} = \%map if %map;
}

# Generic resource converter for URI-based properties
sub _convert_resource_to {
  my ($card, $key, $props, $propname, $kind, $ctx, $type) = @_;
  my $labels = _collect_labels($props);

  my %map;
  for my $item (@{$props->{$propname} // []}) {
    my $val = $item->{value};
    next unless defined $val && $val ne '';
    my $id = _prop_id($item, $ctx);
    my $obj = { '@type' => $type, uri => $val };
    $obj->{kind} = $kind if defined $kind;
    my $mt = _param($item, 'mediatype');
    $obj->{mediaType} = $mt if defined $mt;
    my @types = _params_list($item, 'type');
    if (my $ctx = _make_contexts(@types)) { $obj->{contexts} = $ctx }
    if (my $pref = _make_pref($item)) { $obj->{pref} = $pref }
    _apply_label($obj, $item, $labels);
    $map{$id} = $obj;
  }

  if (%map) {
    $card->{$key} = { %{$card->{$key} // {}}, %map };
  }
}

# URL, FBURL, CONTACT-URI -> links
sub _convert_links {
  my ($card, $props, $ctx) = @_;
  _convert_resource_to($card, 'links', $props, 'url',         undef,     $ctx, 'Link');
  _convert_resource_to($card, 'links', $props, 'fburl',       'freeBusy', $ctx, 'Link');
  _convert_resource_to($card, 'links', $props, 'contact-uri', 'contact', $ctx, 'Link');
}

# CALURI -> calendars
sub _convert_calendars {
  my ($card, $props, $ctx) = @_;
  _convert_resource_to($card, 'calendars', $props, 'caluri', undef, $ctx, 'Calendar');
}

# CALADRURI -> schedulingAddresses
sub _convert_scheduling_addresses {
  my ($card, $props, $ctx) = @_;
  _convert_resource_to($card, 'schedulingAddresses', $props, 'caladruri', undef, $ctx, 'SchedulingAddress');
}

# KEY -> cryptoKeys
sub _convert_crypto_keys {
  my ($card, $props, $ctx) = @_;
  _convert_resource_to($card, 'cryptoKeys', $props, 'key', undef, $ctx, 'CryptoKey');
}

# SOURCE, ORG-DIRECTORY -> directories
sub _convert_directories {
  my ($card, $props, $ctx) = @_;
  _convert_resource_to($card, 'directories', $props, 'source',        'entry',     $ctx, 'Directory');
  _convert_resource_to($card, 'directories', $props, 'org-directory', 'directory', $ctx, 'Directory');
}

# LANG -> preferredLanguages
sub _convert_preferred_languages {
  my ($card, $props, $ctx) = @_;
  my $items = $props->{lang} || return;

  my %map;
  for my $item (@$items) {
    my $val = $item->{value};
    next unless defined $val && $val ne '';
    my $id = _prop_id($item, $ctx);
    my $obj = { '@type' => 'LanguagePref', language => $val };
    my @types = _params_list($item, 'type');
    if (my $ctx = _make_contexts(@types)) { $obj->{contexts} = $ctx }
    if (my $pref = _make_pref($item)) { $obj->{pref} = $pref }
    $map{$id} = $obj;
  }

  $card->{preferredLanguages} = \%map if %map;
}

# EXPERTISE, HOBBY, INTEREST -> personalInfo
sub _convert_personal_info {
  my ($card, $props, $ctx) = @_;

  my %level_map = (beginner => 'low', average => 'medium', expert => 'high');
  my %map;

  for my $spec (['expertise', 'expertise'], ['hobby', 'hobby'], ['interest', 'interest']) {
    my ($propname, $kind) = @$spec;
    for my $item (@{$props->{$propname} // []}) {
      my $val = $item->{value};
      next unless defined $val && $val ne '';
      my $id = _prop_id($item, $ctx);
      my $obj = { '@type' => 'PersonalInfo', kind => $kind, value => $val };

      my $level = _param($item, 'level');
      if ($level) {
        $obj->{level} = $level_map{lc $level} // lc $level;
      }

      my $index = _param($item, 'index');
      $obj->{listAs} = $index + 0 if defined $index;

      $map{$id} = $obj;
    }
  }

  $card->{personalInfo} = \%map if %map;
}

# CATEGORIES -> keywords
sub _convert_keywords {
  my ($card, $props) = @_;
  my $items = $props->{categories} || return;

  my %keywords;
  for my $item (@$items) {
    my $val = $item->{value};
    next unless defined $val;
    for my $cat (split /,/, $val) {
      $cat =~ s/^\s+//;
      $cat =~ s/\s+$//;
      $keywords{$cat} = JSON::true if $cat ne '';
    }
  }

  $card->{keywords} = \%keywords if %keywords;
}

# MEMBER / X-ADDRESSBOOKSERVER-MEMBER -> members
sub _convert_members {
  my ($card, $props, $ctx) = @_;

  my %members;
  for my $propname (qw(member x-addressbookserver-member)) {
    for my $item (@{$props->{$propname} // []}) {
      my $val = $item->{value};
      next unless defined $val && $val ne '';
      $members{$val} = JSON::true;
      push @{$ctx->{sources}{members}{$val}}, $item if $ctx;
    }
  }

  $card->{members} = \%members if %members;
}

# RELATED / X-ABRELATEDNAMES -> relatedTo
sub _convert_related {
  my ($card, $props, $ctx) = @_;
  my $labels = _collect_labels($props);

  my %related;

  # Standard RELATED property
  for my $item (@{$props->{related} // []}) {
    my $val = $item->{value};
    next unless defined $val && $val ne '';

    my $rel = { '@type' => 'Relation' };
    my %relation;
    for my $t (_params_list($item, 'type')) {
      my $lt = lc $t;
      $relation{$lt} = JSON::true
        if $lt =~ /^(acquaintance|agent|child|co-resident|co-worker|colleague|contact|crush|date|emergency|friend|kin|me|met|muse|neighbor|parent|sibling|spouse|sweetheart)$/;
    }
    $rel->{relation} = \%relation if %relation;
    $related{$val} = $rel;
    push @{$ctx->{sources}{relatedTo}{$val}}, $item if $ctx;
  }

  # Apple X-ABRELATEDNAMES + X-ABLabel -> relatedTo
  my %ablabel_relation = (
    'mother' => 'parent', 'father' => 'parent', 'parent' => 'parent',
    'brother' => 'sibling', 'sister' => 'sibling',
    'child' => 'child',
    'friend' => 'friend',
    'spouse' => 'spouse', 'partner' => 'spouse',
    'assistant' => 'colleague', 'manager' => 'colleague',
  );
  for my $item (@{$props->{'x-abrelatednames'} // []}) {
    my $val = $item->{value};
    next unless defined $val && $val ne '';

    my $rel = { '@type' => 'Relation' };
    my %relation;

    # Get relation type from X-ABLabel
    my $label;
    if (my $group = $item->{group}) {
      $label = $labels->{$group};
    }
    if ($label) {
      my $lt = lc $label;
      if (my $mapped = $ablabel_relation{$lt}) {
        $relation{$mapped} = JSON::true;
      }
    }
    $rel->{relation} = \%relation if %relation;
    $related{$val} = $rel;
    push @{$ctx->{sources}{relatedTo}{$val}}, $item if $ctx;
  }

  $card->{relatedTo} = \%related if %related;
}

# GRAMGENDER, PRONOUNS (RFC 9554) -> speakToAs
sub _convert_speak_to_as {
  my ($card, $props, $ctx) = @_;

  my $speak = {};

  if (my $gg = _first_value($props, 'gramgender')) {
    $speak->{grammaticalGender} = lc $gg;
  }

  if (my $items = $props->{pronouns}) {
    my %pronouns;
    for my $item (@$items) {
      my $val = $item->{value};
      next unless defined $val && $val ne '';
      my $id = _prop_id($item, $ctx);
      my $obj = { '@type' => 'Pronouns', pronouns => $val };
      if (my $ctx = _make_contexts(_params_list($item, 'type'))) {
        $obj->{contexts} = $ctx;
      }
      if (my $pref = _make_pref($item)) { $obj->{pref} = $pref }
      $pronouns{$id} = $obj;
    }
    $speak->{pronouns} = \%pronouns if %pronouns;
  }

  $card->{speakToAs} = $speak if %$speak;
}

###############################################################################
# JSCONTACT -> VCARD
###############################################################################

# jscontact_to_vcard($card) writes the Card as a new vCard 4.0.
#
# jscontact_to_vcard($card, original => $vcard) writes it as a patch of
# $vcard, the vCard the Card is an edit of (as fetched from the server,
# bytes or characters): the Card is compared with what $vcard itself
# reads as, and only the entries that differ are rewritten, so whatever
# else $vcard holds is kept (see patch_vcard).  The caller need not keep
# the Card it first read, and may have changed anything in it.  If
# $vcard cannot be parsed, the Card is written as a new vCard instead.
#
# Either way the result is a character string.
sub jscontact_to_vcard {
  my ($card, %opts) = @_;

  if (defined $opts{original}) {
    my $patched = _patch_vcard($opts{original}, $card);
    return $patched if defined $patched;
  }

  my $ctx = _new_context();
  my @props;

  # VERSION (always 4.0)
  push @props, { name => 'version', value => '4.0' };

  # UID
  push @props, { name => 'uid', value => $card->{uid} } if $card->{uid};

  # KIND
  push @props, { name => 'kind', value => $card->{kind} }
    if $card->{kind} && $card->{kind} ne 'individual';

  # PRODID
  push @props, { name => 'prodid', value => $card->{prodId} } if $card->{prodId};

  # REV
  push @props, { name => 'rev', value => $card->{updated} } if $card->{updated};

  # CREATED (RFC 9554)
  push @props, { name => 'created', value => $card->{created} } if $card->{created};

  # LANGUAGE (RFC 9554)
  push @props, { name => 'language', value => $card->{language} } if $card->{language};

  # Name -> N + FN
  _unconvert_name(\@props, $card, $ctx);

  # All map-based properties
  _unconvert_nicknames(\@props, $card, $ctx);
  _unconvert_emails(\@props, $card, $ctx);
  _unconvert_phones(\@props, $card, $ctx);
  _unconvert_addresses(\@props, $card, $ctx);
  _unconvert_organizations(\@props, $card, $ctx);
  _unconvert_titles(\@props, $card, $ctx);
  _unconvert_anniversaries(\@props, $card, $ctx);
  _unconvert_notes(\@props, $card, $ctx);
  _unconvert_online_services(\@props, $card, $ctx);
  _unconvert_media(\@props, $card, $ctx);
  _unconvert_links(\@props, $card, $ctx);
  _unconvert_calendars(\@props, $card, $ctx);
  _unconvert_scheduling_addresses(\@props, $card, $ctx);
  _unconvert_crypto_keys(\@props, $card, $ctx);
  _unconvert_directories(\@props, $card, $ctx);
  _unconvert_preferred_languages(\@props, $card, $ctx);
  _unconvert_personal_info(\@props, $card, $ctx);
  _unconvert_keywords(\@props, $card, $ctx);
  _unconvert_members(\@props, $card, $ctx);
  _unconvert_related(\@props, $card, $ctx);
  _unconvert_speak_to_as(\@props, $card, $ctx);

  return _write_vcard(\@props);
}

###############################################################################
# INDIVIDUAL JSCONTACT -> VCARD CONVERTERS
###############################################################################

sub _contexts_to_types {
  my $contexts = shift;
  return () unless $contexts && ref $contexts eq 'HASH';
  my @types;
  push @types, 'home'  if $contexts->{private};
  push @types, 'work' if $contexts->{work};
  return @types;
}

sub _add_pref_params {
  my ($params, $pref) = @_;
  $params->{pref} = [$pref] if defined $pref;
}

sub _add_label {
  my ($out, $prop, $obj, $ctx) = @_;
  return if $ctx->{no_labels};
  my $label = $obj->{label};
  return unless defined $label && $label ne '';

  my $group = _alloc_group($ctx);
  $prop->{group} = $group;
  push @$out, {
    name   => 'x-ablabel',
    value  => $label,
    params => {},
    group  => $group,
  };
}

sub _add_context_params {
  my ($params, $obj) = @_;
  if ($obj->{contexts}) {
    my @types = _contexts_to_types($obj->{contexts});
    push @{$params->{type}}, @types if @types;
  }
}

sub _unconvert_name {
  my ($out, $card, $ctx) = @_;
  my $name = $card->{name} || return;

  # FN
  if (my $full = $name->{full}) {
    push @$out, { name => 'fn', value => $full, params => {} };
  }

  # N from components
  if (my $components = $name->{components}) {
    my %by_kind;
    for my $c (@$components) {
      push @{$by_kind{$c->{kind}}}, $c->{value};
    }

    # N order: surname, given, given2(additional), title(prefix), credential(suffix), surname2, generation
    my @n_values;
    for my $kind (qw(surname given given2 title credential surname2 generation)) {
      my $vals = $by_kind{$kind};
      # several values of one kind are a list (RFC 6350 S6.2.2)
      push @n_values, $vals ? [ grep { defined $_ } @$vals ] : '';
    }

    # Trim trailing empty components
    pop @n_values while @n_values && !ref $n_values[-1] && $n_values[-1] eq '';

    my $params = {};
    if ($name->{sortAs} && ref $name->{sortAs} eq 'HASH') {
      my @sa;
      for my $kind (qw(surname given given2 title credential surname2 generation)) {
        push @sa, $name->{sortAs}{$kind} // '';
      }
      pop @sa while @sa && $sa[-1] eq '';
      $params->{'sort-as'} = [join(',', @sa)] if @sa;
    }

    push @$out, { name => 'n', values => \@n_values, params => $params };
  }

  # Generate FN from components if no full name given
  if (!$name->{full} && $name->{components}) {
    my @parts;
    for my $c (@{$name->{components}}) {
      next if ($c->{kind} // '') eq 'separator';
      push @parts, $c->{value};
    }
    push @$out, { name => 'fn', value => join(' ', @parts), params => {} } if @parts;
  }
}

sub _unconvert_nicknames {
  my ($out, $card, $ctx) = @_;
  my $nicknames = $card->{nicknames} || return;

  for my $id (sort keys %$nicknames) {
    my $nn = $nicknames->{$id};
    my $params = { 'prop-id' => [$id] };
    _add_context_params($params, $nn);
    _add_pref_params($params, $nn->{pref});
    push @$out, { name => 'nickname', value => $nn->{name}, params => $params };
  }
}

sub _unconvert_emails {
  my ($out, $card, $ctx) = @_;
  my $emails = $card->{emails} || return;

  for my $id (sort keys %$emails) {
    my $em = $emails->{$id};
    my $params = { 'prop-id' => [$id] };
    _add_context_params($params, $em);
    _add_pref_params($params, $em->{pref});
    my $prop = { name => 'email', value => $em->{address}, params => $params };
    _add_label($out, $prop, $em, $ctx);
    push @$out, $prop;
  }
}

sub _unconvert_phones {
  my ($out, $card, $ctx) = @_;
  my $phones = $card->{phones} || return;

  my %feature_to_type = (
    mobile => 'cell', voice => 'voice', fax => 'fax',
    video => 'video', pager => 'pager', text => 'text',
    textphone => 'textphone',
  );

  for my $id (sort keys %$phones) {
    my $ph = $phones->{$id};
    my $params = { 'prop-id' => [$id] };
    _add_context_params($params, $ph);
    _add_pref_params($params, $ph->{pref});

    if ($ph->{features}) {
      for my $feat (sort keys %{$ph->{features}}) {
        my $type = $feature_to_type{$feat};
        push @{$params->{type}}, $type if $type;
      }
    }

    # TEL is TEXT unless it says it is a URI (RFC 6350 S6.4.1); a URI
    # escaped as TEXT is no longer the URI
    $params->{value} = ['uri'] if _looks_like_uri($ph->{number});

    my $prop = { name => 'tel', value => $ph->{number}, params => $params };
    _add_label($out, $prop, $ph, $ctx);
    push @$out, $prop;
  }
}

sub _unconvert_addresses {
  my ($out, $card, $ctx) = @_;
  my $addresses = $card->{addresses} || return;

  my %kind_to_idx = (
    name => 2, apartment => 1,
    locality => 3, region => 4, postcode => 5, country => 6,
  );

  for my $id (sort keys %$addresses) {
    my $adr = $addresses->{$id};
    my $params = { 'prop-id' => [$id] };
    _add_context_params($params, $adr);
    _add_pref_params($params, $adr->{pref});

    $params->{label} = [$adr->{full}]        if $adr->{full};
    $params->{geo}   = [$adr->{coordinates}] if $adr->{coordinates};
    $params->{tz}    = [$adr->{timeZone}]    if $adr->{timeZone};
    $params->{cc}    = [$adr->{countryCode}] if $adr->{countryCode};

    # Build ADR values (7 standard components)
    my @values = ('') x 7;

    if (my $components = $adr->{components}) {
      my %by_idx;
      for my $c (@$components) {
        next if ($c->{kind} // '') eq 'separator';
        my $idx = $kind_to_idx{$c->{kind}};
        push @{$by_idx{$idx}}, $c->{value} if defined $idx;
      }
      # several values of one component are a list (RFC 6350 S6.3.1)
      for my $idx (keys %by_idx) {
        $values[$idx] = $by_idx{$idx};
      }
    }

    push @$out, { name => 'adr', values => \@values, params => $params };
  }
}

sub _unconvert_organizations {
  my ($out, $card, $ctx) = @_;
  my $orgs = $card->{organizations} || return;

  for my $id (sort keys %$orgs) {
    my $org = $orgs->{$id};
    my $params = { 'prop-id' => [$id] };
    _add_context_params($params, $org);

    my @values = ($org->{name} // '');
    if ($org->{units}) {
      for my $unit (@{$org->{units}}) {
        push @values, $unit->{name};
      }
    }

    if (defined $org->{sortAs}) {
      my @sa = ($org->{sortAs});
      if ($org->{units}) {
        for my $unit (@{$org->{units}}) {
          push @sa, $unit->{sortAs} // '';
        }
      }
      pop @sa while @sa && $sa[-1] eq '';
      $params->{'sort-as'} = [join(',', @sa)] if @sa;
    }

    push @$out, { name => 'org', values => \@values, params => $params };
  }
}

sub _unconvert_titles {
  my ($out, $card, $ctx) = @_;
  my $titles = $card->{titles} || return;

  for my $id (sort keys %$titles) {
    my $t = $titles->{$id};
    my $propname = ($t->{kind} // 'title') eq 'role' ? 'role' : 'title';
    my $params = { 'prop-id' => [$id] };
    push @$out, { name => $propname, value => $t->{name}, params => $params };
  }
}

sub _unconvert_anniversaries {
  my ($out, $card, $ctx) = @_;
  my $anns = $card->{anniversaries} || return;

  my %kind_to_prop = (birth => 'bday', wedding => 'anniversary', death => 'deathdate');

  for my $id (sort keys %$anns) {
    my $ann = $anns->{$id};
    my $kind = $ann->{kind} // '';
    my $propname = $kind_to_prop{$kind} // 'anniversary';
    my $params = { 'prop-id' => [$id] };

    my $date = $ann->{date} // '';
    # Convert unknown-year dates to vCard 4 format
    $date = "--$1$2" if $date =~ /^0000-(\d{2})-(\d{2})/;

    push @$out, { name => $propname, value => $date, params => $params };
  }
}

sub _unconvert_notes {
  my ($out, $card, $ctx) = @_;
  my $notes = $card->{notes} || return;

  for my $id (sort keys %$notes) {
    my $note = $notes->{$id};
    my $params = { 'prop-id' => [$id] };

    if ($note->{created}) {
      $params->{created} = [$note->{created}];
    }
    if ($note->{author}) {
      $params->{'author-name'} = [$note->{author}{name}] if $note->{author}{name};
      $params->{author}        = [$note->{author}{uri}]   if $note->{author}{uri};
    }

    push @$out, { name => 'note', value => $note->{note}, params => $params };
  }
}

sub _unconvert_online_services {
  my ($out, $card, $ctx) = @_;
  my $services = $card->{onlineServices} || return;

  for my $id (sort keys %$services) {
    my $svc = $services->{$id};
    my $params = { 'prop-id' => [$id] };
    _add_context_params($params, $svc);
    _add_pref_params($params, $svc->{pref});

    $params->{'service-type'} = [$svc->{service}] if $svc->{service};
    $params->{username}       = [$svc->{user}]    if $svc->{user};

    my $uri = $svc->{uri} // $svc->{user} // '';
    push @$out, { name => 'impp', value => $uri, params => $params };
  }
}

sub _unconvert_media {
  my ($out, $card, $ctx) = @_;
  my $media = $card->{media} || return;

  my %kind_to_prop = (photo => 'photo', logo => 'logo', sound => 'sound');

  for my $id (sort keys %$media) {
    my $m = $media->{$id};
    # A Media given only by blobId: the caller resolves the blob to a
    # data: URI first; this module fetches nothing, and an empty PHOTO
    # is no picture at all.
    next unless defined $m->{uri} && $m->{uri} ne '';
    my $propname = $kind_to_prop{$m->{kind} // 'photo'} // 'photo';
    my $params = { 'prop-id' => [$id] };
    _add_pref_params($params, $m->{pref});
    $params->{mediatype} = [$m->{mediaType}] if $m->{mediaType};
    push @$out, { name => $propname, value => $m->{uri}, params => $params };
  }
}

sub _unconvert_links {
  my ($out, $card, $ctx) = @_;
  my $links = $card->{links} || return;

  for my $id (sort keys %$links) {
    my $link = $links->{$id};
    my $kind = $link->{kind} // '';
    my $propname = $kind eq 'freeBusy' ? 'fburl'
                 : $kind eq 'contact'  ? 'contact-uri'
                 : 'url';
    my $params = { 'prop-id' => [$id] };
    _add_context_params($params, $link);
    _add_pref_params($params, $link->{pref});
    $params->{mediatype} = [$link->{mediaType}] if $link->{mediaType};
    push @$out, { name => $propname, value => $link->{uri}, params => $params };
  }
}

sub _unconvert_resource {
  my ($out, $ctx, $card, $key, $propname) = @_;
  my $resources = $card->{$key} || return;

  for my $id (sort keys %$resources) {
    my $r = $resources->{$id};
    my $params = { 'prop-id' => [$id] };
    _add_context_params($params, $r);
    _add_pref_params($params, $r->{pref});
    $params->{mediatype} = [$r->{mediaType}] if $r->{mediaType};
    push @$out, { name => $propname, value => $r->{uri}, params => $params };
  }
}

sub _unconvert_calendars {
  _unconvert_resource($_[0], $_[2], $_[1], 'calendars', 'caluri');
}

sub _unconvert_scheduling_addresses {
  _unconvert_resource($_[0], $_[2], $_[1], 'schedulingAddresses', 'caladruri');
}

sub _unconvert_crypto_keys {
  _unconvert_resource($_[0], $_[2], $_[1], 'cryptoKeys', 'key');
}

sub _unconvert_directories {
  my ($out, $card, $ctx) = @_;
  my $dirs = $card->{directories} || return;

  for my $id (sort keys %$dirs) {
    my $dir = $dirs->{$id};
    my $kind = $dir->{kind} // '';
    my $propname = $kind eq 'entry' ? 'source' : 'org-directory';
    my $params = { 'prop-id' => [$id] };
    _add_context_params($params, $dir);
    _add_pref_params($params, $dir->{pref});
    $params->{mediatype} = [$dir->{mediaType}] if $dir->{mediaType};
    push @$out, { name => $propname, value => $dir->{uri}, params => $params };
  }
}

sub _unconvert_preferred_languages {
  my ($out, $card, $ctx) = @_;
  my $langs = $card->{preferredLanguages} || return;

  for my $id (sort keys %$langs) {
    my $lp = $langs->{$id};
    my $params = { 'prop-id' => [$id] };
    _add_context_params($params, $lp);
    _add_pref_params($params, $lp->{pref});
    push @$out, { name => 'lang', value => $lp->{language}, params => $params };
  }
}

sub _unconvert_personal_info {
  my ($out, $card, $ctx) = @_;
  my $info = $card->{personalInfo} || return;

  my %level_map = (low => 'beginner', medium => 'average', high => 'expert');

  for my $id (sort keys %$info) {
    my $pi = $info->{$id};
    my $propname = $pi->{kind} // 'expertise';
    my $params = { 'prop-id' => [$id] };
    if ($pi->{level}) {
      $params->{level} = [$level_map{$pi->{level}} // $pi->{level}];
    }
    if (defined $pi->{listAs}) {
      $params->{index} = [$pi->{listAs}];
    }
    push @$out, { name => $propname, value => $pi->{value}, params => $params };
  }
}

sub _unconvert_keywords {
  my ($out, $card, $ctx) = @_;
  my $keywords = $card->{keywords} || return;
  return unless ref $keywords eq 'HASH' && %$keywords;
  # a list: one value, comma-separated (RFC 6350 S6.7.1)
  push @$out, { name => 'categories', values => [[ sort keys %$keywords ]], params => {} };
}

sub _unconvert_members {
  my ($out, $card, $ctx) = @_;
  my $members = $card->{members} || return;
  for my $uid (sort keys %$members) {
    push @$out, { name => 'member', value => $uid, params => {} };
  }
}

sub _unconvert_members_apple {
  my ($out, $card, $ctx) = @_;
  my $members = $card->{members} || return;
  for my $uid (sort keys %$members) {
    # Apple uses urn:uuid: prefix for member UIDs
    my $val = $uid;
    $val = "urn:uuid:$val" unless $val =~ /^urn:uuid:/;
    push @$out, { name => 'x-addressbookserver-member', value => $val, params => {} };
  }
}

sub _unconvert_related {
  my ($out, $card, $ctx) = @_;
  my $related = $card->{relatedTo} || return;

  for my $uid (sort keys %$related) {
    my $rel = $related->{$uid};
    my $params = {};
    if ($rel->{relation} && ref $rel->{relation} eq 'HASH') {
      my @types = sort keys %{$rel->{relation}};
      $params->{type} = \@types if @types;
    }
    # RELATED is a URI unless VALUE=text says otherwise (RFC 6350 S6.6.6)
    $params->{value} = ['text'] unless _looks_like_uri($uid);
    push @$out, { name => 'related', value => $uid, params => $params };
  }
}

sub _unconvert_speak_to_as {
  my ($out, $card, $ctx) = @_;
  my $sta = $card->{speakToAs} || return;

  if ($sta->{grammaticalGender}) {
    push @$out, { name => 'gramgender', value => $sta->{grammaticalGender}, params => {} };
  }

  if ($sta->{pronouns}) {
    for my $id (sort keys %{$sta->{pronouns}}) {
      my $p = $sta->{pronouns}{$id};
      my $params = { 'prop-id' => [$id] };
      _add_context_params($params, $p);
      _add_pref_params($params, $p->{pref});
      push @$out, { name => 'pronouns', value => $p->{pronouns}, params => $params };
    }
  }
}

###############################################################################
# PATCH: Apply JSContact changes to an existing vCard with minimal disruption
###############################################################################

# top-level Card property => the sub that patches it (filled in below)
my %PATCHERS;

# patch_vcard($original, $old_card, $new_card) applies the change from
# $old_card to $new_card to the original vCard, line by line: a line for
# an entry the change does not touch keeps its bytes, its group, its
# folding and its place, and so does every line JSContact cannot say
# anything about.  Returns $original itself when nothing changed; else
# the patched vCard, as bytes if $original was bytes (as read from a
# CardDAV server) and as characters if it was characters.  An original
# that cannot be parsed gives the whole Card written afresh.
sub patch_vcard {
  my ($original_vcard, $old_card, $new_card) = @_;

  # Determine which top-level JSContact properties changed
  my %changed = _diff_cards($old_card, $new_card);
  return $original_vcard unless %changed;

  my $out = _patch_vcard($original_vcard, $new_card, \%changed)
         // jscontact_to_vcard($new_card);
  return utf8::is_utf8($original_vcard) ? $out : encode_utf8($out);
}

# The engine behind patch_vcard and jscontact_to_vcard(original => ...).
# Reads $original (bytes or characters) itself, so the Card it diffs
# against is exactly what the original says, with the vCard properties
# each entry came from.  $only limits the patch to those top-level Card
# properties.  Returns characters, or undef if the original cannot be
# patched (it does not parse, or its lines cannot be matched to what
# Text::VCardFast parsed).
sub _patch_vcard {
  my ($original, $new_card, $only) = @_;

  my $text = _decode_input($original);
  my ($old_card, $ctx, $props) = _read_vcard($text);
  return undef unless $old_card;

  my $P = _split_vcard($text, $props) or return undef;
  $P->{ctx}   = $ctx;
  $P->{props} = $props;
  # vCard 3 (RFC 2426) or 2.1: lines patched in must be valid there
  $P->{v3}    = ((_first_value($props, 'version') // '4.0') =~ /^[23]\./) ? 1 : 0;

  my %changed = $only ? %$only : _diff_cards($old_card, $new_card);
  for my $key (sort keys %changed) {
    my $patcher = $PATCHERS{$key} or next;
    $patcher->($P, $key, $old_card, $new_card);
  }
  _drop_orphan_groups($P);

  return join '', map {
    (@{$_->{before} // []}, ($_->{deleted} ? () : $_->{raw}), @{$_->{after} // []})
  } @{$P->{lines}};
}

# --- The original, as lines ----------------------------------------------

# Split a vCard into content lines, each keeping its raw text (folding and
# line ending included), and match each property line of the first vCard
# to the property Text::VCardFast parsed from it
sub _split_vcard {
  my ($text, $props) = @_;
  return undef unless $text =~ /\n/;
  my $eol = $text =~ /\r\n/ ? "\r\n" : "\n";

  my @lines;
  for my $phys (split /(?<=\n)/, $text) {
    if (@lines && $phys =~ /^[ \t]/) { $lines[-1]{raw} .= $phys }
    else                             { push @lines, { raw => $phys } }
  }

  my ($depth, $end, %by_name) = (0);
  for my $i (0..$#lines) {
    my $line = $lines[$i];
    $line->{index} = $i;
    (my $u = $line->{raw}) =~ s/\r?\n[ \t]//g;
    $u =~ s/\r?\n\z//;
    $line->{text} = $u;
    next if $u =~ /^\s*$/;
    if ($u =~ /^BEGIN:/i) { $depth++; next }
    if ($u =~ /^END:/i) {
      $end //= $i if $depth == 1;
      $depth--;
      next;
    }
    next unless $depth == 1 && !defined $end;
    my ($name) = $u =~ /^([^;:]*)/;
    my $lname = lc $name;
    # as Text::VCardFast: the group is everything before the last dot
    if ($lname =~ s/^(.+)\.(.*?)$/$2/) {
      ($line->{group}) = $name =~ /^(.+)\./;
    }
    $line->{name} = $lname;
    push @{$by_name{$lname}}, $line;
  }
  return undef unless defined $end;

  my %line_of;
  for my $name (keys %$props) {
    my $items = $props->{$name};
    my $ls = $by_name{$name} // [];
    return undef unless @$ls == @$items;
    for my $i (0..$#$items) {
      $line_of{refaddr $items->[$i]} = $ls->[$i];
      $ls->[$i]{item} = $items->[$i];
    }
  }
  for my $name (keys %by_name) {
    return undef unless $props->{$name};
  }

  return {
    lines   => \@lines,
    eol     => $eol,
    end     => $lines[$end],
    by_name => \%by_name,
    line_of => \%line_of,
  };
}

sub _lines_of_items {
  my ($P, $items) = @_;
  return sort { $a->{index} <=> $b->{index} }
         grep { defined && !$_->{deleted} }
         map { $P->{line_of}{refaddr $_} } @{$items // []};
}

sub _lines_named {
  my ($P, @names) = @_;
  return sort { $a->{index} <=> $b->{index} }
         grep { !$_->{deleted} }
         map { @{$P->{by_name}{$_} // []} } @names;
}

sub _group_lines {
  my ($P, $group) = @_;
  return grep { defined $_->{group} && lc $_->{group} eq lc $group && !$_->{deleted} }
         @{$P->{lines}};
}

# --- Editing lines -------------------------------------------------------

sub _set_line {
  my ($P, $line, $text) = @_;
  return if $text eq $line->{text};
  $line->{text} = $text;
  $line->{raw}  = _fold($text, $P->{eol});
}

sub _delete_line {
  my ($P, $line) = @_;
  return unless $line;
  $line->{deleted} = 1;
  $P->{touched_groups}{lc $line->{group}} = 1 if defined $line->{group};
}

# Insert content lines after $anchor (and the lines of its group that
# follow it), or before END:VCARD
sub _insert {
  my ($P, $anchor, @texts) = @_;
  my $at = $P->{end};
  my $where = 'before';
  if ($anchor) {
    my $i = $anchor->{index};
    my $g = $anchor->{group} // $anchor->{new_group};
    my $lines = $P->{lines};
    while (defined $g && $i < $#$lines && defined $lines->[$i+1]{group}
           && lc $lines->[$i+1]{group} eq lc $g) {
      $i++;
    }
    ($at, $where) = ($lines->[$i], 'after');
  }
  push @{$at->{$where}}, map { _fold($_, $P->{eol}) } @texts;
}

# A group left with nothing but annotations (a label, an Apple country
# code, a GEO or TZ for an address) once its property is deleted goes too
my %ANNOTATION = map { $_ => 1 } qw(x-ablabel x-abadr geo tz);

sub _drop_orphan_groups {
  my ($P) = @_;
  for my $g (sort keys %{$P->{touched_groups} // {}}) {
    my @live = _group_lines($P, $g);
    next if grep { !$ANNOTATION{$_->{name}} } @live;
    _delete_line($P, $_) for @live;
  }
}

# --- Writing an entry into a line ----------------------------------------

# A content line split into its name (group included, as written), its
# parameters (each as written, with its values decoded) and its value
sub _parse_line {
  my ($text) = @_;
  $text =~ /\G([^;:]*)/gc;
  my $name = $1;
  my @tokens;
  while ($text =~ /\G(;([^;:=]*)(?:=((?:"[^"]*"|[^";:])*))?)/gc) {
    my ($raw, $pname, $pval) = ($1, $2, $3);
    my $tok = { raw => $raw, rawname => $pname };
    if (defined $pval) {
      $tok->{name} = lc $pname;
      $tok->{values} = [ map {
        my $r = $_;
        (my $v = $r) =~ s/^"(.*)"$/$1/s;
        $v =~ s/\^([n^'])/$1 eq 'n' ? "\n" : $1 eq '^' ? '^' : '"'/ge;
        { raw => $r, val => $v };
      } $pval =~ /((?:"[^"]*"|[^,"])+)/g ];
    }
    else {
      # vCard 2.1: a bare TYPE value
      $tok->{name}   = 'type';
      $tok->{bare}   = 1;
      $tok->{values} = [ { raw => $pname, val => $pname } ];
    }
    push @tokens, $tok;
  }
  return undef unless $text =~ /\G:/gc;
  return { name => $name, tokens => \@tokens, value => substr($text, pos $text) };
}

# The parameters the reader interprets.  Any other parameter on a line is
# kept as it is; so is a TYPE value the reader does not interpret.
my %KNOWN_PARAM = map { $_ => 1 } qw(
  prop-id value type pref label geo tz cc mediatype service-type username
  x-service-type x-user level index created author author-name sort-as
  encoding
), map { "x-$_" } qw(label geo tz cc mediatype sort-as level index created
  author author-name);
my %KNOWN_TYPE = map { $_ => 1 } qw(home work pref cell voice fax video pager
  text textphone);
# properties whose every TYPE value is the reader's (a media format, a
# relation)
my %ALL_TYPES_KNOWN = map { $_ => 1 } qw(photo logo sound related);

sub _param_key {
  my ($name, $val) = @_;
  $name = lc $name;
  return "$name\0" . ($name =~ /^(?:type|value|encoding)$/ ? lc $val : $val);
}

# The line for $prop written over the original $line of the same name:
# the original's name, group and parameters stay as written, except the
# known parameters the new property no longer has
sub _merged_text {
  my ($P, $line, $prop) = @_;
  my $parsed = _parse_line($line->{text}) or return undef;
  my $params = $prop->{params} // {};
  my $lname  = lc $prop->{name};

  my (@want, %want);
  for my $n (_param_order($params)) {
    my $vals = $params->{$n};
    for my $v (ref $vals eq 'ARRAY' ? @$vals : ($vals)) {
      next unless defined $v;
      my $k = _param_key($n, _clean_vcard_text($v));
      push @want, [$n, $v, $k];
      $want{$k}++;
    }
  }

  my $out = $parsed->{name};
  $out = "$line->{new_group}.$out" if $line->{new_group};
  for my $tok (@{$parsed->{tokens}}) {
    my $n = $tok->{name};
    my $keep_all = !$KNOWN_PARAM{$n}
      # a VALUE=date (say) stays unless the new value says otherwise
      || ($n eq 'value' && !$params->{value}
          && !grep { $_->{val} =~ /^(?:uri|text)$/i } @{$tok->{values}});
    if ($keep_all) { $out .= $tok->{raw}; next }
    my (@kept, $dropped);
    for my $v (@{$tok->{values}}) {
      my $k = _param_key($n, $v->{val});
      if ($want{$k}) {
        $want{$k}--;
        push @kept, $v;
      }
      elsif ($n eq 'type' && !$ALL_TYPES_KNOWN{$lname} && !$KNOWN_TYPE{lc $v->{val}}) {
        push @kept, $v;
      }
      else {
        $dropped = 1;
      }
    }
    if (!$dropped) { $out .= $tok->{raw} }
    elsif (@kept) {
      $out .= $tok->{bare} ? join('', map { ";$_->{raw}" } @kept)
                           : ";$tok->{rawname}=" . join(',', map { $_->{raw} } @kept);
    }
  }
  for my $w (@want) {
    my ($n, $v, $k) = @$w;
    next unless $want{$k};
    $want{$k}--;
    $out .= ';' . uc($n) . '=' . _param_value($v);
  }
  return $out . ':' . _value_text($prop);
}

# Write $prop over the original $line: merged when it is the same vCard
# property, else replaced, keeping the line's group (and so its label)
sub _replace_line {
  my ($P, $line, $prop) = @_;
  my $text;
  $text = _merged_text($P, $line, $prop) if lc $prop->{name} eq $line->{name};
  unless (defined $text) {
    $prop->{group} //= $line->{group} // $line->{new_group};
    $text = _prop_line($prop);
  }
  _set_line($P, $line, $text);
}

# A vCard property that has an Apple or older form keeps the form the
# original used
my %KEEP_NAME = (
  'x-abdate'        => { anniversary => 1 },
  'x-socialprofile' => { impp => 1 },
  'socialprofile'   => { impp => 1 },
);

# Make a generated property fit the original: its property name, and the
# vCard 3 syntax if the original is vCard 3
sub _fit {
  my ($P, $prop, $line) = @_;
  $prop->{name} = $line->{name}
    if $line && $KEEP_NAME{$line->{name}} && $KEEP_NAME{$line->{name}}{lc $prop->{name}};
  _to_v3($prop) if $P->{v3};
  return $prop;
}

# vCard 4 parameters with no vCard 3 form keep their value as X- (RFC
# 2426 S4 allows x-name parameters); the reader reads them back
my @V4_ONLY_PARAM = qw(label geo tz cc mediatype sort-as level index created
  author author-name);

# Rewrite a property as the vCard 4 writer made it into vCard 3 (RFC 2426)
# syntax: no PROP-ID; PREF=1 becomes TYPE=pref; an inline data: URI is
# ENCODING=b with the format as TYPE; RFC 9554 SERVICE-TYPE and USERNAME
# are the X-SERVICE-TYPE and X-USER that Apple writes; KIND and MEMBER
# are Apple's X-ADDRESSBOOKSERVER-*; a date without a year uses Apple's
# 1604.  A property defined only for vCard 4 (RELATED, GENDER, LANG, ...)
# keeps its name: RFC 2425 allows any registered name, and a vCard 3
# reader skips one it does not know.
sub _to_v3 {
  my ($prop) = @_;
  my $p = $prop->{params} //= {};
  my $name = lc $prop->{name};

  delete $p->{'prop-id'};
  if (my $pref = delete $p->{pref}) {
    push @{$p->{type}}, 'pref'
      if grep { defined $_ && looks_like_number($_) && $_ == 1 } ref $pref ? @$pref : ($pref);
  }

  if ($name =~ /^(?:photo|logo|sound)$/) {
    my $mt = delete $p->{mediatype};
    if (($prop->{value} // '') =~ m{^data:([^;,]*)(?:;[^;,]*)*;base64,(.*)\z}si) {
      my ($type, $b64) = ($1, $2);
      $type = $mt->[0] if $type eq '' && $mt;
      $type =~ s{.*/}{} if defined $type;
      $p->{encoding} = ['b'];
      $p->{type} = [$type] if defined $type && $type ne '';
      $prop->{value} = $b64;
    }
    else {
      $p->{value} = ['uri'];
    }
  }
  $p->{type} = [ map { uc } @{$p->{type}} ] if $p->{type};

  $p->{'x-service-type'} = delete $p->{'service-type'} if $p->{'service-type'};
  $p->{'x-user'}         = delete $p->{username}       if $p->{username};
  for my $n (@V4_ONLY_PARAM) {
    $p->{"x-$n"} = delete $p->{$n} if exists $p->{$n};
  }

  if ($name eq 'tel' && $p->{value}) {
    # a vCard 3 TEL is a phone number, not a URI (RFC 2426 S3.3.1)
    delete $p->{value};
    $prop->{value} =~ s/^tel://i;
  }
  elsif ($name eq 'related' && $p->{value}) {
    # vCard 3 has no RELATED; RFC 2425 values are text unless they say
    # otherwise, so the vCard 4 VALUE=text is not needed
    delete $p->{value};
  }

  if ($name eq 'kind') {
    $prop->{name} = 'x-addressbookserver-kind';
  }
  elsif ($name eq 'member') {
    $prop->{name} = 'x-addressbookserver-member';
    $prop->{value} = "urn:uuid:$prop->{value}" unless $prop->{value} =~ /^urn:uuid:/i;
  }
  elsif ($name =~ /^(?:bday|anniversary|deathdate|x-abdate)$/
         && ($prop->{value} // '') =~ /^--(\d\d)(\d\d)$/) {
    $prop->{value} = "1604-$1-$2";
  }
  return $prop;
}

# --- Labels ---------------------------------------------------------------

sub _label_text {
  my ($group, $label) = @_;
  return "$group.X-ABLabel:" . _escape_text($label);
}

# Give $line the label $new (none if undef or empty): the X-ABLabel of its
# group is rewritten, added (with a new group if the line has none) or
# deleted
sub _set_label {
  my ($P, $line, $prop, $new) = @_;
  $new = undef if defined $new && (ref $new || $new eq '');
  my $group = $line->{group} // $line->{new_group};
  my ($label_line) = defined $group
    ? grep { $_->{name} && $_->{name} eq 'x-ablabel' } _group_lines($P, $group) : ();
  if (!defined $new) {
    _delete_line($P, $label_line) if $label_line;
    return;
  }
  if ($label_line) {
    my $pl = _parse_line($label_line->{text});
    my $head = $pl ? $pl->{name} . join('', map { $_->{raw} } @{$pl->{tokens}})
                   : "$group.X-ABLabel";
    _set_line($P, $label_line, "$head:" . _escape_text($new));
    return;
  }
  unless (defined $group) {
    $group = _alloc_group($P->{ctx});
    $line->{new_group} = $group;
  }
  $prop->{group} = $group if $prop;
  push @{$line->{after}}, _fold(_label_text($group, $new), $P->{eol});
}

sub _patch_label {
  my ($P, $line, $prop, $old, $new) = @_;
  $_ = (defined $_ && !ref $_ && $_ ne '') ? $_ : undef for my ($o, $n) = ($old, $new);
  return if !defined $o && !defined $n;
  return if defined $o && defined $n && $o eq $n;
  _set_label($P, $line, $prop, $n);
}

# --- Patchers, one per top-level Card property ----------------------------

sub _same {
  my ($x, $y) = @_;
  state $json = JSON->new->canonical->allow_nonref->allow_blessed->convert_blessed;
  return $json->encode([$x]) eq $json->encode([$y]);
}

# The maps whose entries the reader labels from an X-ABLabel
my %LABELLED = map { $_ => 1 } qw(emails phones addresses onlineServices media
  links calendars schedulingAddresses cryptoKeys directories);

my %MAP_WRITERS = (
  nicknames           => \&_unconvert_nicknames,
  emails              => \&_unconvert_emails,
  phones              => \&_unconvert_phones,
  addresses           => \&_unconvert_addresses,
  organizations       => \&_unconvert_organizations,
  titles              => \&_unconvert_titles,
  anniversaries       => \&_unconvert_anniversaries,
  notes               => \&_unconvert_notes,
  onlineServices      => \&_unconvert_online_services,
  media               => \&_unconvert_media,
  links               => \&_unconvert_links,
  calendars           => \&_unconvert_calendars,
  schedulingAddresses => \&_unconvert_scheduling_addresses,
  cryptoKeys          => \&_unconvert_crypto_keys,
  directories         => \&_unconvert_directories,
  preferredLanguages  => \&_unconvert_preferred_languages,
  personalInfo        => \&_unconvert_personal_info,
);

# Patch a map of the Card entry by entry: an unchanged entry keeps its
# line; a changed one is written over its line; a removed one loses its
# line; a new one is added after the lines of the same map.  $gen makes
# the vCard property of one entry (with no label: labels are patched
# here); $hook may adjust it against the original line first.
sub _patch_map {
  my ($P, $key, $old, $new, $gen, $hook) = @_;
  $old = {} unless ref $old eq 'HASH';
  $new = {} unless ref $new eq 'HASH';
  my $sources = $P->{ctx}{sources}{$key} // {};
  my $labelled = $LABELLED{$key};

  my @all = _lines_of_items($P, [ map { @$_ } values %$sources ]);
  my $anchor = $all[-1];

  my %placed;
  for my $id (sort keys %$old) {
    my @lines = _lines_of_items($P, $sources->{$id});
    next unless @lines;
    $placed{$id} = 1;
    my $entry = $new->{$id};
    if (ref $entry ne 'HASH') {
      _delete_line($P, $_) for @lines;
      next;
    }
    next if _same($old->{$id}, $entry);
    my $line = pop @lines;
    _delete_line($P, $_) for @lines;
    my ($prop) = $gen->($id, $entry);
    unless ($prop) {
      _delete_line($P, $line);
      next;
    }
    $hook->($P, $line, $prop, $old->{$id}, $entry) if $hook;
    _fit($P, $prop, $line);
    _patch_label($P, $line, $prop, $old->{$id}{label}, $entry->{label}) if $labelled;
    _replace_line($P, $line, $prop);
  }

  for my $id (sort keys %$new) {
    next if $placed{$id};
    my $entry = $new->{$id};
    next unless ref $entry eq 'HASH';
    my ($prop) = $gen->($id, $entry) or next;
    _fit($P, $prop);
    my $label = $labelled ? $entry->{label} : undef;
    my @texts;
    if (defined $label && !ref $label && $label ne '') {
      $prop->{group} = _alloc_group($P->{ctx});
      @texts = (_prop_line($prop), _label_text($prop->{group}, $label));
    }
    else {
      @texts = (_prop_line($prop));
    }
    _insert($P, $anchor, @texts);
  }
}

# One entry of a map as the writer makes it, without its label
sub _map_writer {
  my ($P, $key) = @_;
  my $ctx = $P->{ctx};
  return sub {
    my ($id, $entry) = @_;
    my @out;
    local $ctx->{no_labels} = 1;
    $MAP_WRITERS{$key}->(\@out, { $key => { $id => $entry } }, $ctx);
    return @out;
  };
}

# An Apple address keeps its country code, coordinates and time zone in
# lines of its group (X-ABADR, GEO, TZ) rather than in parameters: those
# lines are updated instead
sub _address_siblings {
  my ($P, $line, $prop, $old, $new) = @_;
  my $group = $line->{group} // return;
  my $item = $line->{item} // {};
  for my $spec ([cc => 'x-abadr', 'countryCode'], [geo => 'geo', 'coordinates'],
                [tz => 'tz', 'timeZone']) {
    my ($param, $sib_name, $field) = @$spec;
    next if defined $item->{params}{$param};
    my ($sib) = grep { $_->{name} && $_->{name} eq $sib_name } _group_lines($P, $group);
    next unless $sib;
    delete $prop->{params}{$param};
    next if _same($old->{$field}, $new->{$field});
    my $val = $new->{$field};
    if (!defined $val || ref $val || $val eq '') {
      _delete_line($P, $sib);
      next;
    }
    my $pl = _parse_line($sib->{text}) or next;
    my $head = $pl->{name} . join('', map { $_->{raw} } @{$pl->{tokens}});
    my $text = $sib_name eq 'geo' && $val =~ /^[a-z][a-z0-9+.-]*:/i ? _uri_text($val) : _escape_text($val);
    _set_line($P, $sib, "$head:$text");
  }
}

# One vCard property, by name: the first line is written over, or every
# line deleted, or one added before END:VCARD.  With $all, the other lines
# of that name go too (the reader merges them all).
sub _patch_single {
  my ($P, $names, $prop, $all) = @_;
  my @lines = _lines_named($P, @$names);
  unless ($prop) {
    _delete_line($P, $_) for @lines;
    return;
  }
  my $first = shift @lines;
  _fit($P, $prop, $first);
  if ($first) {
    _replace_line($P, $first, $prop);
    if ($all) { _delete_line($P, $_) for @lines }
  }
  else {
    _insert($P, undef, _prop_line($prop));
  }
}

sub _patch_name {
  my ($P, $key, $old_card, $new_card) = @_;
  my $o = ref $old_card->{name} eq 'HASH' ? $old_card->{name} : {};
  my $n = ref $new_card->{name} eq 'HASH' ? $new_card->{name} : {};

  my @gen;
  _unconvert_name(\@gen, { name => $n }, $P->{ctx});
  my ($fn) = grep { $_->{name} eq 'fn' } @gen;
  my ($nn) = grep { $_->{name} eq 'n' } @gen;

  # FN is the full name, or made from the components when there is none
  _patch_single($P, ['fn'], $fn)
    if !_same($o->{full}, $n->{full})
    || (!defined $n->{full} && !_same($o->{components}, $n->{components}));
  _patch_single($P, ['n'], $nn)
    unless _same([$o->{components}, $o->{sortAs}], [$n->{components}, $n->{sortAs}]);

  # TODO(registry): phoneticComponents are read from X-PHONETIC-*-NAME but
  # the writer has no form for them yet (_unconvert_name), so a change to
  # them is not patched; the X-PHONETIC-* lines are left as they are.
  _patch_single($P, [qw(x-phonetic-first-name x-phonetic-middle-name x-phonetic-last-name)], undef)
    unless %$n;
}

sub _patch_keywords {
  my ($P, $key, $old_card, $new_card) = @_;
  my @gen;
  _unconvert_keywords(\@gen, $new_card, $P->{ctx});
  _patch_single($P, ['categories'], $gen[0], 1);
}

sub _patch_members {
  my ($P, $key, $old_card, $new_card) = @_;
  my $o = ref $old_card->{members} eq 'HASH' ? $old_card->{members} : {};
  my $n = ref $new_card->{members} eq 'HASH' ? $new_card->{members} : {};
  my $sources = $P->{ctx}{sources}{members} // {};
  my $apple = $P->{v3} || _lines_named($P, 'x-addressbookserver-member');
  my @all = _lines_named($P, qw(member x-addressbookserver-member));
  my $anchor = $all[-1];

  for my $m (sort keys %$o) {
    next if $n->{$m};
    _delete_line($P, $_) for _lines_of_items($P, $sources->{$m});
  }
  for my $m (sort keys %$n) {
    next if $o->{$m} || !$n->{$m};
    my @gen;
    my $writer = $apple ? \&_unconvert_members_apple : \&_unconvert_members;
    $writer->(\@gen, { members => { $m => JSON::true } }, $P->{ctx});
    _insert($P, $anchor, map { _prop_line(_fit($P, $_)) } @gen);
  }
}

# The X-ABLabel that says a relation to Apple (the reader maps it back)
my %RELATION_LABEL = (spouse => 'Spouse', parent => 'Parent', child => 'Child',
                      friend => 'Friend');

sub _patch_related {
  my ($P, $key, $old_card, $new_card) = @_;
  my $o = ref $old_card->{relatedTo} eq 'HASH' ? $old_card->{relatedTo} : {};
  my $n = ref $new_card->{relatedTo} eq 'HASH' ? $new_card->{relatedTo} : {};
  my $sources = $P->{ctx}{sources}{relatedTo} // {};
  my @all = _lines_named($P, qw(related x-abrelatednames));
  my $anchor = $all[-1];
  my $gen = sub {
    my ($k, $rel) = @_;
    my @out;
    _unconvert_related(\@out, { relatedTo => { $k => $rel } }, $P->{ctx});
    return $out[0];
  };

  my %placed;
  for my $k (sort keys %$o) {
    my @lines = _lines_of_items($P, $sources->{$k});
    next unless @lines;
    $placed{$k} = 1;
    if (ref $n->{$k} ne 'HASH') {
      _delete_line($P, $_) for @lines;
      next;
    }
    next if _same($o->{$k}, $n->{$k});
    my $line = pop @lines;
    _delete_line($P, $_) for @lines;
    if ($line->{name} eq 'x-abrelatednames') {
      # Apple says the relation in the label
      my @rel = grep { $n->{$k}{relation}{$_} } sort keys %{$n->{$k}{relation} // {}};
      if (!@rel) { _set_label($P, $line, undef, undef); next }
      if (@rel == 1 && $RELATION_LABEL{$rel[0]}) {
        _set_label($P, $line, undef, "_\$!<$RELATION_LABEL{$rel[0]}>!\$_");
        next;
      }
    }
    _replace_line($P, $line, _fit($P, $gen->($k, $n->{$k}), $line));
  }
  for my $k (sort keys %$n) {
    next if $placed{$k} || ref $n->{$k} ne 'HASH';
    _insert($P, $anchor, _prop_line(_fit($P, $gen->($k, $n->{$k}))));
  }
}

sub _patch_speak_to_as {
  my ($P, $key, $old_card, $new_card) = @_;
  my $o = ref $old_card->{speakToAs} eq 'HASH' ? $old_card->{speakToAs} : {};
  my $n = ref $new_card->{speakToAs} eq 'HASH' ? $new_card->{speakToAs} : {};
  unless (_same($o->{grammaticalGender}, $n->{grammaticalGender})) {
    my $gg = $n->{grammaticalGender};
    _patch_single($P, ['gramgender'],
      defined $gg && !ref $gg && $gg ne '' ? { name => 'gramgender', value => $gg, params => {} } : undef);
  }
  my $ctx = $P->{ctx};
  _patch_map($P, 'speakToAs', $o->{pronouns}, $n->{pronouns}, sub {
    my ($id, $entry) = @_;
    my @out;
    _unconvert_speak_to_as(\@out, { speakToAs => { pronouns => { $id => $entry } } }, $ctx);
    return @out;
  });
}

sub _scalar_patcher {
  my ($vname) = @_;
  return sub {
    my ($P, $key, $old_card, $new_card) = @_;
    my $v = $new_card->{$key};
    _patch_single($P, [$vname],
      defined $v && !ref $v && $v ne '' ? { name => $vname, value => $v, params => {} } : undef);
  };
}

sub _patch_kind {
  my ($P, $key, $old_card, $new_card) = @_;
  my $v = $new_card->{kind};
  my @names = qw(kind x-addressbookserver-kind);
  my ($line) = _lines_named($P, @names);
  $v = undef if defined $v && (ref $v || $v eq '');
  # Apple writes no kind for an individual
  $v = undef if defined $v && $v eq 'individual' && ($P->{v3} || ($line && $line->{name} ne 'kind'));
  my $name = $line ? $line->{name} : 'kind';
  _patch_single($P, \@names, defined $v ? { name => $name, value => $v, params => {} } : undef);
}

%PATCHERS = (
  name        => \&_patch_name,
  keywords    => \&_patch_keywords,
  members     => \&_patch_members,
  relatedTo   => \&_patch_related,
  speakToAs   => \&_patch_speak_to_as,
  kind        => \&_patch_kind,
  uid         => _scalar_patcher('uid'),
  prodId      => _scalar_patcher('prodid'),
  updated     => _scalar_patcher('rev'),
  created     => _scalar_patcher('created'),
  language    => _scalar_patcher('language'),
  (map {
    my $key = $_;
    ($key => sub {
      my ($P, $k, $old_card, $new_card) = @_;
      _patch_map($P, $key, $old_card->{$key}, $new_card->{$key}, _map_writer($P, $key),
                 $key eq 'addresses' ? \&_address_siblings : undef);
    });
  } keys %MAP_WRITERS),
);

###############################################################################
# WRITING: content lines, byte for byte the same for the same input
###############################################################################

# Text::VCardFast's hash2vcard writes the parameters of a property in
# Perl's hash order, so the same Card gave different bytes on every run
# (and a CardDAV server a new ETag for every unchanged save).  The writer
# here keeps its property order but orders everything it writes.

# properties in this order first (Text::VCardFast's), then by name
my @PROP_ORDER = qw(version fn n nickname lang gender org title role bday
                    anniversary email tel adr url impp);
my %PROP_ORDER = map { $PROP_ORDER[$_] => $_ + 1 } 0..$#PROP_ORDER;

# parameters in this order first, then by name
my @PARAM_ORDER = qw(prop-id value type pref);
my %PARAM_ORDER = map { $PARAM_ORDER[$_] => $_ + 1 } 0..$#PARAM_ORDER;

# A whole vCard from a list of properties; items of one group are written
# together, after the first of them
sub _write_vcard {
  my ($props, $eol) = @_;
  $eol //= "\n";

  my %by_name;
  push @{$by_name{lc $_->{name}}}, $_ for @$props;
  my @names = sort {
    ($PROP_ORDER{$a} // 1000) <=> ($PROP_ORDER{$b} // 1000) || $a cmp $b
  } keys %by_name;

  my %groups;
  for my $prop (@$props) {
    push @{$groups{lc $prop->{group}}}, $prop if defined $prop->{group} && $prop->{group} ne '';
  }

  my (%done, @out);
  for my $name (@names) {
    for my $prop (@{$by_name{$name}}) {
      next if $done{$prop}++;
      push @out, $prop;
      if (defined $prop->{group} && $prop->{group} ne '') {
        push @out, grep { !$done{$_}++ } @{$groups{lc $prop->{group}}};
      }
    }
  }

  return join '', "BEGIN:VCARD$eol", (map { _fold(_prop_line($_), $eol) } @out), "END:VCARD$eol";
}

# One property as an unfolded content line, cleaned of control characters
sub _prop_line {
  my ($prop) = @_;
  my $line = '';
  $line .= "$prop->{group}." if defined $prop->{group} && $prop->{group} ne '';
  $line .= uc $prop->{name};
  $line .= _params_text($prop->{params});
  return $line . ':' . _value_text($prop);
}

sub _params_text {
  my ($params) = @_;
  return '' unless $params && %$params;
  my $text = '';
  for my $name (_param_order($params)) {
    my $vals = $params->{$name};
    for my $val (ref $vals eq 'ARRAY' ? @$vals : ($vals)) {
      next unless defined $val;
      $text .= ';' . uc($name) . '=' . _param_value($val);
    }
  }
  return $text;
}

sub _param_order {
  my ($params) = @_;
  return sort {
    ($PARAM_ORDER{$a} // 1000) <=> ($PARAM_ORDER{$b} // 1000) || $a cmp $b
  } keys %$params;
}

# RFC 6868 caret encoding; quoted when it holds a separator or space
sub _param_value {
  my ($val) = @_;
  $val = _clean_vcard_text($val);
  $val =~ s/([\n^"])/$1 eq "\n" ? '^n' : $1 eq '^' ? '^^' : "^'"/ge;
  $val = qq{"$val"} if $val =~ /[;:,\s]/;
  return $val;
}

# RFC 6350 S3.4: TEXT escapes BACKSLASH, COMMA, SEMICOLON and NEWLINE
sub _escape_text {
  my ($val) = @_;
  die "Text::JSContact: a vCard value must be a string, not $val\n" if ref $val;
  $val = _clean_vcard_text($val // '');
  $val =~ s/([\\,;])/\\$1/g;
  $val =~ s/\n/\\n/g;
  return $val;
}

# A structured value is a list of components, each a string or a list
# of strings (written comma-separated)
sub _value_text {
  my ($prop) = @_;
  if (my $values = $prop->{values}) {
    return join ';', map {
      ref $_ eq 'ARRAY' ? join(',', map { _escape_text($_) } @$_) : _escape_text($_)
    } @$values;
  }
  return _uri_text($prop->{value}) if _is_uri_value($prop);
  return _escape_text($prop->{value});
}

# Fold a content line at 75 octets (RFC 6350 S3.2), never inside a
# character or between a backslash and the character it escapes
sub _fold {
  my ($line, $eol) = @_;
  my @out;
  if ($line !~ /[^\x00-\x7f]/) {
    # one character, one octet
    my $pos = 0;
    while ($pos < length $line) {
      my $max = @out ? 74 : 75;
      my $chunk = substr($line, $pos, $max);
      # an odd run of backslashes at the end splits an escape
      chop $chunk if length $chunk == $max && $pos + $max < length $line
                  && $chunk =~ /(?<!\\)(?:\\\\)*\\\z/;
      push @out, $chunk;
      $pos += length $chunk;
    }
  }
  else {
    my $cur = '';
    my $len = 0;
    for my $ch ($line =~ /(\\.|.)/sg) {
      my $l = $ch =~ /[^\x00-\x7f]/ ? length(encode_utf8($ch)) : length $ch;
      my $max = @out ? 74 : 75;
      if ($len + $l > $max && $len) {
        push @out, $cur;
        $cur = '';
        $len = 0;
      }
      $cur .= $ch;
      $len += $l;
    }
    push @out, $cur;
  }
  push @out, '' unless @out;
  return join("$eol ", @out) . $eol;
}

# RFC 6350 S3.4 escapes COMMA, SEMICOLON, BACKSLASH and NEWLINE in TEXT
# values only; a URI value is written as it is.  Escaping every value
# turns "data:image/png;base64,..." into "data:image/png\;base64\,...",
# no longer a URI (Cyrus then stores it as TEXT with a nonsense media
# type).  These are the properties whose default value type is URI
# (RFC 6350 S6, RFC 6715, RFC 8605, RFC 9554), plus Apple's member
# property.
my %URI_DEFAULT = map { $_ => 1 } qw(
  source photo impp geo logo member sound uid url key fburl caladruri
  caluri related org-directory contact-uri socialprofile
  x-addressbookserver-member
);

sub _is_uri_value {
  my ($prop) = @_;
  return 0 if exists $prop->{values};
  my $val = $prop->{value};
  return 0 if !defined $val || ref $val;
  # only something that is a URI: a bare IMPP username, a vCard 3 GEO
  # or a non-URI UID stays TEXT
  return 0 unless $val =~ /^[a-z][a-z0-9+.-]*:/i;
  my $params = $prop->{params} // {};
  return 0 if $params->{encoding};
  my @vt = map { lc } grep { defined } map { ref $_ ? @$_ : $_ } $params->{value} // ();
  return $vt[0] eq 'uri' if @vt;
  return $URI_DEFAULT{lc $prop->{name}} ? 1 : 0;
}

# A value that is a URI: a scheme, a colon, and no white space
sub _looks_like_uri {
  my ($val) = @_;
  return defined $val && !ref $val && $val =~ /^[a-z][a-z0-9+.-]*:\S+\z/i;
}

sub _uri_text {
  my ($val) = @_;
  $val = _clean_vcard_text($val);
  # A URI has neither, and written raw a LF would end the content line,
  # so percent-encode them; it also means a reader's TEXT unescaping
  # (Text::VCardFast's applies to every value) leaves the URI alone.
  $val =~ s/\\/%5C/g;
  $val =~ s/\n/%0A/g;
  return $val;
}

# A CR from the card data could end the content line early and forge
# extra properties.  vCard allows no control characters but HTAB, so turn
# CR into LF (escaped as \n, or ^n in a parameter) and drop the rest.
sub _clean_vcard_text {
  my ($val) = @_;
  return [ map { _clean_vcard_text($_) } @$val ] if ref $val eq 'ARRAY';
  return $val if !defined $val || ref $val;
  $val =~ s/\r\n?/\n/g;
  $val =~ s/[\x00-\x08\x0b-\x1f\x7f]//g;
  return $val;
}

# Compare two JSContact cards and return hash of changed property names
sub _diff_cards {
  my ($old, $new) = @_;
  my $json = JSON->new->canonical->utf8;

  my %changed;

  # Check all keys in both old and new
  my %all_keys;
  $all_keys{$_} = 1 for keys %$old, keys %$new;

  # Skip internal/metadata keys
  delete $all_keys{$_} for qw(@type version CPath href _raw meta);

  for my $key (keys %all_keys) {
    my $old_val = $old->{$key};
    my $new_val = $new->{$key};

    # Both undef/missing -> no change
    next if !defined $old_val && !defined $new_val;

    # One exists, other doesn't -> changed
    if (!defined $old_val || !defined $new_val) {
      $changed{$key} = 1;
      next;
    }

    # Compare via canonical JSON encoding
    my $old_json = $json->encode([$old_val]);
    my $new_json = $json->encode([$new_val]);
    $changed{$key} = 1 if $old_json ne $new_json;
  }

  return %changed;
}

1;

__END__

=head1 NAME

Text::JSContact - Convert between vCard and JSContact (RFC 9553/9555)

=head1 AUTHOR

Bron Gondwana, C<< <brong at cpan.org> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2026 Fastmail Pty Ltd.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself; that is, either the GNU General
Public License as published by the Free Software Foundation (version 1,
or at your option any later version), or the Artistic License.

See L<http://dev.perl.org/licenses/> and the LICENSE file included with
this distribution for more information.

=cut
