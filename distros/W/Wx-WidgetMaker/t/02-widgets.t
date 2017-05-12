#!/usr/bin/perl -w

use strict;
use FindBin;
use lib "$FindBin::Bin/../lib";

use Test::More tests => 1;


my $app = MyApp->new();
isa_ok($app, 'MyApp');


# [XXX: change into tests rather than a demo]

$app->MainLoop();

package MyApp;
use strict;
use base qw(Wx::App);
use Wx qw(:everything);
use FindBin;
use lib "$FindBin::Bin/../lib";
use Wx::WidgetMaker;

our %labels = (
    red => 'Red',
    green => 'Green',
    blue => 'Blue',
);

sub OnInit {
    my $self = shift;
    my ($frame, $q, $pagesizer, $rowsizer, $control, $control2);

    $frame = Wx::Frame->new(
        undef, -1, 'Test', wxDefaultPosition, wxSIZE(400,500)
    );
    $frame->SetAutoLayout(1);

    $q = Wx::WidgetMaker->new(-parent => $frame);

    $pagesizer = Wx::BoxSizer->new(wxVERTICAL);

    # can use `print' to add the control to the pager
    $q->print($q->h1('H1 text'), $pagesizer);
    $q->print($q->h2('H2 text'), $pagesizer);
    $q->print($q->h3('H3 text'), $pagesizer);
    # or `print' an array ref of controls
    $q->print([$q->h4('H6 text'), $q->h5('H6 text'), $q->h6('H6 text')],
              $pagesizer);

    $rowsizer = Wx::BoxSizer->new(wxHORIZONTAL);
    # or `print' StaticText
    $rowsizer->Add($q->print('Textfield: '));
    $control = $q->textfield(
        -name => 'color_textfield',
        -default => 'blue',
        -size => 50,         # window width, not number of chars
        -maxlength => 30,
    );
    # (can still use Add if you want)
    $rowsizer->Add($control);
    $pagesizer->Add($rowsizer);


    $rowsizer = Wx::BoxSizer->new(wxHORIZONTAL);

    $control = $q->password_field(
        -name => 'color_password',
        -value => 'blue',
        -size => 50,         # window width, not number of chars
        -maxlength => 30,
    );
    $q->print([$q->print('Password: '), $control], $rowsizer);

    $pagesizer->Add($rowsizer);

    $control = $q->textarea(
        -name => 'color_area',
        -default => 'I like colors!',
        -rows => 100,        # window height, not number of rows
        -columns => 200,     # column width, not number of chars
    );
    $q->print($control, $pagesizer);

    $rowsizer = Wx::BoxSizer->new(wxHORIZONTAL);

    $control = $q->popup_menu(
        -name => 'color_popup',
        -values => [qw(red green blue)],
        -default => 'green',
        -labels => \%labels,
    );

    $control2 = $q->scrolling_list(
        -name => 'color_list',
        -values => [qw(red green blue)],
        -default => 'green',
        -size => 40,           # window height, not number of rows
        -multiple => 1,
        -labels => \%labels,
    );
    $q->print([$control, $control2], $rowsizer);
    $pagesizer->Add($rowsizer);

#    $q->checkbox_group(
#        -name => 'color_checkbox_group',
#        -values => ['red', 'green', 'blue', 'yellow'],
#        -default => 'green',
#        -linebreak => 'true',
#        -labels => \%labels,
#        -nolabels => undef,
#        -rows => 2,
#        -columns => 2,
#        -rowheaders => undef,
#        -colheaders => undef,
#    );

    $rowsizer = Wx::BoxSizer->new(wxHORIZONTAL);

    $control = $q->checkbox(
        -name => 'color_checkbox',
        -checked => 'checked',
        -label => 'CLICK ME',
    );

    $control2 = $q->radio_group(
        -name => 'color_radio_group',
        -values => [qw(red green blue)],
        -default => 'green',
        -linebreak => 'true',
        -labels => \%labels,
        -nolabels => 0,
        -rows => 2,
        -cols => 2,
#        -rowheaders => undef,         # unimplemented
#        -colheaders => undef,         # unimplemented
        -caption => 'Color?',         # not originally in CGI
    );
    $q->print([$control, $control2], $rowsizer);
    $pagesizer->Add($rowsizer);

    $rowsizer = Wx::BoxSizer->new(wxHORIZONTAL);

    $control = $q->submit(
        -name => 'color_button',
        -value => 'submit-esque',
    );

    $control2 = $q->image_button(
        -name => 'button_name',
        -src => '../ex/save.xpm',
    );
    $q->print([$control, $control2], $rowsizer);
    $pagesizer->Add($rowsizer);

    print "PARAM VALUES:\n";
    foreach my $param ($q->param()) {
        print $param, ': ', $q->param($param), $/;
    }


    $frame->SetSizer($pagesizer);
    $pagesizer->SetSizeHints($frame);

    $self->SetTopWindow($frame);
    $frame->Show(1);
}


1;
