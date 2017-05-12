$VERSION = "0.5";
package News::Article;
our $VERSION = "0.5";	

# -*- Perl -*-		# Fri Oct 10 09:55:42 CDT 2003 
#############################################################################
# Written by Tim Skirvin <tskirvin@killfile.org>.  Copyright 2003, Tim
# Skirvin.  Redistribution terms are below.
#############################################################################

=head1 NAME

News::Article::Response - create responses to News::Articles

=head1 SYNOPSIS

  use News::Article::Response;

  my $newart = News::Article->response($oldart, 
		{ 'From' => 'Random User <random@user.org.invalid>' },
		'prefix' => 'random.', 'colwrap' => 80, 'nodate' => 1 );

  use News::Article::Response qw( quotewrap );

  my @wrappedtext = quotewrap( 80, '> ', 'overflow', @text );

=head1 DESCRIPTION

News::Article::Response is a set of additional functions for News::Article
to create responses to previous articles.  

=head1 USAGE

=cut

###############################################################################
### main() ####################################################################
###############################################################################

use strict;
use Exporter;

use vars qw( @ISA @EXPORT @EXPORT_OK );
@ISA       = qw( Exporter );
@EXPORT    = qw( );
@EXPORT_OK = qw( quotewrap );

use News::Article;
# use Text::Wrap;	# Is this strictly necessary?  Let's try it without...

###############################################################################
### Variables #################################################################
###############################################################################

use vars qw( $QUOTECHAR $COLWRAP $WRAPTYPE $QUOTECHARS $VERSION $RESTRING
	     $RESTRINGPATTERN );

$QUOTECHAR = '> ';
$COLWRAP   = 80;
$WRAPTYPE  = "overflow";
$QUOTECHARS = '(\s{0,5}[><=|#:}])+\s*'; 
$RESTRING  = "Re: ";
$RESTRINGPATTERN = '[rR][eE]:?\s*';

###############################################################################
### Methods ###################################################################
###############################################################################

=head2 Functions

=over 4

=item response ( ARTICLE, HEADERS, ARGUMENTS )

Creates a new article that's in response to C<ARTICLE> - that is, with
headers based on the original C<ARTICLE>.  Base headers that are created
should be Message-ID, Date, Newsgroups, References, and Subject; more
headers will be added as given in the hash reference C<HEADERS>.  The body
of the message is a quoted version of the original message with the
signature trimmed off.  

C<ARGUMENTS>, a hash, allows for user-modifed behavior.  Arguments that we
listen to:

  prefix	    Message-ID prefix (see News::Article)
  domain	    Message-ID domain (see News::Article)
  nomessageid	    Don't actually add a Message-ID: header

  time		    Time to base Date: off (defaults to local time)
  nodate	    Don't actually add a Date: header

  ignore_followups  Ignore the Followup-To: header when deciding 
		    what groups to respond to.  Especially important
		    if the original line was 'poster', as we return 
		    with 'undef' in that case (we should be sending 
		    an email)
  newsgroups	    Newsgroups to respond to, ignoring both the old 
		    Newsgroups: and Followup-To: headers.

  keepsig	    Keep the signature for quoting.
  quotechar	    The quote method; defaults to '> ', for use 
		    with wrap().
  colwrap	    Columns to wrap at, for use with wrap().
  wraptype	    Wrapping type, for use with wrap().
  respstring	    A code reference that takes as input the old 
		    article, and generates a string of the sort 
		    "Tim Skirvin writes:" for the start of the 
		    body.  The default gets the information out of 
		    From: or Reply-To:, or failing that uses uses
		    '(unknown)'.  Doesn't get added if there's no 
		    quoted material.  
    
Returns 'undef' on failure (not enough arguments, followups were set to
poster so there shouldn't be an article anyway), otherwise returns a
News::Article object.

=cut

sub response {
  my ($self, $original, $headers, %args) = @_;
  my $art = ref $self ? $self : new News::Article;
  return undef unless ($original && ref $original);
  $headers ||= {};

  $art->add_message_id( $args{'prefix'} || "", $args{'domain'} || "" )
		unless $args{nomessageid};
  $art->add_date($args{'time'} || "") unless $args{'nodate'};
  
  # Newsgroups: - we shouldn't respond at all if we're supposed to
  # followup to poster 
  if ($args{'newsgroups'}) { 
    $art->set_headers('newsgroups'), $args{'newsgroups'};
  } elsif ($args{'ignore_followups'}) { 
    $art->set_headers('newsgroups',  $original->header('newsgroups') || "");
  } else { 
    return undef if ($original->header('followup-to') eq 'poster' );
    $art->set_headers('newsgroups', $original->header('followup-to') ||
          			    $original->header('newsgroups')  || "");
  }

  # References - the original References: header, plus the Message ID
  $art->set_headers('references', 
	join(" ", $original->header('references'),
                    $original->header('message-id') ));
  
  # Add a Subject: based on the last Subject, with $RESTRING; this is a 
  # bit hard-coded for my tastes, but we need the regexp too...
  my $subject = $$headers{'subject'} || "";
  $subject ||= join('', $RESTRING, $original->header('subject'))
		if $original->header('subject') ;
  $subject =~ s/^($RESTRINGPATTERN)+/$RESTRING/i if $subject;	
  $art->set_headers('subject', $subject || "");

  # Parse the $headers hash for more headers to add
  foreach (keys %{$headers}) { 
    $art->set_headers($_, $$headers{$_}) if $$headers{$_} 
  }

  # Trim off the old signature
  my (@body, $postsig);
  foreach ($original->body) {	
    if (/^-- /) { $postsig++ unless $args{'keepsig'}; }
    next if $postsig;
    push @body, $_;
  }

  # Wrap the message body and add the quote character
  my $quotechar = $args{'quotechar'} || $QUOTECHAR || '>';
  my $columns   = $args{'colwrap'}   || $COLWRAP   || 80;
  my $wraptype  = $args{'wraptype'}  || $WRAPTYPE  || "wrap";
  @body = quotewrap($columns, $quotechar, $wraptype, @body);
  
  # Added in the "response string" thing if we have a body
  if (scalar @body) { 
    my $code = $args{'respstring'} || \&_respstring;
    unshift @body, $code->($original), '';
  }

  $art->set_body(@body);
  
  $art;
}

=item quotewrap ( COLUMNS, QUOTECHAR, WRAPTYPE, TEXT )

Adds C<QUOTECHAR> to the start of each line of text from C<TEXT>, and then
wraps the text at C<COLUMNS> columns where necessary.  This differs from
Text::Wrap in that lines that don't need to be wrapped won't be; that is,
we keep as much of the original formatting as possible.  

If C<COLUMNS> is less than 0, then don't actually do the wrapping.

C<WRAPTYPE> is currently ignored.  It probably won't be forever.  Offer it
the same values as in Text::Wrap.

This function can be imported by other programs, but is not by default
(@EXPORT_OK).

=cut

sub quotewrap {
  if (ref $_[0]) { shift @_ }	# Is this being run as an object?
  my ($columns, $quotechar, $wraptype, @body) = @_;
  
  my @return;
  map { s/^/$quotechar/g } @body;
  foreach my $line (@body) {
    if ($columns < 0) { push @return, $line; next }
    while ($line =~ /^.{$columns,}$/) {     # If the line has >$max chars
      my ($First, $Second) = $line =~ /^(.{$columns})(.*)$/;
      if ($First =~ /^(.*)\s+(\S+)$/) { 
        $First = $1;  $Second = join('', $2, $Second);
      }
      if ($First =~ /^($QUOTECHARS)/) { # Add quote chars to the second
        $Second = "$1$Second";          # half if this would be useful.
      }
      push (@return, $First);     # Process the lines
      $line = $Second;
    }
    push (@return, $line);
  }
  @return;
}

=back

=cut

###############################################################################
### Internal Functions ########################################################
###############################################################################

### _respstring ( ARTICLE )
# Generates a basic "%s writes:" string.  Not much to write home about.
sub _respstring {
  my ($article) = @_;
  sprintf("%s writes:", $article->header('from') 
			|| $article->header('reply-to') || "(unknown)");
}

### _wrap ($columns, $quotechar, $wraptype, @body)
# Wraps body at columns using quotechar as a prefix of each line.  Uses 
# Text::Wrap in a non-destructive way.  See the Text::Wrap manpage for
# more information ('overflow' and 'wrap' are the two interesting ones)

# sub _wrap {
#   my ($columns, $quotechar, $wraptype, @body) = @_;
#   my $origcols = $Text::Wrap::columns;	$Text::Wrap::columns = $columns;
#   my $orighuge = $Text::Wrap::huge;     $Text::Wrap::huge    = $wraptype;
#   @body = Text::Wrap::wrap($quotechar, $quotechar, @body);
#   $Text::Wrap::columns = $origcols;     $Text::Wrap::huge = $orighuge;
#   @body;
# }

=head1 REQUIREMENTS

B<News::Article>, B<Exporter>, and of course Perl (probably a fairly
modern version at that).

=head1 SEE ALSO

B<News::Article>, B<News::Web>

=head1 NOTES

This was originally written to work with my News::Web project (which I
plan to release), and much of the code was from old News::Verimod (which I
may not release).  It's now part of my newslib project (which *is*
released: http://www.killfile.org/~tskirvin/software/newslib/).  It should
be fairly general-purpose, but we'll see.

=head1 TODO

It would be nice if quotewrap() were to reformat paragraphs into something
reasonable when they're quoted; we'll see if it's something worth doing.

Get rid of the dependency on Text::Wrap, since we're not actually using it
except in an internal function that doesn't get called.

=head1 AUTHOR

Tim Skirvin <tskirvin@killfile.org>

=head1 COPYRIGHT

Copyright 2003 by Tim Skirvin <tskirvin@killfile.org>.  This code may be
distributed under the same terms as Perl itself.

=cut

1;

###############################################################################
### Version History ###########################################################
###############################################################################

# v0.5a 	 Fri Oct 10 09:55:42 CDT 2003 
### First commented version.
# v0.5		Thu Apr 22 12:57:16 CDT 2004 
### Just internal layout/documentation changes.
