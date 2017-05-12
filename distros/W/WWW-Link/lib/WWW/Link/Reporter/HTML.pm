=head1 NAME

WWW::Link::Reporter::HTML - Report on status of links in HTML

=head1 SYNOPSIS 

    use WWW::Link;
    use WWW::Link::Reporter::HTML;

    $link=new WWW::Link;
    #over time do things to the link ......

    $::reporter=new WWW::Link::Reporter::HTML;
    $::reporter->examine($link)

or see WWW::Link::Selector for a way to recurse through all of the links.

=head1 DESCRIPTION

This class will output information about any link that it is given.

If it's constructor is given an index (CDB_File::BiIndex or BiIndex) then it
can use that to generate lists of urls containing links being reported
on.

=cut

package WWW::Link::Reporter::HTML;
$REVISION=q$Revision: 1.7 $ ; $VERSION = sprintf ( "%d.%02d", $REVISION =~ /(\d+).(\d+)/ );

use WWW::Link;
use HTML::Stream;
use WWW::Link::Reporter;
@ISA=qw(WWW::Link::Reporter);
use warnings;
use strict;

=head1 new

This

=cut

sub new ($$;$){
  my ($class,$stream, $index)=@_;
  my $self=WWW::Link::Reporter::new($class, $index);
  $self->{"hstr"} = new HTML::Stream::LinkReport $stream;
  $self->{"docurl"} = "http://localhost/linkcontroler/docs/";
  return $self;
}

sub heading ($) {
  my $self=shift;
  $self->{"hstr"}->Heading;
}

sub footer ($) {
  my $self=shift;
  $self->{"hstr"}->Footer;
}

sub not_found  {
  my $self=shift;
  my $url=shift;
  $self->{"hstr"}-> P
                 -> t("Sorry, the link $url is not in the database.\n")
		 -> _P;
}

sub broken  {
  my ($self, $link, $redir)=@_;

  my $url=$link->url();
  my $hstr=$self->{"hstr"};

  $hstr-> P;

  $hstr -> STRONG -> nl
        ->Link_Heading($url, "Link found BROKEN")
	-> _STRONG -> nl;

  $redir && $self->redirections($link);
  $self->suggestions($link);

  if ($self->{"index"}) {
    $hstr->page_list( $self->{"index"}->lookup_second($url) );
  }

  $hstr-> _P;
}

sub okay  {
  my ($self, $link, $redir)=@_;

  my $url=$link->url();
  my $hstr=$self->{"hstr"};

  $hstr -> P;

  $hstr->Link_Heading($url, "Link tested okay");

  $redir && $self->redirections($link);
  $self->suggestions($link);

  if ($self->{"index"}) {
    $hstr->page_list( $self->{"index"}->lookup_second($url) );
  }

  $hstr -> _P;
}

sub damaged  {
  my ($self, $link, $redir)=@_;

  my $url=$link->url();
  my $hstr=$self->{"hstr"};

  $hstr -> P;

  $hstr->Link_Heading($url, "Link may be broken");

  $redir && $self->redirections($link);
  $self->suggestions($link);

  if ($self->{"index"}) {
    $hstr->page_list( $self->{"index"}->lookup_second($url) );
  }

  $hstr -> _P;
}

sub not_checked  {
  my ($self, $link )=@_;

  my $url=$link->url();
  my $hstr=$self->{"hstr"};

  $hstr -> P;

  $hstr->Link_Heading($url, "Link not yet checked");

  $self->suggestions($link);

  if ($self->{"index"}) {
    $hstr->page_list( $self->{"index"}->lookup_second($url) );
  }

  $hstr -> _P;
}

sub disallowed  {
  my ($self, $link)=@_;

  my $url=$link->url();
  my $hstr=$self->{"hstr"};

  $hstr -> P;

  $hstr->Link_Heading($url, "Link checking not allowed");

  $self->suggestions($link);

  if ($self->{"index"}) {
    $hstr->page_list( $self->{"index"}->lookup_second($url) );
  }

  $hstr -> _P;
}

sub unsupported  {
  my ($self, $link)=@_;

  my $url=$link->url();
  my $hstr=$self->{"hstr"};

  $hstr -> P;

  $hstr->Link_Heading($url, "Link uses unsupported protocol");

  $self->suggestions($link);

  if ($self->{"index"}) {
    $hstr->page_list( $self->{"index"}->lookup_second($url) );
  }

  $hstr -> _P;
}

sub unknown  {
  my ($self, $link)=@_;

  my $url=$link->url();
  my $hstr=$self->{"hstr"};

  $hstr -> P;

  $hstr->Link_Heading($url, "Link status unknown; error?");

  $self->suggestions($link);

  if ($self->{"index"}) {
    $hstr->page_list( $self->{"index"}->lookup_second($url) );
  }

  $hstr -> _P;
}

#we should separately deal with temporary redirections (generally
#ignored) and long term redirections (should generally be applied)

sub redirections  {
  my ($self, $link)=@_;

  my $hstr=$self->{"hstr"};

  my @redirects=$link->redirect_urls();
  if (@redirects) {
    $hstr -> DL;
    foreach my $redir ( @redirects ) {
       $hstr -> DT -> t("redirected to") -> _DT
             -> DD -> Link($redir) -> _DD -> nl;
    }
    $hstr -> _DL;
  }
}

sub suggestions  {
  my ($self, $link)=@_;
  my $hstr=$self->{"hstr"};

  $hstr -> DL;

  my $suggest;
  my $suggestions=$link->fix_suggestions();
  if ($suggestions) {
    foreach $suggest ( @{$suggestions} ) {
      $hstr -> DT -> t("suggest:") -> _DT
            -> DD -> Link($suggest) -> _DD -> nl;
    }
  } 
  $hstr -> _DL;

}

package HTML::Stream::LinkReport;

our @ISA;
@ISA=qw(HTML::Stream);

use warnings;
use strict;

use HTML::Stream;

sub Heading {
  my $self=shift;
  $self->HTML
       ->HEAD
       ->TITLE ->t("Link Controller Report.") -> _TITLE
       ->_HEAD
       ->BODY
       ->H1 ->t("Report Contents") -> _H1;
  return $self;
}

sub Footer {
  my $self=shift;
  $self->_BODY
       ->_HTML;
  return $self;
}

=head2 Link_heading

This function simply prints a heading for a link with the url and text
given as arguments.

=cut

sub Link_Heading ($$$) {
  my ($self, $url, $text) = @_;
  $self -> nl->H2 -> t($text . " ")
	-> Link($url)-> _H2->nl;
}

=head2 page_list

This takes a list of urls as an argument and generates a unnumbered
html list consisting of those urls inside links to those urls.  It is
for use for refering to pages on which urls occur.

Obviously, if the URLs are file urls, then the machine they are being
read on must be the same as the one the file urls refer to.

=cut

sub page_list {
  my $self=shift;
  my $array=shift;
  $self->UL;
  foreach (@$array) {
    $self -> LI
      -> Link($_)
	-> _LI -> nl;
  }
  $self->_UL;
  return $self;
}

=head2 $LR->Link()

This method puts out a url inside a link refering to that url.  I
don't want to encourage this for general use: it's much better to use
a description generally.  This program, however, deals directly with
links so it suits us here.

=cut

sub Link {
  my $self=shift;
  my $url=shift;
  $self -> A(HREF=>$url)
	-> t($url)
	-> _A  ;
  return $self;
}
