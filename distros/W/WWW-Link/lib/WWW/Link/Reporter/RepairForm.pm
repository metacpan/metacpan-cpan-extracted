package WWW::Link::Reporter::RepairForm;
$REVISION=q$Revision: 1.6 $ ; $VERSION = sprintf ( "%d.%02d", $REVISION =~ /(\d+).(\d+)/ );

=head1 NAME

WWW::Link::Reporter::RepairForm - Build a form for repairing links

=head1 SYNOPSIS 

    use WWW::Link;
    use WWW::Link::Reporter::RepairForm;

    $link=new WWW::Link;
    #over time do things to the link ......

    $::reporter=new WWW::Link::Reporter::RepairForm;
    $::reporter->examine($link)

or see WWW::Link::Selector for a way to recurse through all of the links.

=head1 DESCRIPTION

This class will output information about any link that it is given.

=cut


use WWW::Link;
use HTML::Stream;
use WWW::Link::Reporter::HTML;
use CGI::Form;

@ISA=qw(WWW::Link::Reporter::HTML);
use warnings;
use strict;


sub new {
  my $class=shift;
  my $fixlink_cgi=shift;
  my $index=shift;
  my $self=WWW::Link::Reporter::new($class, $index);
  my $stream=shift;
  $self->{"hstr"} = new HTML::Stream::LinkRepairForm $stream;
  $self->{"docurl"} = "http://localhost/linkcontroler/docs/";
  $self->{"fixlink_cgi"} = $fixlink_cgi;
  return $self;
}

sub not_found { return 1; } #just shut up please.

#...inherited methods.....


sub broken {
  my $self=shift;
  my $link=shift;
  my $url=$link->url();
  my $hstr=$self->{"hstr"};

  $hstr-> P;

  $hstr -> STRONG -> nl
        ->Link_Heading($url, "Link found BROKEN")
	-> _STRONG -> nl;

  $hstr -> auto_form($link, $self->{"fixlink_cgi"}, $url);
  
  if ($self->{"index"}) {
    $hstr->page_list( $self->{"index"}->lookup_second($url) );
  }

  $hstr-> _P->nl;
}

sub okay {
  my $self=shift;
  my $link=shift;
  my $url=$link->url();
  my $hstr=$self->{"hstr"};

  $hstr -> P;

  $hstr->Link_Heading($url, "Link tested okay");

  if ($self->{"index"}) {
    $hstr->page_list( $self->{"index"}->lookup_second($url) );
  }

  $hstr -> _P->nl;
}

sub damaged {
  my $self=shift;
  my $link=shift;
  my $url=$link->url();
  my $hstr=$self->{"hstr"};

  $hstr -> P;

  $hstr->Link_Heading($url, "Link may be broken");

  $hstr -> auto_form($link, $self->{"fixlink_cgi"}, $url);
  
  if ($self->{"index "}) {
    $hstr->page_list( $self->{"index"}->lookup_second($url) );
  }

  $hstr -> _P->nl;
}

sub not_checked {
  my $self=shift;
  my $link=shift;
  my $url=$link->url();
  my $hstr=$self->{"hstr"};

  $hstr -> P;

  $hstr->Link_Heading($url, "Link has not yet been checked");

  $hstr -> correct_form($self->{"fixlink_cgi"}, $url);
  
  if ($self->{"index"}) {
    $hstr->page_list( $self->{"index"}->lookup_second($url) );
  }

  $hstr -> _P->nl;
}

sub disallowed {
  my $self=shift;
  my $link=shift;
  my $url=$link->url();
  my $hstr=$self->{"hstr"};

  $hstr -> P;

  $hstr->Link_Heading($url, "Link checking is not permitted");

  $hstr -> auto_form($link, $self->{"fixlink_cgi"}, $url);
  
  if ($self->{"index"}) {
    $hstr->page_list( $self->{"index"}->lookup_second($url) );
  }

  $hstr -> _P->nl;
}

sub unsupported {
  my $self=shift;
  my $link=shift;
  my $url=$link->url();
  my $hstr=$self->{"hstr"};

  $hstr -> P;

  $hstr->Link_Heading($url, "Link uses unsupported protocol");

  $hstr -> auto_form($link, $self->{"fixlink_cgi"}, $url);
  
  if ($self->{"index"}) {
    $hstr->page_list( $self->{"index"}->lookup_second($url) );
  }

  $hstr -> _P->nl;
}

sub unknown {
  my $self=shift;
  my $link=shift;
  my $url=$link->url();
  my $hstr=$self->{"hstr"};

  $hstr -> P;

  $hstr->Link_Heading($url, "Link status unknown; error?");

  $hstr -> auto_form($link, $self->{"fixlink_cgi"}, $url);

  if ($self->{"index"}) {
    $hstr->page_list( $self->{"index"}->lookup_second($url) );
  }

  $hstr -> _P->nl;
}

1;

package HTML::Stream::LinkRepairForm;

our @ISA;
@ISA=qw(HTML::Stream::LinkReport);

use Carp;

=head2 $self->correct_form() $self->auto_form()

 $self->correct_form(action,url,array_ref)
 $self->auto_form(link,action,url)

These methods write a form which can be used for repairing a broken
link.  The form has a hidden attribute giving the original link it
refered to.  It then outputs a list of known suggestions in a radio
list and finally outputs a text field in which a completely new
suggestion can be input.

C<auto_form> automatically populates the form with any suggestions and
redirections which the link has attached to it.

=cut

sub auto_form {
  my $self=shift;
  my $link=shift;
  my @urls=$link->redirect_urls();
  my $suggestions=$link->fix_suggestions();
  unshift @urls, @$suggestions if $suggestions;
  $self->correct_form(@_, \@urls);
}

sub correct_form {
  my $self=shift;
  my $action=shift;
  my $orig_url=shift;
  croak "correct_form called without original url\n" unless defined $orig_url;
  my $array=shift;

  $self->FORM(METHOD=>"POST", ACTION=>$action);
  $self->INPUT(NAME=>"orig-url", VALUE=>$orig_url, TYPE=>"HIDDEN");
  $self->nl->t("Set new end point for link.")->nl->UL;
  if ($array) {
    foreach (@$array) {
      $self -> LI
	    -> INPUT(TYPE=>"radio", NAME=>"canned-suggestion", VALUE=>$_)
	    -> Link($_)
	    -> _LI ->nl;
    }
    $self -> LI
          -> INPUT(TYPE=>"radio", NAME=>"canned-suggestion", VALUE=>"user")
	  -> t("set new url below")
	  -> _LI ->nl;
  }
  $self -> LI
        ->INPUT(TYPE=>"text", NAME=>"user_suggestion")
        ->INPUT(TYPE=>"submit", NAME=>"Repair Link")
        -> _LI;
  $self->_UL
       ->_FORM;
  return $self;
}

