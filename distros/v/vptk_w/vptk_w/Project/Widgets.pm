package vptk_w::Project::Widgets;

use strict;
use base qw(vptk_w::Project);
use vars qw/@user_auto_vars/;

sub new {
  my $class = shift;
  my $this  = vptk_w::Project->new(@_);
  $this->{tree}=[]; # a list of widgets with their paths
  bless $this => $class;
}

sub init {
  my $this = shift;
  $this->{tree}=[];
  $this->{list}=[];
  $this->{data}={};
}

# this function to be revised and extended
# with "insert after" functionality
sub add {
  my $this = shift;
  my ($path,$name,$object) = @_;

  $this->push($name,$object);
  push(@{$this->{tree}},"$path.$name");
}

sub print {
  my $this = shift;
  my $parent = shift;
  my @result;
  my $user_code_before_main;
  my $wballoon='';

  my $strict = ($parent->get('Options')->get('strict'))?'my ':'';
  # Define:
  # - user code before widgets
  # - main window definition
  # - valiables definition
  # - widgets definitions
  # - user code before main loop
  # - call 'MainLoop'
  if ($parent->get('Options')->get('fullcode'))
  {
    push(@result, "${strict}\$mw=MainWindow->new(-title=>\"".
        $parent->get('Options')->get('title')."\");");

    my $user_code_before_widgets = $parent->get('Code')->get('code before widgets');
    if(@$user_code_before_widgets) {
      push(@result, @$user_code_before_widgets);
    }
  }  
  push(@result, "#===vptk widgets definition===< DO NOT WRITE UNDER THIS LINE >===");
  @user_auto_vars=();
  foreach my $element($this->elements)
  {
    my $balloon_color=$parent->get('Options')->get('balloon_color') || 'lightyellow';
    my $balloon_delay=$parent->get('Options')->get('balloon_delay') || 550;
    my ($user_var)=($element->{'opt'}=~/variable[^\$]+\\\$(\w+)/);
    push(@user_auto_vars,$user_var) 
      if $user_var && ! grep($_ eq $user_var,@user_auto_vars);
    $wballoon = "use Tk::Balloon;\n${strict}\$vptk_balloon=\$mw->Balloon(-background=>\"$balloon_color\",-initwait=>$balloon_delay);"
  }

  push(@result,$wballoon) if $wballoon;
  push(@result, "use vars qw/\$".join(' $',@user_auto_vars)."/;\n") if @user_auto_vars;
  push(@result, &::code_print());
  push(@result, "");
  push(@result, map("\$$_",@{$parent->get('Options')->get('bindings')}));
  if($parent->get('Options')->get('fullcode')) {
    $user_code_before_main = $parent->get('Code')->get('code before main');
    if(@$user_code_before_main) {
      push(@result, "#===vptk user code before main===< THE CODE BELOW WILL RUN BEFORE GUI STARTED >===");
      push(@result, @$user_code_before_main);
    }
    push(@result, "MainLoop;\n" );
  }
  return @result;
}

1;#)
