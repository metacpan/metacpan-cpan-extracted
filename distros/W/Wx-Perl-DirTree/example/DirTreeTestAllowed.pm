package DirTreeTestAllowed;

use strict;
use warnings;

use FindBin ();
use lib $FindBin::Bin . '/../lib';
use Wx::Perl::DirTree qw(:const);

use Wx qw( wxVERTICAL wxTOP );

our @ISA = qw(Wx::Frame);

our $VERSION = 0.01;

sub new {
    my( $class ) = shift;
    
    my( $this ) = $class->SUPER::new( @_ );
    
    $this->CreateStatusBar(1);
    $this->SetStatusText("Welcome!", 0);
    
    my $panel = Wx::Panel->new( $this, -1 );
    my $tree  = Wx::Perl::DirTree->new( 
        $panel, 
        [488,220], 
        { 
            dir => '.', 
            allowed => wxPDT_DIR | wxPDT_FILE,
        },
    );
    
    my $main_sizer   = Wx::BoxSizer->new( wxVERTICAL );
    $main_sizer->Add( $tree->GetTree,  0, wxTOP, 0 );
    
    $panel->SetSizer( $main_sizer );
    $panel->SetAutoLayout(1);
    
    $this;
}

1;