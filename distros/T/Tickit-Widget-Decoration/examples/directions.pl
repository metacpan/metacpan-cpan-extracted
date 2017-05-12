#!/usr/bin/env perl
use strict;
use warnings;
use 5.010;
use Tickit;
use Tickit::Widget::Decoration;
use Tickit::Widget::HBox;
use Tickit::Widget::VBox;
use Tickit::Style;
Tickit::Style->load_style(<<'EOF');
Decoration.horizontal {
 gradient-direction: 'horizontal';
}
Decoration.vertical {
 gradient-direction: 'vertical';
}
EOF

my $vbox = Tickit::Widget::VBox->new;
$vbox->add(Tickit::Widget::Decoration->new(class => 'horizontal'));
my $hbox = Tickit::Widget::HBox->new;
$hbox->add(Tickit::Widget::Decoration->new(class => 'vertical'));
$vbox->add($hbox, expand => 1);
Tickit->new(root => $vbox)->run;


