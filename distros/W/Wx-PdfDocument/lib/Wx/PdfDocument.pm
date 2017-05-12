#########################################################################################
# Package       Wx::PdfDocument
# Description:  Wrapper for wxPdfDocument
# Created       Sat Apr 21 02:00:26 2012
# SVN Id        $Id: PdfDocument.pm 195 2015-03-11 16:10:36Z mark.dootson@gmail.com $
# Copyright:    Copyright (c) 2006, 2012 Mark Wardell <mwardell@cpan.org>
# Licence:      This program is free software; you can redistribute it 
#               and/or modify it under the same terms as Perl itself
#########################################################################################

package Wx::PdfDocument;

#########################################################################################

use strict;
use warnings;
use Wx 0.9908;
use Wx::Print;
use Cwd;

our $VERSION = '0.21';

our $_binpath;
our $_libpath;

#-------------------------------------------------------------
# Constants
#-------------------------------------------------------------

our @constants = qw(
    wxPDF_BORDER_NONE wxPDF_BORDER_LEFT wxPDF_BORDER_RIGHT wxPDF_BORDER_TOP 
    wxPDF_BORDER_BOTTOM wxPDF_BORDER_FRAME wxPDF_CORNER_NONE wxPDF_CORNER_TOP_LEFT 
    wxPDF_CORNER_TOP_RIGHT wxPDF_CORNER_BOTTOM_LEFT wxPDF_CORNER_BOTTOM_RIGHT 
    wxPDF_CORNER_ALL wxPDF_STYLE_NOOP wxPDF_STYLE_DRAW wxPDF_STYLE_FILL  
    wxPDF_STYLE_FILLDRAW wxPDF_STYLE_DRAWCLOSE  wxPDF_STYLE_MASK wxPDF_TEXT_RENDER_FILL 
    wxPDF_TEXT_RENDER_STROKE wxPDF_TEXT_RENDER_FILLSTROKE wxPDF_TEXT_RENDER_INVISIBLE 
    wxPDF_FONTSTYLE_REGULAR wxPDF_FONTSTYLE_ITALIC wxPDF_FONTSTYLE_BOLD wxPDF_FONTSTYLE_BOLDITALIC 
    wxPDF_FONTSTYLE_UNDERLINE wxPDF_FONTSTYLE_OVERLINE wxPDF_FONTSTYLE_STRIKEOUT 
    wxPDF_FONTSTYLE_DECORATION_MASK wxPDF_FONTSTYLE_MASK wxPDF_PERMISSION_NONE 
    wxPDF_PERMISSION_PRINT wxPDF_PERMISSION_MODIFY wxPDF_PERMISSION_COPY wxPDF_PERMISSION_ANNOT 
    wxPDF_PERMISSION_FILLFORM wxPDF_PERMISSION_EXTRACT wxPDF_PERMISSION_ASSEMBLE 
    wxPDF_PERMISSION_HLPRINT wxPDF_PERMISSION_ALL wxPDF_ENCRYPTION_RC4V1 wxPDF_ENCRYPTION_RC4V2 
    wxPDF_ENCRYPTION_AESV2 wxPDF_PAGEBOX_MEDIABOX wxPDF_PAGEBOX_CROPBOX wxPDF_PAGEBOX_BLEEDBOX 
    wxPDF_PAGEBOX_TRIMBOX wxPDF_PAGEBOX_ARTBOX wxPDF_BORDER_SOLID wxPDF_BORDER_DASHED 
    wxPDF_BORDER_BEVELED wxPDF_BORDER_INSET wxPDF_BORDER_UNDERLINE wxPDF_ALIGN_LEFT 
    wxPDF_ALIGN_CENTER wxPDF_ALIGN_RIGHT wxPDF_ALIGN_JUSTIFY wxPDF_ALIGN_TOP wxPDF_ALIGN_MIDDLE 
    wxPDF_ALIGN_BOTTOM wxPDF_ZOOM_FULLPAGE wxPDF_ZOOM_FULLWIDTH wxPDF_ZOOM_REAL wxPDF_ZOOM_DEFAULT 
    wxPDF_ZOOM_FACTOR wxPDF_LAYOUT_CONTINUOUS wxPDF_LAYOUT_SINGLE wxPDF_LAYOUT_TWO 
    wxPDF_LAYOUT_DEFAULT wxPDF_VIEWER_HIDETOOLBAR wxPDF_VIEWER_HIDEMENUBAR 
    wxPDF_VIEWER_HIDEWINDOWUI wxPDF_VIEWER_FITWINDOW wxPDF_VIEWER_CENTERWINDOW 
    wxPDF_VIEWER_DISPLAYDOCTITLE wxPDF_MARKER_CIRCLE wxPDF_MARKER_SQUARE wxPDF_MARKER_TRIANGLE_UP 
    wxPDF_MARKER_TRIANGLE_DOWN wxPDF_MARKER_TRIANGLE_LEFT wxPDF_MARKER_TRIANGLE_RIGHT 
    wxPDF_MARKER_DIAMOND wxPDF_MARKER_PENTAGON_UP wxPDF_MARKER_PENTAGON_DOWN 
    wxPDF_MARKER_PENTAGON_LEFT wxPDF_MARKER_PENTAGON_RIGHT wxPDF_MARKER_STAR wxPDF_MARKER_STAR4 
    wxPDF_MARKER_PLUS wxPDF_MARKER_CROSS wxPDF_MARKER_SUN wxPDF_MARKER_BOWTIE_HORIZONTAL 
    wxPDF_MARKER_BOWTIE_VERTICAL wxPDF_MARKER_ASTERISK wxPDF_MARKER_LAST 
    wxPDF_LINEAR_GRADIENT_HORIZONTAL wxPDF_LINEAR_GRADIENT_VERTICAL 
    wxPDF_LINEAR_GRADIENT_MIDHORIZONTAL wxPDF_LINEAR_GRADIENT_MIDVERTICAL 
    wxPDF_LINEAR_GRADIENT_REFLECTION_LEFT wxPDF_LINEAR_GRADIENT_REFLECTION_RIGHT 
    wxPDF_LINEAR_GRADIENT_REFLECTION_TOP wxPDF_LINEAR_GRADIENT_REFLECTION_BOTTOM 
    wxPDF_BLENDMODE_NORMAL wxPDF_BLENDMODE_MULTIPLY wxPDF_BLENDMODE_SCREEN wxPDF_BLENDMODE_OVERLAY 
    wxPDF_BLENDMODE_DARKEN wxPDF_BLENDMODE_LIGHTEN wxPDF_BLENDMODE_COLORDODGE 
    wxPDF_BLENDMODE_COLORBURN wxPDF_BLENDMODE_HARDLIGHT wxPDF_BLENDMODE_SOFTLIGHT 
    wxPDF_BLENDMODE_DIFFERENCE wxPDF_BLENDMODE_EXCLUSION wxPDF_BLENDMODE_HUE 
    wxPDF_BLENDMODE_SATURATION wxPDF_BLENDMODE_COLOR wxPDF_BLENDMODE_LUMINOSITY 
    wxPDF_SHAPEDTEXTMODE_ONETIME wxPDF_SHAPEDTEXTMODE_STRETCHTOFIT wxPDF_SHAPEDTEXTMODE_REPEAT 
    wxPDF_PDFXNONE wxPDF_PDFX1A2001 wxPDF_PDFX32002 wxPDF_PDFA1A wxPDF_PDFA1B 
    wxPDF_RUN_DIRECTION_DEFAULT wxPDF_RUN_DIRECTION_NO_BIDI wxPDF_RUN_DIRECTION_LTR 
    wxPDF_RUN_DIRECTION_RTL wxPDF_COLOURTYPE_UNKNOWN wxPDF_COLOURTYPE_GRAY wxPDF_COLOURTYPE_RGB 
    wxPDF_COLOURTYPE_CMYK wxPDF_COLOURTYPE_SPOT wxPDF_COLOURTYPE_PATTERN wxPDF_LINECAP_NONE 
    wxPDF_LINECAP_BUTT wxPDF_LINECAP_ROUND wxPDF_LINECAP_SQUARE wxPDF_LINEJOIN_NONE 
    wxPDF_LINEJOIN_MITER wxPDF_LINEJOIN_ROUND wxPDF_LINEJOIN_BEVEL wxPDF_SEG_UNDEFINED 
    wxPDF_SEG_MOVETO wxPDF_SEG_LINETO wxPDF_SEG_CURVETO wxPDF_SEG_CLOSE wxPDF_OCG_TYPE_UNKNOWN 
    wxPDF_OCG_TYPE_LAYER wxPDF_OCG_TYPE_TITLE wxPDF_OCG_TYPE_MEMBERSHIP wxPDF_OCG_INTENT_DEFAULT 
    wxPDF_OCG_INTENT_VIEW wxPDF_OCG_INTENT_DESIGN wxPDF_OCG_POLICY_ALLON wxPDF_OCG_POLICY_ANYON 
    wxPDF_OCG_POLICY_ANYOFF wxPDF_OCG_POLICY_ALLOFF wxPDF_PRINTDIALOG_ALLOWNONE
    wxPDF_PRINTDIALOG_ALLOWALL wxPDF_PRINTDIALOG_FILEPATH wxPDF_PRINTDIALOG_PROPERTIES
    wxPDF_PRINTDIALOG_PROTECTION wxPDF_PRINTDIALOG_OPENDOC
    wxPDF_MAPMODESTYLE_STANDARD wxPDF_MAPMODESTYLE_MSW wxPDF_MAPMODESTYLE_GTK
    wxPDF_MAPMODESTYLE_MAC wxPDF_MAPMODESTYLE_PDF
);

push @Wx::EXPORT_OK, @constants;

$Wx::EXPORT_TAGS{'pdfdocument'} = [ @constants ];

#-------------------------------------------------------------
# Load XS module
#-------------------------------------------------------------

require Wx::PdfDocument::Loader;
&_start;
require XSLoader;
XSLoader::load( 'Wx::PdfDocument', $VERSION );

#-------------------------------------------------------------
# Load Font Manager - we must do this or no fonts
#-------------------------------------------------------------

{
    my $fm = Wx::PdfFontManager::GetFontManager();
    $fm->AddSearchPath($ENV{WXPDF_FONTPATH});
}

#---------------------------------------------------------
# utility wrapper funtions
#---------------------------------------------------------

sub MakeFont { Wx::PdfDocument::_utilscmd(qq($_binpath/makefont), $_[0]); }

sub ShowFont { Wx::PdfDocument::_utilscmd(qq($_binpath/showfont), $_[0]); }

#---------------------------------------------------------
# confirm inheritance tree
#---------------------------------------------------------

no strict;

package Wx::PdfLayerGroup;
use vars qw( $VERSION );
$VERSION = '0.01';

package Wx::PdfOcg;
use vars qw( $VERSION );
$VERSION = '0.01';

package Wx::PdfColour;
use vars qw( $VERSION );
$VERSION = '0.01';

package Wx::PdfInfo;
use vars qw( $VERSION );
$VERSION = '0.01';

package Wx::PdfLineStyle;
use vars qw( $VERSION );
$VERSION = '0.01';

package Wx::PdfShape;
use vars qw( $VERSION );
$VERSION = '0.01';

package Wx::PdfFont;
use vars qw( $VERSION );
$VERSION = '0.01';

package Wx::PdfFontDescription;
use vars qw( $VERSION );
$VERSION = '0.01';

package Wx::PdfFontManager;
use vars qw( $VERSION );
$VERSION = '0.01';

package Wx::PdfBarCodeCreator;
use vars qw( $VERSION );
$VERSION = '0.01';

package Wx::PdfLayer;
use vars qw( $VERSION );
$VERSION = '0.01';
@ISA = qw( Wx::PdfOcg );

package Wx::PdfLayerMembership;
use vars qw( $VERSION );
$VERSION = '0.01';
@ISA = qw( Wx::PdfOcg );

package Wx::PdfDC;
use vars qw( $VERSION );
$VERSION = '0.01';
@ISA = qw( Wx::DC );

package Wx::PdfLink;
use vars qw( $VERSION );
$VERSION = '0.01';

package Wx::PdfPageLink;
use vars qw( $VERSION );
$VERSION = '0.01';
@ISA = qw( Wx::PdfLink );

package Wx::PdfPrinter;
use vars qw( $VERSION );
$VERSION = '0.01';
@ISA = qw( Wx::Printer );

package Wx::PdfPrintData;
use vars qw( $VERSION );
$VERSION = '0.01';
@ISA = qw( Wx::Object );

package Wx::PdfPrintPreview;
use vars qw( $VERSION );
$VERSION = '0.01';
@ISA = qw( Wx::PrintPreview );

package Wx::PdfPrintPreviewImpl;
use vars qw( $VERSION );
$VERSION = '0.01';
@ISA = qw( Wx::PrintPreview );

package Wx::PdfPageSetupDialog;
use vars qw( $VERSION );
$VERSION = '0.01';
@ISA = qw( Wx::Dialog );

package Wx::PdfPrintDialog;
use vars qw( $VERSION );
$VERSION = '0.01';
@ISA = qw( Wx::PrintDialog );

package Wx::PlPdfDocument;
use vars qw( $VERSION );
$VERSION = '0.01';
@ISA = qw( Wx::PdfDocument );

1;

=head1 NAME

Wx::PdfDocument - wxPerl wrapper for the wxPdfDocument classes.

=head1 SYNOPSYS

    use Wx::PdfDocument;
    use Wx wq( :pdfdocument );
    
    my $pdfdoc = Wx::PlPdfDocument->new;
    
    ....
    
    my $pdfdoc2 = MyDocClass->new();
    
    ....
    
    package MyDocClass;
    use strict;
    use warnings;
    use Wx::PdfDocument;
    use Wx wq( :pdfdocument );
    use base qw( Wx::PlPdfDocument );
    
    sub new { shift->SUPER::new( @_ ); }
    
    # optionally override virtuals
    
    sub Header { .... }
    sub Footer { .... }
    sub AcceptPageBreak { .... }
    

=head1 DESCRIPTION

Wx::PdfDocument is a wrapper for the wxPdfDocument wxcode classes for the wxWidgets GUI toolkit.
Wx::PdfDocument allows you to create PDF documents directly using B<Wx::PlPdfDocument> methods either
directly or in a derivied class. It also provides classes for the wxWidgets printing framework that
allow you to print output to a PDF document using any Wx::Printout class. For example, you can print
the output of Wx::RichTextPrintout and Wx::HtmlPrintout in addition to any custom Wx::Printout that
you may create.

A module is provided in this distribtion for Wx::Demo that gives extensive examples of usage.

=head1 Wx::PlPdfDocument

For creating PDF documents with your own code, this may be the only class you will need to use.
You can either us the class directly or create a derived class and optionally override
the following virtual methods.

    Footer();
    Header();
    AcceptPageBreak();

The interface is fully described at the wxPdfDocument documentation site.

L<http://wxcode.sourceforge.net/docs/wxpdfdoc/classwx_pdf_document.html>

As is the normal practice for wxPerl implementations, where the C++ documentation
indicates any type of an array parameter, you should pass a reference to a Perl array
containing the appropriate types or objects.

A small number of methods cannot be implemented exactly as they are implemented in C++. 
The wxPerl implementation for these methods is noted below:

=over

=item GetTemplateBBox

    my($x, $y, $width, $height) = $pdfdoc->GetTemplateBBox($templateId);

=item GetTemplateSize

    my($newWidth, $newHeight) = $pdfdoc->GetTemplateSize($templateId, $oldWidth, $oldHeight);

=back

=head1 Wx::PdfDC

The distribution provides a Wx::DC class that you can use to write a PDF document using the
standard Wx::PrinterDC commands.

    my $pdata = Wx::PrintData->new;
    $pdata->SetFilename('somefilename.pdf');
    $pdata->SetPaperId(wxPAPER_A4);
    $pdata->SetOrientation(wxPORTRAIT);
    my $dc = Wx::PdfDC->new( $pdata );
    $dc->StartDoc;
    $dc->StartPage;
    ... do drawing / writing
    $dc->EndPage;
    $dc->EndDoc;

The interface is described at the wxPdfDocument documentation site but is a near complete
implementation of Wx::DC.

L<http://wxcode.sourceforge.net/docs/wxpdfdoc/classwx_pdf_d_c.html>

=head1 wxWidgets Printing Framework

Classes are provided that allow you to use Wx::PdfDocument with existing
wxWidgets classes in the manner of a PDF printer.

For example, with Wx::RichextPrintout

    my $printdata;
    my $dialogdata = Wx::PageSetupDialogData->new;
    $dialogdata->SetMarginTopLeft([25,25]);
    $dialogdata->SetMarginBottomRight([25,25]);
    $dialogdata->EnableMargins(1);
    $dialogdata->EnablePaper(1);
    $dialogdata->EnableOrientation(1);
    my $dialog = Wx::PdfPageSetupDialog->new($self, $dialogdata);
    if($dialog->ShowModal == wxID_OK ) {
        $dialogdata = $dialog->GetPageSetupDialogData;
        $printdata  = Wx::PdfPrintData->new($dialogdata->GetPrintData);
    }
    $dialog->Destroy;
    return unless $printdata;
    
    my $printbuffer = Wx::RichTextBuffer->new($self->{richtext}->GetBuffer);
    my $printprintout = Wx::RichTextPrintout->new("Demo RichText PDF Printing");
    
    $printprintout->SetMargins(
                      10 * $dialogdata->GetMarginTopLeft->y,
                      10 * $dialogdata->GetMarginBottomRight->y,
                      10 * $dialogdata->GetMarginTopLeft->x,
                      10 * $dialogdata->GetMarginBottomRight->x
                      );
    $printprintout->SetRichTextBuffer($printbuffer);
    
    my $previewbuffer = Wx::RichTextBuffer->new($self->{richtext}->GetBuffer);
    my $previewprintout = Wx::RichTextPrintout->new("Demo RichText PDF Preview");
    
    $previewprintout->SetMargins(
                      10 * $dialogdata->GetMarginTopLeft->y,
                      10 * $dialogdata->GetMarginBottomRight->y,
                      10 * $dialogdata->GetMarginTopLeft->x,
                      10 * $dialogdata->GetMarginBottomRight->x
                      );
    $previewprintout->SetRichTextBuffer($previewbuffer);
    
    # Printouts do not take ownership of buffers so the
    # wxWidgets buffers will be deleted along with our Perl
    # objects. The preview frame is not a modal dialog.
    $self->{storerichtextbuffers} = [ $printbuffer, $previewbuffer ];
    
    my $printpreview = Wx::PdfPrintPreview->new( $previewprintout, $printprintout, $printdata);
    
    my $frame = Wx::PreviewFrame->new( $printpreview, $self,
                                     "PDF RichText Printing Preview", [-1, -1], [600, 600] );
    $frame->Initialize();
    $frame->Show( 1 );

=head1 Wx::PdfPageSetupDialog

This page setup dialog allows you to collect settings for margins, paper type and orientation
from the user. It uses the standard Wx::PageSetupDialogData that you can use to determine
which of the three settings; margins, paper and orientation, will be available to the user
to change.

    # get margins and paper but don't let user
    # change orientation
    my $printdata;
    my $dialogdata = Wx::PageSetupDialogData->new;
    $dialogdata->SetMarginTopLeft([25,25]);
    $dialogdata->SetMarginBottomRight([25,25]);
    $dialogdata->EnableMargins(1);
    $dialogdata->EnablePaper(1);
    $dialogdata->EnableOrientation(0);
    $dialogdata->GetPrintData->SetOrientation(&Wx::wxLANDSCAPE);
    my $dialog = Wx::PdfPageSetupDialog->new($self, $dialogdata);
    if($dialog->ShowModal == wxID_OK ) {
        $dialogdata = $dialog->GetPageSetupDialogData;
        $printdata  = $dialogdata->GetPrintData;
    }
    $dialog->Destroy;

=head1 Wx::PdfPrintDialog

This print dialog takes the place of the standard printer setup dialog when using the wxWidgets
printing framework. It is shown by default when using Wx::PdfPrinter and Wx::PdfPrintPreview and
you may also create a dialog yourself to collect user input.

The dialog allows the user to set document properties such as title and subject, choose the output
filename and whether to launch the output in a PDF viewer. It also allows setting encryption and
document passord options.

You can control which of the options are available to the user by passing a Wx::PdfPrintData object
in the constructor with appropropriate settings.

    # all options available
    my $printdata = Wx::PdfPrintData->new;
    my $dialog = Wx::PdfPrintDialog->new($self, $printdata);
    if($dialog->ShowModal == wxID_OK ) {
        $printdata  = $dialog->GetPdfPrintData;
    }
    $dialog->Destroy;
    ...
    # limit options to filepath and launch viewer
    my $printdata = Wx::PdfPrintData->new;
    $printdata->SetPrintDialogFlags( wxPDF_PRINTDIALOG_OPENDOC|wxPDF_PRINTDIALOG_FILEPATH );
    ## check launch doc CheckBox by default
    $printdata->SetLaunchDocumentViewer(1);
    my $dialog = Wx::PdfPrintDialog->new($self, $printdata);
    if($dialog->ShowModal == wxID_OK ) {
        $printdata  = $dialog->GetPdfPrintData;
        Wx::LogMessage('Selected filepath : %s', $printdata->GetFilename);
    }
    $dialog->Destroy;


=head1 Wx::PdfPrintData

This class provides most of the custom features for wxPdfPrinting and is the basis for passing
options to and from Wx::PdfPrintDialog, Wx::PdfPrinter and Wx::PdfPrintPreview.

=head2 Constructors

    my $pdata = Wx::PdfPrintData->new();
    my $pdata = Wx::PdfPrintData->new(<Wx::PdfPrintData>);
    my $pdata = Wx::PdfPrintData->new(<Wx::PrintData>);
    my $pdata = Wx::PdfPrintData->new(<Wx::PrintDialogData>);

=head2 PDF Document Properties

Set the output filename and basic paper detail

    $pdata->SetFilename($filename);
    $pdata->SetPaperId(wxPAPER_A4);
    $pdata->SetOrientation(wxPORTRAIT);
    
    $filename = $pdata->GetFilename;
    $paperid = $pdata->GetPaperid;
    $orient = $pdata->GetOrientation;

You can set various PDF Document properties by adding the information to Wx::PdfPrintData

    $pdata->SetDocumentTitle($title);
    $pdata->SetDocumentSubject($subject);
    $pdata->SetDocumentAuthor($author);
    $pdata->SetDocumentKeywords($keywords);
    $pdata->SetDocumentCreator($applicationname);
    
    $title = $pdata->GetDocumentTitle();
    $subject = $pdata->GetDocumentSubject();
    $author = $pdata->GetDocumentAuthor();
    $keywords = $pdata->GetDocumentKeywords();
    $applicationname = $pdata->GetDocumentCreator();

=head2 Document Protection

see  wxPdfDocument::SetProtection described at

L<http://wxcode.sourceforge.net/docs/wxpdfdoc/classwx_pdf_document.html>

Normally you should collect the options for document protection via the
Wx::PdfPrintDialog and let the Wx::PdfPrinter class apply these options
for you. To set and apply options directly yourself to a PDF document it
is better to call Wx::PdfDocument methods directly.

The following methods of Wx::PdfPrintData are used internally by the
Wx::PdfPrinter

    $pdata->SetDocumentProtection($perms, $userpwd, $ownpwd, $cryptm, $keylen);
    
    # Apply document protection and Title, Subject, etc.
    $pdata->UpdateDocument($wx_pdfdocument);

=head2 Controlling Dialogs and Printing Process

If you pass a Wx::PdfPrintData instance to the contructor of a
Wx::PdfPrinter, Wx::PdfPrintDialog or Wx::PdfPrintPreview object you can
control the printing process and dialog options that will be available to
the user

    $flags = $pdata->GetPrintDialogFlags();
    $pdata->SetPrintDialogFlags($flags);

$flags is a or'd combination of

    wxPDF_PRINTDIALOG_FILEPATH
    Allow setting of the output filepath in dialog
    
    wxPDF_PRINTDIALOG_PROPERTIES
    Allow setting of document properties (Title, Author, Subject, Keywords) in dialog

    wxPDF_PRINTDIALOG_PROTECTION
    Allow setting of protection options in dialog

    wxPDF_PRINTDIALOG_OPENDOC
    Show the "Launch document in default viewer" checkbox

    wxPDF_PRINTDIALOG_ALLOWNONE
    Allow no settings in dialog

    wxPDF_PRINTDIALOG_ALLOWALL
    Allow all settings in dialog

Set the default value for the "Launch document in default viewer" checkbox

    $bool = $pdata->GetLaunchDocumentViewer();
    $pdata->SetLaunchDocumentViewer($bool);

Although not particularly useful when outputting a PDF document, you can set pages
to print in the Wx::PdfPrintData in the same manner as Wx::PrintDialogData

    $pagenum = $pdata->GetFromPage();
    $pagenum = $pdata->GetToPage();
    $pagenum = $pdata->GetMinPage();
    $pagenum = $pdata->GetMaxPage();
    $pdata->SetFromPage($pagenum);
    $pdata->SetToPage($pagenum);
    $pdata->SetMinPage($pagenum);
    $pdata->SetMaxPage($pagenum);

By default, the Wx::PdfPrinter sets up a Wx::PdfDC with a resolution of 600 pixels.
perl inch. It does not make any difference to the output quality what you set the
resolution to. The PDF format is not pixel based so it is simply a matter of
coordinate conversion. However, the Wx::DC drawing functions are integer based
and so always introduce rounding and truncation when coordinates are transformed.
Therefore, the lower the resolution, the bigger the error you may experience. For
example, truncating 600.49 to 600 on a virtual 600 dpi device is a much smaller
error that truncating 72.49 to 72 on a virtual 72 dpi device. So you probably don't
want to change the resolution defaults.

    $dpi = $pdata->GetPrintResolution();
    $pdata->SetPrintResolution($dpi);


=head2 Setting Template Mode

By default a Wx::PdfDC instance creates a Wx::PdfDocument and outputs the result.
The Wx::PdfDC can also operate in 'template mode' where an existing Wx::PdfDocument
instance is passed to the constructor. This can be useful to combine the text methods
of Wx::PdfDocument with the graphics methods of Wx::PdfDC. In this mode, the StartDoc
and EndDoc methods of the Wx::PdfDC have no effect. The Wx::PdfDocument is created
outside the Wx::PdfDC instance and code must handle writing it to disk independently
too.

To allow template mode to be used within the wxWidgets printing framework (perhaps you
have a custom Wx::Printout instance designed to handle enhanced PDF features) you can
set the template parameters in a Wx::PdfPrintData instance that gets passed to
Wx::PdfPrinter or Wx::PdfPrintPreview.

    $pdata->SetTemplate( $wxpdfdocument, $width, $height );
    $pdfdoc =  $pdata->GetTemplateDocument();
    $width  =  $pdata->GetTemplateWidth();
    $height =  $pdata->GetTemplateHeight();
    
    # check if SetTemplate has been called
    $bool   =  $pdata->GetTemplateMode();

=head1 Wx::PdfPrintPreview

A drop in for Wx::PrintPreview used in exactly the same way accepting a Wx::PdfPrintData
instance in its constructor.
    
    my $preview = Wx::PdfPrintPreview->new(
              $previewprintout,
              $printprintout,
              $wxPdfPrintData);
    
    my $frame = Wx::PreviewFrame->new( $printpreview, $self,
            "PDF Printing Preview", [-1, -1], [600, 600] );
    $frame->Initialize();
    $frame->Show( 1 );

There are complete examples in the Wx::Demo demomodule provided with the distribution.

=head1 Wx::PdfPrinter

A drop in for Wx::Printer used in exactly the same way accepting a Wx::PdfPrintData
instance in its constructor.

    my $printer = Wx::PdfPrinter->new($wxPdfPrintData);
    $printer->Print($parent, $wxPrintout, 1);

There are complete examples in the Wx::Demo demomodule provided with the distribution.

=head1 makefont and showfont

An interface is provided for calling the makefont and showfont utilities provided
with wxPdfDocument. This is necessary to add the wxWidgets and wxPdfDocument
libraries in your Perl installation to the appropriate LD_LIBRARY_PATH,
DYLD_LIBRARY_PATH and PATH for your operating system and to set the font file
location environment variables.

    my ($status, $stdout, $stderr) = Wx::PdfDocument::MakeFont( $makefontparams );
    my ($status, $stdout, $stderr) = Wx::PdfDocument::ShowFont( $showfontparams );

see

makefont L<http://wxcode.sourceforge.net/docs/wxpdfdoc/makefont.html>

showfont L<http://wxcode.sourceforge.net/docs/wxpdfdoc/showfont.html>

=head1 Launching a PDF Document Viewer

Wx::PdfDocument provides a static method that will query the system for the correct
command to view a pdf document:

    Wx::PdfDocument::LaunchPdfViewer($pdffilepath);


=head1 See Also

L<http://www.wxwidgets.org>

L<http://wxperl.sourceforge.net>

L<http://wxcode.sourceforge.net/docs/wxpdfdoc/>

=head1 RELEASE NOTES

This 0.10 release builds wxPdfDocument 0.9.3 code with minor changes to Windows makefiles to
allow building in the Perl / wxPerl environment. All applied patches are in the
patches subfolder of the distribution.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 & 2012 by Mark Wardell

This library is free software; you can redistribute it and/or modify it under the
same terms as Perl itself, either Perl version 5.12 or, at your option, any later
version of Perl 5 you may have available.

The wxPdfDocument C++ class was created by Ulrich Telle <ulrich.telle@gmx.de>


=cut
__END__





