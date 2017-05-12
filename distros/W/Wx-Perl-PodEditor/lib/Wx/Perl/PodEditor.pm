package Wx::Perl::PodEditor;

use strict;
use warnings;

use Data::Dumper;
use File::Basename;
use File::Spec;

use Wx qw( 
    wxVERTICAL wxTOP wxHORIZONTAL 
    wxBITMAP_TYPE_XPM 
    wxNO_BORDER 
    wxDEFAULT 
    wxNORMAL
    wxRE_MULTILINE wxRICHTEXT_TYPE_XML
);

use Wx::Event qw( :everything );
use Wx::RichText;

use Wx::Perl::PodEditor::FormatActions qw(:all);
use Wx::Perl::PodEditor::PodParser;
use Wx::Perl::PodEditor::XMLParser;

Wx::Perl::PodEditor::FormatActions->define_styles;

our $AUTOLOAD;

our $VERSION = 0.03;

sub create {
    my ($class, $parent, $size) = @_;
    
    my $panel = Wx::Panel->new( $parent, -1, [-1,-1], [-1,-1], 0 );
    
    my $self  = bless {}, $class;
    my $sizer = $self->sizer();
    
    my $editor  = $self->_editor( $panel, $size );
    $sizer->Add( $editor, 0, wxTOP, 0 );
    
    return $self;
}

sub sizer {
    my ($self) = @_;
    
    unless( $self->{sizer} ){
        $self->{sizer} = Wx::BoxSizer->new( wxVERTICAL );
    }

    $self->{sizer};
}

sub _editor {
    my ($self,$panel,$size) = @_;
    
    if( @_ == 3 ){
        $self->{editor} = Wx::RichTextCtrl->new( $panel, -1, '',[-1,-1], $size, wxRE_MULTILINE );
        my $font = Wx::Font->new( 10, wxDEFAULT, wxNORMAL, wxNORMAL, 0, 'Courier New' );
        
        EVT_KEY_DOWN( $self->{editor}, sub{ $self->_handle_key_down(@_) } );
    }

    $self->{editor};
}

sub _handle_key_down {
    my ($self,$editor,$event) = @_;
    
    my $mod  = $event->GetModifiers || 0;
    my $code = $event->GetKeyCode;
    
    if( $code == 13 ){ # handle return
        $event->Skip;
        if( $self->_is_headline ){
            $editor->Newline;
            $self->default;
            $self->_is_headline( 0 );
        }
    }
    else{
        $event->Skip;
    }
}

sub set_pod {
    my ($self,$pod) = @_;
    
    if( @_ == 2 ){
        $self->{pod}  = $pod;
        $self->{text} = $self->_pod2text;
    }
}

sub _is_headline {
    my ($self,$bool) = @_;
    
    $self->{is_headline} = $bool if @_ == 2;
    $self->{is_headline};
}

sub get_pod {
    my ($self) = @_;
    
    $self->_text2pod;
}

sub _pod2text {
    my ($self) = @_;
    
    my $pod = $self->{pod};
    my $parser = Wx::Perl::PodEditor::PodParser->new( $self->_editor );
    $parser->parse_string_document( $pod );
}

sub _text2pod {
    my ($self) = @_;
    
    my $buffer = $self->_editor->GetBuffer;
    my $file_handler = Wx::RichTextXMLHandler->new( '', '', wxRICHTEXT_TYPE_XML );
    $buffer->AddHandler( $file_handler );
    
    open my $fh, '>', \my $xml;
    $file_handler->SaveFile( $buffer, $fh );
    
    warn $xml;
    my $parser = Wx::Perl::PodEditor::XMLParser->new;
    $parser->parse( $xml );
}

sub AUTOLOAD {
    my ($self) = shift;
    my $name = $AUTOLOAD;
    
    $name =~ s/.*:://;
    
    return if $name eq 'DESTROY';
    
    my $editor = $self->_editor;
    if( my $sub = $editor->can( $name ) ){
        $sub->( $editor, @_ )
    }
    else{
        my @info    = caller(0);
        my $package = __PACKAGE__;
        my $msg     = qq~Can't locate object method "$name" via package "$package" at $info[1] line $info[2]~;
        print STDERR $msg;
        exit;
    }
}

1;
__END__

=head1 NAME

Wx::Perl::PodEditor - A RichText Ctrl for creating Pod

=head1 SYNOPSIS

Perhaps a little code snippet.

    use Wx::Perl::PodEditor;
    
    my $main_sizer = Wx::BoxSizer->new( wxVERTICAL );
    my $foo        = Wx::Perl::PodEditor->create( $self, [500,220] );
    $main_sizer->Add( $editor->sizer, 0, wxTOP, 0 );
    ...

=head1 METHODS

=head2 create

=head2 get_pod

C<get_pod> returns the Pod. It converts the richtext to pod.

  my $pod = $podeditor->get_pod;

=head2 set_pod

With C<set_pod> you can (re)set the documentation text in the RichTextCtrl.
It requires a string with Pod text in it.

  $podeditor->set_pod( '=head1 Test\n\nThis is a simple test' );

=head2 sizer

returns the C<Wx::Sizer> with the RichTextCtrl.

  my $sizer = $podeditor->sizer;
  $main_sizer->Add( $sizer, 0, wxTOP, 0 );

=head1 AUTHOR

Renee Baecker, C<< <module at renee-baecker.de> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-wx-perl-podeditor at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Wx::Perl::PodEditor>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Wx::Perl::PodEditor

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Wx::Perl::PodEditor>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Wx::Perl::PodEditor>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Wx::Perl::PodEditor>

=item * Search CPAN

L<http://search.cpan.org/dist/Wx::Perl::PodEditor>

=back

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2008 Renee Baecker, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
