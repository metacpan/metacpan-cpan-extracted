use strict;
use Test::More;

use Win32::PowerPoint;
use Win32::PowerPoint::Utils qw( convert_cygwin_path );
use File::Spec;

my $ppt_file = File::Spec->rel2abs('t/sample.ppt');
my $jpg_file = File::Spec->rel2abs('t/slide.jpg');

unlink $ppt_file if -f $ppt_file;
unlink $jpg_file if -f $jpg_file;

my $pp;
eval { $pp = Win32::PowerPoint->new };
if ( $@ ) {
  plan skip_all => 'This test requires MS PowerPoint';
  exit;
}

my $initial_presentations;
my $num_of_slides;
my @tests = (
  sub {
    ok(ref $pp eq 'Win32::PowerPoint');
    diag('Hello, '.$pp->application->Name);

    $initial_presentations = $pp->application->Presentations->Count;
    diag("initial presentation: $initial_presentations");
  },
  sub {
    $pp->new_presentation;
    ok($pp->application->Presentations->Count == $initial_presentations + 1, "new presentation");
  },
  sub {
    eval {
      $pp->set_master_footer(
        visible      => 1,
        text         => 'master footer',
        slide_number => 1,
      );
    };
    ok(!$@, $@ ? $@ : "set master footer");
  },
  sub {
    $num_of_slides = $pp->presentation->Slides->Count;
    diag("initial slides: $num_of_slides");
    $pp->new_slide;
    ok($pp->presentation->Slides->Count == $num_of_slides + 1);
  },
  sub {
    ok(!$pp->presentation->Saved);
  },
  sub {
    eval {
      $pp->add_text('Title',     { bold => 1, size => 40 });
      $pp->add_text('contents');
      my $link = $pp->add_text('hyperlink', { link => 'http://www.example.com' });
      $link->TextFrame->TextRange->Characters(1, 5)->Font->{Bold} = $pp->{c}->True;
    };
    ok(!$@, $@ ? $@ : "added texts");
  },
  sub {
    # need to convert explicitly
    $pp->slide->Export(convert_cygwin_path($jpg_file),'jpg');
    ok(-f $jpg_file);
  },

  sub {
    # insert picture
    $pp->new_slide;
    eval {
      $pp->add_picture($jpg_file, { top => 0, left => 0 });
    };
    ok(!$@, $@ ? $@ : "added picture");
  },
  sub {
    eval {
      $pp->set_footer(
        visible         => 1,
        text            => 'slide footer',
        datetime        => 1,
        datetime_format => 'Mdyy',
      );
    };
    ok(!$@, $@ ? $@ : "added footer");
  },

  sub {
    # no need to convert; will be done internally
    $pp->save_presentation($ppt_file);
    ok(-f $ppt_file);
  },
  sub {
    ok($pp->presentation->Saved);
  },
  sub {
    $pp->close_presentation;
    ok($pp->application->Presentations->Count == $initial_presentations);
  },
);

plan tests => scalar @tests;
foreach my $test (@tests) { $test->(); }

unlink $ppt_file if -f $ppt_file;
unlink $jpg_file if -f $jpg_file;
