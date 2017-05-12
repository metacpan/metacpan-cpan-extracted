=head1 NAME

WWW::Link::Reporter::URI - Report link URIs only

=head1 SYNOPSIS

   use WWW::Link;
   use WWW::Link::Reporter::URI;

   $link=new WWW::Link;

   #over time do things to the link ......

   $reporter = new WWW::Link::Reporter::URI
   $reporter->examine($link)

=head1 DESCRIPTION

This is a very simple class derived from WWW::Link::Reporter which
simply prints the URIs of each link reported.  By chosing the correct
reports this is then good for generating output for use in scripts
etc.

=cut

package WWW::Link::Reporter::URI;
$REVISION=q$Revision: 1.1 $ ; $VERSION = sprintf ( "%d.%02d", $REVISION =~ /(\d+).(\d+)/ );

@ISA = qw(WWW::Link::Reporter);

use warnings;
use strict;

use WWW::Link::Reporter;

BEGIN {
  foreach my $rep ( qw( broken okay damaged not_checked disallowed
                        unsupported redirections suggestions page_list ) ) {
    do {
      eval <<EOF;
	sub $rep {
	  my \$self=shift;
	  my \$link=shift;
	  my \$url=\$link->url();
	  print "\$url\n";
	}
EOF
      };
    }
}

sub not_found {
  my $self=shift;
  my $url=shift;
  print STDERR "Link $url is not in the database.\n";
}

sub unknown {
  my $self=shift;
  my $link=shift;
  my $url=$link->url();
  print STDERR "Link $url has unknown status (error?).\n";
}

1;



