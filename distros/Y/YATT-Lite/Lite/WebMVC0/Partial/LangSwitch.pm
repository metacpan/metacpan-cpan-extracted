package YATT::Lite::WebMVC0::Partial::LangSwitch;
sub MY () {__PACKAGE__}
use strict;
use warnings qw(FATAL all NONFATAL misc);
use Carp;

use mro 'c3'; # XXX: Is this ok?

use YATT::Lite::Partial
  (requires => [qw/error/]
   , fields => [qw/cf_lang_list
		   cf_debug_lang
		  /
                , [cf_default_lang => only_if_missing => 1]

              ]
   , -Entity, -CON, -SYS
  );

Entity default_lang => sub {
  my MY $self = $SYS;
  $self->{cf_default_lang} // 'en';
};

Entity current_lang => sub {
  my ($this) = @_;
  $CON->cget('lang');
};

sub before_dirhandler {
  (my MY $self, my ($dh, $con, $file)) = @_;
  $self->load_current_lang($con);
  &maybe::next::method;
}

sub load_current_lang {
  (my MY $self, my ($con, $user)) = @_;

  $con->logdump("lang.init") if $self->{cf_debug_lang};

  if (not $user
      and my $sub = $self->can("load_current_user")) {
    $user = $sub->($self, $con);
  }

  my $lang_key = '--lang';
  my $lang = $con->param($lang_key);
  if ($lang) {
    $self->error("Invalid lang code!") unless $lang =~ /^\w{2}$/;
  }

  my ($ck_lang) = map {$_ ? $_->value : ()} $con->cookies_in->{$lang_key};

  unless ($lang) {
    my $sub;
    if ($user and $sub = $user->can('pref_lang') and my $ul = $sub->($user)) {
      $lang = $ul;
      # XXX: Should delete lang cookie.
    } elsif ($ck_lang) {
      $lang = $ck_lang;
    }
  } elsif (not $ck_lang or $ck_lang ne $lang) {
    $con->set_cookie($lang_key, $lang, -path => $con->site_location);
  }

  my $yatt = $con->cget('yatt');
  $lang ||= +$con->accept_language(filter =>
				   $self->{cf_lang_list} // [qw/en ja/])
    || $yatt->default_lang;
  $con->configure(lang => $lang);
  $yatt->get_lang_msg($lang);

  $con->set_header(Vary => "Accept-Language"); # XXX: Should be idempotent.
  $con->set_header("Content-Language" => $lang);

  &maybe::next::method;
}

1;
