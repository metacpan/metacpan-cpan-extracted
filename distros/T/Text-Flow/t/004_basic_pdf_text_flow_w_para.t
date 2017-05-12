#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

BEGIN {
    eval "use Test::PDF; use t::lib::PDFGen;";
    plan skip_all => "Test::PDF and pdflib_pl required to run PDF tests" if $@;    
}

plan no_plan => 1;

use List::Util 'sum';

BEGIN {
    use_ok('Text::Flow');
    use_ok('Text::Flow::Wrap');
}

my $PDF_TEST_FILE = 'test_flow_w_para.pdf';

{
    my $pdf = PDFGen->new(
        pdf_filename => $PDF_TEST_FILE
    );

    $pdf->open_page(height => 300, width => 600);

    my $font_height = $pdf->font_height;
    
    my $orig_start_top = 290;
    my $start_top      = $orig_start_top;
    my $start_left     = 50;
    my $width          = 150;
    my $height         = 150;    
    
    # create the wrapper ..
    my $flow = Text::Flow->new(
        check_height => sub { 
            my $paras = shift; 
            (sum(map { scalar @$_ || 1 } @$paras) * $font_height) < $height;
        },        
        wrapper => Text::Flow::Wrap->new(
            check_width => $pdf->get_string_width_function(width => $width),
        )
    );

    my $orig_text = join "" => <DATA>;
    my @sections = $flow->flow($orig_text);    

    my $line_top = $start_top;
    
    $start_top -= $font_height;    
    
    my $left = $start_left;
    foreach my $i (0 .. $#sections) {
        
        # draw rectangles to mark the width we want
        $pdf->draw_rect(
            left   => $left, 
            top    => $line_top, 
            width  => $width,
            height => $height + $font_height,
        );       
        
        foreach my $line (split "\n" => $sections[$i]) {
            $pdf->draw_text(
                text => $line,
                left => $left,
                top  => $start_top, 
            );
            $start_top -= $font_height;
        }
        
        $start_top = $orig_start_top - $font_height;
        $left += ($width + 10);
    }

    $pdf->close_page;
    $pdf->write_file;    
}

cmp_pdf($PDF_TEST_FILE, 't/pdfs/004_basic_pdf_text_flow_w_para.pdf', '... our PDFs are identical');
unlink($PDF_TEST_FILE);


__DATA__
Lorem ipsum dolor sit amet, consectetuer adipiscing elit. Duis lobortis nisl in ante. Vestibulum dignissim facilisis turpis. Nunc rutrum sapien sed eros. Donec facilisis placerat dui. Vestibulum ante ipsum primis in faucibus orci luctus et ultrices posuere cubilia Curae; Aenean convallis, urna eget mattis accumsan, dolor augue condimentum est, id aliquam pede eros eget metus. 
Proin felis. Nam hendrerit velit et lorem. Nulla ac mauris in nibh ornare porta. Fusce sodales porta orci. Aenean dolor. Proin nec ligula non eros tristique interdum. Sed aliquet ipsum vel leo. 
Cras a urna vel tortor molestie tincidunt. Aenean risus. Quisque luctus ipsum sit amet massa. Class aptent taciti sociosqu ad litora torquent per conubia nostra, per inceptos hymenaeos. Nam lacus mauris, sagittis volutpat, rutrum eget, commodo non, elit.