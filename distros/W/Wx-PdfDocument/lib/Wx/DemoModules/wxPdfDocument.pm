#########################################################################################
# Package       Wx::DemoModules::wxPdfDocument
# Description:  Package Description
# Created       Tue May 01 21:22:36 2012
# SVN Id        $Id: wxPdfDocument.pm 193 2015-03-11 16:08:33Z mark.dootson@gmail.com $
# Copyright:    Copyright (c) 2012 Mark Dootson
# Licence:      This program is free software; you can redistribute it 
#               and/or modify it under the same terms as Perl itself
#########################################################################################

package Wx::DemoModules::wxPdfDocument;

#########################################################################################

use strict;
use Wx;
use base qw(Wx::Panel);
use Wx qw( :sizer :bitmap :id :font :textctrl :image);
use Wx::Event qw( EVT_BUTTON );
use Wx::PdfDocument;
use Wx::Html;
use Wx::RichText;
use Wx::Print;
use Wx qw( :pdfdocument :print wxThePrintPaperDatabase );
use Cwd;

use vars qw( $VERSION );
$VERSION = '0.03';

sub new {
    my( $class, $parent ) = @_;
    my $self = $class->SUPER::new( $parent,  wxID_ANY );
    
    my $headerdialog = Wx::StaticText->new($self, wxID_ANY, 'Dialogs', [-1,-1],[-1,-1], wxALIGN_CENTRE);
    my $headerprintout = Wx::StaticText->new($self, wxID_ANY, 'Printing', [-1,-1],[-1,-1], wxALIGN_CENTRE);
    
    my $pagedialogallbutton = Wx::Button->new($self, wxID_ANY, 'Page Setup Dialog All');
    my $pagedialogminbutton = Wx::Button->new($self, wxID_ANY, 'Page Setup Dialog Min');
    my $printdialogallbutton = Wx::Button->new($self, wxID_ANY, 'Print Dialog All');
    my $printdialogminbutton = Wx::Button->new($self, wxID_ANY, 'Print Dialog Min');
    my $buttoncustomprint = Wx::Button->new($self, wxID_ANY, 'Custom Print Only');
    my $buttondelegateprint = Wx::Button->new($self, wxID_ANY, 'Delegated Printout');
    my $buttonrtprint = Wx::Button->new($self, wxID_ANY, 'RichText Print Only');
    my $buttonhtmlprint = Wx::Button->new($self, wxID_ANY, 'Html Print Only');
    my $buttonrtpreview = Wx::Button->new($self, wxID_ANY, 'RichText Print Preview');
    my $buttonhtmlpreview = Wx::Button->new($self, wxID_ANY, 'Html Print Preview');
    my $buttonpdfdocument = Wx::Button->new($self, wxID_ANY, 'Wx::PlPdfDocument');
    my $buttonpdfdc = Wx::Button->new($self, wxID_ANY, 'Wx::PdfDC');
    
    
    EVT_BUTTON($self, $pagedialogallbutton, \&OnPageDialogAllButton);
    EVT_BUTTON($self, $pagedialogminbutton, \&OnPageDialogMinButton);
    EVT_BUTTON($self, $printdialogallbutton, \&OnPrintDialogAllButton);
    EVT_BUTTON($self, $printdialogminbutton, \&OnPrintDialogMinButton);
    
    EVT_BUTTON($self, $buttonrtprint, \&OnRichTextPrint);
    EVT_BUTTON($self, $buttonhtmlprint, \&OnHtmlPrint);
    EVT_BUTTON($self, $buttonrtpreview, \&OnRichTextPreview);
    EVT_BUTTON($self, $buttonhtmlpreview, \&OnHtmlPreview);
    
    EVT_BUTTON($self, $buttonpdfdocument, \&OnPrintPDFDocument);
    EVT_BUTTON($self, $buttonpdfdc, \&OnPrintPDFDC);
    
    EVT_BUTTON($self, $buttoncustomprint, \&OnCustomPrint);
    EVT_BUTTON($self, $buttondelegateprint, \&OnDelegatedPrint);
    
    # richtext ctrl used to get print data
    $self->{richtext} = Wx::RichTextCtrl->new($self);
    $self->{richtext}->Show(0);
    
    my $mainsizer = Wx::BoxSizer->new(wxVERTICAL);
    my $flexsizer = Wx::FlexGridSizer->new(2,2,3,20);
    $flexsizer->AddGrowableCol(0);
    $flexsizer->AddGrowableCol(1);
    $flexsizer->Add($headerdialog, 0, wxALL|wxEXPAND, 0);
    $flexsizer->Add($headerprintout, 0, wxALL|wxEXPAND, 0);
    $flexsizer->Add($pagedialogallbutton, 0, wxALL|wxEXPAND, 0);
    $flexsizer->Add($buttonrtprint, 0, wxALL|wxEXPAND, 0);
    $flexsizer->Add($pagedialogminbutton, 0, wxALL|wxEXPAND, 0);
    $flexsizer->Add($buttonhtmlprint, 0, wxALL|wxEXPAND, 0);
    $flexsizer->Add($printdialogallbutton, 0, wxALL|wxEXPAND, 0);
    $flexsizer->Add($buttonrtpreview, 0, wxALL|wxEXPAND, 0);
    $flexsizer->Add($printdialogminbutton, 0, wxALL|wxEXPAND, 0);
    $flexsizer->Add($buttonhtmlpreview, 0, wxALL|wxEXPAND, 0);
    $flexsizer->Add($buttoncustomprint, 0, wxALL|wxEXPAND, 0);
    $flexsizer->Add($buttonpdfdocument, 0, wxALL|wxEXPAND, 0);
    $flexsizer->Add($buttondelegateprint, 0, wxALL|wxEXPAND, 0);
    $flexsizer->Add($buttonpdfdc, 0, wxALL|wxEXPAND, 0);
    
    $mainsizer->Add($flexsizer, 0, wxALL, 15);
    $mainsizer->Add($self->{richtext}, 1, wxALL|wxEXPAND, 0);
    $self->SetSizerAndFit($mainsizer);
    $self->writerichtext;
    return $self;
}

sub OnPageDialogAllButton {
    my ($self, $event) = @_;
    my $printdata;
    my $dialogdata = Wx::PageSetupDialogData->new;
    $dialogdata->SetMarginTopLeft([25,25]);
    $dialogdata->SetMarginBottomRight([25,25]);
    $dialogdata->EnableMargins(1);
    $dialogdata->EnablePaper(1);
    $dialogdata->EnableOrientation(1);
    my $dialog = Wx::PdfPageSetupDialog->new($self, $dialogdata);

    if($dialog->ShowModal == wxID_OK ) {
        # get the paper type and orientation
        # in a Wx::PdfPrintData and populate
        # pagesetup with dialog values
        $dialogdata = $dialog->GetPageSetupDialogData;
        $printdata  = Wx::PdfPrintData->new($dialogdata->GetPrintData);
        my $paper = wxThePrintPaperDatabase->FindPaperType($printdata->GetPaperId);
        Wx::LogMessage('The selected paper is: %s', $paper->GetName);
        Wx::LogMessage('The selected orientation is: %s',
                       ( $printdata->GetOrientation == wxPORTRAIT )
                       ? 'Portrait' : 'Landscape' );
        
    }
    
    $dialog->Destroy;
}

sub OnPageDialogMinButton {
    my ($self, $event) = @_;
    my $printdata;
    my $dialogdata = Wx::PageSetupDialogData->new;
    $dialogdata->SetMarginTopLeft([25,25]);
    $dialogdata->SetMarginBottomRight([25,25]);
    $dialogdata->EnableMargins(0);
    $dialogdata->EnablePaper(1);
    $dialogdata->EnableOrientation(0);
    my $dialog = Wx::PdfPageSetupDialog->new($self, $dialogdata);

    if($dialog->ShowModal == wxID_OK ) {
        # get the paper type and orientation
        # in a Wx::PdfPrintData and populate
        # pagesetup with dialog values
        $dialogdata = $dialog->GetPageSetupDialogData;
        $printdata  = Wx::PdfPrintData->new($dialogdata->GetPrintData);
        my $paper = wxThePrintPaperDatabase->FindPaperType($printdata->GetPaperId);
        Wx::LogMessage('The selected paper is: %s', $paper->GetName);
        Wx::LogMessage('The selected orientation is: %s',
                       ( $printdata->GetOrientation == wxPORTRAIT )
                       ? 'Portrait' : 'Landscape' );
        
    }
    
    $dialog->Destroy;
}

sub OnPrintDialogAllButton {
    my ($self, $event) = @_;
    my $printdata = Wx::PdfPrintData->new;
    my $dialog = Wx::PdfPrintDialog->new($self, $printdata);

     if($dialog->ShowModal == wxID_OK ) {
        $printdata  = $dialog->GetPdfPrintData;
        Wx::LogMessage('Document Title : %s', $printdata->GetDocumentTitle);
    }
    
    $dialog->Destroy;
}

sub OnPrintDialogMinButton {
    my ($self, $event) = @_;
    my $printdata = Wx::PdfPrintData->new;
    $printdata->SetPrintDialogFlags( wxPDF_PRINTDIALOG_OPENDOC|wxPDF_PRINTDIALOG_FILEPATH );
    ## check launch doc CheckBox
    $printdata->SetLaunchDocumentViewer(1);
    
    my $dialog = Wx::PdfPrintDialog->new($self, $printdata);

    if($dialog->ShowModal == wxID_OK ) {
        $printdata  = $dialog->GetPdfPrintData;
        Wx::LogMessage('Selected filepath : %s', $printdata->GetFilename);
    }
    
    $dialog->Destroy;
}

sub OnRichTextPrint {
    my( $self, $event ) = @_;
    
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
    
    my $rtbuffer = Wx::RichTextBuffer->new($self->{richtext}->GetBuffer);
    my $printprintout = Wx::RichTextPrintout->new("Demo RichText PDF Printing");
    
    $printprintout->SetMargins(
                      10 * $dialogdata->GetMarginTopLeft->y,
                      10 * $dialogdata->GetMarginBottomRight->y,
                      10 * $dialogdata->GetMarginTopLeft->x,
                      10 * $dialogdata->GetMarginBottomRight->x
                      );
    $printprintout->SetRichTextBuffer($rtbuffer);
    
    # limit the options available in the print dialog
    # to filepath selection and viewer open
    $printdata->SetPrintDialogFlags( wxPDF_PRINTDIALOG_OPENDOC|wxPDF_PRINTDIALOG_FILEPATH );
    # Have the open checkbox checked by default
    $printdata->SetLaunchDocumentViewer(1);
    
    my $printer = Wx::PdfPrinter->new($printdata);
    $printer->Print($self, $printprintout, 1);
}

sub OnRichTextPreview {
    my( $self, $event ) = @_;
    
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
    $printpreview->SetZoom(65);
    my $frame = Wx::PreviewFrame->new( $printpreview, $self,
                                     "PDF RichText Printing Preview", [-1, -1], [600, 600] );
    $frame->Initialize();
    $frame->Show( 1 );
}

sub OnHtmlPrint {
    my( $self, $event ) = @_;
    
    my $printdata;
    my $dialogdata = Wx::PageSetupDialogData->new;
    $dialogdata->SetMarginTopLeft([25,25]);
    $dialogdata->SetMarginBottomRight([25,25]);
    $dialogdata->EnableMargins(1);
    $dialogdata->EnablePaper(1);
    
    #our particular html only really works in landscape
    $dialogdata->EnableOrientation(0);
    $dialogdata->GetPrintData->SetOrientation(&Wx::wxLANDSCAPE);
    my $dialog = Wx::PdfPageSetupDialog->new($self, $dialogdata);
    if($dialog->ShowModal == wxID_OK ) {
        $dialogdata = $dialog->GetPageSetupDialogData;
        $printdata  = Wx::PdfPrintData->new($dialogdata->GetPrintData);
    }
    $dialog->Destroy;
    return unless $printdata;
    
    my $htmlfile = Wx::Demo->get_data_file( qq(pdfdocument/example.html) );
    my $printprintout = Wx::HtmlPrintout->new('PDF Test Html Print');
    $printprintout->SetHtmlFile($htmlfile);
    $printprintout->SetStandardFonts(12, "Arial Unicode", "Courier New");
    
    $printprintout->SetMargins(
                      $dialogdata->GetMarginTopLeft->y,
                      $dialogdata->GetMarginBottomRight->y,
                      $dialogdata->GetMarginTopLeft->x,
                      $dialogdata->GetMarginBottomRight->x
                      );
    
    # limit the options available in the print dialog
    # to filepath selection and viewer open
    $printdata->SetPrintDialogFlags( wxPDF_PRINTDIALOG_OPENDOC|wxPDF_PRINTDIALOG_FILEPATH );
    # Have the open checkbox checked by default
    $printdata->SetLaunchDocumentViewer(1);
    
    my $printer = Wx::PdfPrinter->new($printdata);
    $printer->Print($self, $printprintout, 1);

}

sub OnHtmlPreview {
    my( $self, $event ) = @_;
    
    my $printdata;
    my $dialogdata = Wx::PageSetupDialogData->new;
    $dialogdata->SetMarginTopLeft([25,25]);
    $dialogdata->SetMarginBottomRight([25,25]);
    $dialogdata->EnableMargins(1);
    $dialogdata->EnablePaper(1);
    
    #our particular html only really works in landscape
    $dialogdata->EnableOrientation(0);
    $dialogdata->GetPrintData->SetOrientation(&Wx::wxLANDSCAPE);
    my $dialog = Wx::PdfPageSetupDialog->new($self, $dialogdata);
    if($dialog->ShowModal == wxID_OK ) {
        $dialogdata = $dialog->GetPageSetupDialogData;
        $printdata  = Wx::PdfPrintData->new($dialogdata->GetPrintData);
    }
    $dialog->Destroy;
    return unless $printdata;
    
    my $htmlfile = Wx::Demo->get_data_file( qq(pdfdocument/example.html) );
    
    my $printprintout = Wx::HtmlPrintout->new('PDF Test Html Print');
    $printprintout->SetHtmlFile($htmlfile);
    $printprintout->SetStandardFonts(12, "Arial Unicode", "Courier New");
    
    $printprintout->SetMargins(
                      $dialogdata->GetMarginTopLeft->y,
                      $dialogdata->GetMarginBottomRight->y,
                      $dialogdata->GetMarginTopLeft->x,
                      $dialogdata->GetMarginBottomRight->x
                      );
    
    my $previewprintout = Wx::HtmlPrintout->new('PDF Test Html Preview');
    $previewprintout->SetHtmlFile($htmlfile);
    $previewprintout->SetStandardFonts(12, "Arial Unicode", "Courier New");
    
    $previewprintout->SetMargins(
                      $dialogdata->GetMarginTopLeft->y,
                      $dialogdata->GetMarginBottomRight->y,
                      $dialogdata->GetMarginTopLeft->x,
                      $dialogdata->GetMarginBottomRight->x
                      );

    my $printpreview = Wx::PdfPrintPreview->new( $previewprintout, $printprintout, $printdata);
    $printpreview->SetZoom(65);
    my $frame = Wx::PreviewFrame->new( $printpreview, $self,
                                     "PDF Html Printing Preview", [-1, -1], [600, 600] );
    $frame->Initialize();
    $frame->Show( 1 );
}

sub OnCustomPrint {
    my( $self, $event ) = @_;
    
    my $printdata;
    my $dialogdata = Wx::PageSetupDialogData->new;
    $dialogdata->SetMarginTopLeft([25,25]);
    $dialogdata->SetMarginBottomRight([25,25]);
    $dialogdata->EnableMargins(0);
    $dialogdata->EnablePaper(1);
    $dialogdata->EnableOrientation(1);
    my $dialog = Wx::PdfPageSetupDialog->new($self, $dialogdata);
    if($dialog->ShowModal == wxID_OK ) {
        $dialogdata = $dialog->GetPageSetupDialogData;
        $printdata  = Wx::PdfPrintData->new($dialogdata->GetPrintData);
    }
    $dialog->Destroy;
    return unless $printdata;
    
    my $printprintout = Wx::DemoModules::wxPdfDocument::CustomPrintOut->new('PDF Test Custom Print');
    
    # limit the options available in the print dialog
    # to filepath selection and viewer open
    $printdata->SetPrintDialogFlags( wxPDF_PRINTDIALOG_OPENDOC|wxPDF_PRINTDIALOG_FILEPATH );
    # Have the open checkbox checked by default
    $printdata->SetLaunchDocumentViewer(1);
    
    my $printer = Wx::PdfPrinter->new($printdata);
    $printer->Print($self, $printprintout, 1);

}

sub OnDelegatedPrint {
    my ($self, $event) = @_;
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
    
    
    my $proxyprint = Wx::DemoModules::wxPdfDocument::DelegatedPrintout->new(
                            "Demo RichText PDF Printing", $printprintout);
    
   
    my $previewbuffer   = Wx::RichTextBuffer->new($self->{richtext}->GetBuffer);
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
    
    my $proxypreview = Wx::DemoModules::wxPdfDocument::DelegatedPrintout->new(
                        "Demo RichText PDF Preview",$previewprintout);
    
    my $printpreview = Wx::PdfPrintPreview->new($proxypreview, $proxyprint, $printdata );
    $printpreview->SetZoom(65);
    my $frame = Wx::PreviewFrame->new( $printpreview, $self,
                                     "PDF RichText Printing Preview", [-1, -1], [600, 600] );
    
    $frame->Initialize();
    $frame->Show( 1 );
    
}

sub OnPrintPDFDocument {
    my($self, $event) = @_;
    
    # select a demo to run
    
    my $demomodule = Wx::GetSingleChoiceData(
        'Select a tutorial or example to run.', 'Wx::PdfDocument',
        [
            'Tutorial 1 - Basics',
            'Tutorial 2 - Header, Footer and Logo',
            'Tutorial 3 - Line Breaks and Colours',
            'Tutorial 4 - Multiple Columns',
            'Tutorial 5 - Tables',
            'Tutorial 6 - Links and Flowing Text',
            'Wx::Font and Adobe Core Font usage',
            'Indic Fonts  - Indic fonts and languages (unicode only)',
            'CJK Fonts - Chinese, Japanese and Korean Fonts (unicode only)',
            'Attachment - Attaching a file',
            'Barcodes   - Barcode creator add-on',
            'Bookmarks  - Adding bookmarks and annotations',
            'Charting   - Simple pie and bar charts',
            'Clipping   - Clipping options',
            'Drawing    - Lines, rectangles, ellipses, polygons and curves with line style',
            'Gradients  - Linear and radial gradients',
            'JavaScript  - Embedding JavaScript in a document',
            'Forms  - Creating interactive forms',
            'Kerning  - Demonstrate use of kerning',
            'Labels  - Print label sheets to PDF',
            'Layers Ordered  - how to order optional content groups',
            'Layers Grouped  - Layers appear in the order in that they were added to the document',
            'Layers Nested  - nested layers',
            'Layers Automatic  - automatic layer grouping and nesting',
            'Layers Radio Group  - demonstrates radio group and zoom',
            'Protection - Print  - allow print but no copy',
            'Protection - Encrypt  - password protect a document',
            'Rotation - rotated text and images',
            'Template - Internal - use an internal template',
            'Template - External - use an external template',
            'Transformation - geometric drawing transformations',
            'Transparency - using masks',
            'XML Write - create documents from Html mark-up'
        ],
        [ qw( 
            Tutorial1 Tutorial2 Tutorial3 Tutorial4 Tutorial5 Tutorial6
            Fonts IndicFonts CJKFonts
            Attachment Barcode Bookmark Charting Clipping Drawing Gradients
            JavaScript Forms Kerning Labels LayersOrdered
            LayersGrouped LayersNested LayersAutomatic LayersRadioGroup
            ProtectionPrint ProtectionEncrypt Rotation TemplateInternal
            TemplateExternal Transformation Transparency XMLWrite
            )
        ],
        $self );
    
    return if !$demomodule;
    
    $demomodule = 'Wx::DemoModules::wxPdfDocument::' . $demomodule;
    
    # get a filename and launch option from user
    
    my $printdata = Wx::PdfPrintData->new;
    $printdata->SetPrintDialogFlags( wxPDF_PRINTDIALOG_OPENDOC|wxPDF_PRINTDIALOG_FILEPATH );
    $printdata->SetLaunchDocumentViewer(1);
    my $dialog = Wx::PdfPrintDialog->new($self, $printdata);
    my ($filepath, $dolaunch);
    if($dialog->ShowModal == wxID_OK ) {
        $printdata  = $dialog->GetPdfPrintData;
        $filepath = $printdata->GetFilename;
        if(($filepath !~ /^[\\\/]/) && ($filepath !~ /^[A-Z]:/i)) {
            $filepath = getcwd() . qq(/$filepath);
        }
        $dolaunch = $printdata->GetLaunchDocumentViewer;
    }
    $dialog->Destroy;
    
    return if !$filepath;
    my $busycursor = Wx::BusyCursor->new();
    my $busy = Wx::BusyInfo->new('Creating Document ...');
    &Wx::wxTheApp->Yield; # update the busyinfo
    my $demo = $demomodule->new;
    $demo->run_pdfdemo($filepath);
    
    if( $dolaunch ) {
        my $mtm = Wx::MimeTypesManager->new();
        if( my $filetype = $mtm->GetFileTypeFromExtension('pdf') ) {
            my $cmd = $filetype->GetOpenCommand($filepath);
            Wx::ExecuteCommand($cmd);
        } else {
            Wx::LogError('Could not find viewer for PDFs');
        }
    }
}

sub OnPrintPDFDC {
    my($self, $event) = @_;
    
    # You can create and use a Wx::PdfDC directly if you wish to create PDF
    # documents using the standard wxWidgets wxDC commands and don't have
    # a Wx::Printout implementation
    
    # Get filename for output from user
    my $printdata = Wx::PdfPrintData->new;
    $printdata->SetPrintDialogFlags( wxPDF_PRINTDIALOG_OPENDOC|wxPDF_PRINTDIALOG_FILEPATH );
    $printdata->SetLaunchDocumentViewer(1);
    my $dialog = Wx::PdfPrintDialog->new($self, $printdata);
    my ($filepath, $dolaunch);
    if($dialog->ShowModal == wxID_OK ) {
        $printdata  = $dialog->GetPdfPrintData;
        $filepath = $printdata->GetFilename;
        if(($filepath !~ /^[\\\/]/) && ($filepath !~ /^[A-Z]:/i)) {
            $filepath = getcwd() . qq(/$filepath);
        }
        $dolaunch = $printdata->GetLaunchDocumentViewer;
    }
    $dialog->Destroy;
    
    return if !$filepath;
    my $busycursor = Wx::BusyCursor->new();
    my $busy = Wx::BusyInfo->new('Creating Document ...');
    &Wx::wxTheApp->Yield; # update the busyinfo
    
    # do the drawing
    
    my $wxprintdata = Wx::PrintData->new;
    $wxprintdata->SetFilename($filepath);
    $wxprintdata->SetOrientation(&Wx::wxPORTRAIT);
    $wxprintdata->SetPaperId(&Wx::wxPAPER_A4);
    
    my $dc = Wx::PdfDC->new($wxprintdata);
    my $resolution = 600.0;
    $dc->SetResolution($resolution);
    $dc->StartDoc('Wx::PdfDC Printing Test');
    # wxPdfDC has a special mode that correctly scales
    # text and graphics together
    $dc->SetMapModeStyle(wxPDF_MAPMODESTYLE_PDF);
    $dc->SetMapMode(&Wx::wxMM_POINTS);

    $dc->StartPage;
      
    $dc->SetBackground(&Wx::wxWHITE_BRUSH);
    $dc->Clear();
    $dc->SetFont(Wx::Font->new(10, wxFONTFAMILY_SWISS, wxFONTSTYLE_NORMAL, wxFONTWEIGHT_NORMAL, 0, 'Arial'));

    $dc->SetBackgroundMode(&Wx::wxTRANSPARENT);

    $dc->SetPen(&Wx::wxBLACK_PEN);
    $dc->SetBrush(&Wx::wxLIGHT_GREY_BRUSH);

    $dc->DrawRectangle(0, 0, 230, 350);
    $dc->DrawLine(0, 0, 229, 349);
    $dc->DrawLine(229, 0, 0, 349);
    $dc->SetBrush(&Wx::wxCYAN_BRUSH);
    $dc->SetPen(&Wx::wxRED_PEN);

    $dc->DrawRoundedRectangle(0, 20, 200, 80, 20);
    $dc->DrawText( 'Rectangle 200 by 80', 40, 40);

    $dc->SetPen(Wx::Pen->new(&Wx::wxBLACK,0,&Wx::wxDOT_DASH) );
    $dc->DrawEllipse(50, 140, 100, 50);
    $dc->SetPen(&Wx::wxRED_PEN);

    $dc->DrawText( 'Test message: this is in 10 point text', 10, 180);
    
    my @pvals = ( 0,0,20,0,20,20,10,20,10,-20 );
    my @points;
    for (my $i = 0; $i < @pvals; $i += 2) {
        push( @points, Wx::Point->new( $pvals[$i], $pvals[$i + 1]) );
    }
    
    $dc->DrawPolygon(\@points, 20, 250, &Wx::wxODDEVEN_RULE );
    $dc->DrawPolygon(\@points, 50, 250, &Wx::wxWINDING_RULE );
    
    $dc->DrawEllipticArc( 80, 250, 60, 30, 0.0, 270.0 );
    
    @pvals = ( 150,250,180,250,180,220,200,220 );
    @points = ();
    for (my $i = 0; $i < @pvals; $i += 2) {
        push( @points, Wx::Point->new( $pvals[$i], $pvals[$i + 1]) );
    }
    
    $dc->DrawSpline( \@points );
    
    $dc->DrawArc( 20,10, 10,10, 25,40 );
    $dc->DrawRotatedText( qq(---- Text at angle 0  -----), 100, 300, 0 );
    $dc->DrawRotatedText( qq(---- Text at angle 35 -----), 100, 300, 35 );
    
    my $logo = Wx::Demo->get_data_file( qq(pdfdocument/wxpdfdoc.png) );
    my $bitmap = Wx::Bitmap->new($logo, &Wx::wxBITMAP_TYPE_PNG);
    $dc->DrawBitmap($bitmap, 300, 200, 0);
    $dc->EndPage;
    $dc->EndDoc;
    
    if( $dolaunch ) {
        my $mtm = Wx::MimeTypesManager->new();
        if( my $filetype = $mtm->GetFileTypeFromExtension('pdf') ) {
            my $cmd = $filetype->GetOpenCommand($filepath);
            Wx::ExecuteCommand($cmd);
        } else {
            Wx::LogError('Could not find viewer for PDFs');
        }
    }
}


sub writerichtext {
    my $self = shift;
    my $font = Wx::Font->new( 12, wxSWISS, wxNORMAL, wxNORMAL , 0, 'Arial');
    my $r = $self->{richtext};
    $r->BeginSuppressUndo;    
    $r->BeginFont($font);
    $r->BeginParagraphSpacing(0, 20);
    $r->BeginAlignment(wxTEXT_ALIGNMENT_CENTRE);
    $r->BeginBold;
    $r->BeginFontSize(16);
    $r->WriteText("Welcome to Wx::PdfDocument, the wxPerl wrapper for wxPdfDocument.");
    $r->EndFontSize;
    $r->Newline;
    $r->BeginItalic;
    $r->WriteText("Text taken from wxRichText control example.");
    $r->EndItalic;
    $r->EndBold;
    $r->Newline;
    $r->Newline;
    my $logo = Wx::Demo->get_data_file( qq(pdfdocument/demologo.png) );
    if( -f $logo ) {
        # my bitmap is intended to be displayed at 100 pixels per inch
        my $imagescale = Wx::ScreenDC->new->GetPPI->x / 100;
        my $bitmap = Wx::Bitmap->new($logo, wxBITMAP_TYPE_PNG);
        my $scalex = int (0.5 + ( $bitmap->GetWidth * $imagescale ));
        my $scaley = int (0.5 + ( $bitmap->GetHeight * $imagescale ));
        $r->WriteImage( Wx::Image->new($bitmap)->Scale($scalex,$scaley, wxIMAGE_QUALITY_HIGH ), wxBITMAP_TYPE_PNG );
        $r->Newline;
        $r->Newline;
    }
    $r->EndAlignment;
    
    for (my $i = 0; $i < 10; $i++) {
        $r->WriteText("What can you do with this thing? ");
        $r->WriteText(" Well, you can change text ");
        $r->BeginTextColour(Wx::Colour->new(255, 0, 0));
        $r->WriteText("colour, like this red bit.");
        $r->EndTextColour;
        $r->BeginTextColour(Wx::Colour->new(0, 0, 255));
        $r->WriteText(" And this blue bit.");
        $r->EndTextColour;
        $r->WriteText(" Naturally you can make things ");
        $r->BeginBold;
        $r->WriteText("bold ");
        $r->EndBold;
        $r->BeginItalic;
        $r->WriteText("or italic ");
        $r->EndItalic;
        $r->BeginUnderline;
        $r->WriteText("or underlined.");
        $r->EndUnderline;
        $r->BeginFontSize(14);
        $r->WriteText(" Different font sizes on the same line is allowed, too.");
        $r->EndFontSize;
        $r->WriteText(" Next we'll show an indented paragraph.");
        $r->BeginLeftIndent(60);
        $r->Newline;
        $r->WriteText("Indented paragraph.");
        $r->EndLeftIndent;
        $r->Newline;
        $r->WriteText("Next, we'll show a first-line indent, achieved using BeginLeftIndent(100, -40).");
        $r->BeginLeftIndent(100, -40);
        $r->Newline;
        $r->WriteText("It was in January, the most down-trodden month of an Edinburgh winter.");
        $r->EndLeftIndent;
        $r->Newline;
        $r->WriteText("Numbered bullets are possible, again using subindents:");
        $r->BeginNumberedBullet(1, 100, 60);
        $r->Newline;
        $r->WriteText("This is my first item. Note that wxRichTextCtrl doesn't automatically do numbering, but this will be added later.");
        $r->EndNumberedBullet;
        $r->BeginNumberedBullet(2, 100, 60);
        $r->Newline;
        $r->WriteText("This is my second item.");
        $r->EndNumberedBullet;
        $r->Newline;
        $r->WriteText("The following paragraph is right-indented:");
        $r->BeginRightIndent(200);
        $r->Newline;
        $r->WriteText("It was in January, the most down-trodden month of an Edinburgh winter. An attractive woman came into the cafe, which is nothing remarkable.");
        $r->EndRightIndent;
        $r->Newline;
        my $attr = Wx::TextAttrEx->new;;
        $attr->SetFlags( wxTEXT_ATTR_TABS );
        $attr->SetTabs( [ 400, 600, 800, 1000 ] );
        $attr->SetFont(Wx::Font->new( 10, wxROMAN, wxNORMAL, wxNORMAL , 0, 'Times New Roman'));
        $r->SetDefaultStyle($attr);
        $r->WriteText("This line contains tabs:\tFirst tab\tSecond tab\tThird tab");
        $r->Newline;
        $r->WriteText("Other notable features of wxRichTextCtrl include:");
        $r->BeginSymbolBullet('*', 100, 60);
        $r->Newline;
        $r->WriteText("Compatibility with wxTextCtrl API");
        $r->Newline;
        $r->EndSymbolBullet;
    }
    $r->EndSuppressUndo;
}

sub add_to_tags { qw( new misc ) }
sub title { 'wxPdfDocument' }

###################################################

package Wx::DemoModules::wxPdfDocument::CustomPrintOut;

###################################################
use strict;
use warnings;
use Wx::PdfDocument;
use Wx qw( :print :font :pdfdocument :dc :brush );
use base qw( Wx::Printout );

use vars qw( $VERSION );
$VERSION = '0.03';

sub new { shift->SUPER::new( @_ ); }


sub GetPageInfo {
    my $self = shift;
    return (1,1,1,1);
}

sub HasPage {
    my ($self, $pagenum) = @_;
    return ( $pagenum == 1 ) ? 1 : 0;
}

sub OnPrintPage {
    my($self, $pagenum) =@_;
    return 0 if $pagenum != 1;
    my $dc = $self->GetDC;
    
    $dc->SetMapModeStyle(wxPDF_MAPMODESTYLE_PDF) if $dc->can('SetMapModeStyle');
    
    # Zoom by factor 5
    
    $dc->SetUserScale(5.0, 5.0);
    
    my $leftmargin = 12.0;
    my $lineheight = 12.0;
    
    $dc->SetMapMode(wxMM_LOMETRIC);
    my $xyscale = 254.0 / 72.0; # translate x y positions
    my $text = 'The quick brown fox jumped over the lazy dog';
    my $font = Wx::Font->new( 12, wxSWISS, wxNORMAL, wxNORMAL , 0, 'Arial');
    $dc->SetFont($font);
    $dc->SetBrush(wxTRANSPARENT_BRUSH);
    my($w,$h,$d,$l) = $dc->GetTextExtent($text);
    
    my $x = $leftmargin;
    my $y = $lineheight;
    
    $dc->DrawText($text, $x * $xyscale, $y * $xyscale);
    # when MapModeStyle is wxPDF_MAPMODESTYLE_PDF then the $y position of text
    # is the font baseline - not the top of the text box - so to draw
    # a rectangle around the text y coord = y - ascent or y - ( height - descent)
    
    $dc->DrawRectangle( $x * $xyscale, ($y * $xyscale) - ( $h - $d ), $w, $h);
    $y += $lineheight;
    
    $dc->DrawText(qq(Metrics A $w, $h, $d, $l), $x * $xyscale, $y * $xyscale);
    $y += $lineheight;
    
    $dc->SetMapMode(wxMM_TWIPS);
    $xyscale = 1440.0 / 72.0;
    ($w,$h,$d,$l) = $dc->GetTextExtent($text);
    
    $dc->DrawText(qq(Metrics C $w, $h, $d, $l),$x * $xyscale, $y * $xyscale);
    $y += $lineheight;
    
    $dc->SetMapMode(wxMM_TEXT);
    $xyscale = $dc->GetResolution / 72.0;
    #my $screenppi = Wx::ScreenDC->new->GetPPI;
    #my $deviceppi = $dc->GetPPI;
    #my $scale = ($deviceppi->x / $screenppi->x);
    
    #$dc->SetUserScale($scale, $scale);
    $text .= ' 2';
    ($w,$h,$d,$l) = $dc->GetTextExtent($text);
    $dc->DrawText($text, $x * $xyscale, $y * $xyscale);
    $dc->DrawRectangle( $x * $xyscale, ($y * $xyscale) - ( $h - $d ), $w, $h);
    $y += $lineheight;
    
    $dc->DrawText(qq(Metrics D $w, $h, $d, $l), $x * $xyscale, $y * $xyscale);
    
    
    return 1;
}

###################################################

package Wx::DemoModules::wxPdfDocument::DelegatedPrintout;

###################################################
use strict;
use warnings;
use Wx::PdfDocument;
use Wx qw( :print :font :dc :brush :pen);
use base qw( Wx::Printout );

use vars qw( $VERSION );
$VERSION = '0.03';

sub new {
    my( $class, $title, $delegate) = @_;
    my $self = $class->SUPER::new($title);
    $self->{_delegate} = $delegate;
    return $self;
}

sub _delegate { $_[0]->{_delegate} ; }

sub _prepare_delegate { $_[0]->_delegate->SetDC( $_[0]->GetDC ); }

sub OnPreparePrinting {
    my $self = shift;
    # we must set up the delegate printout
    # as it would be setup by the printer
    # so we can just copy our settings
   
    $self->_delegate->SetPPIScreen($self->GetPPIScreen);
    $self->_delegate->SetPPIPrinter($self->GetPPIPrinter);
    $self->_delegate->SetPageSizePixels($self->GetPageSizePixels);
    $self->_delegate->SetPaperRectPixels($self->GetPaperRectPixels);
    $self->_delegate->SetPageSizeMM($self->GetPageSizeMM);
    $self->_prepare_delegate;
    
    if( $self->IsPreview ) {
        if( $self->_delegate->can('SetPreview') ) {
            $self->_delegate->SetPreview($self->GetPreview);
        } else {
            $self->_delegate->SetIsPreview(1);
        }
    }
   
    $self->_delegate->OnPreparePrinting;
}

sub GetPageInfo {
    my $self = shift;
    my ($min, $max, $from, $to) = $self->_delegate->GetPageInfo();
    return ($min, $max, $from, $to);
}

sub HasPage { $_[0]->_delegate->HasPage( $_[1] ); }

sub OnBeginPrinting { $_[0]->_delegate->OnBeginPrinting; }

sub OnBeginDocument {
    my ($self, $start, $end) = @_;
    $self->_prepare_delegate;
    return $self->_delegate->OnBeginDocument( $start, $end );
}

sub OnEndDocument {
    $_[0]->_prepare_delegate;
    $_[0]->_delegate->OnEndDocument;
}

sub OnEndPrinting { $_[0]->_delegate->OnEndPrinting; }

sub OnPrintPage {
    my($self, $pagenum ) = @_;
    $self->_prepare_delegate;
    return 0 unless $self->_delegate->OnPrintPage( $pagenum );
    
    my $dc = $self->_delegate->GetDC;
    
    # save DC state
    my ($restoreScaleX, $restoreScaleY) = $dc->GetUserScale;
    my $restoreMapMode  = $dc->GetMapMode;
    my $restorePen      = $dc->GetPen;
    my $restoreBrush    = $dc->GetBrush;
    
    # scaling
    if( $self->IsPreview ) {
        my $screenppi = Wx::ScreenDC->new->GetPPI;
        my $scale = $restoreScaleX * $screenppi->x / 72.0;
        $dc->SetUserScale($scale, $scale);
    } else {
        $dc->SetUserScale(1.0, 1.0);
    }
    $dc->SetMapMode(wxMM_LOMETRIC);
    
    # drawing
    $dc->SetBrush(wxTRANSPARENT_BRUSH);
    $dc->SetPen(wxBLACK_PEN);
    my( $pageW, $pageH) = $self->_delegate->GetPageSizeMM;
    $dc->DrawRectangle( 100, 100, ($pageW * 10) - 200 , ($pageH * 10) - 200 );
    
    # restore
    $dc->SetMapMode($restoreMapMode);
    $dc->SetUserScale($restoreScaleX, $restoreScaleY);
    $dc->SetBrush($restoreBrush);
    $dc->SetPen($restorePen);
    
    return 1;
}

#############################################################################
#
# Wx::PdfDocument tutorial classes
#
#############################################################################

###################################################

package 
   Wx::DemoModules::wxPdfDocument::Tutorial1;

###################################################

#/**
#* Minimal example
#*
#* The wxPdfDocument constructor is used here with the default values:
#* pages are in A4 portrait and the measure unit is millimeter.
#*
#* It would be possible to use landscape, other page formats (such as Letter and Legal)
#* and measure units (pt, cm, in). 
#* 
#* There is no page for the moment, so we have to add one with AddPage(). The origin is
#* at the upper-left corner and the current position is by default placed at 1 cm from
#* the borders; the margins can be changed with SetMargins(). 
#*
#* Before we can print text, it is mandatory to select a font with SetFont(), otherwise
#* the document would be invalid. We choose Helvetica bold 16.
#*
#* We could have specified italics with I, underlined with U or a regular font with an
#* empty string (or any combination). Note that the font size is given in points, not
#* millimeters (or another user unit); it is the only exception. The other standard fonts
#* are Times, Courier, Symbol and ZapfDingbats. 
#
#* We can now print a cell with Cell(). A cell is a rectangular area, possibly framed,
#* which contains some text. It is output at the current position. We specify its dimensions,
#* its text (centered or aligned), if borders should be drawn, and where the current position
#* moves after it (to the right, below or to the beginning of the next line).
#* 
#* To add a new cell next to it with centered text and go to the next line, we would do:
#* 
#* $pdf->Cell(60,10,'Powered by wxPdfDocument',wxPDF_BORDER_NONE,1,wxPDF_ALIGN_CENTER);
#* 
#* Remark : the line break can also be done with Ln(). This method allows to specify in
#* addition the height of the break. 
#* 
#* Finally, the document is closed and sent to file with SaveAsFile().
#*/

use strict;
use warnings;
use Wx::PdfDocument;
use Wx qw( :pdfdocument :print );

sub new {
    my $class = shift;
    my $self = bless {}, $class;
    return $self;
}

sub run_pdfdemo {
    my ($self, $filepath) = @_;
    my $pdf = Wx::PlPdfDocument->new;
    $pdf->AddPage(wxPORTRAIT,wxPAPER_A4);
    $pdf->SetFont('Helvetica','B',16);
    $pdf->Cell(40,10,'Hello World!');
    $pdf->AddPage(wxLANDSCAPE,wxPAPER_A4);
    $pdf->SetFont('Helvetica','B',16);
    $pdf->Cell(40,10,'Hello World!');
    $pdf->AddPage(wxPORTRAIT,wxPAPER_A3);
    $pdf->SetFont('Helvetica','B',16);
    $pdf->Cell(40,10,'Hello World!');
    $pdf->AddPage(wxLANDSCAPE,wxPAPER_A3);
    $pdf->SetFont('Helvetica','B',16);
    $pdf->Cell(40,10,'Hello World!');
    $pdf->SaveAsFile($filepath);
}

###################################################

package 
   Wx::DemoModules::wxPdfDocument::Tutorial2;

###################################################

#/**
#* Here is a two page example with header, footer and logo: 
#*
#* This example makes use of the Header() and Footer() methods to process page
#* headers and footers. They are called automatically. They already exist in the
#* wxPdfDocument class but do nothing, therefore we have to extend the class and override
#* them. 
#* 
#* The logo is printed with the Image() method by specifying its upper-left corner
#* and its width. The height is calculated automatically to respect the image
#* proportions. 
#* 
#* To print the page number, a null value is passed as the cell width. It means
#* that the cell should extend up to the right margin of the page; it is handy to
#* center text. The current page number is returned by the PageNo() method; as for
#* the total number of pages, it is obtained by means of the special value {nb}
#* which will be substituted on document closure (provided you first called
#* AliasNbPages()). 
#* 
#* Note the use of the SetY() method which allows to set position at an absolute
#* location in the page, starting from the top or the bottom. 
#
#* Another interesting feature is used here: the automatic page breaking. As soon
#* as a cell would cross a limit in the page (at 2 centimeters from the bottom by
#* default), a break is performed and the font restored. Although the header and
#* footer select their own font (Helvetica), the body continues with Times. This mechanism
#* of automatic restoration also applies to colors and line width. The limit which
#* triggers page breaks can be set with SetAutoPageBreak(). 
#*/

use strict;
use warnings;
use Wx::PdfDocument;
use Wx qw( :pdfdocument :print );
use base qw( Wx::PlPdfDocument );

sub new {
    my $class = shift;
    my $self = $class->SUPER::new( @_ );
    return $self;
}

sub Header {
    my $self = shift;
    # Logo
    my $logo = Wx::Demo->get_data_file( qq(pdfdocument/wxpdfdoc.png) );
    $self->Image($logo,10,8,28);
    # Helvetica bold 15
    $self->SetFont('Helvetica','B',15);
    # Move to the right
    $self->Cell(80);
    # Title
    $self->Cell(30,10,'Title',wxPDF_BORDER_FRAME,0,wxPDF_ALIGN_CENTER);
    # Line break
    $self->Ln(20);
}

sub Footer {
    my $self = shift;
    # Position at 1.5 cm from bottom
    $self->SetY(-15);
    # Helvetica italic 8
    $self->SetFont('Helvetica','I',8);
    # Page number
    $self->Cell(0,10, sprintf("Page %s", $self->PageNo ),0,0,wxPDF_ALIGN_CENTER);
}

sub run_pdfdemo {
    my ($self, $filepath) = @_;
    $self->AliasNbPages();
    $self->AddPage();
    
    my $smile = Wx::Demo->get_data_file( qq(pdfdocument/smile.jpg) );
    my $apple = Wx::Demo->get_data_file( qq(pdfdocument/apple.gif) );
    
    $self->Image($smile,70,40,12);
    $self->Image($apple,110,40,25);
    $self->SetFont('Times','',12);
  
    for (my $i = 1; $i <= 40; $i++)
    {
        $self->Cell(0,10, qq(Printing line number $i),0,1);
    }
    
    $self->SaveAsFile($filepath);
}

###################################################

package 
   Wx::DemoModules::wxPdfDocument::Tutorial3;

###################################################

#/**
#* Line breaks and colors
#*
#* Let's continue with an example which prints justified paragraphs.
#* It also illustrates the use of colors. 
#* 
#* The GetStringWidth() method allows to determine the length of a string in the
#* current font, which is used here to calculate the position and the width of
#* the frame surrounding the title. Then colors are set (via SetDrawColor(),
#* SetFillColor() and SetTextColor()) and the thickness of the line is set to
#* 1 mm (against 0.2 by default) with SetLineWidth(). Finally, we output the cell
#* (the last parameter to 1 indicates that the background must be filled). 
#* 
#* The method used to print the paragraphs is MultiCell(). Each time a line reaches
#* the right extremity of the cell or a carriage-return character is met, a line
#* break is issued and a new cell automatically created under the current one.
#* Text is justified by default. 
#* 
#* Two document properties are defined: title (SetTitle()) and author (SetAuthor()).
#* Properties can be viewed by two means. First is open the document directly with
#* Acrobat Reader, go to the File menu, Document info, General. Second, also available
#* from the plug-in, is click on the triangle just above the right scrollbar and
#* choose Document info. 
#*/

use strict;
use warnings;
use Wx::PdfDocument;
use Wx qw( :pdfdocument :print );
use base qw( Wx::PlPdfDocument );

sub new {
    my $class = shift;
    my $self = $class->SUPER::new( @_ );
    return $self;
}

sub Header {
    my $self = shift;
    # page header
    $self->SetFont("Helvetica","B",15);
    # Calculate width of title and position
    my $w = $self->GetStringWidth($self->{title}) + 6;
    $self->SetX((210 - $w)/2);
    # Colors of frame, background and text
    $self->SetDrawColour(Wx::Colour->new(0,80,180));
    $self->SetFillColour(Wx::Colour->new(230,230,0));
    $self->SetTextColour(Wx::Colour->new(220,50,50));
    # Thickness of frame (1 mm)
    $self->SetLineWidth(1);
    # Title
    $self->Cell($w,9,$self->{title},wxPDF_BORDER_FRAME,1,wxPDF_ALIGN_CENTER,1);
    # line break
    $self->Ln(10);
}

sub Footer {
    my $self = shift;
    # Page footer
    $self->SetY(-15);
    $self->SetFont("Helvetica","I",8);
    #  Text color in gray
    $self->SetTextColour(128);
    $self->Cell(0, 10, sprintf("Page %d", $self->PageNo() ),0,0,wxPDF_ALIGN_CENTER);
}

sub run_pdfdemo {
    my ($self, $filepath) = @_;
    $self->{title} = "20,000 Leagues Under the Sea";
    $self->{col} = 0;
    $self->SetTitle($self->{title});
    $self->SetAuthor("Jules Verne");
    $self->PrintChapter(1, "A RUNAWAY REEF", "20k_c1.txt");
    $self->PrintChapter(2, "THE PROS AND CONS", "20k_c2.txt");
    $self->SaveAsFile($filepath);
}

sub ChapterTitle {
    my ($self, $num, $label) = @_;
    # Title
    $self->SetFont("Helvetica","",12);
    # backfround colour
    $self->SetFillColour(Wx::Colour->new(200,220,255));
    # title
    $self->Cell(0,6, sprintf("Chapter  %s : ", qq($num $label)),0,1,wxPDF_ALIGN_LEFT,1);
    # linebreak
    $self->Ln(4);
}

sub ChapterBody {
    my ($self, $filename) = @_;
    
    my $filepath = Wx::Demo->get_data_file( qq(pdfdocument/$filename) );
    
    # Read text file
    open my $fh, '<', $filepath or die qq(could not open $_->[2] : $!);
    my $content;
    while(<$fh>) {
        $content .= $_;
    }
    close($fh);
   
    # Font
    $self->SetFont("Times","",12);
    # Output justified text
    $self->MultiCell(0,5,$content);
    # linebreak
    $self->Ln();
    # Mention in italics
    $self->SetFont("","I");
    $self->Cell(0,5,"(end of excerpt)");
}

sub PrintChapter {
    my($self, $num, $title, $file) = @_;

    # Add chapter
    $self->AddPage;
    $self->ChapterTitle($num, $title);
    $self->ChapterBody($file);
}

###################################################

package 
   Wx::DemoModules::wxPdfDocument::Tutorial4;

###################################################

#/**
#* Multi-columns
#* 
#* This example is a variant of Tutorial3 showing how to lay the text
#* across multiple columns. 
#* 
#* The key method used is AcceptPageBreak(). It allows to accept or not an
#* automatic page break. By refusing it and altering the margin and current
#* position, the desired column layout is achieved. 
#* For the rest, not much change; two properties have been added to the class
#* to save the current column number and the position where columns begin, and
#* the MultiCell() call specifies a 6 centimeter width. 
#*/

use strict;
use warnings;
use Wx::PdfDocument;
use Wx qw( :pdfdocument );
use base qw( Wx::PlPdfDocument );

sub new {
    my $class = shift;
    my $self = $class->SUPER::new( @_ );
    return $self;
}

sub AcceptPageBreak {
    my $self = shift;
    # Method accepting or not automatic page break
    if ($self->{col} < 2) {
        # Go to next column
        $self->SetCol( $self->{col} + 1 );
        # Set ordinate to top
        $self->SetY($self->{y0});
        # Keep on page
        return 0;
    } else {
        # Go back to first column
        $self->SetCol(0);
        # Page break
        return 1;
    }
}

sub Header {
    my $self = shift;
    # page header
    $self->SetFont("Helvetica","B",15);
    my $w = $self->GetStringWidth($self->{title}) + 6;
    $self->SetX((210 - $w)/2);
    $self->SetDrawColour(Wx::Colour->new(0,80,180));
    $self->SetFillColour(Wx::Colour->new(230,230,0));
    $self->SetTextColour(Wx::Colour->new(220,50,50));
    $self->SetLineWidth(1);
    $self->Cell($w,9,$self->{title},wxPDF_BORDER_FRAME,1,wxPDF_ALIGN_CENTER,1);
    $self->Ln(10);
    ##Save ordinate
    $self->{y0} = $self->GetY();
}

sub Footer {
    my $self = shift;
    # Page footer
    $self->SetY(-15);
    $self->SetFont("Helvetica","I",8);
    $self->SetTextColour(128);
    $self->Cell(0, 10, sprintf("Page %d", $self->PageNo() ),0,0,wxPDF_ALIGN_CENTER);
}

sub run_pdfdemo {
    my ($self, $filepath) = @_;
    $self->{title} = "20,000 Leagues Under the Sea";
    $self->{col} = 0;
    $self->SetTitle($self->{title});
    $self->SetAuthor("Jules Verne");
    $self->PrintChapter(1, "A RUNAWAY REEF", "20k_c1.txt");
    $self->PrintChapter(2, "THE PROS AND CONS", "20k_c2.txt");
    $self->SaveAsFile($filepath);
}

sub SetCol {
    my($self, $col) = @_;
    # Set position at a given column
    $self->{col} = $col;
    my $x = 10 + $self->{col} * 65;
    $self->SetLeftMargin($x);
    $self->SetX($x); 
}

sub ChapterTitle {
    my ($self, $num, $label) = @_;
    # Title
    $self->SetFont("Helvetica","",12);
    $self->SetFillColour(Wx::Colour->new(200,220,255));
    $self->Cell(0,6, sprintf("Chapter  %s : ", qq($num $label)),0,1,wxPDF_ALIGN_LEFT,1);
    $self->Ln(4);
    # Save ordinate
    $self->{y0} = $self->GetY();
}

sub ChapterBody {
    my ($self, $filename) = @_;
    
    my $filepath = Wx::Demo->get_data_file( qq(pdfdocument/$filename) );
    
    # Read text file
    open my $fh, '<', $filepath or die qq(could not open $_->[2] : $!);
    my $content;
    while(<$fh>) {
        $content .= $_;
    }
    close($fh);
   
    # Font
    $self->SetFont("Times","",12);
    # Output text in a 6 cm width column
    $self->MultiCell(60,5,$content);
    $self->Ln();
    # Mention
    $self->SetFont("","I");
    $self->Cell(0,5,"(end of excerpt)");
    # Go back to first column
    $self->SetCol(0);
}

sub PrintChapter {
    my($self, $num, $title, $file) = @_;

    # Add chapter
    $self->AddPage;
    $self->ChapterTitle($num, $title);
    $self->ChapterBody($file);
}

###################################################

package 
   Wx::DemoModules::wxPdfDocument::Tutorial5;

###################################################

#/**
#* Tables
#*
#* This tutorial shows how to make tables easily. 
#* 
#* A table being just a collection of cells, it is natural to build one from
#* them. The first example is achieved in the most basic way possible: simple
#* framed cells, all of the same size and left aligned. The result is rudimentary
#* but very quick to obtain. 
#* 
#* The second table brings some improvements: each column has its own width,
#* titles are centered and figures right aligned. Moreover, horizontal lines
#* have been removed. This is done by means of the border parameter of the Cell()
#* method, which specifies which sides of the cell must be drawn. Here we want the
#* left (L) and right (R) ones. It remains the problem of the horizontal line to
#* finish the table. There are two possibilities: either check for the last line in
#* the loop, in which case we use LRB for the border parameter; or, as done here,
#* add the line once the loop is over. 
#* 
#* The third table is similar to the second one but uses colors. Fill, text and
#* line colors are simply specified. Alternate coloring for rows is obtained by
#* using alternatively transparent and filled cells. 
#*/

use strict;
use warnings;
use Wx::PdfDocument;
use Wx qw( :pdfdocument :print );
use base qw( Wx::PlPdfDocument );

sub new {
    my $class = shift;
    my $self = $class->SUPER::new( @_ );
    return $self;
}

sub BasicTable {
    my($self, $header, $data) = @_;
    
    # Header
    for (my $j = 0; $j < @$header; $j++)
    {
        $self->Cell(40,7,$header->[$j],wxPDF_BORDER_FRAME);
    }
    $self->Ln();
    # Data
    for (my $j = 0; $j < @$data; $j++)
    {
      for (my $k = 0; $k < @{ $data->[$j] }; $k++)
      {
        $self->Cell(40,6,$data->[$j]->[$k],wxPDF_BORDER_FRAME);
      }
      $self->Ln();
    }
}

sub ImprovedTable {
    my($self, $header, $data) = @_;

    # Column widths
    my @widths  = (40,35,40,45);
    my $totalwidth;
    $totalwidth += $_ for ( @widths );
    
    # Header
    for (my $i = 0; $i < @$header; $i++)
    {
        $self->Cell($widths[$i], 7, $header->[$i], wxPDF_BORDER_FRAME);
    }
    
    $self->Ln();
    # Data
    for (my $j = 0; $j < @$data; $j++)
    {
        $self->Cell($widths[0],6,$data->[$j]->[0],wxPDF_BORDER_LEFT | wxPDF_BORDER_RIGHT);
        $self->Cell($widths[1],6,$data->[$j]->[1],wxPDF_BORDER_LEFT | wxPDF_BORDER_RIGHT);
        $self->Cell($widths[2],6,$data->[$j]->[2],wxPDF_BORDER_LEFT | wxPDF_BORDER_RIGHT,0,wxPDF_ALIGN_RIGHT);
        $self->Cell($widths[3],6,$data->[$j]->[3],wxPDF_BORDER_LEFT | wxPDF_BORDER_RIGHT,0,wxPDF_ALIGN_RIGHT);
        $self->Ln();
    }
    # Closure line
    $self->Cell($totalwidth,0,'',wxPDF_BORDER_TOP);
}

sub FancyTable {
    my($self, $header, $data) = @_;    

    # Colors, line width and bold font
    $self->SetFillColour(Wx::Colour->new(255,0,0));
    $self->SetTextColour(255);
    $self->SetDrawColour(Wx::Colour->new(128,0,0));
    $self->SetLineWidth(0.3);
    $self->SetFont('','B');
    
   
    # Column widths
    my @widths  = (40,35,40,45);
    my $totalwidth;
    $totalwidth += $_ for ( @widths );
    
    # Header
    for (my $i = 0; $i < @$header; $i++)
    {
        $self->Cell($widths[$i], 7, $header->[$i], wxPDF_BORDER_FRAME, 0, wxPDF_ALIGN_CENTER, 1);
    }
    $self->Ln();
    
    ## Color and font restoration
    $self->SetFillColour(Wx::Colour->new(224,235,255));
    $self->SetTextColour(0);
    $self->SetFont('');
    
    # Data
    my $fill = 0;
    for (my $j = 0; $j < @$data; $j++)
    {
        $self->Cell($widths[0],6,$data->[$j]->[0],wxPDF_BORDER_LEFT | wxPDF_BORDER_RIGHT,0,wxPDF_ALIGN_LEFT,$fill);
        $self->Cell($widths[1],6,$data->[$j]->[1],wxPDF_BORDER_LEFT | wxPDF_BORDER_RIGHT,0,wxPDF_ALIGN_LEFT,$fill);
        $self->Cell($widths[2],6,$data->[$j]->[2],wxPDF_BORDER_LEFT | wxPDF_BORDER_RIGHT,0,wxPDF_ALIGN_RIGHT,$fill);
        $self->Cell($widths[3],6,$data->[$j]->[3],wxPDF_BORDER_LEFT | wxPDF_BORDER_RIGHT,0,wxPDF_ALIGN_RIGHT,$fill);
        $self->Ln();
        $fill = 1 - $fill;
    }
    # Closure line
    $self->Cell($totalwidth,0,'',wxPDF_BORDER_TOP);
}


sub run_pdfdemo {
    my ($self, $filepath) = @_;
    
    my $header = [ 'Country', 'Capital', 'Area (sq km)', 'Pop. (Thousands)' ];
   
    my $data = [
        [ qw( Austria Vienna 83859 8075 ) ],
        [ qw( Denmark Copenhagen 43094 5295 ) ],
        [ qw( Finland Helsinki 304529 5147 ) ],
        [ qw( France Paris 543965 58728 ) ],
        [ qw( Germany Berlin 357022 82057 ) ],
        [ qw( Greece Athens 131625 10511 ) ],
        [ qw( Ireland Dublin 70723 3694 ) ],
        [ qw( Italy Roma 301316 57563 ) ],
        [ qw( Luxembourg Luxembourg 2586 424 ) ],
        [ qw( Netherlands Amsterdam 41526 15654 ) ],
        [ qw( Portugal Lisbon 91906 9957 ) ],
        [ qw( Spain Madrid 504790 39348 ) ],
        [ qw( Sweden Stockholm 410934 8839 ) ],
        [ qw( United-Kingdom London 243820 58862 ) ],
    ];

    $self->SetFont('Helvetica','',14);
    $self->AddPage();
    $self->BasicTable($header,$data);
    $self->AddPage();
    $self->ImprovedTable($header,$data);
    $self->AddPage();
    $self->FancyTable($header,$data); 
    $self->SaveAsFile($filepath);
}

###################################################

package 
   Wx::DemoModules::wxPdfDocument::Tutorial6;

###################################################

#/**
#* Links and flowing text
#*
#* This tutorial explains how to insert links (internal and external) and shows
#* a new text writing mode. It also contains a rudimentary HTML parser.
#* The new method to print text is Write(). It is very close to MultiCell();
#* the differences are: The end of line is at the right margin and the next line
#* begins at the left one. The current position moves at the end of the text. 
#* So it allows to write a chunk of text, alter the font style, then continue from
#* the exact place we left it. On the other hand, you cannot full justify it. 
#*
#* The method is used on the first page to put a link pointing to the second one.
#* The beginning of the sentence is written in regular style, then we switch to
#* underline and finish it. The link is created with AddLink(), which returns a
#* link identifier. The identifier is passed as third parameter of Write(). Once
#* the second page is created, we use SetLink() to make the link point to the
#* beginning of the current page. 
#*
#* Then we put an image with a link on it. An external link points to an URL
#* (HTTP, mailto...). The URL is simply passed as last parameter of Image().
#*
#* Finally, the left margin is moved after the image with SetLeftMargin() and some
#* text in XML format is output. 
#* Recognized tags are <B>, <I>, <U>, <A> and <BR>; the others are ignored.
#*
#*/

use strict;
use warnings;
use Wx::PdfDocument;
use Wx qw( :pdfdocument :print );
use base qw( Wx::PlPdfDocument );

sub new {
    my $class = shift;
    my $self = $class->SUPER::new( @_ );
    return $self;
}

sub run_pdfdemo {
    my ($self, $filepath) = @_;
    
    my $xml = q(You can now easily print text mixing different styles : <b>bold</b>, <i>italic</i>, <u>underlined</u>, );
    $xml .= q(or <b><i><u>all at once</u></i></b>!<br/>You can also insert links );
    $xml .= q(on text, such as <a href="http://www.fpdf.org">www.fpdf.org</a>, or on an image: click on the logo.);
    
    # First page
    $self->AddPage();
    $self->SetFont('Helvetica', '', 20.0);
    $self->StartTransform();
    $self->Write(5, q(To find out what's new in this tutorial, click ));
    $self->SetFont('', 'U');
    my $linkid = $self->AddLink();
    $self->Write(5, 'here', Wx::PdfLink->new($linkid));
    $self->SetFont('');
    $self->StopTransform();
    # Second page
    $self->AddPage();
    $self->SetLink($linkid);
    
    my $logofile = Wx::Demo->get_data_file( qq(pdfdocument/fpdflogo.png) );
       
    $self->Image($logofile, 10, 10, 30, 0, '', Wx::PdfLink->new('http://www.fpdf.org'));
    $self->SetLeftMargin(45);
    $self->SetFontSize(14);
    $self->WriteXml($xml);
    
    $self->SaveAsFile($filepath);
}

###################################################

package 
   Wx::DemoModules::wxPdfDocument::Fonts;

###################################################

# wxPdfDocument has extensive support for including many types of fonts and
# encodings. For details you should consult the wxPdfDocument documentation
# directly. All necessary methods should be wrapped in the wxPerl wrapper.
# The makefont utility is also supported with a wrapper call in Wx::PdfDocument
# (see the pod). Use of Indic fonts and CJK fonts is covered in their
# respective examples elsewhere in this demo.
#
# If you only use western encodings then you may never have to look beyond
# Wx::Font. Using Wx::Font with wxPdfDocument automatically handle subsetting
# and embedding of TrueType and OpenType fonts in the PDF.
# When using Wx::PdfDC, this is all handled transparently for you.
#
# For the smallest possible document size use only the 14 built in Adobe
# Core fonts which are aliases for common system fonts and result in no
# embedding.
#
# Helvetica  - ( in normal, bold, italic and bold-italic ) ( 4 fonts )
# Times      - ( in normal, bold, italic and bold-italic ) ( 4 fonts )
# Courier    - ( in normal, bold, italic and bold-italic ) ( 4 fonts )
# Symbol
# ZapfDingbats
#
# In addition, 'Arial' is registered as an alias for Helvetica
#
# For each PDF session, for fonts other than the Adobe Core fonts you must
# 'register' any font you wish to use with the font manager before usage.
# This is quite simple as shown in the example below.

use strict;
use warnings;
use Wx::PdfDocument;
use Wx qw( :pdfdocument :print :font);
use base qw( Wx::PlPdfDocument );

sub new {
    my $class = shift;
    my $self = $class->SUPER::new( @_ );
    return $self;
}

sub run_pdfdemo {
    my ($self, $filepath) = @_;
    
    $self->AddPage();
    
    # get the global font manager object
    my $fontman = Wx::PdfFontManager::GetFontManager();
    # register some wxFont fonts
    my $rfont = Wx::Font->new(12, wxFONTFAMILY_ROMAN, wxFONTSTYLE_NORMAL, wxFONTWEIGHT_NORMAL, 0, 'Times New Roman');
    $fontman->RegisterFont($rfont, $rfont->GetFaceName);
    my $sfont = Wx::Font->new(12, wxFONTFAMILY_SWISS, wxFONTSTYLE_NORMAL, wxFONTWEIGHT_NORMAL, 0, 'Arial');
    # register font with an alias
    $fontman->RegisterFont($sfont, 'Arial Forced Embedded');
    $fontman->RegisterFont(wxNORMAL_FONT);
    
    # we can use Wx::Fonts or registered font names or core font names
    # or font aliases as params to SetFont
    for my $fontorname ( wxNORMAL_FONT, $rfont, 'Arial Forced Embedded',
                         'Helvetica', 'Times', 'Courier'  ) {
        
        $self->SetFont($fontorname);
        $self->SetFontSize(18);
        $self->Write(7, $self->GetCurrentFont->GetName );
        $self->Ln;
        $self->SetFontSize(10);
        $self->Write(7, 'The quick brown fox jumped over the lazy dog.');
        $self->Ln;
        $self->SetFontSize(12);
        $self->Write(7, 'The quick brown fox jumped over the lazy dog.');
        $self->Ln;
        $self->SetFontSize(16);
        $self->Write(7, 'The quick brown fox jumped over the lazy dog.');
        $self->Ln(14);
    }
    
    $self->SaveAsFile($filepath);
}

###################################################

package 
   Wx::DemoModules::wxPdfDocument::IndicFonts;

###################################################

#/**
#* Indic fonts and languages
#*
#* This example demonstrates the use of Indic fonts and languages.
#* wxPdfDocument provides the Rhagu
#* 
#*
#* Remark: Only available in Unicode build. 
#*/

use strict;
use warnings;
use Wx::PdfDocument;
use Wx qw( :pdfdocument :print );
use base qw( Wx::PlPdfDocument );

sub new {
    my $class = shift;
    my $self = $class->SUPER::new( @_ );
    return $self;
}

sub writeFullMoon {
    my($self, $txt1, $txt2, $fontName) = @_;
    $self->AddFont($fontName);
    $self->SetFont($fontName, '', 22);
    $self->Cell(40, 12, $txt1);
    $self->Cell(100, 12, $txt2);
    $self->Ln(13);
}

sub fullmoon {
    my $self = shift;
    use utf8;
    my $hindi1 = "११११";
    my $hindi2 = "पूर्ण चाँद";
    my $bengali1 = "১১১১";
    my $bengali2 = "পূরো চাঁদ";
    my $punjabi1 = "੧੧੧੧";
    my $punjabi2 = "ਪੂਰਾ ਚੰਦ";
    my $gujarati1 = "૧૧૧૧";
    my $gujarati2 = "પૂર્ણ ચંદ્ર";
    my $oriya1 = "୧୧୧୧";
    my $oriya2 = "ପୂର୍ଣ୍ଣ ଚନ୍ଦ୍ର";
    my $tamil1 = "௧௧௧௧";
    my $tamil2 = "முழு நிலவு";
    my $telugu1 = "౧౧౧౧";
    my $telugu2 = "పూర్ణచంద్రుడు";
    my $kannada1 = "೧೧೧೧";
    my $kannada2 = "ಪೂರ್ಣ ಚನ್ದ್ರ";
    my $malayalam1 = "൧൧൧൧";
    my $malayalam2 = "പൂറ്ണ്ണചന്ദ്റന്";
 
    $self->SetTopMargin(20);
    $self->SetLeftMargin(20);
    $self->AddPage();
    $self->SetFont('Helvetica', 'B',24);
    $self->Write(10,'Full Moon in 9 Indic Scripts');
    $self->Ln(15);
    $self->writeFullMoon( $hindi1, $hindi2, 'RaghuHindi');
    $self->writeFullMoon( $bengali1, $bengali2, 'RaghuBengali');
    $self->writeFullMoon( $punjabi1, $punjabi2, 'RaghuPunjabi');
    $self->writeFullMoon( $gujarati1, $gujarati2, 'RaghuGujarati');
    $self->writeFullMoon( $oriya1, $oriya2, 'RaghuOriya');
    $self->writeFullMoon( $tamil1, $tamil2, 'RaghuTamil');
    $self->writeFullMoon( $telugu1, $telugu2, 'RaghuTelugu');
    $self->writeFullMoon( $kannada1, $kannada2, 'RaghuKannada');
    $self->writeFullMoon( $malayalam1, $malayalam2, 'RaghuMalayalam');
}

sub writesample {
    my ($self, $header, $sampleFile, $fontName) = @_;
    $self->SetFont('Helvetica', 'B', 16);
    $self->Write(10,$header);
    $self->Ln(14);
    
    my $textfile = Wx::Demo->get_data_file( qq(pdfdocument/$sampleFile) );
    my $sampletext;
    open my $fh, '<:encoding(UTF-8)', $textfile or die qq(failed to open $textfile : $!);
    while(<$fh>) {
        $sampletext .= $_;
    }
    close($fh);
    $self->AddFont($fontName);
    $self->SetFont($fontName, '', 15);
    $self->MultiCell(160, 7, $sampletext, 0, wxPDF_ALIGN_LEFT);
    $self->Ln();
}

sub samples {
    my $self = shift;
    $self->SetTopMargin(30);
    $self->SetLeftMargin(30);
    $self->AddPage();
    $self->SetFont('Helvetica', 'B',32);
    $self->Write(10,'Indic Fonts and Languages');
    $self->Ln(17);
    $self->writesample( 'Assamese (as)','indic-assamese.txt', 'RaghuBengali');
    $self->writesample( 'Bengali (bn)', 'indic-bengali.txt', 'RaghuBengali');
    $self->writesample( 'Gujarati (gu)', 'indic-gujarati.txt','RaghuGujarati');
    $self->writesample( 'Hindi (hi)', 'indic-hindi.txt', 'RaghuHindi');
    $self->writesample( 'Kannada (kn)', 'indic-kannada.txt', 'RaghuKannada');
    $self->writesample( 'Malayalam (ml)', 'indic-malayalam.txt', 'RaghuMalayalam');
    $self->writesample( 'Nepali (ne) - Devanagari', 'indic-nepali.txt', 'RaghuHindi');
    $self->writesample( 'Oriya (or)', 'indic-oriya.txt', 'RaghuOriya');
    $self->writesample( 'Punjabi (pa)', 'indic-punjabi.txt','RaghuPunjabi');
    $self->writesample( 'Tamil (ta)', 'indic-tamil.txt', 'RaghuTamil');
    $self->writesample( 'Telugu (te)', 'indic-telugu.txt', 'RaghuTelugu');
}

sub run_pdfdemo {
    my ($self, $filepath) = @_;
    $self->fullmoon;
    $self->samples;
    $self->SaveAsFile($filepath);
}

###################################################

package 
   Wx::DemoModules::wxPdfDocument::CJKFonts;

###################################################

#/**
#* Chinese, Japanese and Korean fonts
#*
#* This example demonstrates the use of CJK fonts.
#* Users must have the Adobe CJK Type1 font packs
#* installed to view.
#*
#* Remark: Only available in Unicode build. 
#*/

use strict;
use warnings;
use Wx::PdfDocument;
use Wx qw( :pdfdocument :print );

sub new {
    my $class = shift;
    my $self = bless {}, $class;
    return $self;
}

sub run_pdfdemo {
    my ($self, $filepath) = @_;
    my $pdf = Wx::PlPdfDocument->new;
        
    my $cnfile = Wx::Demo->get_data_file( qq(pdfdocument/cp950.txt) );
    open my $fh, '<:encoding(cp-950)', $cnfile;
    my $s_cn = readline($fh);
    close($fh);
    
    $pdf->AddFontCJK('Big5');
    $pdf->AddPage();
    $pdf->SetFont('Helvetica', '',24);
    $pdf->Write(10,'Chinese');
    $pdf->Ln(12);
    $pdf->SetFont('Big5','',20);
    $pdf->Write(10,$s_cn);
    
    my $jpfile = Wx::Demo->get_data_file( qq(pdfdocument/cp932.txt) );
    open $fh, '<:encoding(cp-932)', $jpfile;
    my $s_jp = readline($fh);
    close($fh);
    
    $pdf->AddFontCJK('SJIS');
    $pdf->Ln(12);
    #$pdf->AddPage();
    $pdf->SetFont('Helvetica', '',24);
    $pdf->Write(10,'Japanese');
    $pdf->Ln(12);
    $pdf->SetFont('SJIS','',18);
    $pdf->Write(8,$s_jp);
    
    my $krfile = Wx::Demo->get_data_file( qq(pdfdocument/cp949.txt) );
    open $fh, '<:encoding(cp-949)', $krfile;
    my $s_kr = readline($fh);
    close($fh);
    
    $pdf->AddFontCJK('UHC');
    $pdf->Ln(12);
    #$pdf->AddPage();
    $pdf->SetFont('Helvetica', '',24);
    $pdf->Write(10,'Korean');
    $pdf->Ln(12);
    $pdf->SetFont('UHC','',18);
    $pdf->Write(8,$s_kr);
    
    $pdf->SaveAsFile($filepath);
}

###################################################

package 
   Wx::DemoModules::wxPdfDocument::Attachment;

###################################################

#/**
#* Attachments
#* 
#* This example shows how to attach a file to a PDF document.
#*/

use strict;
use warnings;
use Wx::PdfDocument;
use Wx qw( :pdfdocument :print );
use base qw( Wx::PlPdfDocument );

sub new {
    my $class = shift;
    my $self = $class->SUPER::new( @_ );
    return $self;
}

sub run_pdfdemo {
    my ($self, $filepath) = @_;
    
    my $attachfile = Wx::Demo->get_data_file( qq(pdfdocument/20k_c2.txt) );
    
    $self->AttachFile($attachfile, '', 'A simple text file');
    $self->AddPage();
    $self->SetFont('Helvetica','',14);
    $self->Write(5, 'This PDF contains an attached plain text file.');
    
    $self->SaveAsFile($filepath);
}

###################################################

package 
   Wx::DemoModules::wxPdfDocument::Barcode;

###################################################

#/**
#* Barcodes
#*
#* This example shows how to use the barcode creator add-on .
#*/


use strict;
use warnings;
use Wx::PdfDocument;
use Wx qw( :pdfdocument :print );
use base qw( Wx::PlPdfDocument );

sub new {
    my $class = shift;
    my $self = $class->SUPER::new( @_ );
    return $self;
}

sub run_pdfdemo {
    my ($self, $filepath) = @_;
    
    my $barcode = Wx::PdfBarCodeCreator->new($self);
    
    $self->AddPage();
  
    $barcode->EAN13(80, 40, '123456789012');
    $barcode->UPC_A(80, 70, '1234567890');
  
    $barcode->Code39(60, 100, 'Code 39');
  
    $barcode->I25(90, 140, '12345678');
  
    my $zipcode = '48109-1109';
    $barcode->PostNet(40,180,$zipcode);
    $self->Text(40,185,$zipcode);
  
    $self->AddPage();
    $self->SetFont('Helvetica', '', 10);
  
    # A set
    my $code128 = 'CODE 128';
    $barcode->Code128A(50, 20, $code128, 20);
    $self->SetXY(50, 45);
    $self->Write(5, qq(A set: $code128));
  
    # B set
    $code128 = 'Code 128';
    $barcode->Code128B(50, 70, $code128, 20);
    $self->SetXY(50,95);
    $self->Write(5, qq(B set: $code128));
  
    # C set
    $code128 = '12345678901234567890';
    $barcode->Code128C(50, 120, $code128, 20);
    $self->SetXY(50, 145);
    $self->Write(5, qq(C set: $code128));
  
    # A,B,C sets
    $code128 = 'ABCDEFG1234567890AbCdEf';
    $barcode->Code128(50, 170, $code128, 20);
    $self->SetXY(50, 195);
    $self->Write(5, qq(ABC sets combined: $code128));
  
    # EAN with AIs
    $code128 = '(01)00000090311314(10)ABC123(15)060916';
    $barcode->EAN128(50, 220, $code128, 20);
    $self->SetXY(50, 245);
    $self->Write(5, qq(EAN with AIs: $code128));

    $self->SaveAsFile($filepath);
}

###################################################

package 
   Wx::DemoModules::wxPdfDocument::Bookmark;

###################################################

#/**
#* Bookmarks
#*
#* This example demonstrates the use of bookmarks.
#*/
# We also create a Wx::PlPdfDocument directly
# instead of inheriting its methods which is fine
# so long as  we don't need virtual overides

use strict;
use warnings;
use Wx qw( :pdfdocument :print );

sub new {
    my $class = shift;
    my $self = bless {}, $class;
    return $self;
}

sub run_pdfdemo {
    my ($self, $filepath) = @_;
    
    my $pdf = Wx::PlPdfDocument->new;
    $pdf->SetFont('Helvetica','',15);
    # Page 1
    $pdf->AddPage();
    $pdf->Bookmark('Page 1');
    $pdf->Bookmark('Paragraph 1',1,-1);
    $pdf->Cell(0,6,'Paragraph 1');
    $pdf->Ln(50);
    $pdf->Bookmark('Paragraph 2',1,-1);
    $pdf->Cell(0,6,'Paragraph 2');
    $pdf->Annotate(60,30,'First annotation on first page');
    $pdf->Annotate(60,60,'Second annotation on first page');
    # Page 2
    $pdf->AddPage();
    $pdf->Bookmark('Page 2');
    $pdf->Bookmark('Paragraph 3',1,-1);
    $pdf->Cell(0,6,'Paragraph 3');
    $pdf->Annotate(60,40,'First annotation on second page');
    $pdf->Annotate(90,40,'Second annotation on second page');
    
    $pdf->SaveAsFile($filepath);
}

###################################################

package 
   Wx::DemoModules::wxPdfDocument::Charting;

###################################################

#/**
#* Charting
#*
#* This example shows how very simple pie and bar charts can be created.
#* Additionally the available marker symbols are shown.
#*/

use strict;
use warnings;
use Wx::PdfDocument;
use Wx qw( :pdfdocument :print );
use base qw( Wx::PlPdfDocument );

sub new {
    my $class = shift;
    my $self = $class->SUPER::new( @_ );
    return $self;
}

sub PieChart {
    my( $self, $width, $height, $nData, $label, $data, $colors) = @_;
    
    $self->SetFont('Helvetica', '', 10);
    my $margin  = 2;
    my $hLegend = 5;

    # Determine maximal legend width and sum of data values
    my $sum = 0.;
    my $wLegend = 0;
    my $labelWidth;
    for (my $i = 0; $i < $nData; $i++)
    {
      $sum = $sum + $data->[$i];
      $labelWidth = $self->GetStringWidth($label->[$i]);
      if ($labelWidth > $wLegend) { $wLegend = $labelWidth; }
    }

    my $radius = $width - $margin * 4 - $hLegend - $wLegend;
    if ($radius > $height - $margin * 2) { $radius = $height - $margin * 2; }
    $radius = int($radius / 2);
    my $xPage = $self->GetX();
    my $xDiag = $self->GetX() + $margin + $radius;
    my $yDiag = $self->GetY() + $margin + $radius;
    # Sectors
    $self->SetLineWidth(0.2);
    my $angle = 0;
    my $angleStart = 0;
    my $angleEnd = 0;
    for (my $i = 0; $i < $nData; $i++)
    {
      $angle = ($sum != 0) ? int(($data->[$i] * 360) / $sum) : 0;
      if ($angle != 0)
      {
        $angleEnd = $angleStart + $angle;
        $self->SetFillColour($colors->[$i]);
        $self->Sector($xDiag, $yDiag, $radius, $angleStart, $angleEnd);
        $angleStart += $angle;
      }
    }
    if ($angleEnd != 360)
    {
      $self->Sector($xDiag, $yDiag, $radius, $angleStart - $angle, 360);
    }

    # Legends
    my $x1 = $xPage + 2 * $radius + 4 * $margin;
    my $x2 = $x1 + $hLegend + $margin;
    my $y1 = $yDiag - $radius + (2 * $radius - $nData*($hLegend + $margin)) / 2;
    for (my $i = 0; $i < $nData; $i++)
    {
      $self->SetFillColour($colors->[$i]);
      $self->Rect($x1, $y1, $hLegend, $hLegend, wxPDF_STYLE_FILLDRAW);
      $self->SetXY($x2, $y1);
      $self->Cell(0, $hLegend, $label->[$i]);
      $y1 += $hLegend + $margin;
    }
}

sub BarDiagram {
    my($self, $width, $height, $nData, $label, $data, $colour, $maxVal, $nDiv) = @_;

    $colour ||= Wx::Colour->new(155,155,155);
    $maxVal ||= 0;
    $nDiv = 4 unless defined($nDiv);
    
    my $savecolour = $self->GetFillColour;
    
    my $localColour = $colour;
    if (!$localColour->Ok())
    {
      $localColour = Wx::Colour->new(155,155,155);
    }

    $self->SetFont('Helvetica', '', 10);

    # Determine maximal legend width and sum of data values
    my $maxValue = $data->[0];
    my $sum = 0.0;
    my $wLegend = 0;
    my $labelWidth;
   
    for (my $i = 0; $i < $nData; $i++)
    {
      if ($data->[$i] > $maxValue) { $maxValue = $data->[$i]; }
      $sum = $sum + $data->[$i];
      $labelWidth = $self->GetStringWidth($label->[$i]);
      if ($labelWidth > $wLegend) { $wLegend = $labelWidth; }
    }
    if ($maxVal == 0)
    {
      $maxVal = $maxValue;
    }

    my $margin = 2;
    my $yDiag = $self->GetY() + $margin;
    my $hDiag = int($height - $margin * 2);
    my $xDiag = $self->GetX() + $margin * 2 + $wLegend;
    my $wDiag = int($width - $margin * 3 - $wLegend);

    my $tickRange = int( 0.5 + ($maxVal / $nDiv) );
    $maxVal = $tickRange * $nDiv;
    my $tickLen = int($wDiag / $nDiv);
    $wDiag = $tickLen * $nDiv;
    my $unit = $wDiag / $maxVal;
    my $hBar = int($hDiag / ($nData + 1));
    $hDiag = $hBar * ($nData + 1);
    my $eBaton = int($hBar * 0.8);

    $self->SetLineWidth(0.2);
    $self->Rect($xDiag, $yDiag, $wDiag, $hDiag);

    my($xpos, $ypos);
    # Scales
    for (my $i = 0; $i <= $nDiv; $i++)
    {
      $xpos = $xDiag + $tickLen * $i;
      $self->Line($xpos, $yDiag, $xpos, $yDiag + $hDiag);
      my $val = sprintf("%.2f", $i * $tickRange);
      $xpos -= $self->GetStringWidth($val) / 2;
      $ypos = $yDiag + $hDiag;
      $self->Text($xpos, $ypos + 2*$margin, $val);
    }

    $self->SetFillColour($colour);
    my $wval;
    for (my $i = 0; $i < $nData; $i++)
    {
      # Bar
      $wval = ($data->[$i] != 0.0) ? int($data->[$i] * $unit) : int(2.5 * $unit);
      $ypos = $yDiag + ($i + 1) * $hBar - $eBaton / 2;
      $self->Rect($xDiag, $ypos, $wval, $eBaton, wxPDF_STYLE_FILLDRAW);
      # Legend
      $self->SetXY(0, $ypos);
      $self->Cell($xDiag - $margin, $eBaton, $label->[$i], wxPDF_BORDER_NONE, 0, wxPDF_ALIGN_RIGHT);
    }
    $self->SetFillColour($savecolour);
}


sub run_pdfdemo {
    my ($self, $filepath) = @_;
    
    # Show examples of a simple pie chart and a simple bar chart
    $self->AddPage();
    $self->SetFont('Helvetica','',12);
  
    my $nData = 4;
    my $colours = [
        Wx::Colour->new(92,172,238),
        Wx::Colour->new(67,205,128),
        Wx::Colour->new(255,99,71),
        Wx::Colour->new(255,215,0),
    ];
    
    my $labels = [
         'Job 1', 'Job 2', 'Job 3', 'Job 4'
    ];
    
    my $pieData = [ 30.0, 20.0, 40.0, 10.0 ];
  
    $self->SetX(40);
    $self->MultiCell(0,4.5, 'Pie Chart Sample');
    $self->Ln(5);
    $self->SetX($self->GetX + 30);
    $self->PieChart(125, 70, $nData, $labels, $pieData, $colours);
  
    $self->SetFont('Helvetica','',12);
    $self->SetXY(40,110);
    $self->MultiCell(0,4.5, 'Bar Chart Sample');
    $self->SetXY(40,120);
    $nData = 3;
    my $barData = [ 50.0, 80.0, 25.0 ];
    my $label =  [ 'Job 1', 'Job 2', 'Job 3' ];
    $self->BarDiagram(70, 35, $nData, $label, $barData, Wx::Colour->new(176,196,222), 100, 2);
  
  
    #// Show available marker symbols
    $self->AddPage();
    
    $self->Cell(40.0,0.0, 'Marker symbols and arrows');
    $self->Marker(25.0, 80.0, wxPDF_MARKER_CIRCLE, 15.0);
    $self->Arrow(35.0,85.0, 70.0, 105.0, 0.50, 8.0, 3.0);
    $self->Marker(78.0, 109.0, wxPDF_MARKER_CIRCLE, 10.0);
    $self->SetFillColour(Wx::Colour->new(255,99,71));
    $self->Arrow(120.0,75.0, 90.0, 100.0, 0.20, 6.0, 2.0);
    $self->SetFillColour(Wx::Colour->new(255,255,0));
    
    $self->SetLineWidth(0.12);
    my $x;
    my $x0 = 10;
    my $y0 = 25.;
    my $y1 = 20;
    my $y2 = 30;
    $self->Line(10, $y1, 150, $y1);
    $self->Line(10, $y2, 150, $y2);
    
    for (my $i = 0; $i < wxPDF_MARKER_LAST; $i++)
    {
      $x = 7. * $i + 7. + $x0;
      $self->Line($x, $y0 + 9., $x, $y0 - 9.);
      $self->Marker($x, $y1, $i, 4.2);
    }
    
    $self->SetFillColour(Wx::Colour->new(0,0,0));
    for (my $i = 0; $i < wxPDF_MARKER_LAST; $i++)
    {
      $x = 7. * $i + 7. + $x0;
      $self->Marker($x, $y2, $i, 4.2);
    }
    
    $self->AddPage();
    $self->SetLineWidth(0.2);
    $self->SetDrawColour(0,0,0);
    $self->Rect(55, 53, 100, 72);
    
    $self->SetAlpha(1, 0.5);
    $self->SetFillColour(Wx::PdfColour->new('#BBBBBB'));
    for (my $j = 0; $j < 3; $j++)
    {
      $self->Rect(55, 53+2*$j*12, 100, 12, wxPDF_STYLE_FILL);
    }
    $self->SetFillColour(Wx::PdfColour->new('#DDDDDD'));
    for (my $j = 0; $j < 3; $j++)
    {
      $self->Rect(55, 53+2*($j+1)*12-12, 100, 12, wxPDF_STYLE_FILL);
    }
    $self->SetAlpha();
    
    my $dash = [ 3.0, 3.0 ];
    my $dashStyle = Wx::PdfLineStyle->new(0.2, wxPDF_LINECAP_BUTT, wxPDF_LINEJOIN_MITER, $dash, 0.0, Wx::PdfColour->new('gray'));
    $self->SetLineStyle($dashStyle);
    for (my $j = 1; $j < 6; $j++)
    {
      $self->Line(55, 53+$j*12, 55+100, 53+$j*12);
    }
    for (my $j = 1; $j < 10; $j++)
    {
      $self->Line(55+$j*10, 53, 55+$j*10, 53+72);
    }
    
    my $xdata = [ 10,  20, 30,  40,  50,  60, 70, 80,  90, 100 ];
    my $ydata = [ 10, 120, 80, 190, 260, 170, 60, 40,  20, 230 ];
    my $ydata2 = [ 10,  70, 40, 120, 200,  60, 80, 40,  20,   5 ];
    my $fcol = Wx::PdfColour->new('#440000');
    my $tcol = Wx::PdfColour->new('#FF9090');
    my $grad = $self->LinearGradient($fcol, $tcol, wxPDF_LINEAR_GRADIENT_REFLECTION_LEFT);
    for (my $j = 0; $j < 10; $j++)
    {
      $self->SetFillGradient($xdata->[$j]-3+50, 125-$ydata->[$j]*0.25, 6, $ydata->[$j]*0.25, $grad);
    }
    my $solid = []; # no dashes
    my $solidStyle = Wx::PdfLineStyle->new(0.1, wxPDF_LINECAP_BUTT, wxPDF_LINEJOIN_MITER, $solid, 0.0, Wx::PdfColour->new('blue'));
    $self->SetLineStyle($solidStyle);
    my ( @xl, @yl );
    for (my $j = 0; $j < 10; $j++)
    {
      push(@xl, $xdata->[$j] +50);
      push(@yl, 125 - $ydata2->[$j]*0.25);
    }
    push(@xl, $xdata->[9]+50 );
    push(@yl , 125);
    push(@xl, $xdata->[0]+50);
    push(@yl , 125);
    $self->SetDrawColour(Wx::PdfColour->new('navy'));
    $self->SetFillColour(Wx::PdfColour->new('skyblue'));
    $self->SetAlpha(0.75,0.5);
    $self->Polygon(\@xl, \@yl, wxPDF_STYLE_FILLDRAW);
    $self->SetAlpha(0.75,1);
    $self->SetDrawColour(Wx::PdfColour->new('blue'));
    $self->SetFillColour(Wx::PdfColour->new('lightblue'));
    $self->SetLineWidth(0.1);
    for (my $j = 0; $j < 10; $j++)
    {
      $self->Marker($xdata->[$j]+50, 125-$ydata2->[$j]*0.25, wxPDF_MARKER_SQUARE, 2.);
    }
    $self->SetAlpha();

    $self->SaveAsFile($filepath);
}

###################################################

package 
   Wx::DemoModules::wxPdfDocument::Clipping;

###################################################

#/**
#* Clipping
#*
#* This example shows several clipping options provided by wxPdfDocument.
#* A clipping area restricts the display and prevents any elements from showing outside
#* of it. 3 shapes are available: text, rectangle and ellipse. For each one, you can
#* choose whether to draw the outline or not.
#*/

use strict;
use warnings;
use Wx qw( :pdfdocument :print );

sub new {
    my $class = shift;
    my $self = bless {}, $class;
    return $self;
}

sub run_pdfdemo {
    my ($self, $filepath) = @_;
    
    my $pdf = Wx::PlPdfDocument->new;
    $pdf->AddPage();
    
    my $clipimage = Wx::Demo->get_data_file( qq(pdfdocument/clips.jpg) );

    # example of clipped cell
    $pdf->SetFont('Helvetica','',14);
    $pdf->SetX(72);
  
    $pdf->ClippedCell(60,6,'These are clipping examples',wxPDF_BORDER_FRAME);
  
    my $true = 1;
  
    # example of clipping text
    $pdf->SetFont('Helvetica','B',120);
    # set the outline color
    $pdf->SetDrawColour(0);
    # set the outline width (note that only its outer half will be shown)
    $pdf->SetLineWidth(2);
    # draw the clipping text
    $pdf->ClippingText(40,55,'CLIPS',$true);
    # fill it with the image
    $pdf->Image($clipimage,40,10,130);
    # remove the clipping
    $pdf->UnsetClipping();
  
    # example of clipping rectangle
    $pdf->ClippingRect(45,65,116,20,$true);
    $pdf->Image($clipimage,40,10,130);
    $pdf->UnsetClipping();
  
    # example of clipping ellipse
    $pdf->ClippingEllipse(102,104,16,10,$true);
    $pdf->Image($clipimage,40,10,130);
    $pdf->UnsetClipping();
  
    # example of clipping polygon
    
    my @arrx = (  30,  60,  40,  70,  30 );
    my @arry = ( 135, 155, 155, 160, 165 );
  
    $pdf->ClippingPolygon(\@arrx,\@arry,$true);
    $pdf->Image($clipimage,20,100,130);
    $pdf->UnsetClipping();
  
    # example of clipping using a shape
    my $shape = Wx::PdfShape->new();
    $shape->MoveTo(135,140);
    $shape->CurveTo(135,137,130,125,110,125);
    $shape->CurveTo(80,125,80,162.5,80,162.5);
    $shape->CurveTo(80,180,100,202,135,220);
    $shape->CurveTo(170,202,190,180,190,162.5);
    $shape->CurveTo(190,162.5,190,125,160,125);
    $shape->CurveTo(145,125,135,137,135,140);
  
    $pdf->SetLineWidth(1);
    $pdf->SetFillColour(Wx::PdfColour->new('red'));
    $pdf->ClippingPath($shape, wxPDF_STYLE_FILLDRAW);
    $pdf->UnsetClipping();
    
    $pdf->SaveAsFile($filepath);
}

###################################################

package 
   Wx::DemoModules::wxPdfDocument::Drawing;

###################################################

#/**
#* Drawing of geometric figures
#*
#* This example shows how to draw lines, rectangles, ellipses, polygons and curves with line style.
#*/

use strict;
use warnings;
use Wx qw( :pdfdocument :print :bitmap );
use Math::Trig;

sub new {
    my $class = shift;
    my $self = bless {}, $class;
    return $self;
}

sub run_pdfdemo {
    my ($self, $filepath) = @_;
    
    my $pdf = Wx::PlPdfDocument->new;
    $pdf->AddPage();
    
    my $pattern1file = Wx::Demo->get_data_file( qq(pdfdocument/pattern1.png) );
    my $pattern2file = Wx::Demo->get_data_file( qq(pdfdocument/pattern2.png) );
    
    $pdf->SetFont('Helvetica', '', 10);
    
    my $pattern1 = Wx::Image->new($pattern1file, wxBITMAP_TYPE_PNG, -1);
    my $pattern2 = Wx::Image->new($pattern2file, wxBITMAP_TYPE_PNG, -1);
    $pdf->AddPattern('pattern1', $pattern1, 5, 5);
    $pdf->AddPattern('pattern2', $pattern2, 10, 10);
  
    my $dash1 = [ 3.5, 7.0, 1.75, 3.5 ];
    
    my $style = Wx::PdfLineStyle->new(0.5, wxPDF_LINECAP_BUTT, wxPDF_LINEJOIN_MITER, $dash1,
                                      3.5, Wx::PdfColour->new(255, 0, 0));
  
    my $dash2 = []; # solid
    my $style2 = Wx::PdfLineStyle->new(0.5, wxPDF_LINECAP_BUTT, wxPDF_LINEJOIN_MITER, $dash2,
                                      0.0, Wx::PdfColour->new(255, 0, 0));
  
    my $dash3 = [ 0.7, 3.5 ];
    my $style3 = Wx::PdfLineStyle->new(1.0, wxPDF_LINECAP_ROUND, wxPDF_LINEJOIN_ROUND, $dash3,
                                      0.0, Wx::PdfColour->new(255, 0, 0));
        
    my $style4 = Wx::PdfLineStyle->new(0.5, wxPDF_LINECAP_BUTT, wxPDF_LINEJOIN_MITER, $dash1,
                                      3.5, Wx::PdfColour->new(255, 0, 0));
    
    my $style5 = Wx::PdfLineStyle->new(0.25, wxPDF_LINECAP_BUTT, wxPDF_LINEJOIN_MITER, $dash2,
                                      0.0, Wx::PdfColour->new(0, 0, 0));
  
    my $dash6 = [ 3.5, 3.5 ];
    my $style6 = Wx::PdfLineStyle->new(0.5, wxPDF_LINECAP_BUTT, wxPDF_LINEJOIN_MITER, $dash6,
                                       0.0, Wx::PdfColour->new(0, 255, 0));
  
    my $style7 = Wx::PdfLineStyle->new(2.5, wxPDF_LINECAP_BUTT, wxPDF_LINEJOIN_MITER, $dash2,
                                       3.5, $pdf->GetPatternColour('pattern1'));
  
    my $style8 = Wx::PdfLineStyle->new(0.5, wxPDF_LINECAP_BUTT, wxPDF_LINEJOIN_MITER, $dash2,
                                       0.0, Wx::PdfColour->new(0, 0, 0));
  
    # Line
    $pdf->Text(5, 7, 'Line examples');
    $pdf->SetLineStyle($style);
    $pdf->Line(5, 10, 80, 30);
    $pdf->SetLineStyle($style2);
    $pdf->Line(5, 10, 5, 30);
    $pdf->SetLineStyle($style3);
    $pdf->Line(5, 10, 80, 10);
  
    # Rect
    $pdf->Text(100, 7, 'Rectangle examples');
    $pdf->SetLineStyle($style5);
    $pdf->SetFillColour(Wx::Colour->new(220, 220, 200));
    $pdf->Rect(100, 10, 40, 20, wxPDF_STYLE_FILLDRAW);
    $pdf->SetLineStyle($style3);
    $pdf->Rect(145, 10, 40, 20, wxPDF_STYLE_DRAW);
  
    # Curve
    $pdf->Text(5, 37, 'Curve examples');
    $pdf->SetLineStyle($style6);
    $pdf->Curve(5, 40, 30, 55, 70, 45, 60, 75, wxPDF_STYLE_DRAW);
    $pdf->Curve(80, 40, 70, 75, 150, 45, 100, 75, wxPDF_STYLE_FILL);
    $pdf->SetFillColour(Wx::Colour->new(200, 220, 200));
    $pdf->Curve(140, 40, 150, 55, 180, 45, 200, 75, wxPDF_STYLE_FILLDRAW);
  
    # Circle and ellipse
    $pdf->Text(5, 82, 'Circle and ellipse examples');
    $pdf->SetLineStyle($style5);
    $pdf->Circle(25,105,20);
    $pdf->SetLineStyle($style6);
    $pdf->Circle(25,105,10, 90, 180, wxPDF_STYLE_DRAW);
    $pdf->Circle(25,105,10, 270, 360, wxPDF_STYLE_FILL);
    $pdf->Circle(25,105,10, 270, 360, wxPDF_STYLE_DRAWCLOSE);
    
    $pdf->SetLineStyle($style5);
    $pdf->Ellipse(100,105,40,20);
    $pdf->SetLineStyle($style6);
    $pdf->Ellipse(100,105,20,10, 0, 90, 180, wxPDF_STYLE_DRAW);
    $pdf->Ellipse(100,105,20,10, 0, 270, 360, wxPDF_STYLE_FILLDRAW);
    
    $pdf->SetLineStyle($style5);
    $pdf->Ellipse(175,105,30,15, 45);
    $pdf->SetLineStyle($style6);
    $pdf->Ellipse(175,105,15,7.50, 45, 90, 180, wxPDF_STYLE_DRAW);
    $pdf->SetFillColour(Wx::Colour->new(220, 200, 200));
    $pdf->Ellipse(175,105,15,7.50, 45, 270, 360, wxPDF_STYLE_FILL);
    
    # Polygon
    $pdf->Text(5, 132, 'Polygon examples');
    $pdf->SetLineStyle($style8);
    
    my $x1 = [5,45,15];
    my $y1 = [135,135,165];
    $pdf->Polygon($x1, $y1);
    
    my $x2 = [60,60,80,70,50];
    my $y2 = [135,135,155,165,155];
    $pdf->SetLineStyle($style6);
    $pdf->Polygon($x2, $y2, wxPDF_STYLE_FILLDRAW);
    
    my $x3 = [120,140,150,110];
    my $y3 = [135,135,155,155];
    $pdf->SetLineStyle($style7);
    $pdf->Polygon($x3, $y3, wxPDF_STYLE_DRAW);
    
    my $x4 = [160,190,170,200,160];
    my $y4 = [135,155,155,160,165];
    $pdf->SetLineStyle($style6);
    $pdf->SetFillPattern('pattern2');
    $pdf->Polygon($x4, $y4, wxPDF_STYLE_FILLDRAW);
    
    # Regular polygon
    $pdf->Text(5, 172, 'Regular polygon examples');
    $pdf->SetLineStyle($style5);
    $pdf->SetFillColour(Wx::Colour->new(220, 220, 220));
    $pdf->RegularPolygon(20, 190, 15, 6, 0, 1, wxPDF_STYLE_FILL);
    $pdf->RegularPolygon(55, 190, 15, 6);
    $pdf->SetLineStyle($style7);
    $pdf->RegularPolygon(55, 190, 10, 6, 45, 0, wxPDF_STYLE_FILLDRAW);
    $pdf->SetLineStyle($style5);
    $pdf->SetFillColour(Wx::Colour->new(200, 220, 200));
    $pdf->RegularPolygon(90, 190, 15, 3, 0, 1, wxPDF_STYLE_FILLDRAW, wxPDF_STYLE_FILL,
            Wx::PdfLineStyle->new, Wx::PdfColour->new(255, 200, 200));
    $pdf->RegularPolygon(125, 190, 15, 4, 30, 1, wxPDF_STYLE_DRAW, wxPDF_STYLE_DRAW, $style6);
    $pdf->RegularPolygon(160, 190, 15, 10);
    
    # Star polygon
    $pdf->Text(5, 212, 'Star polygon examples');
    $pdf->SetLineStyle($style5);
    $pdf->StarPolygon(20, 230, 15, 20, 3, 0, 1, wxPDF_STYLE_FILL);
    $pdf->StarPolygon(55, 230, 15, 12, 5);
    $pdf->SetLineStyle($style7);
    $pdf->StarPolygon(55, 230, 7, 12, 5, 45, 0, wxPDF_STYLE_FILLDRAW);
    $pdf->SetLineStyle($style5);
    $pdf->SetFillColour(Wx::Colour->new(220, 220, 200));
    $pdf->StarPolygon(90, 230, 15, 20, 6, 0, 1, wxPDF_STYLE_FILLDRAW,
                        wxPDF_STYLE_FILL, Wx::PdfLineStyle->new, Wx::PdfColour->new(255, 200, 200));
    $pdf->StarPolygon(125, 230, 15, 5, 2, 30, 1, wxPDF_STYLE_DRAW, wxPDF_STYLE_DRAW, $style6);
    $pdf->StarPolygon(160, 230, 15, 10, 3);
    $pdf->StarPolygon(160, 230, 7, 50, 26);
    
    # Rounded rectangle
    $pdf->Text(5, 252, 'Rounded rectangle examples');
    $pdf->SetLineStyle($style8);
    $pdf->RoundedRect(5, 255, 40, 30, 3.50, wxPDF_CORNER_ALL, wxPDF_STYLE_FILLDRAW);
    $pdf->RoundedRect(50, 255, 40, 30, 6.50, wxPDF_CORNER_TOP_LEFT);
    $pdf->SetLineStyle($style6);
    $pdf->RoundedRect(95, 255, 40, 30, 10.0, wxPDF_CORNER_ALL, wxPDF_STYLE_DRAW);
    $pdf->SetFillColour(Wx::Colour->new(200, 200, 200));
    $pdf->RoundedRect(140, 255, 40, 30, 8.0, wxPDF_CORNER_TOP_RIGHT | wxPDF_CORNER_BOTTOM_RIGHT, wxPDF_STYLE_FILLDRAW);
    
    $pdf->AddPage();
    
    $pdf->SetFont('Helvetica', 'B', 20);
    $pdf->SetLineWidth(1);
    
    $pdf->SetDrawColour(50, 0, 0, 0);
    $pdf->SetFillColour(100, 0, 0, 0);
    $pdf->SetTextColour(100, 0, 0, 0);
    $pdf->Rect(10, 10, 20, 20, wxPDF_STYLE_FILLDRAW);
    $pdf->Text(10, 40, 'Cyan');
    
    $pdf->SetDrawColour(0, 50, 0, 0);
    $pdf->SetFillColour(0, 100, 0, 0);
    $pdf->SetTextColour(0, 100, 0, 0);
    $pdf->Rect(40, 10, 20, 20, wxPDF_STYLE_FILLDRAW);
    $pdf->Text(40, 40, 'Magenta');
    
    $pdf->SetDrawColour(0, 0, 50, 0);
    $pdf->SetFillColour(0, 0, 100, 0);
    $pdf->SetTextColour(0, 0, 100, 0);
    $pdf->Rect(70, 10, 20, 20, wxPDF_STYLE_FILLDRAW);
    $pdf->Text(70, 40,'Yellow');
    
    $pdf->SetDrawColour(0, 0, 0, 50);
    $pdf->SetFillColour(0, 0, 0, 100);
    $pdf->SetTextColour(0, 0, 0, 100);
    $pdf->Rect(100, 10, 20, 20, wxPDF_STYLE_FILLDRAW);
    $pdf->Text(100, 40, 'Black');
    
    $pdf->SetDrawColour(128, 0, 0);
    $pdf->SetFillColour(255, 0, 0);
    $pdf->SetTextColour(255, 0, 0);
    $pdf->Rect(10, 50, 20, 20, wxPDF_STYLE_FILLDRAW);
    $pdf->Text(10, 80, 'Red');
    
    $pdf->SetDrawColour(0, 127, 0);
    $pdf->SetFillColour(0, 255, 0);
    $pdf->SetTextColour(0, 255, 0);
    $pdf->Rect(40, 50, 20, 20, wxPDF_STYLE_FILLDRAW);
    $pdf->Text(40, 80, 'Green');
    
    $pdf->SetDrawColour(0, 0, 127);
    $pdf->SetFillColour(0, 0, 255);
    $pdf->SetTextColour(0, 0, 255);
    $pdf->Rect(70, 50, 20, 20, wxPDF_STYLE_FILLDRAW);
    $pdf->Text(70, 80, 'Blue');
    
    $pdf->SetDrawColour(92);
    $pdf->SetFillColour(192);
    $pdf->SetTextColour(0);
    $pdf->Rect(10, 90, 20, 20, wxPDF_STYLE_FILLDRAW);
    $pdf->Text(10, 120, 'Gray');
    
    $pdf->AddSpotColour('PANTONE 404 CVC', 0, 9.02, 23.14, 56.08);
    $pdf->SetFillColour('PANTONE 404 CVC');
    $pdf->Rect(10, 130, 20, 20, wxPDF_STYLE_FILL);
    $pdf->Text(10, 160, 'PANTONE 404 CVC');
    
    $pdf->SetLineWidth(0.2);
    $pdf->SetFont('Helvetica', '', 48);
    $pdf->SetTextRenderMode(wxPDF_TEXT_RENDER_FILLSTROKE);
    $pdf->SetDrawColour(31);
    $pdf->SetTextPattern('pattern2');
    $pdf->Text(10, 200, 'Text with Pattern');
    $pdf->SetTextRenderMode();
    $pdf->SetTextColour(0);
    
    $pdf->AddPage();
    $pdf->SetFont('Helvetica', '', 10);
    $pdf->SetLineWidth(0.2);
    $pdf->SetDrawColour(0);
    
    $pdf->Curve(25, 40, 50, 55, 90, 45, 80, 75, wxPDF_STYLE_DRAW);
    my $shape1 = Wx::PdfShape->new;
    $shape1->MoveTo(25,40);
    $shape1->CurveTo(50, 55, 90, 45, 80, 75);
    $pdf->ShapedText($shape1, 'This is a simple text string along a shaped line.');
    
    $pdf->Curve(80, 175, 90, 145, 50, 155, 25, 140, wxPDF_STYLE_DRAW);
    my $shape2 = Wx::PdfShape->new;
    $shape2->MoveTo(80, 175);
    $shape2->CurveTo(90, 145, 50, 155, 25, 140);
    $pdf->ShapedText($shape2, 'This is a simple text string along a shaped line.');
    
    $pdf->Curve(125, 40, 150, 55, 190, 45, 180, 75, wxPDF_STYLE_DRAW);
    my $shape3 = Wx::PdfShape->new;
    $shape3->MoveTo(125,40);
    $shape3->CurveTo(150, 55, 190, 45, 180, 75);
    $pdf->ShapedText($shape3, 'Repeat me! ', wxPDF_SHAPEDTEXTMODE_REPEAT);
    
    my $shape4 = Wx::PdfShape->new;
    $shape4->MoveTo(125, 130);
    $shape4->LineTo(150, 130);
    $shape4->LineTo(150, 150);
    $shape4->ClosePath();
    $shape4->MoveTo(125, 175);
    $shape4->CurveTo(150, 145, 190, 155, 180, 140);
    $pdf->Shape($shape4, wxPDF_STYLE_FILL | wxPDF_STYLE_DRAWCLOSE);
    
    $pdf->AddPage();
    $pdf->SetFont('Helvetica', '', 10);
    
    my $pi = 4. * atan(1.0);
    
    $pdf->Text(130, 40, 'Closed Bezier spline');
    my( @xp, @yp );
    my $nseg = 10;
    my $radius = 30;
    my $step = 2 * $pi / $nseg;
    for (my $i = 0; $i < $nseg; ++$i)
    {
      my $angle = $i * $step;
      push( @xp, 20 + $radius * (sin($angle) + 1));
      push( @yp, 20 + $radius * (cos($angle) + 1));
      $pdf->Marker($xp[$i], $yp[$i], wxPDF_MARKER_CIRCLE, 2.0);
    }
    $pdf->ClosedBezierSpline(\@xp, \@yp, wxPDF_STYLE_DRAW);
    
    $pdf->Text(130, 120, 'Bezier spline for Sine function');
    # Sinus points in [0,2PI].
    # Fill point array with scaled in X,Y Sin values in [0, PI].
    my( @xpSin, @ypSin);
    my $scaleX = 20;
    my $scaleY = 20;
    $step = 2 * $pi / $nseg;
    for (my $i = 0; $i < $nseg; ++$i)
    {
      my $angle = $i * $step;
      push( @xpSin, 20 + $scaleX * $angle);
      push( @ypSin, 100 + $scaleX * (1 - sin($angle)));
      $pdf->Marker($xpSin[$i], $ypSin[$i], wxPDF_MARKER_CIRCLE, 2.0);
    }
    $pdf->BezierSpline(\@xpSin, \@ypSin, wxPDF_STYLE_DRAW);
    
    $pdf->Text(130, 180, 'Bezier spline for Runge function');
    my( @xpRunge, @ypRunge );
    $step = 2.0 / ($nseg - 1);
    for (my $i = 0; $i < $nseg; ++$i)
    {
      my $xstep = -1 + $i * $step;
      push(@xpRunge, 20 + $scaleX * ($xstep+1));
      push(@ypRunge, 160 + $scaleY * (1 - 1 / (1 + 25 * $xstep * $xstep)));
      $pdf->Marker($xpRunge[$i], $ypRunge[$i], wxPDF_MARKER_CIRCLE, 2.0);
    }
    $pdf->BezierSpline(\@xpRunge, \@ypRunge, wxPDF_STYLE_DRAW);
    
    $pdf->Text(130, 240, 'Bezier spline for arc from 0 to 270 degree');
    my( @xpArc, @ypArc   );
    $step = 270.0 / ($nseg - 1);
    for (my $i = 0; $i < $nseg; ++$i)
    {
      my $angle = $pi * $i * $step / 180;
      push(@xpArc, 20 + $scaleX * (cos($angle) + 1));
      push(@ypArc, 220 + $scaleY * (sin($angle) + 1)); 
      $pdf->Marker($xpArc[$i], $ypArc[$i], wxPDF_MARKER_CIRCLE, 2.0);
    }
    $pdf->BezierSpline(\@xpArc, \@ypArc, wxPDF_STYLE_DRAW);

    
    $pdf->SaveAsFile($filepath);
}

###################################################

package 
   Wx::DemoModules::wxPdfDocument::Gradients;

###################################################

#/**
#* Gradients
#* 
#* This example shows examples of linear and radial gradient shadings
#*/

use strict;
use warnings;
use Wx qw( :pdfdocument :print :bitmap );
use Math::Trig;

sub new {
    my $class = shift;
    my $self = bless {}, $class;
    return $self;
}

sub run_pdfdemo {
    my ($self, $filepath) = @_;
    
    my $pdf = Wx::PlPdfDocument->new;
    $pdf->AddPage();
    
    # set colors for gradients (r,g,b) or (grey 0-255)
    my $blue = Wx::PdfColour->new(0,0,255);
  
    my $green = Wx::PdfColour->new(0,255,0);
    my $red = Wx::PdfColour->new(255,0,0);
    my $yellow = Wx::PdfColour->new(255,255,0);
    my $magenta = Wx::PdfColour->new(255,0,255);
    my $cyan = Wx::PdfColour->new(0,255,255);
    my $white = Wx::PdfColour->new(255,255,255);
    my $black = Wx::PdfColour->new(0,0,0);
    my $navy = Wx::PdfColour->new('navy');
    my $lightsteelblue = Wx::PdfColour->new('lightsteelblue');
    my $light = Wx::PdfColour->new('#EEEEEE');
    my $fcol = Wx::PdfColour->new('#440000');
    my $tcol = Wx::PdfColour->new('#FF9090');

    # paint a linear gradient
    my $grad1 = $pdf->LinearGradient($red,$blue);
    $pdf->SetFillGradient(10,10,90,90,$grad1);

    # paint a radial gradient
    my $grad2 = $pdf->RadialGradient($white,$black,0.5,0.5,0,1,1,1.2);
    $pdf->SetFillGradient(110,10,90,90,$grad2);
    
    my $grad3 = $pdf->LinearGradient($navy, $lightsteelblue, wxPDF_LINEAR_GRADIENT_MIDHORIZONTAL);
    $pdf->SetFillGradient(10,200,10,20,$grad3);

    my $grad4 = $pdf->LinearGradient($navy, $lightsteelblue, wxPDF_LINEAR_GRADIENT_MIDVERTICAL);
    $pdf->SetFillGradient(30,200,10,20,$grad4);

    my $grad5 = $pdf->LinearGradient($navy, $lightsteelblue, wxPDF_LINEAR_GRADIENT_HORIZONTAL);
    $pdf->SetFillGradient(50,200,10,20,$grad5);
  
    my $grad6 = $pdf->LinearGradient($navy, $lightsteelblue, wxPDF_LINEAR_GRADIENT_VERTICAL);
    $pdf->SetFillGradient(70,200,10,20,$grad6);
  
    my $grad7 = $pdf->MidAxialGradient($navy, $lightsteelblue, 0, 0, 1, 0, 0.5, 0.75);
    $pdf->SetFillGradient(90,200,10,20,$grad7);
  
    my $grad8a = $pdf->LinearGradient($fcol, $tcol, wxPDF_LINEAR_GRADIENT_REFLECTION_LEFT);
    $pdf->SetFillGradient(110,200,10,20,$grad8a);
  
    my $grad8b = $pdf->LinearGradient($fcol, $tcol, wxPDF_LINEAR_GRADIENT_REFLECTION_RIGHT);
    $pdf->SetFillGradient(130,200,10,20,$grad8b);
  
    my $grad8c = $pdf->LinearGradient($fcol, $tcol, wxPDF_LINEAR_GRADIENT_REFLECTION_TOP);
    $pdf->SetFillGradient(150,200,10,20,$grad8c);
  
    my $grad8d = $pdf->LinearGradient($fcol, $tcol, wxPDF_LINEAR_GRADIENT_REFLECTION_BOTTOM);
    $pdf->SetFillGradient(170,200,10,20,$grad8d);
  
    # example of clipping polygon
    my( @x1, @x2, @y);
    
    @x1 = (30,60,40,70,30);
    @x2 = (120,150,130,160,120);
    @y = (135,155,155,160,165);
  
    my $false = 0;
  
    $pdf->ClippingPolygon(\@x1,\@y,$false);
    $pdf->SetFillGradient(20,135,50,30,$grad1);
    $pdf->UnsetClipping();
    $pdf->ClippingPolygon(\@x2,\@y,$false);
    $pdf->SetFillGradient(110,125,60,50,$grad2);
    $pdf->UnsetClipping();
  
    # coons patches
    $pdf->AddPage();
  
    # paint a coons patch mesh with default coordinates
    my $mesh1 = Wx::PdfCoonsPatchMesh->new;
    my $colours1 = [ $yellow, $blue, $green, $red ];

    my $x1a = [ 0.00, 0.33, 0.67, 1.00, 1.00, 1.00, 1.00, 0.67, 0.33, 0.00, 0.00, 0.00 ];
    my $y1a = [ 0.00, 0.00, 0.00, 0.00, 0.33, 0.67, 1.00, 1.00, 1.00, 1.00, 0.67, 0.33 ];
    $mesh1->AddPatch(0, $colours1, $x1a, $y1a);
  
    my $coons1 = $pdf->CoonsPatchGradient($mesh1);
    $pdf->SetFillGradient(20,115,80,80,$coons1);
  
    # set the coordinates for the cubic Bézier points x1,y1 ... x12, y12 of the patch
    # (see coons_patch_mesh_coords.jpg)
    my $mesh2 = Wx::PdfCoonsPatchMesh->new;
    my $colours2 = [ $yellow, $blue, $green, $red ];
    my $x2a = [ 0.00, 0.33, 0.67, 1.00, 0.80, 0.80, 1.00, 0.67, 0.33, 0.00, 0.20, 0.00 ];
    my $y2a = [ 0.00, 0.20, 0.00, 0.00, 0.33, 0.67, 1.00, 0.80, 1.00, 1.00, 0.67, 0.33 ];
    $mesh2->AddPatch(0, $colours2, $x2a, $y2a);
  
    my $minCoord2 = 0; # minimum value of the coordinates
    my $maxCoord2 = 1; # maximum value of the coordinates
    my $coons2 = $pdf->CoonsPatchGradient($mesh2, $minCoord2, $maxCoord2);
    $pdf->SetFillGradient(110,115,80,80,$coons2);
  
    # Next Page
    $pdf->AddPage();
    $pdf->Ln();
    
    my $mesh3 = Wx::PdfCoonsPatchMesh->new;
    my $minCoord3 = 0; # minimum value of the coordinates
    my $maxCoord3 = 2; # maximum value of the coordinates

    #// first patch: f = 0
    my $colours3a = [ $yellow, $blue, $green, $red ];
    my $x3a = [ 0.00, 0.33, 0.67, 1.00, 1.00, 0.80, 1.00, 0.67, 0.33, 0.00, 0.00, 0.00 ];
    my $y3a = [ 0.00, 0.00, 0.00, 0.00, 0.33, 0.67, 1.00, 0.80, 1.80, 1.00, 0.67, 0.33 ];
    $mesh3->AddPatch(0, $colours3a, $x3a, $y3a);
    
    #// second patch - above the other: f = 2
    my $colours3b = [ $black, $magenta ];
    my $x3b = [ 0.00, 0.00, 0.00, 0.33, 0.67, 1.00, 1.00, 1.50 ];
    my $y3b = [ 1.33, 1.67, 2.00, 2.00, 2.00, 2.00, 1.67, 1.33 ];
    $mesh3->AddPatch(2, $colours3b, $x3b, $y3b);
    
    #// third patch - right of the above: f = 3
    my $colours3c = [ $cyan, $black ];
    my $x3c = [ 1.33, 1.67, 2.00, 2.00, 2.00, 2.00, 1.67, 1.33 ];
    my $y3c = [ 0.80, 1.50, 1.00, 1.33, 1.67, 2.00, 2.00, 2.00 ];
    $mesh3->AddPatch(3, $colours3c, $x3c, $y3c);
    
    #// fourth patch - below the above, which means left(?) of the above: f = 1
    my $colours3d = [ $black, $blue ];
    my $x3d = [ 2.00, 2.00, 2.00, 1.67, 1.33, 1.00, 1.00, 0.80 ];
    my $y3d = [ 0.67, 0.33, 0.00, 0.00, 0.00, 0.00, 0.33, 0.67 ];
    $mesh3->AddPatch(1, $colours3d, $x3d, $y3d);
    
    my $coons3 = $pdf->CoonsPatchGradient($mesh3, $minCoord3, $maxCoord3);
    $pdf->SetFillGradient(10,25,190,200,$coons3);
    
    $pdf->SaveAsFile($filepath);
}


###################################################

package 
   Wx::DemoModules::wxPdfDocument::JavaScript;

###################################################

#/**
#* JavaScript
#*
#* This example demonstrates how you could start the print dialog on opening
#* your PDF document using a bit of JavaScript.
#*/

use strict;
use warnings;
use Wx::PdfDocument;
use Wx qw( :pdfdocument :print );

sub new {
    my $class = shift;
    my $self = bless {}, $class;
    return $self;
}

sub run_pdfdemo {
    my ($self, $filepath) = @_;
    my $pdf = Wx::PlPdfDocument->new;
    $pdf->AddPage();
    $pdf->SetFont('Helvetica', '', 20);
    $pdf->Text(90, 50, 'Print me!');
    # Launch the print dialog
    my $jscript = q(print(true););
    $pdf->AppendJavascript($jscript);
    $pdf->SaveAsFile($filepath);
}

###################################################

package 
   Wx::DemoModules::wxPdfDocument::Forms;

###################################################

#/**
#* Interactive forms
#*
#* This example demonstrates how create interactive forms in your PDF document.
#*/

use strict;
use warnings;
use Wx::PdfDocument;
use Wx qw( :pdfdocument :print );

sub new {
    my $class = shift;
    my $self = bless {}, $class;
    return $self;
}

sub run_pdfdemo {
    my ($self, $filepath) = @_;
    my $pdf = Wx::PlPdfDocument->new;
    $pdf->SetFormColours(Wx::PdfColour->new(255,0,0), Wx::PdfColour->new(250,235,186), Wx::PdfColour->new(0,0,255));
    $pdf->AddPage();
  
    # Title
    $pdf->SetFont('Helvetica', 'U', 16);
    $pdf->Cell(0, 5, 'Subscription form', 0, 1, wxPDF_ALIGN_CENTER);
    $pdf->Ln(10);
    $pdf->SetFont('', '', 12);
  
    # First name
    $pdf->Cell(35, 5, 'First name:');
    $pdf->SetFormBorderStyle(wxPDF_BORDER_UNDERLINE);
    $pdf->TextField('firstname', $pdf->GetX(), $pdf->GetY(), 50, 5, '');
    $pdf->Ln(6);
  
    # Last name
    $pdf->Cell(35, 5, 'Last name:');
    $pdf->SetFormBorderStyle(wxPDF_BORDER_UNDERLINE);
    $pdf->TextField('lastname', $pdf->GetX(), $pdf->GetY(), 50, 5, '');
    $pdf->Ln(6);
  
    # Title
    $pdf->Cell(35, 5, 'Title:');
    $pdf->SetFormBorderStyle();
    $pdf->ComboBox('titlecombo', $pdf->GetX(), $pdf->GetY(), 20,5, ['', 'Dr.', 'Prof.']);
    $pdf->Ln(8);
  
    # Gender
    $pdf->Cell(35, 5, 'Gender:', 0, 0);
    my $x = $pdf->GetX();
    my $y = $pdf->GetY();
    $pdf->RadioButton('gender', 'male', $x, $y, 4);
    $pdf->RadioButton('gender', 'female', $x+25, $y, 4);
    $pdf->SetXY($x+6, $y);
    $pdf->Cell(20, 5, 'male', 0, 0);
    $pdf->SetXY($x+31, $y);
    $pdf->Cell(20, 5, 'female', 0, 0);
    $pdf->Ln(8);
   
    my $true  = 1;
    my $false = 0;
    
    # Address
    $pdf->Cell(35, 5, 'Address:');
    $pdf->SetFormBorderStyle();
    $pdf->TextField('address', $pdf->GetX(), $pdf->GetY(), 60, 18, '', $true);
    $pdf->Ln(19);
  
    # E-mail
    $pdf->Cell(35, 5, 'E-mail:');
    $pdf->SetFormBorderStyle();
    $pdf->TextField('email', $pdf->GetX(), $pdf->GetY(), 50, 5, '');
    $pdf->Ln(6);
  
    # Newsletter
    $pdf->Cell(35, 5, 'Receive our', 0, 1);
    $pdf->Cell(35, 5, 'newsletter:');
    $pdf->SetFormBorderStyle(wxPDF_BORDER_DASHED);
    $pdf->CheckBox('newsletter', $pdf->GetX(), $pdf->GetY(), 5, $false);
    $pdf->Ln(10);
  
    # Date of the day
    $pdf->Cell(35, 5, 'Date: ');
    $pdf->SetFormBorderStyle();
    $pdf->TextField('date', $pdf->GetX(), $pdf->GetY(), 30, 5, Wx::DateTime::Today->FormatISODate);
    $pdf->Ln(5);
    $pdf->Cell(35, 5,'Signature:');
    $pdf->Ln(12);
  
    # Button to print
    $pdf->SetX(95);
    $pdf->SetFormBorderStyle();
    $pdf->PushButton('print', $pdf->GetX(), $pdf->GetY(), 20,8, 'Print', 'print(true);');
    
    $pdf->SaveAsFile($filepath);
}

###################################################

package 
   Wx::DemoModules::wxPdfDocument::Kerning;

###################################################

#/**
#* Kerning
#*
#* This example demonstrates the use of kerning.
#*/

use strict;
use warnings;
use Wx::PdfDocument;
use Wx qw( :pdfdocument :print );

sub new {
    my $class = shift;
    my $self = bless {}, $class;
    return $self;
}

sub run_pdfdemo {
    my ($self, $filepath) = @_;
    my $pdf = Wx::PlPdfDocument->new;
    $pdf->SetFont('Helvetica','',24);
    $pdf->AddPage();
    $pdf->SetKerning(0);
    $pdf->Cell(0,6,'WATER AWAY (without kerning)');
    $pdf->Ln(12);
    $pdf->SetKerning(1);
    $pdf->Cell(0,6,'WATER AWAY (with kerning)');
    $pdf->SaveAsFile($filepath);
}

###################################################

package 
   Wx::DemoModules::wxPdfDocument::Labels;

###################################################

#/**
#* Labels
#* 
#* This example demonstrates the PDF label printing.
#*
#* The code is based on the PHP script PDF_Label of Laurent PASSEBECQ.
#*
#* Following are the comments from the original PHP code:
#*
#* ////////////////////////////////////////////////////
#* // PDF_Label 
#* //
#* // Class to print labels in Avery or custom formats
#* //
#* // Copyright (C) 2003 Laurent PASSEBECQ (LPA)
#* // Based on code by Steve Dillon : steved@mad.scientist.com
#* //
#* //-------------------------------------------------------------------
#* // VERSIONS :
#* // 1.0  : Initial release
#* // 1.1  : + : Added unit in the constructor
#* //        + : Now Positions start @ (1,1).. then the first image @top-left of a page is (1,1)
#* //        + : Added in the description of a label : 
#* //        font-size  : defaut char size (can be changed by calling Set_Char_Size(xx);
#* //        paper-size  : Size of the paper for this sheet (thanx to Al Canton)
#* //        metric    : type of unit used in this description
#* //                You can define your label properties in inches by setting metric to 'in'
#* //                and printing in millimiter by setting unit to 'mm' in constructor.
#* //        Added some labels :
#* //        5160, 5161, 5162, 5163,5164 : thanx to Al Canton : acanton@adams-blake.com
#* //        8600             : thanx to Kunal Walia : kunal@u.washington.edu
#* //        + : Added 3mm to the position of labels to avoid errors 
#* // 1.2  : + : Added Set_Font_Name method
#* //        = : Bug of positioning
#* //        = : Set_Font_Size modified -> Now, just modify the size of the font
#* //        = : Set_Char_Size renamed to Set_Font_Size
#* ////////////////////////////////////////////////////
#*/

use strict;
use warnings;
use Wx::PdfDocument;
use Wx qw( :pdfdocument :print );
use base qw( Wx::PlPdfDocument );

our $_formatdata = [
    [ '5160',  wxPAPER_LETTER, 'mm', 1.762, 10.7,    3, 10,  3.175,  0.,  66.675,  25.4,   8 ],
    [ '5161',  wxPAPER_LETTER, 'mm', 0.967, 10.7,    2, 10,  3.967,  0.,  101.6,   25.4,   8 ],
    [ '5162',  wxPAPER_LETTER, 'mm', 0.97,  20.224,  2,  7,  4.762,  0.,  100.807, 35.72,  8 ],
    [ '5163',  wxPAPER_LETTER, 'mm', 1.762, 10.7,    2,  5,  3.175,  0.,  101.6,   50.8,   8 ],
    [ '5164',  wxPAPER_LETTER, 'in', 0.148, 0.5,     2,  3,  0.2031, 0.,    4.0,    3.33, 12 ],
    [ '8600',  wxPAPER_LETTER, 'mm', 7.1,   19,      3, 10,  9.5,    3.1,  66.6,   25.4,   8 ],
    [ 'L7163', wxPAPER_A4,     'mm', 5.0,   15,      2,  7,  25.0,   0.,   99.1,   38.1,   9 ],
];

our $_formatdb = {};

{
    # make label format db
    for my $format ( @$_formatdata ) {
        $_formatdb->{$format->[0]} = {
            name        =>  $format->[0],
            paper       =>  $format->[1],
            metric      =>  $format->[2],
            marginleft  =>  $format->[3],
            margintop   =>  $format->[4],
            nx          =>  $format->[5],
            ny          =>  $format->[6],
            xspace      =>  $format->[7],
            yspace      =>  $format->[8],
            width       =>  $format->[9],
            height      =>  $format->[10],
            fontsize    =>  $format->[11],
        };
    }
}

sub get_format_member {
    my $mb = shift;
    if(exists($_formatdb->{$mb})) {
        return $_formatdb->{$mb};
    } else {
        return undef;
    }
}

sub ConvertMetric {
    my($value, $src, $dest) = @_;
    my $rval = $value;
    if ($src eq 'in' && $dest eq 'mm'){
      $rval *= (1000./ 39.37008);
    } elsif ($src eq 'mm' && $dest eq 'in'){
      $rval *= (39.37008 / 1000.);
    }
    return $rval;
}

sub GetHeightChars {
    my($pt) = @_;
    my $height = 100;
    # Array matching character sizes and line heights
    
    my @ctable = ( 6, 7,   8, 9, 10, 11, 12, 13, 14, 15 );
    my @htable = ( 2, 2.5, 3, 4,  5,  6,  7,  8,  9, 10 );
    for (my $i = 0; $i < @ctable; $i++) {
      if ($pt == $ctable[$i]) {
        $height = $htable[$i];
        last;
      }
    }
    return $height;
}

sub new {
    my ($class, $format, $posx, $posy) = @_;
    $format = 'L7163' if !$format;
    $posx = 1 if !defined($posx);
    $posy = 1 if !defined($posy);
    $format = get_format_member($format) unless(ref($format) eq 'HASH');
    if(!$format) {
        die qq(Label format does not exist in the label format database);
    }
    my $self = $class->SUPER::new(wxPORTRAIT, $format->{metric}, $format->{paper});
    $self->SetFormat($format);
    $self->SetFontName('Helvetica');
    $self->SetMargins(0,0); 
    $self->SetAutoPageBreak(0); 
    # Start at the given label position
    $self->{xcount} = ($posx >= $self->{xnumber}) ? $self->{xnumber} -1 : (($posx > 1) ? $posx-1 : 0);
    $self->{ycount} = ($posy >= $self->{ynumber}) ? $self->{ynumber} -1 : (($posy > 1) ? $posy-1 : 0);
    
    return $self;
}

sub SetFontName {
    my($self, $fontname) = @_;
    if ($fontname) {
      $self->{fontname} = $fontname;
      $self->SetFont($fontname);
    }
}

sub SetFontSize {
    my($self, $pt) = @_;
    if ($pt > 3) {
      $self->{charsize} = $pt;
      $self->{lineheight} = GetHeightChars($pt);
      $self->SUPER::SetFontSize($self->{charsize});
    }
}

sub AddLabel {
    my ($self, $text) = @_;

    # We are in a new page, then we must add a page
    if (($self->{xcount} == 0) && ($self->{ycount} == 0)) {
      $self->AddPage();
    }
    
    my $posX = $self->{marginleft} + ($self->{xcount} * ( $self->{width} + $self->{xspace}));
    my $posY = $self->{margintop}  + ($self->{ycount} * ( $self->{height} + $self->{yspace}));
    $self->SetXY($posX+3, $posY+3);
    $self->MultiCell($self->{width}, $self->{lineheight}, $text);

    $self->{ycount}++;

    if ($self->{ycount} == $self->{ynumber}) {
      # End of column reached, we start a new one
      $self->{xcount}++;
      $self->{ycount} = 0;
    }

    if ($self->{xcount} == $self->{xnumber}) {
      # Page full, we start a new one
      $self->{xcount} = 0;
      $self->{ycount} = 0;
    }
}

sub SetFormat {
    my ($self, $format) = @_;
    $self->{metric}      = $format->{metric};
    $self->{averyname}   = $format->{name};
    $self->{marginleft} = ConvertMetric($format->{marginleft}, $self->{metric}, 'mm');
    $self->{margintop}  = ConvertMetric($format->{margintop},  $self->{metric}, 'mm');
    $self->{xspace}      = ConvertMetric($format->{xspace},     $self->{metric}, 'mm');
    $self->{yspace}      = ConvertMetric($format->{yspace},     $self->{metric}, 'mm');
    $self->{width}       = ConvertMetric($format->{width},      $self->{metric}, 'mm');
    $self->{height}      = ConvertMetric($format->{height},     $self->{metric}, 'mm');
    $self->{xnumber}     = $format->{nx};
    $self->{ynumber}     = $format->{ny};
    $self->SetFontSize($format->{fontsize});
}

sub run_pdfdemo {
    my ($self, $filepath) = @_;
    my $pdf = Wx::PlPdfDocument->new;
    #// To create the object, 2 possibilities:
    #// either pass a custom format via a hash
    #// or use a built-in AVERY name
    #// by default we have setup in this demo as Avery type L7163

    for (my $i = 1; $i <= 40; $i++ )    {
        $self->AddLabel(qq(Laurent $i\nImmeuble Titi\nav. fragonard\n06000, NICE, FRANCE));
    }   
    
    $self->SaveAsFile($filepath);
}

###################################################

package 
   Wx::DemoModules::wxPdfDocument::LayersOrdered;

###################################################

#/**
# * OrderedLayers demonstrates how to order optional content groups.
# */

use strict;
use warnings;
use Wx::PdfDocument;
use Wx qw( :pdfdocument :print );
use base qw( Wx::PlPdfDocument );

sub new {
    my $class = shift;
    my $self = $class->SUPER::new( @_ );
    return $self;
}

sub run_pdfdemo {
    my ($self, $filepath) = @_;
    
    $self->AddPage();

    # Layers appear in the order in that they were added to the document
    
    my $l1 = $self->AddLayer('Layer 1');
    my $l2 = $self->AddLayer('Layer 2');
    my $l3 = $self->AddLayer('Layer 3');
    my $m1 = $self->AddLayerMembership();
    $m1->AddMember($l2);
    $m1->AddMember($l3);
    
    $self->SetTextColour(Wx::PdfColour->new('red'));
    $self->SetFont('Helvetica','B',20);
    $self->Cell(0,6,'Ordered layers');
    $self->Ln(25);
    $self->SetTextColour(Wx::PdfColour->new('black'));
    $self->SetFont('Helvetica','',12);
    $self->EnterLayer($l1);
    $self->Cell(0,6,'Text in layer 1');
    $self->Ln(15);
    $self->LeaveLayer();
    $self->EnterLayer($m1);
    $self->Cell(0,6,'Text in layer 2 or layer 3');
    $self->Ln(15);
    $self->LeaveLayer();
    $self->EnterLayer($l3);
    $self->Cell(0,6,'Text in layer 3');
    $self->Ln(15);
    $self->LeaveLayer();

    $self->SaveAsFile($filepath);
}

###################################################

package 
   Wx::DemoModules::wxPdfDocument::LayersGrouped;

###################################################

#/**
# * GroupedLayers demonstrates how to group optional content.
# */

use strict;
use warnings;
use Wx::PdfDocument;
use Wx qw( :pdfdocument :print );
use base qw( Wx::PlPdfDocument );

sub new {
    my $class = shift;
    my $self = $class->SUPER::new( @_ );
    return $self;
}

sub run_pdfdemo {
    my ($self, $filepath) = @_;
    
    $self->AddPage();

    # Layers appear in the order in that they were added to the document
    my $l1 = $self->AddLayer('Layer 1');
    my $l2 = $self->AddLayer('Layer 2');
    my $l3 = $self->AddLayer('Layer 3');
    my $l0 = $self->AddLayerTitle('A group of two');
    $l0->AddChild($l2);
    $l0->AddChild($l3);
    
    my $m1 = $self->AddLayerMembership();
    $m1->AddMember($l2);
    $m1->AddMember($l3);
    
    $self->SetTextColour(Wx::PdfColour->new('red'));
    $self->SetFont('Helvetica','B',20);
    $self->Cell(0,6,'Grouping layers');
    $self->Ln(25);
    $self->SetTextColour(Wx::PdfColour->new('black'));
    $self->SetFont('Helvetica','',12);
    
    $self->EnterLayer($l1);
    $self->Cell(0,6,'Text in layer 1');
    $self->Ln(15);
    $self->LeaveLayer();
    $self->EnterLayer($m1);
    $self->Cell(0,6,'Text in layer 2 or layer 3');
    $self->Ln(15);
    $self->LeaveLayer();
    $self->EnterLayer($l3);
    $self->Cell(0,6,'Text in layer 3');
    $self->Ln(15);
    $self->LeaveLayer();
    
    $self->SaveAsFile($filepath);
}

###################################################

package 
   Wx::DemoModules::wxPdfDocument::LayersNested;

###################################################

#/**
# * NestedLayers demonstrates the use of nested layers.
# */

use strict;
use warnings;
use Wx::PdfDocument;
use Wx qw( :pdfdocument :print );
use base qw( Wx::PlPdfDocument );

sub new {
    my $class = shift;
    my $self = $class->SUPER::new( @_ );
    return $self;
}

sub run_pdfdemo {
    my ($self, $filepath) = @_;
    
        $self->AddPage();

    # Layers appear in the order in that they were added to the document
    my $l1 = $self->AddLayer('Layer 1');
    my $l23 = $self->AddLayer('Top Layer 2 3');
    my $l2 = $self->AddLayer('Layer 2');
    my $l3 = $self->AddLayer('Layer 3');
    
    $l23->AddChild($l2);
    $l23->AddChild($l3);
    
    $self->SetTextColour(Wx::PdfColour->new('red'));
    $self->SetFont('Helvetica','B',20);
    $self->Cell(0,6,'Nesting layers');
    $self->Ln(25);
    $self->SetTextColour(Wx::PdfColour->new('black'));
    $self->SetFont('Helvetica','',12);
    
    $self->EnterLayer($l1);
    $self->Cell(0,6,'Text in layer 1');
    $self->Ln(15);
    $self->LeaveLayer();
    $self->EnterLayer($l23);
    $self->EnterLayer($l2);
    $self->Cell(0,6,'Text in layer 2');
    $self->Ln(15);
    $self->LeaveLayer();
    $self->EnterLayer($l3);
    $self->Cell(0,6,'Text in layer 3');
    $self->Ln(15);
    $self->LeaveLayer();
    $self->LeaveLayer();
    $self->SaveAsFile($filepath);
}

###################################################

package 
   Wx::DemoModules::wxPdfDocument::LayersAutomatic;

###################################################

#/**
# * AutomaticLayers demonstrates automatic layer grouping and nesting
# */
 
use strict;
use warnings;
use Wx::PdfDocument;
use Wx qw( :pdfdocument :print );
use base qw( Wx::PlPdfDocument );

sub new {
    my $class = shift;
    my $self = $class->SUPER::new( @_ );
    return $self;
}

sub run_pdfdemo {
    my ($self, $filepath) = @_;
    
    $self->AddPage();

    # Layers appear in the order in that they were added to the document
    my $l12 = $self->AddLayer('Layer Nesting');
    my $l1 = $self->AddLayer('Layer 1');
    my $l2 = $self->AddLayer('Layer 2');
    my $l34 = $self->AddLayerTitle('Layer grouping');
    my $l3 = $self->AddLayer('Layer 3');
    my $l4 = $self->AddLayer('Layer 4');
    $l12->AddChild($l1);
    $l12->AddChild($l2);
    $l34->AddChild($l3);
    $l34->AddChild($l4);
    
    $self->SetTextColour(Wx::PdfColour->new('red'));
    $self->SetFont('Helvetica','B',20);
    $self->Cell(0,6,'Automatic Grouping and Nesting of Layers');
    $self->Ln(25);
    $self->SetTextColour(Wx::PdfColour->new('black'));
    $self->SetFont('Helvetica','',12);
  
    $self->EnterLayer($l1);
    $self->Cell(0,6,'Text in layer 1');
    $self->Ln(15);
    $self->LeaveLayer();
    $self->EnterLayer($l2);
    $self->Cell(0,6,'Text in layer 2');
    $self->Ln(15);
    $self->LeaveLayer();
    $self->EnterLayer($l3);
    $self->Cell(0,6,'Text in layer 3');
    $self->Ln(15);
    $self->LeaveLayer();
    $self->EnterLayer($l4);
    $self->Cell(0,6,'Text in layer 4');
    $self->Ln(15);
    $self->LeaveLayer();
    
    $self->SaveAsFile($filepath);
}

###################################################

package 
   Wx::DemoModules::wxPdfDocument::LayersRadioGroup;

###################################################

#/**
# * LayerRadioGroup demonstrates radio group and zoom.
# */

use strict;
use warnings;
use Wx::PdfDocument;
use Wx qw( :pdfdocument :print );
use base qw( Wx::PlPdfDocument );

sub new {
    my $class = shift;
    my $self = $class->SUPER::new( @_ );
    return $self;
}

sub run_pdfdemo {
    my ($self, $filepath) = @_;
    
    $self->AddPage();

    # Layers appear in the order in that they were added to the document
    my $lrg = $self->AddLayerTitle('Layer radio group');
    my $l1 = $self->AddLayer('Layer 1');
    my $l2 = $self->AddLayer('Layer 2');
    my $l3 = $self->AddLayer('Layer 3');
    my $l4 = $self->AddLayer('Layer 4');
    $lrg->AddChild($l1);
    $lrg->AddChild($l2);
    $lrg->AddChild($l3);
  
    $l4->SetZoom(2, -1);
    $l4->SetOnPanel(0);
    $l4->SetPrint('Print', 1);
    $l2->SetOn(0);
    $l3->SetOn(0);
  
    my $radio = Wx::PdfLayerGroup->new;
    $radio->Add($l1);
    $radio->Add($l2);
    $radio->Add($l3);
    $self->AddLayerRadioGroup($radio);
  
    $self->SetTextColour(Wx::PdfColour->new('red'));
    $self->SetFont('Helvetica','B',20);
    $self->Cell(0,6,'Layer Radio Group and Zoom');
    $self->Ln(25);
    $self->SetTextColour(Wx::PdfColour->new('black'));
    $self->SetFont('Helvetica','',12);
  
    $self->EnterLayer($l1);
    $self->Cell(0,6,'Text in layer 1');
    $self->Ln(15);
    $self->LeaveLayer();
    $self->EnterLayer($l2);
    $self->Cell(0,6,'Text in layer 2');
    $self->Ln(15);
    $self->LeaveLayer();
    $self->EnterLayer($l3);
    $self->Cell(0,6,'Text in layer 3');
    $self->Ln(15);
    $self->LeaveLayer();
    $self->EnterLayer($l4);
    $self->Cell(30,6,'Text in layer 4');
    $self->LeaveLayer();
    $self->SetTextColour(Wx::PdfColour->new('blue'));
    $self->SetFont('Courier','',12);
    $self->Cell(0, 6, '<< Zoom here (200% or more)!');
    $self->Ln(15);
    
    $self->SaveAsFile($filepath);
}

###################################################

package 
   Wx::DemoModules::wxPdfDocument::ProtectionPrint;

###################################################

#/**
#* Protection1
#*
#* This example demonstrates how you could protect your PDF document
#* against copying text via cut & paste.
#*/

use strict;
use warnings;
use Wx::PdfDocument;
use Wx qw( :pdfdocument :print );
use base qw( Wx::PlPdfDocument );

sub new {
    my $class = shift;
    my $self = $class->SUPER::new( @_ );
    return $self;
}

sub run_pdfdemo {
    my ($self, $filepath) = @_;
    
    $self->SetProtection(wxPDF_PERMISSION_PRINT);
    $self->AddPage();
    $self->SetFont('Helvetica');
    $self->Cell(0,10,'You can print me but not copy my text.',0,1);
    
    $self->SaveAsFile($filepath);
}

###################################################

package 
   Wx::DemoModules::wxPdfDocument::ProtectionEncrypt;

###################################################

#/**
#* Protection1
#*
#* This example demonstrates how you could protect your PDF document
#* against unauthorized access by using passwords with 128-bit encryption key.
#*/

use strict;
use warnings;
use Wx::PdfDocument;
use Wx qw( :pdfdocument :print );
use base qw( Wx::PlPdfDocument );

sub new {
    my $class = shift;
    my $self = $class->SUPER::new( @_ );
    return $self;
}

sub run_pdfdemo {
    my ($self, $filepath) = @_;
    
    $self->SetProtection(wxPDF_PERMISSION_NONE, 'Hello', 'World', wxPDF_ENCRYPTION_RC4V2, 128);
    $self->AddPage();
    $self->SetFont('Helvetica');
    $self->Cell(0,10,'You can only view me on screen.',0,1);
   
    $self->SaveAsFile($filepath);
}

###################################################

package 
   Wx::DemoModules::wxPdfDocument::Rotation;

###################################################

#/**
#* Rotations
#* 
#* This example shows the effects of rotating text and an image.
#*/

use strict;
use warnings;
use Wx::PdfDocument;
use Wx qw( :pdfdocument :print );
use base qw( Wx::PlPdfDocument );

sub new {
    my $class = shift;
    my $self = $class->SUPER::new( @_ );
    return $self;
}

sub run_pdfdemo {
    my ($self, $filepath) = @_;
    
    my $png = Wx::Demo->get_data_file( qq(pdfdocument/circle.png) );
    
    $self->AddPage();
    $self->SetFont('Helvetica','',20);
    $self->RotatedImage($png,85,60,40,16,45);
    $self->RotatedText(100,60,'Hello!',45);
    
    $self->SaveAsFile($filepath);
}


###################################################

package 
   Wx::DemoModules::wxPdfDocument::TemplateInternal;

###################################################

#/**
#* Templates Internal
#* 
#* This example shows the creation and use of internal templates.
#*/

use strict;
use warnings;
use Wx::PdfDocument;
use Wx qw( :pdfdocument :print );
use base qw( Wx::PlPdfDocument );

sub new {
    my $class = shift;
    my $self = $class->SUPER::new( @_ );
    return $self;
}

sub run_pdfdemo {
    my ($self, $filepath) = @_;
    
    $self->AddPage();
    
    # Generate a template clip on  x=0, y=0, width=180, height=350
    # Take care, that the margins of the Template are set to the
    # original margins.
    my $tpl1 = $self->BeginTemplate(0, 0, 180, 350);
    $self->SetFont('Helvetica', '', 14);
    $self->SetTextColour(0);
    for(my $i = 0; $i < 200; $i++)
    {
      $self->Write(10, qq(dummy text $i ));
    }
    $self->Image(Wx::Demo->get_data_file( qq(pdfdocument/glasses.png) ), 100, 60, 100);
    $self->EndTemplate();
    
    # Generate a template that will hold the whole page
    my $tpl2 = $self->BeginTemplate();
    $self->SetFont('Helvetica', '', 14);
    
    # demonstrate how to lay text in background of an existing template
    $self->SetXY(115, 55);
    $self->Write(10, 'write behind it...');
    
    # Now we use our first created template on position x=10, y=10 and
    # give it a width of 50mm (height is calculated automaticaly) and draw a border around it
    $self->UseTemplate($tpl1, 10, 10, 50);
    my $w = 50;
    my $h = 0;
    $self->GetTemplateSize($tpl1, $w, $h);
    $self->Rect(10, 10,$w, $h);
    
    # Same as above, but another size
    $self->UseTemplate($tpl1, 70, 10, 100);
    $w = 100;
    $h = 0;
    $self->GetTemplateSize($tpl1, $w, $h);
    $self->Rect(70, 10, $w, $h);
    $self->EndTemplate();
    
    # Till now, there is no output to the PDF-File
    # We draw Template No. 2, that includes 2 Versions of the first
    $self->UseTemplate($tpl2);
    
    $self->AddPage();
    
    # Here we reuse Template No. 2
    # For example I used the rotate-script
    # to show u how, easy it is to use the created templates
    $self->SetFillColour(255);
    for (my $i = 90; $i >= 0; $i -= 30)
    {
      $self->StartTransform();
      $self->Rotate($i, 10, 120);
      $w = 100;
      $h = 0;
      $self->GetTemplateSize($tpl2, $w, $h);
      $self->Rect(10, 120, $w, $h, wxPDF_STYLE_FILLDRAW);
      $self->UseTemplate($tpl2, 10, 120, 100);
      $self->StopTransform();
    }
      
    $self->SaveAsFile($filepath);
}

###################################################

package 
   Wx::DemoModules::wxPdfDocument::TemplateExternal;

###################################################

#/**
#* Templates External
#* 
#* This example shows the creation and use of external templates.
#*/

use strict;
use warnings;
use Wx::PdfDocument;
use Wx qw( :pdfdocument :print );
use base qw( Wx::PlPdfDocument );

sub new {
    my $class = shift;
    my $self = $class->SUPER::new( @_ );
    return $self;
}

sub run_pdfdemo {
    my ($self, $filepath) = @_;
    
    $self->AddPage();
    $self->SetTextColour(Wx::PdfColour->new('black'));
    my $pages = $self->SetSourceFile( Wx::Demo->get_data_file( qq(pdfdocument/chart2d.pdf) ) );
  
    # Get the document information from the imported PDF file
    my $info = $self->GetSourceInfo();
    my $tpl  = $self->ImportPage(1);
  
    # Add some extra white space around the template
    my ($x, $y, $w, $h) = $self->GetTemplateBBox($tpl);
    
    $self->SetTemplateBBox($tpl, $x-10, $y-10, $w+20, $h+20);
    $self->UseTemplate($tpl, 20, 20, 160);
    
    # Draw a rectangle around the template
    $w = 160;
    $h = 0;
    ($w, $h) = $self->GetTemplateSize($tpl, $w, $h);
    $self->Rect(20, 20, $w, $h);
    
    $self->SetXY(30,30+$h);
    $self->SetFont('Helvetica','', 10);
    $self->SetLeftMargin(30);
    $self->Cell(0, 5, 'Title: ' . $info->GetTitle());
    $self->Ln(5);
    $self->Cell(0, 5, 'Creator: '  . $info->GetCreator());
    $self->Ln(5);
    $self->Cell(0, 5, 'Producer: ' .  $info->GetProducer());
    $self->SaveAsFile($filepath);
}

###################################################

package 
   Wx::DemoModules::wxPdfDocument::Transformation;

###################################################

#/**
#* Transformations
#* 
#* This example shows the effects of various geometric transformations
#*/

use strict;
use warnings;
use Wx::PdfDocument;
use Wx qw( :pdfdocument :print );
use base qw( Wx::PlPdfDocument );

sub new {
    my $class = shift;
    my $self = $class->SUPER::new( @_ );
    return $self;
}

sub run_pdfdemo {
    my ($self, $filepath) = @_;
    
    $self->AddPage();
    $self->SetFont('Helvetica','',12);
    
    # Scaling
    $self->SetDrawColour(200);
    $self->SetTextColour(200);
    $self->Rect(50, 20, 40, 10, wxPDF_STYLE_DRAW);
    $self->Text(50, 19, 'Scale');
    $self->SetDrawColour(0);
    $self->SetTextColour(0);
    # Start Transformation
    $self->StartTransform();
    # Scale by 150% centered by (50,30) which is the lower left corner of the rectangle
    $self->ScaleXY(150, 50, 30);
    $self->Rect(50, 20, 40, 10, wxPDF_STYLE_DRAW);
    $self->Text(50, 19, 'Scale');
    # Stop Transformation
    $self->StopTransform();
    
    # Translation
    $self->SetDrawColour(200);
    $self->SetTextColour(200);
    $self->Rect(125, 20, 40, 10, wxPDF_STYLE_DRAW);
    $self->Text(125, 19, 'Translate');
    $self->SetDrawColour(0);
    $self->SetTextColour(0);
    # Start Transformation
    $self->StartTransform();
    # Translate 20 to the right, 15 to the bottom
    $self->Translate(20, 15);
    $self->Rect(125, 20, 40, 10, wxPDF_STYLE_DRAW);
    $self->Text(125, 19, 'Translate');
    # Stop Transformation
    $self->StopTransform();
    
    #Rotation
    $self->SetDrawColour(200);
    $self->SetTextColour(200);
    $self->Rect(50, 50, 40, 10, wxPDF_STYLE_DRAW);
    $self->Text(50, 49, 'Rotate');
    $self->SetDrawColour(0);
    $self->SetTextColour(0);
    # Start Transformation
    $self->StartTransform();
    # Rotate 20 degrees counter-clockwise centered by (50,60)
    # which is the lower left corner of the rectangle
    $self->Rotate(20, 50, 60);
    $self->Rect(50, 50, 40, 10, wxPDF_STYLE_DRAW);
    $self->Text(50, 49, 'Rotate');
    # Stop Transformation
    $self->StopTransform();
    
    # Skewing
    $self->SetDrawColour(200);
    $self->SetTextColour(200);
    $self->Rect(125, 50, 40, 10, wxPDF_STYLE_DRAW);
    $self->Text(125, 49, 'Skew');
    $self->SetDrawColour(0);
    $self->SetTextColour(0);
    # Start Transformation
    $self->StartTransform();
    # skew 30 degrees along the x-axis centered by (125,60)
    # which is the lower left corner of the rectangle
    $self->SkewX(30, 125, 60);
    $self->Rect(125, 50, 40, 10, wxPDF_STYLE_DRAW);
    $self->Text(125, 49, 'Skew');
    # Stop Transformation
    $self->StopTransform();
    
    # Mirroring horizontally
    $self->SetDrawColour(200);
    $self->SetTextColour(200);
    $self->Rect(50, 80, 40, 10, wxPDF_STYLE_DRAW);
    $self->Text(50, 79, 'MirrorH');
    $self->SetDrawColour(0);
    $self->SetTextColour(0);
    # Start Transformation
    $self->StartTransform();
    # mirror horizontally with axis of reflection at x-position 50 (left side of the rectangle)
    $self->MirrorH(50);
    $self->Rect(50, 80, 40, 10, wxPDF_STYLE_DRAW);
    $self->Text(50, 79, 'MirrorH');
    # Stop Transformation
    $self->StopTransform();
    
    # Mirroring vertically
    $self->SetDrawColour(200);
    $self->SetTextColour(200);
    $self->Rect(125, 80, 40, 10, wxPDF_STYLE_DRAW);
    $self->Text(125, 79, 'MirrorV');
    $self->SetDrawColour(0);
    $self->SetTextColour(0);
    # Start Transformation
    $self->StartTransform();
    # mirror vertically with axis of reflection at y-position 90 (bottom side of the rectangle)
    $self->MirrorV(90);
    $self->Rect(125, 80, 40, 10, wxPDF_STYLE_DRAW);
    $self->Text(125, 79, 'MirrorV');
    # Stop Transformation
    $self->StopTransform();

    $self->SaveAsFile($filepath);
}

###################################################

package 
   Wx::DemoModules::wxPdfDocument::Transparency;

###################################################

#/**
#* Transparency
#* 
#* This example shows transparency effects and image masking.
#*/

use strict;
use warnings;
use Wx::PdfDocument;
use Wx qw( :pdfdocument :print );
use base qw( Wx::PlPdfDocument );

sub new {
    my $class = shift;
    my $self = $class->SUPER::new( @_ );
    return $self;
}

sub run_pdfdemo {
    my ($self, $filepath) = @_;
    
    $self->AddPage();
    $self->SetFont('Helvetica','',16);
    
    my $text;
    for (my $j = 0; $j < 180; $j++) { $text .= 'Hello World! '; }
    $self->MultiCell(0,8, $text);
    
    # A) provide image + separate 8-bit mask (best quality!)
    # first embed mask image (w, h, x and y will be ignored, the image will be scaled to the target image's size)
    my $maskImg = $self->ImageMask( Wx::Demo->get_data_file( qq(pdfdocument/mask.png) ) );
    
    # embed image, masked with previously embedded mask
    $self->Image(Wx::Demo->get_data_file( qq(pdfdocument/image.png) ),
                 55, 10, 100, 0, 'png',
                 Wx::PdfLink->new(-1), $maskImg);
    
    # B) use alpha channel from PNG
    $self->Image( Wx::Demo->get_data_file( qq(pdfdocument/image_with_alpha.png) ), 55, 190, 100);
    
    $self->AddPage();
    $self->SetLineWidth(1.5);
    
    # draw opaque red square
    $self->SetAlpha();
    $self->SetFillColour(Wx::PdfColour->new(255,0,0));
    $self->Rect(10, 10, 40, 40, wxPDF_STYLE_FILLDRAW);
    
    # set alpha to semi-transparency
    $self->SetAlpha(1, 0.5);
    
    # draw green square
    $self->SetFillColour(Wx::PdfColour->new(0,255,0));
    $self->Rect(20, 20, 40, 40, wxPDF_STYLE_FILLDRAW);
    
    # draw jpeg image
    $self->Image( Wx::Demo->get_data_file( qq(pdfdocument/lena.jpg) ), 30, 30, 40);
    
    # restore full opacity
    $self->SetAlpha();
    
    # print name
    $self->SetFont('Helvetica', '', 12);
    $self->Text(46,68,'Lena');    
    
    $self->SaveAsFile($filepath);
}

###################################################

package 
   Wx::DemoModules::wxPdfDocument::XMLWrite;

###################################################

#/**
#* XML write
#*
#* This example demonstrates the use of "rich text" cells,
#* i.e. cells containing a subset of HTML markup.
#*/

use strict;
use warnings;
use Wx::PdfDocument;
use Wx qw( :pdfdocument :print );
use base qw( Wx::PlPdfDocument );

sub new {
    my $class = shift;
    my $self = $class->SUPER::new( @_ );
    return $self;
}

sub run_pdfdemo {
    my ($self, $filepath) = @_;
    my $xmlString1 = <<'EOT1:'
<p align="justify">This example shows text <b>styling</b> with <i>simple</i> XML.H<sub>2</sub>SO<sub>4</sub> is an acid. Nesting of super or subscripting is possible: x<sup>i<sup>2</sup></sup> + y<sub>k<sub>3</sub></sub>. 
Now follows a <i>rather</i> long text, showing whether the justification algorithm <b>really</b> works. At least one <b>additional</b> line should be printed, further <b><font color="red">demonstrating</font></b> the algorithm.
<br/><u>Underlined <b>and </b> <s>striked through</s></u> or <o>overlined</o></p><img src="WXIMAGEPATH" width="160" height="120" align="center"/>
EOT1:
;
    my $imagefile = Wx::Demo->get_data_file( qq(pdfdocument/wxpdfdoc.png) );
    $imagefile =~ s/\\/\//g;
    $xmlString1 =~ s/WXIMAGEPATH/$imagefile/;

    my $xmlString2 = <<'EOT2:'
<h1>Header 1 (left)</h1><h2 align="right">Header 2 (right)</h2><h3 align="center">Header 3 (centered)</h3><h4 align="justify">Header 4 (justified)</h4><h5>Header 5</h5><h6>Header 6</h6>

EOT2:
;

    my $xmlString3 = <<'EOT3:'
Let's start an enumeration with roman numerals at offset 100:<ol type="i" start="100"><li>Anton</li><li>Berta</li><li>Caesar</li></ol>Who would be next?
<p align="right">This section should be right aligned.<br/>Do you want to go to the <a href="http://www.wxwidgets.org">wxWidgets website</a>?</p>

EOT3:
;

    my $xmlString4 = <<'EOT4:'
<h1>Nested tables example</h1><br/><table border="1"><colgroup><col width="40" span="4" /></colgroup><tbody><tr height="12"><td bgcolor="#cccccc">Cell 1,1</td><td colspan="2" align="center" valign="middle">Cell 1,2-1,3</td><td>Cell 1,4</td></tr><tr><td>Cell 2,1</td><td>Cell 2,2</td><td>Cell 2,3</td><td>Cell 2,4</td></tr><tr><td>Cell 3,1</td><td>Cell 3,2</td><td colspan="2" rowspan="2" align="center">
<table border="1"><colgroup><col width="19" span="4" /></colgroup><tbody odd="#cceeff" even="#ccffee"><tr><td bgcolor="#cccccc">Cell 1,1</td><td colspan="2">Cell 1,2-1,3</td><td>Cell 1,4</td></tr><tr><td>Cell 2,1</td><td>Cell 2,2</td><td>Cell 2,3</td><td>Cell 2,4</td></tr><tr><td>Cell 3,1</td><td>Cell 3,2</td><td colspan="2" rowspan="2">Cell 3,3-4.4</td></tr><tr><td>Cell 4,1</td><td>Cell 4,2</td></tr></tbody></table>
</td></tr><tr><td>Cell 4,1</td><td>Cell 4,2</td></tr></tbody></table>
                        
EOT4:
;
    my $xmlString5 = <<'EOT5:'
<h1>Table with row and column spans</h1><br/><table border="1" align="center">\n
<colgroup><col width="50"/><col width="20"/><col width="30"/><col width="20" span="3" /></colgroup>\n
<tbody><tr><td rowspan="2" valign="middle" border="0">rowspan=2, valign=middle</td><td>Normal</td><td>Normal</td><td>Normal</td><td colspan="2" rowspan="2" valign="bottom" bgcolor="#FF00FF">colspan=2<br/>rowspan=2<br/>valign=bottom</td></tr>\n
<tr><td height="15">Normal</td><td rowspan="2" align="right" bgcolor="#aaaaaa" border="0">rowspan=2</td><td border="0">border=0</td></tr>\n
<tr><td>Normal</td><td>Normal</td><td>Normal</td><td rowspan="3" valign="top" bgcolor="#CC3366">rowspan=3</td><td>Normal</td></tr>\n
<tr bgcolor="#cccccc"><td>Normal</td><td colspan="3" align="center">align center, colspan=3</td><td>Normal</td></tr>\n
<tr height="20"><td align="right" valign="bottom">align=right<br/>valign=bottom</td><td>Normal</td><td>&#160;</td><td>Normal</td><td>height=20</td></tr>\n
</tbody></table>

EOT5:
;
    my $xmlString6 = <<'EOT6:'
<h1>Table with more rows than fit on a page</h1><br/><table border="1"><colgroup><col width="20"/></colgroup>
<thead><tr bgcolor="#999999"><td><b>Headline</b></td></tr></thead>
<tbody odd="#ffffff" even="#dddddd">
<tr><td>This is a table cell with some text. This is a table cell with some text. This is a table cell with some text.</td></tr>
<tr><td>This is a table cell with some text. This is a table cell with some text. This is a table cell with some text.</td></tr>
<tr><td>This is a table cell with some text. This is a table cell with some text. This is a table cell with some text.</td></tr>
<tr><td>This is a table cell with some text. This is a table cell with some text. This is a table cell with some text.</td></tr>
<tr><td>This is a table cell with some text. This is a table cell with some text. This is a table cell with some text.</td></tr>
<tr><td>This is a table cell with some text. This is a table cell with some text. This is a table cell with some text.</td></tr>
<tr><td>This is a table cell with some text. This is a table cell with some text. This is a table cell with some text.</td></tr>
<tr><td>This is a table cell with some text. This is a table cell with some text. This is a table cell with some text.</td></tr>
<tr><td>This is a table cell with some text. This is a table cell with some text. This is a table cell with some text.</td></tr>
</tbody></table>

EOT6:
;

    my $xmlString7 = <<'EOT7:'
<table border="1"><tbody><tr bgcolor="#ffff00"><td><font face="Courier">
This is a very simple table with text in font face Courier.
<code>    // 4 leading spaces\n    <b>if</b> (condition)\n      x++;\n    <b>else</b>&#160;\n      x--;</code>
<br/></font></td></tr></tbody></table>
<code>    // 4 leading spaces\n    <b>if</b> (condition)\n      x++;\n    <b>else</b>&#160;\n      x--;</code>

EOT7:
;

    $self->AddPage();
    $self->SetFont('Helvetica','',10);
    $self->SetRightMargin(50);
    $self->WriteXml('<a name="top">Top of first page</a><br/>');
    $self->WriteXml('<a href="#bottom">Jump to bottom of last page</a><br/>');
    $self->WriteXml($xmlString1);
    $self->Ln();
    $self->WriteXml('<a name="second">Second anchor</a><br/>');
    $self->WriteXml($xmlString2);
    $self->WriteXml('<a name="third">Third anchor</a><br/>');
    $self->WriteXml($xmlString3);
    $self->AddPage();
    $self->SetLeftMargin(20);
    $self->SetRightMargin(20);
    $self->SetFont('Helvetica','',10);
    $self->WriteXml('<a name="fourth">Fourth anchor</a><br/>');
    $self->WriteXml($xmlString4);
    $self->Ln(20);
    $self->WriteXml($xmlString5);
    $self->Ln(20);
    $self->WriteXml($xmlString6);
    $self->AddPage();
    $self->WriteXml($xmlString7);
    $self->WriteXml('<a name="bottom">Bottom anchor</a><br/>');
    $self->WriteXml('<a href="#top">Jump to top of first page</a><br/>');
    $self->WriteXml('<a href="#second">Jump to second anchor</a><br/>');
    $self->WriteXml('<a href="#third">Jump to third anchor</a><br/>');

    $self->SaveAsFile($filepath);
}


1;
