#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

BEGIN {
    eval "use Test::PDF; use t::lib::PDFGen;";
    plan skip_all => "Test::PDF and pdflib_pl required to run PDF tests" if $@;    
}

plan no_plan => 1;

BEGIN {
    use_ok('Text::Flow::Wrap');
}

my $PDF_TEST_FILE = 'test_wrap_w_para.pdf';

{
    my $pdf = PDFGen->new(
        pdf_filename => $PDF_TEST_FILE
    );

    # create the wrapper ..
    my $wrapper = Text::Flow::Wrap->new(
        check_width => $pdf->get_string_width_function(width => 300),
    );

    my $orig_text = join "" => <DATA>;
    my $wrapped_text = $wrapper->wrap($orig_text);

    $pdf->open_page(height => 400, width => 400);

    my $start_top   = 390;
    my $font_height = $pdf->font_height;

    # draw a rectangle to mark the width we want
    $pdf->draw_line(left => 50, top => $start_top, width => 300);

    $start_top -= $font_height;
    foreach my $line (split "\n" => $wrapped_text) {
        $pdf->draw_text(
            text => $line,
            left => 50,
            top  => $start_top, 
        );
        $start_top -= $font_height;
    }

    $pdf->close_page;
    $pdf->write_file;
}

cmp_pdf($PDF_TEST_FILE, 't/pdfs/013_pdf_text_wrap_w_para.pdf', '... our PDFs are identical');

unlink($PDF_TEST_FILE);

__DATA__
Lorem ipsum dolor sit amet, consectetuer adipiscing elit. Duis lobortis nisl in ante. Vestibulum dignissim facilisis turpis. Nunc rutrum sapien sed eros. Donec facilisis placerat dui. Vestibulum ante ipsum primis in faucibus orci luctus et ultrices posuere cubilia Curae; Aenean convallis, urna eget mattis accumsan, dolor augue condimentum est, id aliquam pede eros eget metus. 
Proin felis. Nam hendrerit velit et lorem. Nulla ac mauris in nibh ornare porta. Fusce sodales porta orci. Aenean dolor. Proin nec ligula non eros tristique interdum. Sed aliquet ipsum vel leo. 
Cras a urna vel tortor molestie tincidunt. Aenean risus. Quisque luctus ipsum sit amet massa. Class aptent taciti sociosqu ad litora torquent per conubia nostra, per inceptos hymenaeos. Nam lacus mauris, sagittis volutpat, rutrum eget, commodo non, elit.
