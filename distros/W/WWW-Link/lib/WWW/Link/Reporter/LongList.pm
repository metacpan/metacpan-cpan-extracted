=head1 NAME

WWW::Link::Reporter::LongList - Long list files which contain broken links

=head1 SYNOPSIS

   use WWW::Link;
   use WWW::Link::Reporter::LongList;

   $link=new WWW::Link;

   #over time do things to the link ......

   $reporter = new WWW::Link::Reporter::LongList \*STDOUT, $index;
   $reporter->examine($link)

or see WWW::Link::Selector for a way to recurse through all of the links.

=head1 DESCRIPTION

This is a WWW::Link::Reporter very similar to WWW::Link::Reporter::Text, but
when it detects a broken link in a local file it will list that file
in C<ls -l> format.  This can be used to allow easy editing, for
example by C<link-report-dired> in C<emacs>

=cut

package WWW::Link::Reporter::LongList;
$REVISION=q$Revision: 1.10 $ ; $VERSION = sprintf ( "%d.%02d", $REVISION =~ /(\d+).(\d+)/ );

use WWW::Link::Reporter::Text;
@ISA = qw(WWW::Link::Reporter::Text);
use warnings;
use strict;
use Data::Dumper;
use Carp;

sub new {
  my $proto=shift;
  my $url_to_file=shift;
  croak "usage <class>->new(<convert function>,<index>)"
    unless ref $url_to_file and @_;
  my $class = ref($proto) || $proto;
  my $self  = $class->SUPER::new(@_);
  $self->{"url_to_file"}=$url_to_file;

  if ( $self->{"verbose"} & 128) {
    my $dump=Dumper($self);
    $dump =~ s/[^[:graph:]\s]/_/g;
    print "self\n" . $dump . "\n";
  }

  return $self;
}

sub page_list {
  my $self=shift;
  my @worklist=();
  my @unresolve=();
  my $url_to_file=$self->{"url_to_file"};
  foreach my $url (@_) {
    my $file = &$url_to_file($url);
    if ($file) {
      push @worklist, quotemeta ($file);
    } else {
      push @unresolve,  $url;
    }
  }
  if ( @worklist ) {
    my $workfile=join ' ', @worklist;
    print `ls -l $workfile`;
  }
  print 'unresolved:-  ', join ("\nunresolved:-  ", @unresolve), "\n"
    if @unresolve;
}

