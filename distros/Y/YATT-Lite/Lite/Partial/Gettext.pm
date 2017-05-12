package YATT::Lite::Partial::Gettext; sub MY () {__PACKAGE__}
use strict;
use warnings qw(FATAL all NONFATAL misc);
use YATT::Lite::Partial
  (fields => [qw/locale_cache/]
   , requires => [qw/error use_encoded_config/]);

use YATT::Lite::Util qw/ckeval/;

#========================================
# Locale support.
#========================================

use YATT::Lite::Util::Enum (_E_ => [qw/MTIME DICT LIST
				       FORMULA NPLURALS HEADER/]);

sub configure_locale {
  (my MY $self, my $spec) = @_;

  require Locale::PO;

  if (ref $spec eq 'ARRAY') {
    my ($type, @args) = @$spec;
    my $sub = $self->can("configure_locale_$type")
      or $self->error("Unknown locale spec: %s", $type);
    $sub->($self, @args);
  } else {
    die "NIMPL";
  }
}

sub configure_locale_data {
  (my MY $self, my $value) = @_;
  my $cache = $self->{locale_cache} ||= {};
  foreach my $lang (keys %$value) {
    my $entry = [];
    $entry->[_E_LIST] = my $list = $value->{$lang};
    $entry->[_E_DICT] = my $hash = {};
    foreach my $po (@$list) {
      $hash->{$po->dequote($po->msgid)} = $po;
    }
    $self->lang_parse_header($entry);
    $cache->{$lang} = $entry;
  }
}

sub lang_parse_header {
  (my MY $self, my $entry) = @_;
  my $header = $entry->[_E_DICT]->{''}
    or return;
  my $xhf = YATT::Lite::XHF::parse_xhf
    ($header->dequote($header->msgstr));
  my ($sub, $nplurals);
  if (my $form = $xhf->{'Plural-Forms'}) {
    if (($nplurals, my $formula) = $form =~ m{^\s*nplurals\s*=\s*(\d+)\s*;
					      \s*plural\s*=\s*([^;]+)}x) {
      $formula =~ s/\bn\b/\$n/g;
      $sub = ckeval(sprintf q|sub {my ($n) = @_; %s}|, $formula);
    }
  } else {
    $sub = \&lang_plural_formula_en;
    $nplurals = 2;
  }
  @{$entry}[_E_FORMULA, _E_NPLURALS, _E_HEADER] = ($sub, $nplurals, $xhf);

}

sub lang_load_msgcat {
  (my MY $self, my ($lang, $fn)) = @_;
  require Locale::PO;
  my $entry = [];
  $entry->[_E_DICT] = my $hash = {};
  $entry->[_E_LIST] = my $res = Locale::PO->load_file_asarray($fn);

  my $use_encoding = $self->use_encoded_config;

  foreach my $loc (@$res) {
    if ($use_encoding) {
      $loc->msgid(Encode::decode("utf-8", $loc->dequote($loc->msgid)));
      $loc->msgstr(Encode::decode("utf-8", $loc->dequote($loc->msgstr)));
    }
    my $id = $loc->dequote($loc->msgid);
    $hash->{$id} = $loc;
  }
  $self->lang_parse_header($entry);
  $self->{locale_cache}{$lang} = $entry;
}

sub _lang_dequote {
  shift;
  my $string = shift;
  $string =~ s/^"(.*)"/$1/s; # XXX: Locale::PO::dequote is not enough.
  $string =~ s/\\"/"/g;
  return $string;
}

sub lang_plural_formula_en { my ($n) = @_; $n != 1 }

sub lang_gettext {
  (my MY $self, my ($lang, $msgid)) = @_;
  my $entry = $self->lang_getmsg($lang, $msgid)
    or return $msgid;
  $entry->dequote($entry->msgstr) || $msgid;
}

sub lang_ngettext {
  (my MY $self, my ($lang, $msgid, $msg_plural, $num)) = @_;
  if (my ($locale, $entry) = $self->lang_getmsg($lang, $msgid)) {
    my $ix = $locale->[_E_FORMULA]->($num);
    my $hash = $entry->msgstr_n;
    if (defined (my $hit = $hash->{$ix})) {
      return $entry->dequote($hit);
    }
  }
  return ($msgid, $msg_plural)[lang_plural_formula_en($num)];
}

sub lang_msgcat {
  (my MY $self, my $lang) = @_;
  my ($catalog);
  return unless defined $lang
    and $catalog = $self->{locale_cache}{$lang};
  if (wantarray) {
    # For later use in lang_extract_lcmsg
    ($catalog->[_E_LIST] //= [], $catalog->[_E_DICT] //= {});
  } else {
    $catalog;
  }
}

sub lang_getmsg {
  (my MY $self, my ($lang, $msgid)) = @_;
  my ($catalog, $msg);
  if (defined $msgid and defined $lang
      and $catalog = $self->{locale_cache}{$lang}
      and $msg = $catalog->[_E_DICT]{$msgid}) {
    wantarray ? ($catalog, $msg) : $msg;
  } else {
    return;
  }
}

1;
