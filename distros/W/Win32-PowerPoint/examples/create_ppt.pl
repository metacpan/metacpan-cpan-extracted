#!perl
use strict;
use warnings;
use File::Basename;
use Win32::PowerPoint;

my $pp = Win32::PowerPoint->new;
$pp->new_presentation;

my $txtfile = shift or die "Usage: create_ppt <textfile>\n";
die "$txtfile not exists" unless -s $txtfile;

open my $fh, '<', $txtfile or die $!;
my $new_slide = 1;
my $text     = '';
my $subtitle = '';
while( <$fh> ) {
  chomp;
  if ( /^\-\-\-\-/ ) {
    if ( $text or $subtitle ) {
      $pp->new_slide;
      $text     =~ s/\n+$//;
      $subtitle =~ s/\n+$//;
      for (split /\n\n/s, $text) {
        $pp->add_text( $_, {
          left   => 50,
          height => 90,
          width  => 620,
          align  => 'center',
          size   => 72,
          font   => 'Trebuchet MS',
        });
      }
      $pp->add_text( $subtitle, {
        top    => 450,
        left   => 50,
        width  => 620,
        height => 50,
        align  => 'center',
        size   => 32,
        bold   => 1,
      }) if $subtitle;
    }
    $text = $subtitle = '';
    next;
  }
  elsif ( /^### (.+)/ ) {
    $subtitle .= "$1\n";
    next;
  }
  $text .= "$_\n";
}
close $fh;

(my $pptfile = $txtfile) =~ s|\.txt$||;
$pp->save_presentation($pptfile.'.ppt');
