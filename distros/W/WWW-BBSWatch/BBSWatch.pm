package WWW::BBSWatch;

=pod

=head1 NAME

WWW::BBSWatch - Send, via email, messages posted to a WWW bulletin board

=head1 SYNOPSIS

  use WWW::BBSWatch; # should really be a subclass

  sub WWW::BBSWatch::article_list { # generates warning (rightly so)
    my $self = shift;
    my $content = shift;
    return ($$content =~ m%<A HREF="($self->{bbs_url}\?read=\d*)%gs);
  }

  BBSWatch->new(-MAIL => 'me',
    -BBS_URL => 'http://www.foo.org/cgi-bin/bbs.pl')->retrieve;

See better, working examples below.

=head1 DESCRIPTION

There are many interesting discussions that take place on World Wide Web
Bulletin Boards, but I do not have the patience to browse to each article.  I
can process email and newsgroups many times faster than a WWW bulletin board
because of the lag inherent in the web. Instead of ignoring this wealth of
information, B<WWW::BBSWatch> was created. It will monitor a World Wide Web
Bulletin Board and email new postings to you. The email headers are as correct
as possible, including reasonable I<From>, I<Subject>, I<Date>, I<Message-Id>
and I<References> entries.

This module requires B<LWP::UserAgent> and B<MIME::Lite>.

=head1 INTERFACE

=over 4

=cut

use strict;

use vars qw/$VERSION/;
$VERSION = "1.02";

use LWP::UserAgent ();
use SDBM_File;
use Fcntl;
use MIME::Lite ();

local $ = 1;

use constant LOCK_SH => 1;
use constant LOCK_EX => 2;
use constant LOCK_NB => 4;
use constant LOCK_UN => 8;

=pod

=item $b = WWW::BBSWatch->new

Arguments are:

C<-BBS_URL>: The URL of the bulletin board's index page. This field is
required.

C<-MAIL>: The email address to send mail to

C<-MDA>: Sets the mail delivery agent by calling MIME::Lite::send(HOW, HOWARGS).
If a scalar value is passed in, it is passed as send("sendmail", $mda_value). If
an array ref is provided, send(@$mda_value) is called.

C<-DB>: Basename of the database that keeps track of visited articles

C<-WARN_TIMEOUT>: Number of seconds before warning message is sent
proclaiming inability to contact BBS_URL page. Default is 10,800 (3 hours).

C<-MAX_ARTICLES>: Maximum number of articles to send in one
batch. Default is essentially all articles.

C<-VERBOSE>: Controls the amount of informative output. Useful values are 0, 1,
2. Default is 0 (completely silent).

=cut

sub new {
  my $class = shift;
  my %args = @_;

  # Normalize args
  foreach (keys %args) {
    my $new = uc($_);
    $new = "-$new" unless $new =~ /^-/;
    unless ($new eq $_) {
      $args{$new} = $args{$_};
      delete $args{$_};
    }
  }

  if ($args{-MDA}) {
    if (ref $args{-MDA}) {
      MIME::Lite::send(@{$args{-MDA}});
    } else {
      MIME::Lite::send("sendmail", $args{-MDA});
    }
  }

  my $self = {
    addr            => $args{-MAIL},
    warn_timeout    => $args{-WARN_TIMEOUT} || (3600 * 3),
    db              => $args{-DB} || 'BBSWatch',
    bbs_url         => $args{-BBS_URL},
    max_articles    => $args{-MAX_ARTICLES} || 999999999,
    verbose         => $args{-VERBOSE} || 0,
  };

  die "Must supply -BBS_URL" unless $self->{bbs_url};

  return bless $self, $class;
}

=pod

=item $b->retrieve([$catchup])

This method emails new bulletin board messages. If the optional parameter
I<catchup> is true, messages will be marked as read without being
emailed. Nothing useful will happen unless the C<article_list> method is
defined to return the list of articles from the BBS's index page.

B<WWW::BBSWatch> uses the B<LWP::UserAgent> module to retrieve the index and
articles. It honors firewall proxies by calling the
C<LWP::UserAgent::env_proxy> method. So if you are behind a firewall, define
the environment variable I<http_proxy> and your firewall will be handled
correctly.

=back

=cut

# In hindsight this is embarrassingly monolithic.
sub retrieve {
  my $self = shift;
  my $catchup = shift || 0;
  my %msgs = ();
  my $lock_file = $self->{db}."_lock";
  open(LOCK, ">".$lock_file) or die "Can't open lock file, '$lock_file': $!";
  flock(LOCK, LOCK_EX|LOCK_NB) or exit;

  tie %msgs, 'SDBM_File', $self->{db}, O_CREAT|O_RDWR, 0644;

  my $ua = LWP::UserAgent->new;
  $ua->env_proxy();

  my $res = $ua->request(HTTP::Request->new('GET', $self->{bbs_url}));
  if ($res->is_error) {
    my $now = time;
    if (defined($msgs{ERROR_TIME})) {
      if ($now - $msgs{ERROR_TIME} > $self->{warn_timeout}) {
        $self->_mail_error("Unable to retrieve the page\n",
           $self->{bbs_url},
           "\nfor over ${\($self->{warn_timeout}/3600.0)} hours. Will keep trying.\n",
           " ---- Server Error Response ----\n",
           $res->error_as_HTML,);
        $msgs{ERROR_TIME} = $now;
      }
    } else {
      $msgs{ERROR_TIME} = $now;
    }
  } else {
    my $err = '';
    my $content = $res->content;
    print STDERR "Retrieved index successfully.\n" if $self->{verbose} > 1;
    my @articles = $self->article_list(\$content);
    print STDERR "Found ", scalar(@articles), " articles.\n"
      if $self->{verbose} > 1;
    my $ct = 0;
    foreach my $art_url (sort @articles) {
      next if defined $msgs{$art_url} and $msgs{$art_url} > 0;
      if ($catchup) {
        print STDERR "Marking $art_url as read\n" if $self->{verbose};
        $msgs{$art_url} = time;
        exit if defined $self->{max_articles} and
          ++$ct >= $self->{max_articles};
        next;
      }
      $res = $ua->request(HTTP::Request->new('GET', $art_url));
      if ($res->is_success) {
        print STDERR "Sending $art_url\n" if $self->{verbose};
        my $content = $res->content;
        my ($type, $data) = $self->process_article(\$content);
        my %opts = (To      => $self->{addr},
                    Subject => $art_url,
                    Type    => $type,
                    Data    => $$data,
                    'Message-Id' => "<$art_url>");
        {
          # There is a very real and legitimate possibility of unitialized
          # values in this block. Turn off warnings.
          local $ = 0;
          my ($from, $name, $subj, $timestamp, $reference) =
            $self->get_header_info(\$content);
          my $new_from = 0;
          if ($from and $name) {
            $new_from = "\"$name\" <$from>";
          } elsif ($from) {
            $new_from = $from;
          } elsif ($name) {
            $new_from = "\"$name\"";
          }
          $opts{From} = $new_from if $new_from;
          $opts{Subject} = $subj if $subj;
          $opts{Date} = $timestamp if $timestamp;
          $opts{References} = "<$reference>" if $reference;
        }
        my $m = MIME::Lite->new(%opts);
        $m->send;
        $msgs{$art_url} = time;
        exit if defined $self->{max_articles} and
          ++$ct >= $self->{max_articles};
      } else {
        if (--$msgs{$art_url} <= -3) {
          $self->_mail_error("Trouble retrieving $art_url. Failed 3 times. Marking as read.\n", $res->error_as_HTML);
          $msgs{$art_url} = time;
        }
      }
    }
  }
  untie %msgs;
  flock(LOCK, LOCK_UN);
}

=pod

=head1 USER-REFINABLE METHODS

=over 4

=pod

=item $b->article_list($content_ref)

Method that returns a list of complete URLs for the articles on the bulletin
board. It is passed a reference to the contents of the bbs_url page. The base
version does not do anything.

=cut

sub article_list {
  return;
}

=pod

=item $b->get_header_info($content_ref)

Method that returns the header info for the message. It is passed a scalar
reference to the entire HTML for the message. The method should return a
list of

        * the poster's email address
        * the poster's name
        * the article's subject
        * the article's timestamp
        * any response-to message URL

Any values in the return list can be undef, but the more info returned, the
more useful the email headers will be. The base version of the method doesn't
do anything.

=cut

sub get_header_info {
  return;
}

=pod

=item $b->process_article($content_ref)

Method that is used to process the article before it is mailed. It is passed a
reference to the contents of the article. It should return a list of the MIME
type of the article and a reference to the contents of the article. For
example, you could refine this method to run the article through
B<HTML::FormatText> so that text messages are sent instead of HTML ones. The
default method returns the list of C<text/html> and its argument untouched.

=back

=cut

sub process_article {
  shift; # get rid of "$self"
  return ('text/html', @_);
}

################################# Internal methods #########################

sub _mail_error {
  my $self = shift;
  my @data = @_;

  if ($self->{addr}) {
    MIME::Lite->new(To=>$self->{addr}, Subject=>'BBSWatch Error!',
                    Type=>'TEXT', Data=>join('', @data))->send;
  }
}

##############################  End Internal methods ########################

1;

__END__

=pod

=head1 PRACTICAL EXAMPLES

Here are examples of how I personally use B<WWW::BBSWatch>. A useful assumption
is that WWW bulletin boards are programmatically generated so the HTML of the
articles tends to be very regular and predictable. This allows regular
expression matching when pulling header info or processing articles instead of
having to use B<HTML::Parser> or B<HTML::TreeBuilder>.

=head1 Monitoring the Perl Modules BBS

  package MyBBSWatch;

  use strict;
  use vars qw/@ISA/;
  use WWW::BBSWatch;
  @ISA = qw/WWW::BBSWatch/;

  sub get_header_info {
    my $self = shift;
    my $content_ref = shift;

    my ($name, $addr) =
      $$content_ref =~ m%<b>From</b>:\s*(.*) .*;<A HREF="mailto:(.*)">%m;
    $name =~ s/^"|"$//g;
    my ($subj) = $$content_ref =~ m%<H1>(.*)</H1>%m;
    my ($date) = $$content_ref =~ m%^<LI><b>Date</b>: (.*)</LI>$%m;
    $subj = "$subj [MODULES]"; # add tag for easy mail filtering
    return ($addr, $name, $subj, $date);
  }

  sub article_list {
    my $self = shift;
    my $content_ref = shift;

    my $base = $self->_base();
    return map { "$base/$_" }
      ($$content_ref =~ m%<A NAME="\d*" HREF="(msg\d*.html)">%sg);
  }

  # The index page of the Perl Modules list changes every month.
  # For everyone's benefit define a new method to figure out the index URL.
  sub _base {
    my ($y, $m) = (localtime)[5,4];
    return sprintf("http://www.xray.mpe.mpg.de/mailing-lists/modules/%4d-%02d",
                   $y+1900, $m+1);
  }

  package main;

  my $b = MyBBSWatch->new(
    -MAIL      =>'tayers',
    -BBS_URL   =>MyBBSWatch->_base()."/index.html",
    -DB        =>'/home/users/tayers/perl/.modules',
                         );

  $b->retrieve();

=head1 Monitoring two BBS's run from the same engine

  package TheOakBBSWatch;

  # To watch multiple bulletin boards using the same engine requires
  # defining only one subclass of WWW::BBSWatch since the bulletin board
  # engine will generate the various boards in the same general format

  use vars qw/@ISA/;
  use WWW::BBSWatch;
  @ISA = qw/WWW::BBSWatch/;

  sub get_header_info {
    my $self = shift;
    my $content_ref = shift;

    my ($name) = $$content_ref =~ m%Posted By: <BIG>(.*)</BIG>%m;
    $name =~ s/^"|"$//g; # strip double-quotes

    my ($addr) = $$content_ref =~ m%<A HREF="mailto:.*subject.*>(.*)</A>%m;

    my ($subj) = $$content_ref =~ m%<H1 ALIGN=CENTER>(.*)</H1>%m;
    $subj = "$subj $self->{tag}"; # add a tag for filtering mail

    my ($date) = $$content_ref =~ /.*Date: (.*)$/m;

    my ($parent) = $$content_ref =~ m%In Response To: <A HREF="([^"]*)"%m;

    return ($addr, $name, $subj, $date, $parent);
  }

  sub article_list {
    my $self = shift;
    my $content_ref = shift;
    return ($$content_ref =~ m%<A HREF="($self->{bbs_url}\?read=\d*)%gs);
  }

  # Send articles from these bulletin boards as plain text. Hack the
  # HTML::FormatText to print out the href link as well as the "title". (Is
  # there a proper way to do this?) Changing the behavior this way works in
  # practice because the interesting links in BBS messages (the links that
  # people include in their message) are almost always fully specified. In
  # general this won't work since most links in documents are relative so
  # you need to keep track of the base.
  # Redefine the function in a backhanded way to suppress the "Subroutine
  # redefined" warning.
  use HTML::TreeBuilder;
  use HTML::FormatText;
  {
    local $ = 0;
    *HTML::Formatter::a_start = sub {
      my ($self, $el) = @_;
      $self->out($el->attr('href')." - ");
      $self->{anchor}++;
      1;
    };
    *HTML::Formatter::img_start = sub {
      my ($self, $el) = @_;
      $self->out($el->attr('src')." - ".($el->attr('alt') || "[IMAGE]"));
    };
  }

  sub process_article {
    my $self = shift;
    my $content_ref = shift;

    $$content_ref =~ s%<H2 ALIGN=CENTER><A NAME="Responses">.*$%</BODY></HTML>%s;
    $$content_ref =~ s%<A NAME="PostResponse"></A>.*$%</BODY></HTML>%s;

    my $tree = HTML::TreeBuilder->new->parse($$content_ref);
    $tree->eof;
    my $text = HTML::FormatText->new(leftmargin=>0)->format($tree);
    $tree->delete;
    return ('text/plain', \$text);
  }

  package main;

  # Advertise the firewall
  $ENV{http_proxy} = 'http://httpproxy:411';

  # Grab the general list
  my $b = TheOakBBSWatch->new(
    -MAIL      =>'tayers',
    -BBS_URL   =>'http://theoak.com/cgi-bin/forum/general.pl',
    -DB        =>'/home/users/tayers/perl/general',
    -MAX_ARTICLES => 250,
    -VERBOSITY =>0,
                         );

  # Break OO design by using knowledge of the underlying data structure.
  # The correct way is to refine new() and pass in -TAG, but this is
  # SO MUCH easier. (Famous last words!) The 'tag' is used in the
  # get_header_info method.
  $b->{tag} = "[OAK-GEN]";

  $b->retrieve();

  # Grab the Tools list
  $b = TheOakBBSWatch->new(
    -MAIL      =>'tayers',
    -BBS_URL   =>'http://theoak.com/cgi-bin/tools1/tools1.pl',
    -DB        =>'/home/users/tayers/perl/tools',
    -MAX_ARTICLES => 250,
    -VERBOSITY =>0,
                         );

  $b->{tag} = "[OAK-TOOL]";

  $b->retrieve();

=head1 SEE ALSO

L<perlre>. At least a passing knowledge of regular expressions helps quite a
bit.

=head1 AUTHOR

 This module was written by
 Tim Ayers (http://search.cpan.org/search?author=TAYERS).

=head1 COPYRIGHT

Copyright (c) 2000, 2001 Tim R. Ayers. All rights reserved. 

=head1 LICENSE

This program is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

=cut
