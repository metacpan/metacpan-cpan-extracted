package IO::Page;

use strict;
use vars qw( $VERSION );

$VERSION = '0.02';

local( *PAGER, *STDOLD, ) ;

BEGIN {
  my( $try, $pager, ) ;
  
  if ( -t STDOUT ) {
    # only bother to check if we're going to page
    # other fallbacks could be `which less`, `which more`, etc
    TRY:
    foreach $try ( $ENV{PAGER},
                   '/usr/local/bin/less',
                   '/usr/bin/less',
                   '/usr/bin/more',
                 ) {
      eval { chomp $try } ;
      if ( -x $try ) {
        $pager = $try ;
	last TRY ;
      }
    }

    die "Couldn't find a pager!\n" unless -x $pager ;

    open PAGER, "| $pager"
      or die "Can't pipe to $pager: $!" ;
    open STDOLD, ">&STDOUT"
      or die "Can't save STDOUT: $!" ;
    open STDOUT, ">&PAGER"
      or die "Can't dup STDOUT to PAGER: $!" ;
  }
}

END {
  if ( fileno STDOLD ) {
    open STDOUT, ">&STDOLD"
      or die "Can't restore STDOUT: $!" ;
  }
  close PAGER ;
}

# module loaded OK!
1 ;

__END__

=head1 NAME

  IO::Page - Pipe STDOUT to a pager if STDOUT is a TTY

=head1 SYNOPSIS

Pipes STDOUT to a pager if STDOUT is a TTY

=head1 DESCRIPTION

IO::Page is designed to programmaticly decide whether or not to point
the STDOUT file handle into a pipe to program specified in $ENV{PAGER}
or one of a standard list of pagers.

=head1 USAGE

  use IO::Page ;
  print <<"  HEREDOC" ;
  ...
  A bunch of text later
  HEREDOC

=head1 AUTHOR

  Monte Mitzelfelt <monte-iopage@gonefishing.org>

=cut
