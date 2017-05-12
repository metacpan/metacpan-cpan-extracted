=head1 NAME

WWW::Link::Reporter::Text - Report on status of links in plain text

=head1 SYNOPSIS

   use WWW::Link;
   use WWW::Link::Reporter::Text;

   $link=new WWW::Link;

   #over time do things to the link ......

   $reporter = new WWW::Link::Reporter::Text
   $reporter->examine($link)

=head1 DESCRIPTION

This is a very simple class derived from WWW::Link::Reporter which provides
a report on the status of links in text for easy reading.  Nothing
much can be done other than read it.

=cut

package WWW::Link::Reporter::Text;
$REVISION=q$Revision: 1.9 $ ; $VERSION = sprintf ( "%d.%02d", $REVISION =~ /(\d+).(\d+)/ );

@ISA = qw(WWW::Link::Reporter);

use warnings;
use strict;

use WWW::Link::Reporter;
use Carp;

sub broken {
  my $self=shift;
  my $link=shift;
  my $redir=shift;
  my $url=$link->url();
  print "broken:-       $url\n";
  $redir && $self->redirections($link);
  $self->suggestions($link);
  if ($self->{"index"}) {
    my $page_array=$self->{"index"}->lookup_second($url);
    $self->page_list ( @$page_array );
  }
}

sub not_found {
  my $self=shift;
  my $url=shift;
  print "Sorry, the link $url is not in the database.\n";
}

sub okay {
  my $self=shift;
  my $link=shift;
  my $redir=shift;
  my $url=$link->url();
  print "tested okay:-  $url\n";
  $redir && $self->redirections($link);
  $self->suggestions($link);
  if ($self->{"index"}) {
    my $page_array=$self->{"index"}->lookup_second($url);
    $self->page_list ( @$page_array );
  }
  return 1;
}

sub damaged {
  my $self=shift;
  my $link=shift;
  my $redir=shift;
  my $url=$link->url();
  print "could be broken:- $url\n";
  $redir && $self->redirections($link);
  $self->suggestions($link);
  if ($self->{"index"}) {
    my $page_array=$self->{"index"}->lookup_second($url);
    $self->page_list ( @$page_array );
  }
  return 1;
}

sub not_checked {
  my $self=shift;
  my $link=shift;
  my $url=$link->url();
  print "not yet checked:-  $url\n";
  $self->suggestions($link);
  if ($self->{"index"}) {
    my $page_array=$self->{"index"}->lookup_second($url);
    $self->page_list ( @$page_array );
  }
}

sub disallowed {
  my $self=shift;
  my $link=shift;
  my $url=$link->url();
  print "checking disallowed:-  $url\n";
  $self->suggestions($link);
  if ($self->{"index"}) {
    my $page_array=$self->{"index"}->lookup_second($url);
    $self->page_list ( @$page_array );
  }
}

sub unsupported {
  my $self=shift;
  my $link=shift;
  my $url=$link->url();
  print "unsupported protocol:-  $url\n";
  $self->suggestions($link);
  if ($self->{"index"}) {
    my $page_array=$self->{"index"}->lookup_second($url);
    $self->page_list ( @$page_array );
  }
}

sub unknown {
  my $self=shift;
  my $link=shift;
  my $url=$link->url();
  print "unknown status (error?):-  $url";
  $self->suggestions($link);
  if ($self->{"index"}) {
    my $page_array=$self->{"index"}->lookup_second($url);
    $self->page_list ( @$page_array );
  }
}


sub redirections {
  my $self=shift;
  my $link=shift;
  my @redirects=$link->redirect_urls();
  foreach my $redir ( @redirects ) {
    print "redirected to\t$redir\n";
  }
}


sub suggestions {
  my $self=shift;
  my $link=shift;
  my $suggestions=$link->fix_suggestions();
  if ($suggestions) {
    foreach my $suggest ( @{$suggestions} ) {
      print "suggest	$suggest\n";
    }
  }
  return 1;
}


sub page_list {
  my $self=shift;
  foreach (@_) {
    print "	$_\n";
  }
}

1;



