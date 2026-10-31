package YATT::Lite::CLI::Render; sub MY () {__PACKAGE__}
use strict;
use warnings qw(FATAL all NONFATAL misc);
use mro 'c3';

use parent qw(YATT::Lite::CLI);
use YATT::Lite::MFields;

#========================================
# yatt.render FILE [name=value..] [FILE2 [name=value..] ..]
#
# name=value params before the first file are common to all files;
# params right after a file apply to that file (overriding common ones).
#
# Dispatch (part resolution, sigil, public check, argument reordering)
# is identical to the web thanks to Site->render_file. Raw die from a
# template passes through untouched (perl -d friendly).
#========================================

sub main {
  my ($self, @argv) = @_;
  $self->parse_params(\@argv, \ my %common);

  binmode STDOUT;

  my $nerror = 0;
  while (@argv) {
    my $file = shift @argv;
    my %params = %common;
    $self->parse_params(\@argv, \%params);

    my $site = $self->site_for($file);
    my $res = $site->render_file($file, \%params);
    if ($res->is_success) {
      print scalar $res->body;
    } else {
      print STDERR join(" ", grep {defined $_ and $_ ne ''}
			$res->status, $res->content), "\n";
      $nerror++;
    }
  }
  $nerror ? 1 : 0;
}

1;
