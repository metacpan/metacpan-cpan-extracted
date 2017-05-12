package Wx::Perl::PodEditor::PodParser;

use strict;
use warnings;

use Data::Dumper;  # TODO: nach Fertigstellung entfernen

use Pod::Simple::Methody;

our @ISA = qw( Pod::Simple::Methody );
our $VERSION = 0.01;

my @overs;
my $current_ident = 0;

sub new {
    my $class  = shift;
    my $editor = shift;
    
    my $self = $class->SUPER::new( @_ );
    $self->editor( $editor );
    
    return $self;
}

sub editor {
    my ($self,$editor) = @_;
    
    $self->{editor} = $editor if @_ == 2;
    $self->{editor};
}

sub handle_text {
    my ($self,$text) = @_;
    my @parts  = split /\r?\n/, $text;
    my $editor = $self->editor;
    
    while( my $part = shift @parts ){
        $editor->AppendText( $part );
        $self->add_newline if @parts;
    }
}

sub start_item_number {
    my ($self) = @_;
    my $editor = $self->editor;
    $editor->BeginNumberedBullet(++$overs[-1]->[1], 100, 60);
}

sub start_item_text {
    my ($self) = @_;
    my $editor = $self->editor;
    $editor->BeginNumberedBullet(++$overs[-1]->[1], 100, 60);
}

sub start_item_bullet {
    my ($self) = @_;
    my $editor = $self->editor;
    $editor->BeginNumberedBullet(2,100, 60);
}

sub end_item_bullet {
    my ($self) = @_;
    $self->add_newline;
    $self->editor->EndNumberedBullet;
}

sub end_item_number {
    my ($self) = @_;
    $self->add_newline;
    $self->editor->EndNumberedBullet;
}

sub end_item_text {
    my ($self) = @_;
    $self->add_newline;
    $self->editor->EndNumberedBullet;
}

sub start_over_text {
    my ($self) = @_;
    my $ident = 2;
    $current_ident += $ident;
    $self->add_newline;
    push @overs, [$ident, 0];
}

sub start_over_number {
    my ($self) = @_;
    my $ident = 2;
    $current_ident += $ident;
    $self->add_newline;
    push @overs, [$ident, 0];
}

sub start_over_bullet {
    my ($self) = @_;
    my $ident = 2;
    $current_ident += $ident;
    $self->add_newline;
    push @overs, [$ident, 0];
}

sub end_over_bullet {
    my ($self) = @_;
    $self->add_newline;
}

sub end_over_number {
    my ($self) = @_;
    $self->add_newline;
}

sub add_newline {
    my ($self) = @_;
    
    my $editor = $self->editor;
    $editor->Newline;
}

sub start_Para {
    my ($self) = @_;
    $self->add_newline;
}

sub end_Para {
    my ($self) = @_;
    $self->add_newline;
}

sub start_head1 {
    my ($self,$text) = @_;
    #$self->editor->
}

sub end_head1 {
    my ($self) = @_;
    $self->add_newline;
}

sub start_B {
    my ($self,$text) = @_;
    
    $self->editor->BeginBold;
}

sub end_B {
    shift->editor->EndBold;
}

sub start_I {
    shift->editor->BeginItalic;
}

sub end_I {
    shift->editor->EndItalic;
}

sub start_F {
    
}

sub end_F {
    
}

sub start_L {
    
}

sub end_L {
    
}

sub start_Verbatim {}
sub end_Verbatim {}


'translating Pod to RichText is relatively easy';

=pod

=head1 NAME

Wx::Perl::PodEditor::PodParser - parse Pod and display it in the RichTextCtrl.

=head1 DESCRIPTION

The PodEditor aims to help the developer. Therefor the developer should be able
to save the documentation and edit it later. The documentation is saved as Pod, so
we have to parse the documentation to display it in the RichTextCtrl.

This module inherits from Pod::Simple::Methody and implements the most common
Pod directives.

=head1 SYNOPSIS

    my $parser = Wx::Perl::PodEditor::PodParser->new( $wx_richtextctrl );
    $parser->parse_string_document( $documentation );

=head1 AUTHOR

Renee Baecker, E<lt>module@renee-baecker.deE<gt>

=cut