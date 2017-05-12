$VERSION = '0.71';
package News::Article::Cancel;
our $VERSION = '0.71';

# -*- Perl -*- Thu Apr 22 10:49:53 CDT 2004 
#############################################################################
# Written by Tim Skirvin <tskirvin@killfile.org>.
# Based on a script by Chris Lewis <clewis@bnr.ca>, and relying almost
# exclusively on the News::Article package written by Andrew Gierth 
# <andrew@erlenstar.demon.co.uk>.  Thanks, folks. 
# 
# Copyright 2000-2004 Tim Skirvin.  Redistribution terms are in the
# documentation, and I'm sure you can find them.
#############################################################################

=head1 NAME

News::Article::Cancel - a module to generate accurate cancel messages 

=head1 SYNOPSIS

  use News::Article::Cancel;
  my $article = new News::Article::Cancel(\*STDIN);
  next if $article->verify_resurrected($GROUP);

  my $from    = $article->header('from') || "";
  my $subject = $article->header('subject') || "";
  my $xauth   = $article->header('x-auth') || "";
  my $mid     = $article->header('message-id') || "";
  my $cancel = $article->make_cancel( $NAME, "moder",
                "From: $from", "Subject: $subject", "Message-ID: $mid",
                "X-Auth: $xauth");

=head1 DESCRIPTION

Creates a cancel message based on a Usenet article, which may be posted
normally to delete a message.  Also adds a verification for reposted
messages in moderated newsgroups.

=head1 USAGE

=over 2

=item use News::Article::Cancel;

=back

News::Article::Cancel is class that inherits News::Article and adds two
new functions: make_cancel() and verify_resurrected().

=cut

require 5;			# Requires Perl 5

use News::Article;
use Exporter;
use strict;

use vars qw($KILL_CANCELS @ISA @EXPORT @EXPORT_OK );

@ISA = qw( Exporter News::Article );

=head2 Article Methods

=over 4

=item make_cancel ( CANCELLER TYPE [TEXT] )

Creates a cancel message based on the current article and the given
C<TYPE>.  C<CANCELLER> is the email address of the poster, and is
required; C<TEXT> is an array of lines which will be appended to cancel
message's body.  C<TYPE> determines several characteristics of the cancel
message, and must be one of the following (not case sensitive):

=over 2

- spam      - Spam, EMP, or ECP cancel.

- spew      - Spew cancel.

- aup       - Cancel by poster's service provider.

- personal  - Original article posted by user.

- mmf       - Make.Money.Fast cancel.

- binary    - Binary in a non-binary group.

- moderator - Cancel by group moderator.

- retromod  - Cancel by group retromoderator.

- forgery   - Forged article.

- request   - Cancel by poster's request.

=back

make_cancel returns a News::Article object if successful, or an error
message if not.

=cut

sub make_cancel {
  my $self = shift;
  my ($canceller, $type, @text) = @_;

  return "No canceller given" unless $type;

  my ($PATH, $PREFIX, @BODY);
  my $RAND = rand(32767);  	# A random number for message-ids
     $RAND =~ s/\..*//;		

  my $cancel = new News::Article;

  # Decide what kind of cancel this will be, based on $type
  if      ($type =~ /^(spam|emp|ecp)/i) {
    $PATH   = "cyberspam!not-for-mail";
    $PREFIX = "cancel.";
    @BODY   = "Spam cancelled by $canceller";
  } elsif ($type =~ /^spew/i) {
    $PATH   = "spewcancel!cyberspam!not-for-mail";
    $PREFIX = "cancel.";
    @BODY   = "Spew cancelled by $canceller";
  } elsif ($type =~ /^(mmf|make-)/i) {
    $PATH   = "mmfcancel!cyberspam!not-for-mail";
    $PREFIX = "cancel.";
    @BODY   = "Make Money Fast cancelled by $canceller.";
  } elsif ($type =~ /^binar/i) {
    $PATH   = "bincancel!cyberspam!not-for-mail";
    $PREFIX = "cancel.";
    @BODY   = "Binary in a non-binary group cancelled by $canceller";
  } elsif ($type =~ /^moder/i) {
    $PATH   = "not-for-mail";
    $PREFIX = "can.$RAND.";
    @BODY   = 
	"Moderation approval forged (or in error) cancelled by $canceller";
  } elsif ($type =~ /^retro/i) {
    $PATH   = "retromod!cyberspam!not-for-mail";
    $PREFIX = "cancel.";
    @BODY   = "Article cancelled from retromoderated group by $canceller";
  } elsif ($type =~ /^forge/i) {
    $PATH   = "not-for-mail";
    $PREFIX = "can.$RAND.";
    @BODY   = "Forged message cancelled by $canceller.";
  } elsif ($type =~ /^personal/i) {
    $PATH   = "not-for-mail";
    $PREFIX = "can.$RAND.";
    @BODY   = "Personal message cancelled by $canceller";
  } elsif ($type =~ /^(aup|isp|tos)/i) {
    $PATH   = "not-for-mail";
    $PREFIX = 'cancel.';
    @BODY   = "Post in violation of terms-of-service cancelled by $canceller";
  } elsif ($type =~ /^request/i) {
    $PATH   = "not-for-mail";
    $PREFIX = "can.$RAND.";
    @BODY   = "Cancelled at original poster's request by $canceller";
  } else {
    return "Cancel-type \"$type\" not recognized";
  }
  
  # Create headers for the cancel and test to make sure a cancel is allowed.
  return "No cancel issuer" unless $canceller;
  if (defined $self->header('control') && $self->header('control') =~/cancel/) {
    return "Shouldn't try to cancel cancels, often loops" unless $KILL_CANCELS;
  }

  my @GROUPS = split /\s*,+\s*/, $self->header('newsgroups') ;
  @GROUPS = grep !/test$/, @GROUPS;	# Don't post to *.test
  @GROUPS = "news.admin.misc" unless @GROUPS; 	# Default group
  return "No newsgroups for cancel" unless @GROUPS;

  my $id = $self->header('message-id');
  my $newid = $id;
     $newid =~ s/^\s*<(.*)>\s*$/<$PREFIX$1>/;
  return "Missing or bad Message-ID" unless ($id && $newid);
  
  my $from = $self->header('sender') || $self->header('from');
     # THIS IS A HACK.  Ick ick ick!  - Tue Jan 25 00:57:05 CST 2000
     $from = $self->header('from') unless ($from =~ /\S+\@\S+/);
     # $from =~ s/\(/</g; $from =~ s/\)/>/g;      # MORE HACK
     $from =~ s/(\S+\@[^.\s]+)/$1.com/g;
     # $from =~ s/<\s*(.*)\s*>/<$1>/g;
     $from = "\"$from\" <nobody\@nowhere.com>" unless $from =~ /@/;
  return "Can't find original From" unless $from;

  # Set the headers and body of the cancel
  $cancel->set_headers('Newsgroups', join(',', @GROUPS));
  $cancel->set_headers('Path', $PATH || "");
  $cancel->set_headers('Message-ID', $newid || "");
  # $cancel->set_headers('From', $canceller);		# More accurate
  $cancel->set_headers('From', $from || "");
  $cancel->set_headers('Sender', $from || "");
  $cancel->set_headers('Control', "cancel $id" || "");
  $cancel->set_headers('Subject', "cmsg cancel $id" || "");
  $cancel->set_headers('Approved', $canceller || "");
  $cancel->set_headers('X-Cancelled-By', $canceller || "");
  $cancel->add_date;

  $cancel->set_body(@BODY, @text);
  
  return $cancel;
}
push @EXPORT, qw( make_cancel );

=over 4

=item verify_resurrected ( GROUP )

Does the same thing as C<verify_pgpmoose()>, but reformats the message for
a message reposted by Dave the Resurrector.  

=back

=cut

sub verify_resurrected {
  my ($self, $group) = @_;
  my $newarticle = new News::Article;

  my ($line, @oldbody);
  my $oldfrom = $self->header('from') || "";
  my $oldsubject = $self->header('subject') || "";
     $oldsubject =~ s/^\s*REPOST:\s//;
  my $oldid = $self->header('X-Original-Message-ID') || "";
  my $oldxauth = $self->header('X-Auth') || "";
  my $oldgroups = $self->header('newsgroups') || "";

  foreach $line ($self->body) {
    last if $line =~ /^========= WAS CANCELLED BY =======:$/;
    push (@oldbody, $line);
  }

  $newarticle->set_headers('from', $oldfrom, 'subject', $oldsubject,
                           'message-id', $oldid, 'x-auth', $oldxauth,
                           'newsgroups', $oldgroups);
  $newarticle->set_body( @oldbody );

  $newarticle->verify_pgpmoose($group);
}
push @EXPORT, qw( verify_resurrected );

=head1 NOTES

Standard article manipulation information can be read in the News::Article
manpages.  

Cancel messages are not toys.  Before using this module, all users should
have a good idea of how cancels work, what they are used for, and what the
results of their actions may be.  This information can be found in the
Cancel Messages FAQ, posted monthly to news.answers and available on the
web at <URL:http://www.killfile.org/faqs/cancel.html>.

=head1 TODO

Make sure I've got all of the different cancel types taken care of.

=head1 SEE ALSO

B<pgpmoose>, at B<http://www.killfile.org/~tskirvin/software/pgpmoose/>

=head1 AUTHOR

Written by Tim Skirvin <tskirvin@killfile.org>, based on a shell script by
Chris Lewis <clewis@bnr.ca>.  

=head1 COPYRIGHT

Copyright 2000-2004 by Tim Skirvin <tskirvin@killfile.org>.  This code may
be redistributed under the same terms as Perl itself.

=cut

###############################################################################
### Version History ###########################################################
###############################################################################
# v0.1a		Thu Apr 22 13:45:25 CDT 1999
### First version.  Unfinished, but it needs to be here so that I can get
### pgpmoose.pl working again.
# v0.2a 	Wed Jul  7 19:28:17 CDT 1999
# Got the documentation done and fixed stuff up in general.  
# v0.5b 	Mon Feb  7 17:10:35 CST 2000
### Put it up on the website, made a few cosmetic changes.  Need to work on 
### an installation script and stuff soon.
# v0.6b 	Fri Feb 11 16:27:41 CST 2000
### Added verify_resurrected.  We'll see what happens.
# v0.61b 	Mon Mar 13 18:08:57 CST 2000
### Made some more hacks on the "make a from line" code.  Ick.
# v0.70b 	Fri Feb 13 16:22:47 CST 2004 
### Why was I using News::Article namespace?  I suck.  Oh well.
# v0.71		Thu Apr 22 10:48:48 CDT 2004 
### Cleaning up the code and comments to match my normal work.  Generally
### matching things to the new version of pgpmoose.  Better docs.

1;
