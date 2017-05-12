#!perl

use strict;
use warnings;

use Test::More tests => 1;
use File::Find;

# TODO this + the name matching regexp won't do for ./bin
use constant SRC => qw( lib inc xt t );

### Assorted pre-flight tests ###

is_deeply scan_project( SRC ), {}, 'no nasties';

sub scan_project {
  my @dirs  = @_;
  my %error = ();
  scan_dirs(
    @dirs,
    sub {
      return if $_ eq $0;    # Don't test me
      my $file = $_;
      open my $fh, '<', $file or die "Can't read $file: $!\n";
      while ( <$fh> ) {
        /\$DB::single/ && $error{db_single}++;
      }
    }
  );
  return \%error;
}

sub scan_dirs {
  my @dirs = @_;
  my $cb   = pop @dirs;

  find {
    no_chdir => 1,
    wanted   => sub {
      $cb->() if /\.(?:pm|pl|t|PM)$/ && -f;
    },
   },
   @dirs;
}

# vim:ts=2:sw=2:et:ft=perl

