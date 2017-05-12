
package PDFGen;
use Moose;
use MooseX::Params::Validate;

use pdflib_pl;

has 'pdf'          => (is => 'rw');
has 'pdf_filename' => (is => 'rw');
has 'font'         => (is => 'rw');
has 'font_size'    => (is => 'rw', default => 12);
has 'font_height'  => (is => 'rw');

sub BUILD {
    my ($self, $params) = @_;
    my $pdf = pdflib_pl::PDF_new();
    (pdflib_pl::PDF_open_file($pdf, $self->pdf_filename) != -1) 
        || die "cannot open file for PDF document : $!";
        
    my $font = pdflib_pl::PDF_findfont($pdf, 'Helvetica', 'host', 0);
    (defined($font)) 
        || die "Could not load font";        

    $self->font($font);
    $self->pdf($pdf);    
}

sub get_string_width_function {
    my ($self, %params) = validate(\@_, 
        width  => { isa => 'Int' },
    );
    sub {
        pdflib_pl::PDF_stringwidth(
            $self->pdf, 
            $_[0], 
            $self->font, 
            $self->font_size
        ) < $params{width}    
    }
}

sub open_page {
    my ($self, %params) = validate(\@_, 
        width  => { isa => 'Int' },
        height => { isa => 'Int' }                
    );
    pdflib_pl::PDF_begin_page($self->pdf, $params{width}, $params{height});
    pdflib_pl::PDF_setfont($self->pdf, $self->font, $self->font_size);
    $self->font_height(pdflib_pl::PDF_get_value($self->pdf, "leading", 0));    
}

sub draw_line {
    my ($self, %params) = validate(\@_, 
        top    => { isa => 'Int' },
        left   => { isa => 'Int' },
        width  => { isa => 'Int' },
        height => { isa => 'Int', default => 1 }                
    );
    pdflib_pl::PDF_rect($self->pdf, $params{left}, $params{top}, $params{width}, $params{height});
    pdflib_pl::PDF_fill($self->pdf);    
}

sub draw_rect {
    my ($self, %params) = validate(\@_, 
        top    => { isa => 'Int' },
        left   => { isa => 'Int' },
        width  => { isa => 'Int' },
        height => { isa => 'Int' }                
    );
    pdflib_pl::PDF_rect(
        $self->pdf, 
        $params{left}, 
        ($params{top} - $params{height}), 
        $params{width}, 
        $params{height},
    );
    pdflib_pl::PDF_stroke($self->pdf);    
}

sub draw_text {
    my ($self, %params) = validate(\@_, 
        top  => { isa => 'Int' },
        left => { isa => 'Int' },
        text => { isa => 'Str' },
    );
    pdflib_pl::PDF_show_xy(
        $self->pdf, 
        $params{text},
        $params{left},
        $params{top}, 
    );
}

sub close_page {
    pdflib_pl::PDF_end_page((shift)->pdf);
}

sub write_file {
    pdflib_pl::PDF_close((shift)->pdf);    
}

1;

__END__