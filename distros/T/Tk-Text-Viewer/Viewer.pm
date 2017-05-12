# Author: Oded S. Resnik           Email: razinf@cpan.org
#  Copyright (c) 2003-2004 RAZ Information Systems LTD. http://www.raz.co.il
#
#You may distribute under the terms of either the GNU General Public
#License or the Artistic License, as specified in the Perl README file
#
package Tk::Text::Viewer;

use vars qw($VERSION);
$VERSION = '0.95';
$ENV{LANG} = 'C' unless $ENV{LANG};
use Tk::Text;
use base  qw(Tk::Text);
Construct Tk::Widget 'Viewer';

#default enrty lable options
my $rh_entry_label = {-text=>'Find:', Name=>'entry_label', -cursor=> 'arrow'};
my $rh_entry = {-width=>25, -relief=>'sunken', -borderwidth=>3};
                

sub LabelConfig {
#Allow client to change serach label options
 my ($w, $config)  = @_;
 $w->ConfigDo($config,$rh_entry_label);
	};

sub EntryConfig {
#Allow client to change serach enrty options
 my ($w, $config)  = @_;
 $w->ConfigDo($config,$rh_entry);
        };

sub ConfigDo {
#Genegric Wigdet config
my ($w, $config, $rh_wiget_def) = @_;
 if (ref($config) eq '') {
	if ($config =~ /=>/) {
		my ($key,$value) = split ('=>',$config);
		$key =~ s/\s//g;	
		$value =~ s/\'|\"//g;
		$$rh_wiget_def{"$key"} = $value if $key;
		}
	else {
 		$$rh_wiget_def{"text"} = $config if $config;
		};
	};
 if (ref($config) eq 'HASH') {
	foreach my $key (keys %$config)
		{
		$key =~ s/\s//g;
		$$config{$key} =~ s/\'|\"//g;
		$$rh_wiget_def{$key} = $$config{$key};
		};
	}
}

#Fix context menu
sub clipEvents
{
 return qw[Copy];
}

sub SearchMenuItems
{# Remoove the Replace option
 my ($w) = @_;
 my $rOptions = $w->SUPER::SearchMenuItems(@_);
 my $rNewOptions = undef;
 for ( 0 .. $#$rOptions) {
     next if $$rOptions[$_][1] =~ /replace/i;
    push (@$rNewOptions, $$rOptions[$_]);
    };
return $rNewOptions;
}

sub ClassInit
{
 my ($class,$mw) = @_;
 my $cb  = $mw->bind($class,'<Next>');
 $class->bindRdOnly($mw);
 $mw->bind($class,'<space>',$cb) if (defined $cb);
 $cb  = $mw->bind($class,'<Prior>');
 $mw->bind($class,'<BackSpace>',$cb) if (defined $cb);
 $class->clipboardOperations($mw,'Copy');
 $mw->bind($class,'<Key-slash>',FindSimplePopUp);
 $mw->bind($class,'<Key-n>', FindSelectionNext);
 $mw->bind($class,'<Key-N>', FindSelectionPrevious);
 $mw->bind($class,'<Control-a>', FindAll );
 return $class;
 }


sub Tk::Widget::ScrlViewer { shift->Scrolled('Viewer' => @_) }

sub GetSelPattern {
# As we want to be able to to "Next" afer FindAll we
# can't always use selection so we use tags
 my $w=shift;
 my @ranges = $w->tagRanges('sel'); #Get tag index
 my ($start_index, $end_index) = @ranges;
 my $range_pattern = $w->get($start_index, $end_index) if @ranges;
 my $select_patern; #Selection
 eval { $select_patern = $w->SelectionGet(-selection => "PRIMARY"); };
 if ($range_pattern) {
	return $range_pattern if ($range_pattern eq $select_patern); 
	return $select_pattern 
			if ($select_pattern && @ranges> 1 
				&& $select_pattern !~ /$range_patten/i); 
        $w->unselectAll;	
	$w->tagAdd('sel', $start_index, $end_index);
	return $range_pattern;
 	}
 return $select_pattern;
}

sub FindSimplePopUp {
 my $w=shift;
 my $pattern = $w->GetSelPattern();
 foreach  ($w->children) { #Not allowing open when active
    if ($_->name eq 'entry_label' ) { 
                $w->bell;
        return;
            };
    };
 my $entry_label = $w-> Label(%$rh_entry_label);
 $entry_label-> pack(-anchor=>'sw', -side=>'left', -expand => 'no');
 my $find_entry = $w->Entry(%$rh_entry);
 if ($pattern) { #Defalut value for entry the previous value
 	$find_entry -> insert(0, $pattern);
 	$find_entry -> selectionRange(0, length ($pattern)); 
	}
 $find_entry -> bind( '<Any-KeyPress>' => \&KeyCheck);
 $find_entry -> pack (-anchor=>'se', -expand => 'yes' , -fill => 'x',
	-side=>'right');
 $find_entry -> focus();
 return;
}

sub FindAll {
my ($w,$mode, $case, $pattern ) = @_;
$mode = '-exact' unless $mode;
$case = '-nocase' unless $case;
if (!$pattern) {
		$pattern = $w->GetSelPattern();
		}
return $w->SUPER::FindAll($mode, $case, $pattern);
}

sub FindSelectionNext {
my $w = shift;
$w->FindNext('-forward', '-exact', '-case',$w->GetSelPattern());
}

sub FindSelectionPrevious {
my $w = shift;
$w->FindNext('-backward', '-exact', '-case',$w->GetSelPattern());
}

sub FindSimpleDo
{
 my $w = shift;
 my $parent = $w->parent;
 $parent->FindNext ('-forward','-exact','-nocase',$w->get());
 $parent->focus();
 foreach  ($parent->children) { 
		$_->destroy() if ($_->name eq 'entry_label' );
            };
$w->destroy();
}

sub KeyCheck
{
my $class = shift;
my $Key = $class->XEvent->K;
FindSimpleDo($class) if ($Key =~ /Return|Tab/);
return 1;
}

sub Load
# Load copied from TextUndo
# Unicode support added for UTF-8 locale
{
 my ($text,$file) = @_;
 my $fmode  = ($ENV{LANG} =~ /\.UTF-8/) && $]> 5.007 ? "<:utf8" : "<";
 if (open(FILE,$fmode, $file))
  {
   $text->MainWindow->Busy;
   $text->delete('1.0','end');
   while (<FILE>)
    {
     $text->insert('end',$_);
    }
   close(FILE);
   $text->markSet('insert', '@1,0');
   $text->MainWindow->Unbusy;
  }
 else
  {
   $text->messageBox(-message => "Cannot open $file: $!\n");
   die;
  }
return 1;
}
1;
