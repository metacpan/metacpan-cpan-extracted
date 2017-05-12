package WWW::TWikiClient;

use WWW::Mechanize;

use strict;
use warnings;

use vars qw($VERSION);
$VERSION = '0.11';

use base 'WWW::Mechanize';

use Class::MethodMaker
 get_set => [
             'bin_url',
             'current_default_web',
             'current_topic',
             'auth_user',
             'auth_passwd',
             'override_locks',
             'release_edit_lock',
             'verbose',
             'skin_hints',
            ],
 new_hash_init => 'hash_init'
 ;

sub new {
  my $class = shift;
  my $self = WWW::Mechanize::new ($class);
  $self->pre_init ();
  $self->hash_init (@_);
  $self->post_init ();
  return $self;
}

sub pre_init {
  my $self   = shift;
  $self->override_locks    (0);
  $self->release_edit_lock (1);
  $self->verbose           (0);
  $self->skin_hints        ({});
}

sub post_init {
  my $self   = shift;
}

# overloaded to provide username and password
# that we have in two own getters/setters
sub get_basic_credentials {
  my $self = shift;
  return ($self->auth_user, $self->auth_passwd);
}

# constructs URL
# if topic doesn't contain a Web prefix, "current_default_web" is prepended
sub _make_url {
  my $self  = shift;
  my $cmd   = shift;
  my $topic = shift;
  my $tail  = shift;

  my $url = $self->bin_url;
  if ($topic =~ /\./) {
    $topic =~ s!\.!/!;
  } else {
    $topic = $self->current_default_web."/$topic";
  }
  $url .= '/' if $url !~ m!/$!;
  $url .= "$cmd/";
  $url .= $topic;
  $url .= $tail if $tail;
  return $url;
}

sub _skin_regex_topic_locked {
  my $self = shift;
  return qr/\(oops\).*name="Topic_is_locked_by_another_user"/s;
}

sub _skin_regex_topic_locked_edit_anyway {
  my $self = shift;
  return qr/Edit anyway/;
}

sub _skin_regex_authentication_failed {
  my $self = shift;
  return qr/TWikiRegistration.*\(oops\).*name="Either_you_need_to_register_or_t"/s;
}

sub _skin_regex_save_or_preview_page {
  my $self = shift;
  my $topic = shift || ''; # needed for "where I am"-heuristic

  return qr/form name=".*".*action=".*\/save\/.*$topic">/s;
}

# a little helper function
sub _htmlparse_get_text {
  my $self = shift;

  my($p, $stop) = @_;
  my $text;
  while (defined(my $t = $p->get_token)) {
    if (ref $t) {
      $p->unget_token($t) unless $t->[0] eq $stop;
      last;
    }
    else {
      $text .= $t;
    }
  }
  return $text;
}

sub htmlparse_extract_single_textarea {
  my $self = shift;
  my $doc = shift || $self->doc || '';

  my @FORM_TAGS = qw(form textarea);
  my $p = HTML::PullParser->new (
                                 doc 	     => $doc,
                                 start 	     => 'tag, attr',
                                 end   	     => 'tag',
                                 text  	     => '@{text}',
                                 report_tags => \@FORM_TAGS,
                                );
  while (defined(my $t = $p->get_token)) {
    next unless ref $t; # skip text
    if ($t->[0] eq "form") {
      shift @$t;
      while (defined(my $t = $p->get_token)) {
        next unless ref $t;  # skip text
        last if $t->[0] eq "/form";
        if ($t->[0] eq "textarea") {
          return $self->_htmlparse_get_text ($p, "/textarea");
        }
      }
    } elsif ($t->[0] eq "textarea") {
      return $self->_htmlparse_get_text ($p, "/textarea");
    }
  }
  return undef;
}

sub edit_press_cancel {
  my $self = shift;

  my $url = $self->_make_url ('view', $self->current_topic, '?unlock=on');
  #print STDERR "edit_press_cancel: $url\n" if $self->verbose;
  $self->follow_link (url => $url);
}

sub read_topic {
  my $self = shift;
  my $topic = shift || $self->current_topic;
  my $url = $self->_make_url ('view', $topic, '?raw=on');
  #print STDERR "read_topic: $url\n" if $self->verbose;
  $self->get ($url);
  return $self->htmlparse_extract_single_textarea ($self->content);
}

sub _handle_release_edit_lock {
  my $self = shift;

  my $unlock_checkbox = $self->current_form->find_input ('unlock', 'checkbox');
  # "release edit lock"
  if ($unlock_checkbox) {
    if ($self->release_edit_lock) {
      $self->tick ('unlock', 'on');
    } else {
      $self->untick ('unlock', 'on');
    }
  }
}

sub save_topic {
  my $self = shift;
  my $content = shift;
  my $topic = shift || $self->current_topic;

  my $url = $self->_make_url ('edit', $topic);
  #print STDERR "save_topic: $url\n" if $self->verbose;

  # get page
  $self->get ($url);

  # locked?
  $self->_save_topic_handle_locks ($url) or return undef;

  # fill form
  $self->form_number (1);
  $self->current_form;
  $self->set_fields ( text => $content );
  $self->_save_topic_Save ($topic);
  return 1;
}

sub attach_to_topic {
  my $self           = shift;
  my $local_filename = shift;
  my $comment        = shift;
  my $create_link    = shift;
  my $hide_file      = shift;
  my $topic          = shift || $self->current_topic;

  my $url = $self->_make_url ('attach', $topic);
  print STDERR "attach_to_topic url: $url\n" if $self->verbose;

  # get page
  $self->get ($url);

  # fill form
  $self->form_number (1);
  $self->current_form;

  $self->set_fields
   (
    filepath    => $local_filename,
    filecomment => $comment,
   );
  $self->tick ('createlink', 'on') if $create_link;
  $self->tick ('hidefile', 'on')   if $hide_file;

  $self->submit();
  return;
}

sub _save_topic_handle_locks {
  my $self  = shift;
  my $url   = shift;

  my $html_content = $self->content;
  if ($html_content =~ $self->_skin_regex_topic_locked) {
    if ($self->override_locks) {
      # edit anyway
      print STDERR "Override topic lock.\n" if $self->verbose;
      $self->follow_link (text_regex => $self->_skin_regex_topic_locked_edit_anyway);
      $self->get ($url);
    } else {
      print STDERR "Topic is locked.\n" if $self->verbose;
      return undef;
    }
  } elsif ($html_content =~ $self->_skin_regex_authentication_failed) {
    print STDERR "Access denied. Authentication failed.\n" if $self->verbose;
    return undef;
  }
  return 1;
}

sub _save_topic_Save {
  my $self  = shift;
  my $topic = shift || ''; # needed for "where I am"-heuristic

  $self->_handle_release_edit_lock;
  # simply submit (== either "Preview Changes" or "Save Changes")
  $self->submit();
  # did we arrive at a preview page?
  my $content = $self->content;
  if ($content =~ _skin_regex_save_or_preview_page ($topic)) {
    # simply submit again (== "Save Changes")
    $self->_handle_release_edit_lock;
    $self->submit();
  }
}

1;
