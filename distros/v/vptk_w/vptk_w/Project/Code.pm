package vptk_w::Project::Code;

use strict;
use base qw(vptk_w::Project);

sub new {
  my $class = shift;
  my $this  = vptk_w::Project->new(@_);
  bless $this => $class;
}

sub print {
  my $this = shift;
  my $parent = shift;
  my @result;

  return () unless scalar(@{$this->get('user code')});
  return () unless $parent->get('Options')->get('fullcode');
#  push(@result, "#===vptk end===< DO NOT CODE ABOVE THIS LINE >===\n\n");
  push(@result, @{$this->get('user code')});
  return @result;
}

1;#)
