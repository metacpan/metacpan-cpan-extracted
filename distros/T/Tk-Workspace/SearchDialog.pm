package Tk::SearchDialog;
my $RCSRevKey = '$Revision: 0.43 $';
$RCSRevKey =~ /Revision: (.*?) /;
$VERSION=$1;
use vars qw( $VERSION );

=head1 NAME

  SearchDialog.pm--Search Dialog Widget for Perl/Tk Text.

=head1 SYNOPSIS

  use Tk::SearchDialog;

  my $dialog = $mw -> SearchDialog;
  my @searchoptions = $dialog -> Show;

=head1 DESCRIPTION

The Tk::SearchDialog widget opens a dialog window that allows
entry of search and/or replacement text, and the selection
of search options.

The SearchDialog returns a list of ($option, $value) pairs (see below)
when the user clicks the "Search!" button, and undef if the user
clicks the "Cancel" button.

=head1 SEARCH OPTIONS

The SearchDialog returns a list with the following search
specifications.  All specifications are string scalar values.  The
'-option*' options are set to '1' when selected, and '0' or undef if
not selected. Labels and titles are read-only.

=head2 -searchstring 

=head2 -replacestring

=head2 -optioncase 

=head2 -optionregex

=head2 -optionbackward

=head2 -optionquery

=head2 -entrylabel

=head2 -replacelabel

=head2 -optiontitle

=head2 -optcaselabel

=head2 -optregexlabel

=head2 -optbackwardlabel

=head2 -optquerylabel

=head2 -searchlabel

=head2 -cancellable 

=head2 -accept

=head1 BUGS

Allow all option defaults to be set by the calling module.  Should
have some entry validation.

=head1 VERSION INFORMATION

$Id: SearchDialog.pm,v 0.43 2002/08/22 16:34:50 kiesling Exp $

Author: Robert Allan Kiesling <rkiesling@earthlink.net>

=cut 


use Tk qw(Ev);
use Carp;
use Tk::widgets qw( LabEntry Button Frame Listbox Scrollbar );
use base qw(Tk::Toplevel);

Construct Tk::Widget 'SearchDialog';

my $defaultfont="*-helvetica-medium-r-*-*-12-*";

sub Cancel {
  shift -> withdraw;
  return undef;
}

sub Accept {
  my ($w, $args) = @_;
  $w -> {'Configure'}{'-accept'} = '1';
}

sub Populate {
  my ($w, $args) = @_;
  require Tk::Label;
  require Tk::Entry;
  require Tk::Frame;
  require Tk::Checkbutton;

  $w -> SUPER::Populate( $args );

  $w -> ConfigSpecs(-searchstring => ['PASSIVE', undef, undef, ''],
		    -replacestring => ['PASSIVE', undef, undef, ''],
		    -optioncase => ['PASSIVE', undef, undef, ''],
		    -optionregex => ['PASSIVE', undef, undef, ''],
		    -optionbackward => ['PASSIVE', undef, undef, ''],
		    -optionquery => ['PASSIVE', undef, undef, ''],
		    -entrylabel => ['PASSIVE', undef, undef,
				      "Search Pattern: "],
		     -replacelabel => ['PASSIVE', undef, undef,
				      "Replace String: "], 
		     -optiontitle  => ['PASSIVE', undef, undef,
				       "Search Options:" ],
		     -optcaselabel => ['PASSIVE', undef, undef,
				       "Case Sensitive" ], 
		     -optregexlabel => ['PASSIVE', undef, undef,
				       "Regular Expression" ],
		     -optbackwardlabel => ['PASSIVE', undef, undef,
				       "Search Backward" ],
		     -optquerylabel => ['PASSIVE', undef, undef,
				       "Replace without Asking" ],
		     -searchlabel => ['PASSIVE', undef, undef,
				       "Search!" ],
		     -cancellabel => ['PASSIVE', undef, undef,
				       "Cancel" ],
		     -accept => ['PASSIVE', undef, undef, undef ]
		   );

  my $f = $w -> Component( Frame => 'entryframe',
			    -container => 0, -relief => 'groove', 
			    -borderwidth => 3 );
  # search pattern
  my $s = $w->Component( Label => 'searchlabel',
			 -textvariable => \$w->{'Configure'}{'-entrylabel'},
			 -font => $defaultfont
		       );
  $s->grid( -in => $f, -column => 1, -row => 1, -padx => 5, -pady => 5 );
  my $searchpat = $w -> Component( Entry => 'searchstring',
				   -width => 30,
		 -textvariable => \$w -> {'Configure'}{'-searchstring'});
  $searchpat->grid(  -in => $f, -column => 2, -row => 1, -padx => 5, 
		     -pady => 5 );

  my $s1 = $w->Component( Label => 'replacelabel',
		 -textvariable => \$w -> {'Configure'}{'-replacelabel'},
		 -font => $defaultfont
	       );
  $s1->grid(  -in => $f, -column => 1, -row => 2, -padx => 5, -pady => 5 );
  my $replace = $w -> Component( Entry => 'replacestring',
				   -width => 30,
		 -textvariable => \$w -> {'Configure'}{'-replacestring'});
  $replace -> grid( -in => $f, -column => 2, -row => 2, -padx => 5, 
		    -pady => 5, -columnspan => 3 );
  $f -> grid( -in => $w, -row => 1, -columnspan => 5, -sticky => 'ew',
	    -ipady => 5 );

  my $s2 = $w -> Component( Label => 'optionsTitle',
		   -textvariable => \$w -> {'Configure'}{'-optiontitle'},
		   -font => $defaultfont );
  $s2 -> grid( -in => $w, -row => 3, -column => 1, -sticky => 'w',
	     -padx => 5, -pady => 5 );
  my $case = $w -> Component( Checkbutton => 'optcase',
	      -textvariable => \$w->{'Configure'}{'-optcaselabel'},
	      -font => $defaultfont,
  	  -variable => \$w -> {'Configure'}{'-optioncase'}  );
  $case -> grid( -in => $w, -row => 4, -column => 1, -sticky => 'w',
	       -padx => 5, -pady => 5 );  
  my $regex = $w -> Component( Checkbutton => 'optregex',
		      -textvariable => \$w -> {'Configure'}{'-optregexlabel'},
		      -font => $defaultfont,
  	  -variable => \$w -> {'Configure'}{'-optionregex'}  );
  $regex -> grid( -in => $w, -row => 5, -column => 1, -sticky => 'w',
		-padx => 2, -pady => 2 );  
  my $backward = $w -> Component( Checkbutton => 'optbackward',
	      -textvariable => \$w -> {'Configure'}{'-optbackwardlabel'},
			      -font => $defaultfont,
  	  -variable => \$w -> {'Configure'}{'-optionbackward'} );
  $backward -> grid( -in => $w, -row => 4, -column => 2, -sticky => 'w',
		   -padx => 2, -pady => 2 );  
  my $query = $w -> Component( Checkbutton => 'optquery',
	      -textvariable => \$w -> {'Configure'}{'-optquerylabel'},
		      -font => $defaultfont,
  	  -variable => \$w -> {'Configure'}{'-optionbackward'} );
  $query-> grid( -in => $w, -row => 5, -column => 2, -sticky => 'w',
	       -padx => 2, -pady => 2 );  
  my $s3 = $w -> Component( Label => 'blank',
			   -text => '',
			   -font => $defaultfont );
  $s3 -> grid( -in => $w, -row => 6, -column => 1 );

  my $f1 = $w -> Component( Frame => 'buttonframe',
			  -container => 0, -relief => 'groove', 
			  -borderwidth => 3 );
  my $ab = $f1 -> Component ( Button => 'searchacceptbutton',
		      -textvariable => \$w -> {'Configure'}{'-searchlabel'},
		      -font => $defaultfont,
		      -default => 'active',
		      -command => ['Accept', $w]) 
    -> grid( -in => $f1, -column => 2, -row => 1, -padx => 10, -pady => 5 );
  my $cb = $f1 -> Component ( Button => 'cancelbutton', 
		      -textvariable => \$w -> {'Configure'}{'-cancellabel'},
		      -font => $defaultfont,
		    -default => 'normal',
		    -command => ['Cancel', $w])
    -> grid( -in => $f1, -column => 4, -row => 1, -padx => 20, -pady => 2 );
  $f1 -> grid( -in => $w, -row => 7, -columnspan => 5, -sticky => 'ew' );

  return $w;
}

sub Show {
  my ($w, $args) = @_;
  $w -> waitVariable( \$w -> {'Configure'}{'-accept'} );
  $w -> withdraw;
  return %{$w -> {'Configure'}};
}

1;
__END__;
