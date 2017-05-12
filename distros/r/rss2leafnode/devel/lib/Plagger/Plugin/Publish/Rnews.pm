# Copyright 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015 Kevin Ryde
#
# This file is part of RSS2Leafnode.
#
# RSS2Leafnode is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3, or (at your option) any later
# version.
#
# RSS2Leafnode is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with RSS2Leafnode.  If not, see <http://www.gnu.org/licenses/>.


package Plagger::Plugin::Publish::Rnews;
use 5.006;
use strict;
use warnings;
use DateTime;
use DateTime::Format::Mail;
use List::Util;
use MIME::Words;
use MIME::Entity;
use URI;
use News::Rnews;
use base 'Plagger::Plugin';

our $VERSION = 79;


sub rule_hook { return 'publish.feed' }

sub register {
  my($self, $context) = @_;
  $context->register_hook ($self,
                           'publish.init' => \&initialize,
                           'publish.feed' => \&publish,
                           'publish.finalize' => \&finalize);
}

# object initializer
sub init {
  my ($self, @args) = @_;
  $self->SUPER::init(@args);

  $self->conf->{'group'} or Plagger->context->error('group is required');
  $self->{'rnews'} = News::Rnews->new;
}

# 'publish.init' handler
sub initialize {
  my ($self, $context) = @_;
}

# 'publish.finalize' handler, called after all feeds published
sub finalize {
  my ($self, $context, $args) = @_;
  $self->{'rnews'}->flush;
}

# 'publish.feed' handler
sub publish {
  my ($self, $context, $args) = @_;

  my $feed = $args->{'feed'};
  if ($feed->count == 0) {
    $context->log(info => "Rnews: ignore empty feed");
    return;
  }

  my $conf = $self->conf;
  my $group = $conf->{'group'};
  my $rnews = $self->{'rnews'};
  $rnews->open;

  my $msg = feed_to_multipart_message ($self, $context, $feed);
  $msg->head->replace ('Path:'       => feed_host($feed));
  $msg->head->replace ('Newsgroups:' => $group);

  my $msgid = $msg->head->get('Message-ID'); $msgid =~ s/\n+$//;
  my $subject = $msg->head->get('Subject');  $subject =~ s/\n+$//;

  if ($rnews->message_id_exists ($msgid)) {
    $context->log(info => "Already in spool: $subject, $msgid");
  }
  print $msg->as_string,"\n";
  $context->log (info => "Write: $subject, $msgid");
  $rnews->write ($msg);

  if ($conf->{'flush_feed'}) {
    $rnews->flush;
  }
}

# Templatized through html.tt
#
sub feed_to_html_message {
  my ($self, $context, $feed) = @_;

  if ($feed->count == 0) {
    $context->log(info => "Rnews: ignore empty feed");
    return;
  }

  my $rnews = $self->{'rnews'};
  $rnews->open;

  my $conf = $self->conf;

  my $timezone = $context->conf->{'timezone'};
  my $now = Plagger::Date->now (timezone => $timezone);
  my $now822 = $now->format('Mail');

  my $first_entry = $feed->entries->[0];

  my $from = $first_entry->author || $feed->author;
  if (defined $from) {
    $from = $from->plaintext;
  } else {
    $from = 'nobody';
  }

  my $subject = $feed->title_text;
  if (! defined $subject) { $subject = 'untitled'; }

  # generic html.tt has utf-8 hard coded (whereas gmail_notify.tt has an
  # encoding parameter)
  my $encoding = 'utf-8';
  my $body = $self->templatize ('html.tt',
                                { feed => $feed,
                                  encoding => $encoding });
  my $body_type = 'text/html';

  my $date = $first_entry->date || $now;
  $date = $date->format('Mail');

  my $copyright = $feed->meta->{'copyright'};
  my $language = $feed->language;
  my $msgid = feed_message_id ($feed);

  # List-Post and perhaps more
  my $mail_headers = $first_entry->meta->{'mail_headers'};

  foreach ($from, $subject, $copyright) {
    if (defined $_) {
      $_ = MIME::Words::encode_mimewords ($_);
    }
  }
  my $msg = MIME::Entity->build (From          => $from,
                                 Subject       => $subject,
                                 'Message-ID'  => $msgid,
                                 Date          => $date,
                                 'Date-Received:'    => $now822,
                                 'Content-Language:' => $language,
                                 'X-Copyright'       => $copyright,
                                 'X-Feed-Link'       => $feed->link,
                                 %$mail_headers,

                                 Type          => $body_type,
                                 Encoding      => '-SUGGEST',
                                 Charset       => $encoding,
                                 Data          => $body);

  $msg->head->replace ('X-Mailer',
                       "PublishRnews/$VERSION Plagger/$Plagger::VERSION "
                       . $msg->head->get('X-Mailer'));
  return $msg;
}

# A multipart of all the entries, or singlepart if just one entry
#
sub feed_to_multipart_message {
  my ($self, $context, $feed) = @_;

  my $encoding = 'utf-8';

  my $timezone = $context->conf->{'timezone'};
  my $now = Plagger::Date->now (timezone => $timezone);
  my $now822 = $now->format('Mail');

  my $first_entry = $feed->entries->[0];

  my $from = $first_entry->author || $feed->author;
  if (defined $from) {
    $from = $from->plaintext;
  } else {
    $from = 'nobody';
  }

  my $subject = $feed->title_text;
  if (! defined $subject) { $subject = 'untitled'; }

  my $date = $first_entry->date || $now;
  $date = $date->format('Mail');

  my $copyright = $feed->meta->{'copyright'};
  my $language = $feed->language;
  my $msgid = feed_message_id ($feed);

  foreach ($from, $subject, $copyright) {
    if (defined $_) {
      $_ = MIME::Words::encode_mimewords ($_);
    }
  }
  my $msg;
  foreach my $entry ($feed->entries) {
    # List-Post and perhaps more
    my $mail_headers = $first_entry->meta->{'mail_headers'};

    my $body = $entry->body;
    my $body_type;
    if ($body->is_html) {
      $body = $body->html;
      $body_type = 'text/html';
      if ($body !~ /<html>/i) {
        $body = <<"HERE"
<!DOCTYPE html PUBLIC \"-//W3C//DTD HTML 4.01 Transitional//EN\">
<html><body>
$body
/body></html>
HERE
      }
      print "html: $body\n";

    } else {
      $body = $body->plaintext;
      $body_type = 'text/plain';
    }
    if (! $msg) {
      $msg = MIME::Entity->build (From          => $from,
                                  Subject       => $subject,
                                  'Message-ID'  => $msgid,
                                  Date          => $date,
                                  'Date-Received:'    => $now822,
                                  'Content-Language:' => $language,
                                  'X-Copyright'       => $copyright,
                                  'X-Feed-Link'       => $feed->link,
                                  %$mail_headers,

                                  Type          => $body_type,
                                  Encoding      => '-SUGGEST',
                                  Charset       => $encoding,
                                  Data          => $body);
    } else {
      $msg->attach(Type     => $body_type,
                   Encoding => '-SUGGEST',
                   Charset  => $encoding,
                   Data     => $body);
    }

    foreach my $enclosure ($entry->enclosures) {
      my $path = $enclosure->local_path || next;
      $msg->attach(Type     => $enclosure->type,
                   Encoding => '-SUGGEST',
                   Charset  => $encoding,
                   Path     => $path, # the actual content
                   Filename => $enclosure->filename); # suggested name
    }
  }

  $msg->head->replace ('X-Mailer',
                       "PublishRnews/$VERSION Plagger/$Plagger::VERSION "
                       . $msg->head->get('X-Mailer'));
  return $msg;
}

# return a mail message id like "<PlaggerRnews.FOOBARQUUX@hostname.org>"
sub feed_message_id {
  my ($feed) = @_;
  return ('<PlaggerRnews.' . msgid_chars($feed->id)
          . '@' . msgid_chars(feed_host($feed)) . '>');
}

sub feed_host {
  my ($feed) = @_;
  if (my $url = $feed->url) {
    my $uri = URI->new ($url);
    if ($uri->can('host')) {
      if (my $host = $uri->host) {
        return $host;
      }
    }
  }
  return 'localhost';
}

# return $str with characters stripped which are not allowed in a Message-ID
sub msgid_chars {
  my ($str) = @_;
  $str =~ s/[^a-zA-Z0-9.]//g;
  return $str;
}

1;

__END__

=head1 NAME

Plagger::Plugin::Publish::Rnews - write to newsgroup using rnews

=for test_synopsis 1

=for test_synopsis __END__

=head1 SYNOPSIS

 - module: Publish::Rnews
   config:
     group: my.local.newsgroup.name

=head1 DESCRIPTION

This plugin publishes a feed as a news message using the C<rnews> program
(through C<News::Rnews>).  It's designed for use with Leafnode version 2
with a local newsgroup, ie. one which doesn't propagate anywhere, is just
readable locally.

Note that you must run C<plagger> as user C<news> to be able to spawn the
C<rnews> program successfully.

    su news -c '/usr/bin/plagger -c myconf.yaml'

A single message per feed is inserted, with feed entries in a style similar
to C<Publish::Gmail>.  See L<Plagger::Plugin::Filter::BreakEntriesToFeeds>
to split into one entry per feed and thus one entry per message.  Eg.

    - module: Filter::BreakEntriesToFeeds
    - module: Publish::Rnews
      config:
        group: my.local.newsgroup.name

For both multi-entry or single-entry a repeat or duplicate message is not
inserted again into the news spool.  When using single-entry style this
means an automatic "de-dup" of entries, like C<Filter::Rule> with C<Deduped>
does.

=head1 CONFIG

=over 4

=item group

The name of the local newsgroup to post into.  You must create the group
manually in Leafnode by adding a line to F</etc/news/leafnode/local.groups>
like

    r2l.surfing	n	My surf feeds

The description is optional, but note it's a tab character between the name
and the "n" status, and between the "n" and any description.  See "LOCAL
NEWSGROUPS" in the Leafnode F<README> file for more information.

=back

=head1 SEE ALSO

L<Plagger>, L<Plagger::Plugin::Publish::Gmail>

=head1 HOME PAGE

http://user42.tuxfamily.org/rss2leafnode/index.html

=head1 LICENSE

Copyright 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015 Kevin Ryde

RSS2Leafnode is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the Free
Software Foundation; either version 3, or (at your option) any later
version.

RSS2Leafnode is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
more details.

You should have received a copy of the GNU General Public License along with
RSS2Leafnode.  If not, see <http://www.gnu.org/licenses/>.

=cut
