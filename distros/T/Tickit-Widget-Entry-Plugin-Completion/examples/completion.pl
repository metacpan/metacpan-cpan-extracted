#!/usr/bin/perl

use v5.14;
use warnings;

use Tickit;
use Tickit::Widgets qw( Entry VBox Scroller );
use Tickit::Widget::Scroller::Item::Text;
use Tickit::Widget::Entry::Plugin::Completion;

my $vbox = Tickit::Widget::VBox->new(
   spacing => 1,
);

$vbox->add(
   my $scroller = Tickit::Widget::Scroller->new,
   expand => 1,
);

my @words = qw( zero one two three four five six seven eight nine ten );
push @words, qw( eleven twelve );
$scroller->push(
   Tickit::Widget::Scroller::Item::Text->new( $_ )
) for @words;

$vbox->add(
   my $entry = Tickit::Widget::Entry->new(
      style => { bg => "blue" },
      on_enter => sub {
         my ( $entry, $line ) = @_;
      },
   ),
);

Tickit::Widget::Entry::Plugin::Completion->apply( $entry,
   # completion-related args here?
   words => \@words,
);

Tickit->new( root => $vbox )->run;
