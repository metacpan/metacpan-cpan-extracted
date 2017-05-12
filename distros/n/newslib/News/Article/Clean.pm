$VERSION = "1.02";
package News::Article;
our $VERSION = "1.02";

# -*- Perl -*- # Mon Mar 22 11:34:43 CST 2004 
###############################################################################
# Written by Tim Skirvin <tskirvin@killfile.org>
# Copyright 1996-2004 Tim Skirvin.  Redistribution terms are in the
# documentation, and I'm sure you can find them.
###############################################################################

=head1 NAME

News::Article::Clean - subroutines to clean news article headers

=head1 SYNOPSIS

  use News::Article::Clean;
  my $article = new News::Article;
  $article->set_headers('References', 
		$article->clean_header( 'References' );

  my $references = News::Article->clean_references($refstring);

See below for more subroutines.

=head1 DESCRIPTION

News::Article::Clean is a package that helps clean up news articles for
future posting.  It can be used as part of a pre-posting script for local
users, or as part of a moderation suite.  It is intended as an add-on for
News::Article.

=head1 USAGE

=cut


###############################################################################
### main() ####################################################################
###############################################################################

use strict;
use Date::Parse;
use News::Article;
use Net::Domain qw(hostfqdn);
use vars qw($MY_PREFIX $MY_DOMAIN $MAX_REFERENCES);

$MAX_REFERENCES = 10;
$MY_DOMAIN      = $ENV{'HOSTNAME'} || hostfqdn() || 'broken-configuration';
$MY_PREFIX      = "";
 
use vars qw( $GROUP_CHARS $TAG_CHAR $CODE_CHAR $CHARSET $ENCODING $CODES	
    $ENCODED_WORD $UNQUOTED_CHAR $QUOTED_CHAR $PAREN_CHAR $UNQUOTED_WORD
    $QUOTED_WORD $PLAIN_WORD $PAREN_PHRASE $PLAIN_PHRASE $LOCAL_PART $DOMAIN 
    $ADDRESS $FROM_CONTENT );

# Define the various character strings that are allowed in Usenet headers.  
# All of this was found in RFC1036bis, which was probably fairly
# accurate a few years ago; future versions may want to fix this up.
# Also, it might be nice to use '' instead of "", to get rid of some of 
# the escaping.

$GROUP_CHARS   = "[a-zA-Z0-9_+-]";
$TAG_CHAR      = "[^!\\\(\\\)<>\\\@,:\\\;\\\"\\\[\\\]\\\/\\\?\\\\\\\\\=]";
$CODE_CHAR     = "[^\\\?]";
$CHARSET       = $TAG_CHAR . "+";
$ENCODING      = $TAG_CHAR . "+";
$CODES         = $CODE_CHAR . "+";
$ENCODED_WORD  = "\"=\\\?" . $CHARSET . "\\\?" . $ENCODING . "\\\?" .
                                              $CODES . "?=\\\"";
$UNQUOTED_CHAR = "[^!\\\(\\\)<>\\\@,\\\;:\\\\\\\\\"\\\.\\\[\\\]]";
$QUOTED_CHAR   = "[^\\\"\\\(\\\)\\\\\\<>]";  # needs a \?  Find out later.
$PAREN_CHAR    = "[^\\\(\\\)<>\\\\]";
$UNQUOTED_WORD = $UNQUOTED_CHAR . "+";
$QUOTED_WORD   = "\"" . $QUOTED_CHAR . "+\"";
$PLAIN_WORD    = "(?:" . $UNQUOTED_WORD . "|" . $QUOTED_WORD . "|" .
                                                 $ENCODED_WORD . ")";
$PAREN_PHRASE  = '(?:' . $PAREN_CHAR . '|\s|' . $ENCODED_WORD . ')+';
$PLAIN_PHRASE  = $PLAIN_WORD . "(?: " . $PLAIN_WORD . ")*";
$LOCAL_PART    = $UNQUOTED_WORD . "(?:\." . $UNQUOTED_WORD . ")*";
$DOMAIN        = $UNQUOTED_WORD . "(?:\." . $UNQUOTED_WORD . ")*";
$ADDRESS       = $LOCAL_PART . "\@" . $DOMAIN;

=head2 Subroutines

This package offers the following subroutines within News::Article:

=over 4

=item clean_newsgroups ( STRING [, STRING [, STRING [...]]] )

Takes an array of strings containing newsgroup names (separated by commas,
as per standard Newsgroups: format), and returns either an array of valid
newsgroup names or (in scalar context) a string with these names
concatenated with ',' - ie, a proper Newsgroups: header.

=cut

sub clean_newsgroups {
  my ($self, @groups) = @_;

  my %groups = ();
  foreach ( split(/\s*,\s*|\s+/, join(',', @groups) ) ) {
    s/\s+//g;	# Trim whitespace
    if (/^$GROUP_CHARS+(\.$GROUP_CHARS+)*$/) { $groups{$_}++ }
  }
  wantarray ? keys %groups : join(',', keys %groups);
}

=item clean_followupto ( STRING [, STRING [, STRING [...]]] )

Same as clean_newsgroups, except that, if any of the strings are "poster",
then it just returns "poster".

=cut

sub clean_followupto { 
  my ($self, @groups) = @_;
  @groups = $self->clean_newsgroups(@groups); 
  return "poster" if grep { $_ eq 'poster' } @groups;
  wantarray ? @groups : join (',', @groups);
}

=item clean_references ( MAXREF, STRING [, STRING [, STRING [...]]] )

Takes an array of strings containing message-IDs, and tries to manage them
into a reasonable References: line.  Message-IDs that don't patch RFC
standards are trimmed; also only keeps C<MAXREF> references (defaults to
$News::Article::MAX_REFERENCES), trimming the extra to a single ID of the
format <trimmed-C<COUNT>@C<HOSTNAME>> (C<COUNT> is the total number of
trimmed messages, and C<HOSTNAME> is taken from $News::Article::MY_DOMAIN).
Returns an array of complete References or (in scalar context) a string
formatted for 80 columns, useful in the References: header.

=cut

sub clean_references {
  my ($self, $maxref, @refs) = @_;
  $maxref ||= $MAX_REFERENCES;
  my $value = join(' ', @refs) || $self->header('references');
  
  my ($trimmed, @refs, %refs);
  foreach (split('\s+|\s*,\s*|>\s*<', $value)) {
    s/\s//g;			# Wipe the whitespace.
    s/^/</ unless /^</;		# Adds in the <'s and >'s if necessary.
    s/$/>/ unless />$/;
    next if $refs{$_}++;

    if (/^<trimmed[- ]?(\d*).*>$/) { $trimmed += $1; next; }
    my $clean = $self->clean_messageid($_);
    $clean eq $_ ? push (@refs, $_) : $trimmed++;
  }
  
  if (scalar(@refs) > $maxref ) {	# There's too many references
    my $difference = scalar(@refs) - $maxref;
    $trimmed += $difference;
    @refs = ($refs[0], splice(@refs, $difference + 1));
  }

  if ($trimmed) {
    @refs = ($refs[0], "<trimmed-$trimmed\@$MY_DOMAIN>", splice(@refs, 1));
  }
  wantarray ? @refs : _format_refs(80, @refs);
}

=item clean_messageid ( STRING )

Takes a Message-ID in C<STRING>; if the ID is not formatted correctly, it
will make a new one using the same algorithm as News::Article's
C<add_messageid()>, with the prefix C<$News::Cleanheader::PREFIX> and the
domain C<$News::Cleanheader::MY_DOMAIN>.  There's nothing here to try to
actually clean up the header yet.

=cut

sub clean_messageid {
  my ($self, $id) = @_;
     $id =~ s/\s+//g;
     $id =~ s/^/</ unless $id =~ /^</;
     $id =~ s/$/>/ unless $id =~ />$/;

  # Is the ID valid?  If so, return it and we're done.
  return $id if $id =~ m/^<$ADDRESS>$/x;

  # Rewrite bad IDs here, if possible - that'll take some thinking later.

  # Make a new ID if necessary (code from Andrew Gierth's News::Article)
  my ($sec,$min,$hr,$mday,$mon,$year) = gmtime(time);
  ++$mon;
  $id = sprintf('<%s%04d%02d%02d%02d%02d%02d$%04x@%s>',
                 $MY_PREFIX || "" , $year+1900, $mon, $mday, $hr, $min, $sec,
                 0xFFFF & (rand(32768) ^ $$), $MY_DOMAIN || "" );
  return $id;
}

=item clean_date ( STRING )

Takes a Date string from just about any known format and converts it to
standard 1036-based time.  Returns undef if it can't parse the format;
but given that we're using Date::Parse, this shouldn't be much of a
problem.

=cut

sub clean_date {
  my ($self, $date) = @_;
  my $time = str2time($date) || return undef;
  _format_date($time);
}

=item clean_subject ( STRING )

Reformats a Subject: string to have a standardized Re: format.  It should
probably get rid of REPOSTs (from Dave the Resurrector) too, but it
doesn't yet.

This currently makes "Re: Rejection threshold" into "Re: jection
threshold"  This oughta be fixed.  D'oh.

=cut

sub clean_subject {
  my ($self, $line) = @_;
  $line =~ s/^(\s*(Re:?)?\s*REPOST\s*)//g;	# Get rid of REPOST headers
  $line =~ s/^\s*(Re(:\s*|\s+))+/Re: /i;        # Standardize the Re: format
  $line;
}

=item clean_from ( ADDRESS )

Takes a From: string and reformats it.  If the email address is
unqualified, it either adds $MY_DOMAIN (if it's a user of the system) or
"unknown.invalid" to the address; if it can't find an address at all, it
sets the address to "unknown@unknown.invalid".  This obviously doesn't
demunge addresses, but it's a start.

=cut

sub clean_from {
  my ($self, $address) = @_;
  my $comment = "";

  # RFC 1036 standard From: formats
  if ($address =~ /^\s*(?:\"?($PLAIN_PHRASE)?\"?\s*<($ADDRESS)>|
		         ($ADDRESS)\s*(?:\(($PAREN_PHRASE)\))?)\s*$/x) {
    $address = $2 || $3;
    $comment = $1 || $4;

  # No sitename was attached to the address - either append the local one if 
  # appropriate or set something saying that there wasn't one at all.
  } elsif ($address =~ /^\s*(?:\"?($PLAIN_PHRASE)?\"?\s*<($LOCAL_PART)>|
		         ($LOCAL_PART)\s*(?:\(($PAREN_PHRASE)\))?)\s*$/x) {
    $address = $2 || $3;
    $comment = $1 || $4; 
    
    my $host = $MY_DOMAIN if (getpwnam ($address));
       $host ||= "unknown.invalid";
    $address .= "\@$host";

  # The phrases had a bad part to them - scrap those parts.
  } elsif ($address =~ /^\s*(?:(.*)\s*<($LOCAL_PART\@?$DOMAIN?)>|
			($LOCAL_PART\@?$DOMAIN?)\s*(.*))\s*$/x) {

    $address = $2 || $3;
    $comment = $1 || $4;
    
    unless ($address =~ /\@\S+$/) {
      $address =~ s/\@$//g;
      my $host = $MY_DOMAIN if (getpwnam ($address));
         $host ||= "unknown.invalid";
      $address .= "\@$host";
    }

  # There's no way we're getting a valid address out of this; just give up.
  } else {
    $comment = $address;
    $address = "unknown\@unknown.invalid";
  }

  $address ||= "";  $comment ||= "";
  map { s%(^\s*|\s*$)%%g } ($address, $comment);
  return $comment ? "$comment <$address>" : "$address";
}

=item control ( STRING )

Checks over the given C<STRING> to see if it's a valid Control: string.
Returns undef if not.  

Not currently very well done.

=cut

sub clean_control {
  my ($self, $line) = @_;

  if ($line =~ /^\s*([a-zA-Z0-9]+)((?:\s+\S+)*)\s*$/) {
    my $verb = lc $1;
    my $args = $2;
    if ($verb eq "cancel") {
      return "$verb $args" if $args =~ /^\s*<$LOCAL_PART\@$DOMAIN>\s*$/;
    } elsif ($verb =~ /^(ihave|sendme)$/) {
      return "$verb $args" if $verb eq "ihave" && $args =~
		/^\s*(<$LOCAL_PART\@$DOMAIN>\s+)+\s*[a-zA-Z0-9\.-_]+\s*$/;
      return "$verb $args" if $verb eq "sendme" && $args =~
		/^\s*(<$LOCAL_PART\@$DOMAIN>\s+)+\s*$/s;
    } elsif ($verb eq "newgroup") {
      return "$verb $args" if $args =~ /^\s*$GROUP_CHARS+(\.$GROUP_CHARS+)*
					   (\s+(moderated|unmoderated))?\s*$/x;
    } elsif ($verb eq "rmgroup") {
      return "$verb $args" if $args =~ /^\s*$GROUP_CHARS+(\.$GROUP_CHARS+)*$/x;
    } elsif ($verb eq "sendsys") {
      return "$verb $args" if $args =~ /^\s*([a-zA-Z0-9\.-_]+)?\s*$/;
    } elsif ($verb eq "version") {
      return "$verb $args" if $args =~ /^\s*$/;
    } elsif ($verb eq "whogets") {
      return "$verb $args" if $args =~ /^\s*$GROUP_CHARS+(\.$GROUP_CHARS+)*
					   (\s+[a-zA-Z0-9\.-_]+)?\s*$/x;
    } elsif ($verb eq "checkgroups") {
      return "$verb $args" if $args =~ /^\s*$/;
    }
  }
  return undef;
}

=item clean_distibution ( ARRAY )

=item clean_keywords ( ARRAY )

Takes an array of strings and returns a properly formatted array of their 
contents.  And yes, these are the same function.

=cut

sub clean_distribution {
  my ($self, @array) = @_;
  my %distribs;
  foreach (@array) {
    foreach (split('\s*,\s*', $_)) {
      $distribs{$_}++ unless /^\s*$/;
    }
  }
  return keys %distribs;
}

sub clean_keywords { clean_distribution(@_) }

=item clean_header ( HEADER, ARGHASHREF, VALUE )

Basically a giant switch statement between all of the above.  Passes
C<VALUE> into the functions if we get it; otherwise, we get it out of
C<header()>.  Arguments come in C<ARGHASHREF>.  

Additional headers that can be cleaned with this:

  See-Also	Parsed with clean_references()
  Reply-To	Parsed with clean_from()
  Also-Control	Parsed with clean_control()
  Supersedes	Clears unless clean_messageid() doesn't change anything.

Headers that are known to be clear text (X-*, NNTP-*, Organization,
Summary, Lines) have their leading and trailing whitespace trimmed.  Other
headers have nothing change at all.

Returns the updated information.

=cut

sub clean_header {
  my ($self, $header, $args, $value) = @_;

  $args  ||= [];
  $value ||= $self->header($header);

  if (lc $header eq 'references' || lc $header =~ /^see[_-]also$/ ) { 
    return $self->clean_references( @{$args}[0] || $MAX_REFERENCES, $value );

  } elsif ($header =~ /^(from|reply[-_]to)$/) {
    return $self->clean_from( $value );

  } elsif (lc $header eq 'newsgroups') {
    return scalar $self->clean_newsgroups( $value );

  } elsif ($header =~ /^followup[_-]to$/) {
    return scalar $self->clean_followupto( $value );

  } elsif ($header =~ /^message[_-]id$/) {
    return $self->clean_messageid( $value );

  } elsif (lc $header eq 'date' || lc $header eq 'expires') {
    return $self->clean_date( $value );

  } elsif (lc $header eq 'subject') {
    return $self->clean_subject( $value );

  } elsif (lc $header eq 'distribution' || lc $header eq 'keywords') {
    return scalar $self->clean_distribution( $value );

  } elsif ($header =~ /^(also[-_])?control$/) {
    return $self->clean_control( $value );

  } elsif (lc $header eq 'supersedes') {
    my $return = $self->clean_messageid( $value );
    return undef unless ( $value =~ /^<?$return?>$/);
    return $return;

  ## Not yet implemented
  # } elsif (lc $header eq 'approved') {
  #   return join(',', @args);

  # } elsif (lc $header eq 'path') {
  #   return join('!', @args); 

  # Trim the leading/trailing whitespace, but that's all.
  } elsif ($header =~ /^(x.*|nntp.*|organization|summary|lines)$/x) {
    $value =~ s/(^\s+|\s+$)//;
    return $value;

  } else { return $value }
}

=item clean_head ( HEADER, ARGS )

Sets the value of C<HEADER> to the response of C<clean_header( HEADER,
ARGS)>. Basically a one-step helper function.

=cut

sub clean_head {
  my ($self, $header, $args) = @_;
  $self->set_headers($header, scalar $self->clean_header( $header, $args ) );
}

=item clean_head_all ()

Runs C<clean_head()> on all headers in the message.

=cut

sub clean_head_all {
  my ($self) = @_;
  foreach ( $self->header_names() ) { $self->clean_head($_) }
  $self;
}

=item clean_body ()

Not yet done.  Or really all that close.  It does currently do its
modifications in place...

=cut

sub clean_body {
  my ($self) = @_;
  
  my @body = $self->body();

  # Convert Microsoft smart quotes to their real counterparts.
  map { tr/\x91\x92\x93\x94/\`\'\"\"/ } @body;
  map { s/\x85/--/g } @body;

  # Remove CRs (DOS line endings, most likely) and delete
  # characters.
  map { tr/\r\x7f//d } @body;

  # Wipe out any non-ISO 8859-1 characters
  map { s/[^\s!-~\xa0-\xff]//g } @body;

  # Finish off later

  $self->set_body(@body);
  return wantarray ? @body : join("\n", @body);
}

=item clean_article ()

Runs C<clean_head_all()> and C<clean_body()> on the article. 

=cut

sub clean_article {
  my ($self) = @_;
  $self->clean_head_all && $self->clean_body;
}

=back

=cut

###############################################################################
### Internal Subroutines ######################################################
###############################################################################

## _format_refs ( COLS, REFARRAY )
# Formats a References: line for COLS columns.  Used by format_references().
sub _format_refs {
  my ($cols, @refs) = @_;
  my $less = $cols - 8;
  my $refs = shift(@refs) || "";
  my $length = 4 + length ($refs);
  foreach (@refs) {
    $length += 1 + length $_;
    $refs .= ($length < $less ? ' ' : "\n\t") . $_;
    $length = length $_ if ($length >= $less);
  }
  $refs;
}

## _format_date ( TIME )
# Takes TIME in seconds-since-epoch; returns a string suitable for formatting 
# into a Date: format.
sub _format_date {
  my $time = shift || time;
  my ($sec,$min,$hr,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($time);
  my ($gsec,$gmin,$ghr,$gmday) = gmtime($time);

  use integer;
  $gmday = $mday + ($mday <=> $gmday) if (abs($mday-$gmday) > 1);
  my $tzdiff = 24*60*($mday-$gmday) + 60*($hr-$ghr) + ($min-$gmin);
  my $tz = sprintf("%+04.4d", $tzdiff + ($tzdiff/60*40));

  $mon = (qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec))[$mon];
  $wday = (qw(Sun Mon Tue Wed Thu Fri Sat Sun))[$wday];
  $year += 1900;

  my $return = sprintf("%s, %02d %s %d %02d:%02d:%02d $tz",
                 $wday,$mday,$mon,$year,$hr,$min,$sec,$tz);
  $return;
}

1;

=head2 Variables 

The following global variables are added to News::Article when this
package is loaded.

=over 4

=item $News::Article::MAX_REFERENCES

Used by clean_references() to determine what the maximum number of entries
in the References: header should be.  Defaults to 10, can be set within
clean_references().

=item $News::Article::MY_DOMAIN

Used by clean_messageid(), clean_references(), clean_from(), and
clean_control() as the default domain for IDs (see B<News::Article>) and
From: lines.  Defaults to $ENV{'HOSTNAME'}, hostfqdn(), or
'broken-configuration'; this is something that you may want to set on your
own.

=item $News::Article::MY_PREFIX

Used by clean_messageid()
as the default prefix new message-IDs (see B<News::Article>)IDs and From: lines.  Defaults
to $ENV{'HOSTNAME'}, hostfqdn(), or 'broken-configuration'; this is
something that you may want to set on your own.


=item $News::Article::GROUP_CHARS, $News::Article::TAG_CHAR, [...]

Defined in RFC1036bis and used here to decide what header text is valid
and what is not.  The full list of variables:

=over 2

GROUP_CHARS TAG_CHAR CODE_CHAR CHARSET ENCODING CODES	
ENCODED_WORD UNQUOTED_CHAR QUOTED_CHAR PAREN_CHAR UNQUOTED_WORD
QUOTED_WORD PLAIN_WORD PAREN_PHRASE PLAIN_PHRASE LOCAL_PART DOMAIN 
ADDRESS FROM_CONTENT

=back

=head1 NOTES

The RFC1036bis character formatting bits are fairly old, but seem to be
fairly well in use across Usenet at this date.  They may well be replaced
sometime in the near future, though.

=head1 REQUIREMENTS

Date::Parse, News::Article

=head1 SEE ALSO

B<News::Article>

=head1 TODO

Finish off clean_body().  Put into NewsLib.  Set version to 'v1.0'.  Use
the newer RFC when it's put out.

=head1 AUTHOR

Tim Skirvin <tskirvin@killfile.org>

=head1 LICENSE

This code may be redistributed under the same terms as Perl itself.

=head1 COPYRIGHT

Copyright 1996-2004, Tim Skirvin.

=cut

###############################################################################
##### Version History #########################################################
###############################################################################

# v1.00		Thu Mar 18 14:23:29 CST 2004 
### Actually trying to get this into a useful, releasable format now.  
# v1.01		Mon Mar 22 11:34:35 CST 2004 
### Documentation fixes.
# v1.02		Thu Apr 22 11:40:18 CDT 2004 
### Just fixing things to make them better for Perl.
