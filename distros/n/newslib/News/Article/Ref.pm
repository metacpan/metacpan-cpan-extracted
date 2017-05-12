$VERSION = "0.2";
package News::Article::Ref;
our $VERSION = "0.2";

# -*- Perl -*-
#############################################################################
# Written by Tim Skirvin <tskirvin@killfile.org>.  Copyright 2000-2002, Tim 
# Skirvin.  Redistribution terms are below.
#############################################################################

=head1 NAME

News::Article::Ref - reference functions for news articles

=head1 SYNOPSIS

  use News::Article::Ref;

  my $date = "Wed, 06 Mar 2002 11:23:10 -0600";
  my $gooddate = News::Article::Ref->valid_date($date);

  my $messageid = '<godwin-20020306172310$31f9@news.killfile.org>';
  my $goodmid = News::Article::Ref->valid_messageid($messageid);

Further functions are below.

=head1 DESCRIPTION

News::Article::Ref is a module for determining if a news article is
technically suited for Usenet - ie, it checks to see if it follows all of
Usenet's technical rules, as set down in the RFCs.  This is useful for
moderation 'bots and other news processing.

The current specifications are based on a combination of RFC1036 and
RFC1036bis.  This probably isn't the best idea, but it works for now.

News::Article::Ref exports nothing.

=head1 USAGE

=cut

###############################################################################
### main() ####################################################################
###############################################################################

use Net::Domain qw(hostfqdn);
use strict;
use vars qw($VERSION $DEBUG);
$VERSION = "0.1a";
$DEBUG   = "0";

###############################################################################
### VARIABLES #################################################################
###############################################################################
## There are lots of variables here.  Most of them are for use in regular 
##   expressions later down the line.

use vars qw( $GROUP_CHARS $TAG_CHAR $CODE_CHAR $CHARSET $ENCODING $CODES
    $ENCODED_WORD $UNQUOTED_CHAR $QUOTED_CHAR $PAREN_CHAR $UNQUOTED_WORD 
    $QUOTED_WORD $PLAIN_WORD $PAREN_PHRASE $PLAIN_PHRASE $LOCAL_PART $DOMAIN 
    $ADDRESS $RELAYER $NONBLANK $NAMECOMPONENT );

$GROUP_CHARS   = '[a-zA-Z0-9_+-]';	
$TAG_CHAR      = '[^!\(\)<>@,\;:\\"\[\]\/\?=]+';
$ENCODING      = $TAG_CHAR;
$CODES         = '[^\?]+';
$ENCODED_WORD  = join('', '=\?',$CHARSET,'\?',$ENCODING,'\?',$CODES,'\?=');
$UNQUOTED_CHAR = '[^!\(\)<>@,\;:\\\"\.\[\]]';
$QUOTED_CHAR   = '[^"\(\)\\<>]';  
$PAREN_CHAR    = '[^\(\)\\<>]';
$UNQUOTED_WORD = $UNQUOTED_CHAR . '+';
$QUOTED_WORD   = '"' . $QUOTED_CHAR . '+"';
$PLAIN_WORD    = join('', '(?:', $UNQUOTED_WORD, '|', $QUOTED_WORD, 
						 '|', $ENCODED_WORD, ')');
$PLAIN_PHRASE  = $PLAIN_WORD . '(?: ' . $PLAIN_WORD . ')*';
$PAREN_PHRASE  = join('', '(?:', $ENCODED_WORD, '|\s|', $PAREN_CHAR, ')+');
$LOCAL_PART    = $UNQUOTED_WORD . '(?:\.' . $UNQUOTED_WORD . ')*';
$DOMAIN        = $UNQUOTED_WORD . '(?:\.' . $UNQUOTED_WORD . ')*';
$ADDRESS       = join('@', $LOCAL_PART, $DOMAIN);
$RELAYER       = '[a-zA-Z0-9=.-_]+';
$NONBLANK      = '\s*\S.*';
$NAMECOMPONENT = '[a-zA-Z0-9][a-zA-Z0-9_\+-]+';

###############################################################################
### METHODS ###################################################################
###############################################################################

=head2 Validation Methods 

The following methods validate the information already in a header - ie,
they check to see if it's valid with current Usenet specifications.  This
may be more or less restrictive than any given news server will require, but
it's a good general rule to follow the rules regardless.

=over 4

=item valid_header ( HEADER, CONTENTS )

Verifies that the B<CONTENTS> of B<HEADER> are valid.  Checks 
From, Subject, Newsgroups, Message-ID, Path, Date, Followup-to, Expires, 
Reply-To, Sender, References, Control, Distribution, Summary, Approved,
Lines, Organization, and Supersedes; all other headers are assumed to be
unnecessary but okay.  

Note that many of these functions are available below.  

=cut

sub valid_header {
  my ($self, $header, $contents) = @_;
  return 0 unless ($header && $contents);
  if (lc $header eq 'from')          { $self->valid_from($contents) }  
  elsif (lc $header eq 'subject')    { $self->valid_subject($contents) }
  elsif (lc $header eq 'newsgroups') { $self->valid_newsgroups($contents) }
  elsif (lc $header eq 'message-id') { $self->valid_messageid($contents) }
  elsif (lc $header eq 'path')       { $self->valid_path($contents) }
  elsif (lc $header eq 'date')       { $self->valid_date($contents) }
  elsif (lc $header eq 'followup-to') { 
    return 1 if $contents eq 'poster';
    $self->valid_header('newsgroups', $contents);
  }
  elsif (lc $header eq 'expires')  { $self->valid_header('date', $contents) }
  elsif (lc $header eq 'reply-to') { $self->valid_header('from', $contents) }
  elsif (lc $header eq 'sender')   { $self->valid_header('from', $contents) }
  elsif (lc $header eq 'references') {
    foreach (split(/\s+/, $contents)) {
      return 0 unless $self->valid_header('message-id', $_);
    }
    1;
  }
  elsif (lc $header eq 'control') { $self->valid_control($contents) }
  elsif (lc $header eq 'distribution' || lc $header eq 'keywords') { 
    foreach (split(',', $contents)) { 
      return 0 unless ($contents =~ /^$NAMECOMPONENT$/);
    }
    1;
  }
  elsif (lc $header eq 'summary')  { $contents =~ /^$NONBLANK$/s ? 1 : 0 }
  elsif (lc $header eq 'approved') { 
    foreach (split(',', $contents)) { 
      return 0 unless $self->valid_header('from', $_);
    }
    1;
  }
  elsif (lc $header eq 'lines') { $contents =~ /^\d+$/ ? 1 : 0 } 
  elsif (lc $header eq 'organization') { $contents =~ /^$NONBLANK$/ ? 1 : 0 }
  elsif (lc $header eq 'supersedes') { 
    $self->valid_header('message-id', $contents) 
  }
  else { 1 }	# We don't mess with other headers
}

=item valid_headers ( HEADERS )

Takes an array of headers B<HEADERS>, and verifies that together they make
up a valid set of headers for a news article.  This means, in general, that
each header is valid, and that enough headers are there to be posted.  Takes
advantage of B<valid_headers()>.  Returns 1 if valid, 0 otherwise.

=cut

sub valid_headers { 
  my ($self, @headers) = @_;
  
  my (%headers, $prev);
  foreach (@headers) { 
    chomp;
    return 0 unless ($_ =~ /^(?:(\S+):\s*(.*)|\s+(.*))$/);
    my $header = lc $1 || $prev;  return 0 unless $header;
    my $contents = $2 || $3;
    return 0 if $headers{$header} && defined $2;
    $headers{$header} = 
	$headers{$header} ? join("\n	", $headers{$header}, $contents)
 			  : $contents;
    $prev = $header;
  }
  
  # Need newsgroups, subject, from, message-id, date
  return 0 unless $headers{'newsgroups'};
  return 0 unless $headers{'subject'};
  return 0 unless $headers{'from'};
  return 0 unless $headers{'message-id'};
  return 0 unless $headers{'date'};
  # return 0 unless $headers{'path'};

  # Can't have both a Supersedes: and Control:
  return 0 if $headers{'control'} && $headers{'supersedes'};

  foreach (keys %headers) {
    return 0 unless $self->valid_header($_, $headers{$_});
  }
  
  1;
}

=item valid_body ( BODY )

Verifies that B<BODY> is a valid message body for the article.  Currently
just checks to make sure that there *is* a body; this may change later.
Returns 1 if valid, 0 otherwise.

=cut

sub valid_body {
  my ($self, @lines) = @_;
  return 0 unless scalar @lines;
  1;
}

=item valid_article ( ARTICLE )

Takes a whole B<ARTICLE> as input, and does both B<verify_headers()> and
B<verify_body()> on it.  Returns 1 if the article is valid, 0 otherwise.

=cut

sub valid_article {
  my ($self, @lines) = @_;
  my ($count, @headers, @body);
  foreach (@lines) {
    chomp;
    if (/^$/) { $count++; next; }
    $count ? push @body, $_ : push @headers, $_;
  }
  $self->valid_headers(@headers) && $self->valid_body(@body);
}


=item valid_messageid ( ID )

Determines whether B<ID> is a valid Message-ID, which is of the general form
'<unique.string4159@site.com.invalid>'.  Returns 1 if yes, 0 otherwise.  

=cut

sub valid_messageid { $_[1] =~ /^<$LOCAL_PART\@$DOMAIN>$/ ? 1 : 0; }

=item valid_date ( DATE )

Determines whether B<DATE> is a valid Date header, which is of the general
form 'Wed, 06 Mar 2002 11:23:10 -0600'.  Returns 1 if yes, 0 otherwise.

=cut

sub valid_date { 
  my ($self, $date) = @_;
  return 0 unless $date;
  $date =~ m/^
	      (\w{3},?\s*)?					# Day of Week
              ((\d{1,2})\s*(\w{3})| (\w{3})\s*(\d{1,2}))\s*     # Day and Month
              (\d{2,5})?\s*                  			# Year, maybe.
              (\d\d):(\d\d):(\d\d)\s*        			# H,M,S
              ([^\d\s]\S+)?\s*               			# Timezone
              (\d{2,5})?\s*(.*)?\s*                		# Year+TZ
		/sx ? 1 : 0;
}



=item valid_from ( ADDRESS )

Verifies that the email address is "valid" - not that it delivers, but that
it follows the proper form.  B<ADDRESS> can take one of three forms:

  tskirvin@killfile.org
  Tim Skirvin <tskirvin@killfile.org>
  tskirvin@killfile.org (Tim Skirvin)

Returns 1 if valid, 0 otherwise.

=cut

sub valid_from {
  my ($self, $address) = @_;
  $address =~ /^(?:\"?($PLAIN_PHRASE)?\"?\s*<($ADDRESS)>|
               ($ADDRESS)\s*(?:\(($PAREN_PHRASE)\))?)$/sx ? 1 : 0;
}

=item valid_path ( PATH )

Determines if B<PATH> is valid for the Path: header.  Takes the form
'news.meat.net!news.killfile.org!local-form'.  Returns 1 if valid, 0
otherwise.

=cut

sub valid_path {
  my ($self, $path) = @_;
  my @contents = split('!', $path);
  my $local = pop @contents;  return 0 unless ($local =~ /^$LOCAL_PART$/);
  foreach (@contents) { return 0 unless /^$RELAYER$/ }
  1;
}

=item valid_groupname ( GROUPNAME )

Determines if the given B<GROUPNAME> is a valid newsgroup name - letters and
numbers only, with '.' as a separator.  Returns 1 if valid, 0 otherwise.

=cut

sub valid_groupname { $_[1] =~ /^$GROUP_CHARS+(\.$GROUP_CHARS+)*$/ ? 1 : 0; }

=item valid_newsgroups ( NEWSGROUPS )

Determines of B<NEWSGROUPS> is a valid Newsgroups: header - each group name
must be separated by only a comma, and new groups can be repeated.  Returns
1 if valid, 0 otherwise.

=cut

sub valid_newsgroups {
  my ($self, $groups) = @_;
  return 0 unless $groups;
  my %groups;
  foreach my $group (split(',', $groups)) {
    return 0 unless $self->valid_groupname($group);
    return 0 if $groups{$group};	# Can't repeat newsgroup names
    $groups{$group}++; 
  }
  1;
}

=item valid_subject ( SUBJECT )

Determines if B<SUBJECT> is a valid subject header.  This isn't too tough -
it just has to be not blank.  Returns 1 if valid, 0 otherwise.

=cut

sub valid_subject { $_[1] =~ /^$NONBLANK$/ ? 1 : 0 }

=item valid_control ( LINE )

Determines if B<LINE> is a valid Control: header.  This is fairly tricky,
because there are many types of control headers:
 
  cancel MESSAGEID
  ihave  MESSAGEID [HOST]
  sendme MESSAGEID [HOST]
  newgroup GROUPNAME [moderated|unmoderated]
  rmgroup GROUPNAME
  sendsys 
  version
  checkgroups

Returns 1 if valid, 0 otherwise.
 
=cut

sub valid_control {
  my ($self, $line) = @_;
  if ($line =~ /^([a-zA-Z0-9]+)((?:\s+\S+)*)\s*$/) {
    my $verb = lc $1;  my $args = $2;
    if ($verb eq 'cancel') { $self->valid_messageid($2) ? 1 : 0 }
    elsif ($verb eq 'ihave') {
      my @args = split(/\s+/, $args);
      return 0 unless $self->valid_messageid($args[0]);
      return 0 unless (!$args[1] || $args[1] =~ /^$RELAYER$/);
      return 0 if (scalar @args > 1);
      return 1;
    }
    elsif ($verb eq 'sendme') {
      my @args = split(/\s+/, $args);
      return 0 unless $self->valid_messageid($args[0]);
      return 0 unless (!$args[1] || $args[1] =~ /^$RELAYER$/);
      return 0 if (scalar @args > 1);
      return 1;
    } 
    elsif ($verb eq 'newgroup') { 
      my @args = split(/\s+/, $args);
      return 0 unless $self->valid_groupname($args[0]);
      return 0 if ($args[1] && $args[1] !~ /^(moderated|unmoderated)$/);
      return 0 if (scalar @args > 1);
      1;
    } 
    elsif ($verb eq 'rmgroup')     { $self->valid_groupname($args) ? 1 : 0 }
    elsif ($verb eq 'sendsys')     { $args ? 0 : 1 }
    elsif ($verb eq 'version')     { $args ? 0 : 1 } 
    elsif ($verb eq 'checkgroups') { $args ? 0 : 1 }
    else { 0 } 
  }
}

=back

=head2 Create-New-Entry Methods

The following methods can be used to create new data suitable for using in
article headers.  

=over 4

=item create_messageid ( [ PREFIX [, DOMAIN ]] )

Creates a valid message-ID based on B<PREFIX>, B<DOMAIN>, and the
current time.  Based on B<add_message_id()> from News::Article.

=cut

sub create_messageid {
  my ($self, $prefix, $domain) = @_;
  $prefix ||= "";  
  $domain ||= hostfqdn() || 'broken-configuration';

  my ($sec,$min,$hr,$mday,$mon,$year) = gmtime(time); ++$mon;
  sprintf('<%s%04d%02d%02d%02d%02d%02d$%04x@%s>', $prefix, $year+1900, 
     $mon, $mday, $hr, $min, $sec, 0xFFFF & (rand(32768) ^ $$), $domain);
}

=item create_date ( [TIME] )

Creates a valid Date: header from B<TIME> (seconds since the epoch), or 
the current time if not offered.  Based on B<add_date()> from News::Article.

=cut

sub create_date {
  my ($self, $time) = @_; 	$time ||= time;
  my ($sec,$min,$hr,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($time);
  my ($gsec,$gmin,$ghr,$gmday) = gmtime($time);

  # mystic incantations to calculate zone offset from difference
  # between UTC and local time. Assumes that difference is not more
  # than a full day (saves having to take months into consideration).
  # ANSI is apparently going to add a spec to strftime() to do this,
  # but that isn't yet commonly available.

  use integer;
  $gmday = $mday + ($mday <=> $gmday) if (abs($mday-$gmday) > 1);
  my $tzdiff = 24*60*($mday-$gmday) + 60*($hr-$ghr) + ($min-$gmin);
  my $tz = sprintf("%+04.4d", $tzdiff + ($tzdiff/60*40));

  $mon = (qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec))[$mon];
  $wday = (qw(Sun Mon Tue Wed Thu Fri Sat Sun))[$wday];
  $year += 1900;
  sprintf("%s, %02d %s %d %02d:%02d:%02d %s",
          $wday,$mday,$mon,$year,$hr,$min,$sec,$tz);
}

=back

=head1 TODO

Put some clean_* functions somewhere - ie B<clean_date()>, which would make
a canonical date header for the article based on whatever it's offered.
This wouldn't necessarily go in this module, though.

Include some debugging information, so that the user can determine *how*
there were problems.  This will involve some major re-writes.

Choose which RFC to follow.  

=head1 AUTHOR

Tim Skirvin <tskirvin@killfile.org>

=head1 COPYRIGHT

This code may be distributed under the same terms as Perl itself.

=cut

###############################################################################
### Version History ###########################################################
###############################################################################
# v0.1a 	Thu Mar  7 17:07:20 CST 2002
### First commented version.
# v0.2		Thu Apr 22 11:40:48 CDT 2004 
### No real changes, just version numbers.
