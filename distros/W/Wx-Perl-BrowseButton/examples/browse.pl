#!/usr/bin/perl

use Wx;

package MyFrame;

use strict;
use Wx qw(:sizer);
use Wx::Perl::BrowseButton qw(:everything);

our @ISA = qw(Wx::Frame);

sub new {
    my( $class ) = shift;
    my( $self ) = $class->SUPER::new( undef, -1, $_[0] );

    $self->SetIcon( Wx::GetWxPerlIcon() );

    my $panel = Wx::Panel->new( $self );
    my $browsef = Wx::Perl::BrowseButton->new( $panel, -1, '', [ -1, -1 ],
                                               [ -1, -1 ], wxPL_BROWSE_FILE );
    my $browsed = Wx::Perl::BrowseButton->new( $panel, -1, '', [ -1, -1 ],
                                               [ -1, -1 ], wxPL_BROWSE_DIR );
    my $text = Wx::StaticText->new( $panel, -1, '' );

    my $top = Wx::BoxSizer->new( wxVERTICAL );
    $top->Add( $browsef, 0, wxGROW|wxALL, 5 );
    $top->Add( $browsed, 0, wxGROW|wxALL, 5 );
    $top->Add( $text, 0, wxGROW|wxALL, 5 );

    $panel->SetSizer( $top );

    my $evth = sub {
        $text->SetLabel( $_[1]->GetPath );
    };

    Wx::Event::EVT_COMMAND( $self, -1, -1, $evth );
    EVT_PL_BROWSE_PATH_CHANGED( $self, $browsef, $evth );
    EVT_PL_BROWSE_PATH_CHANGED( $self, $browsed, $evth );

    return $self;
}

package main;

Wx::App->new( sub {
    MyFrame->new( "Wx::Perl::BrowseButton example" )->Show( 1 );

    return 1;
} )->MainLoop;
