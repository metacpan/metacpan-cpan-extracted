# Backwards-compatibility and speed stub for Text::Query

package Text::Query::Simple;

use strict;
use vars qw(@ISA $VERSION);
$VERSION = '0.09';
use Text::Query;
@ISA=qw(Text::Query);

#use base qw(Text::Query);

sub new {
  my $class=shift;
  $class->SUPER::new (@_,-mode => 'simple_text');
}

sub match {
  my($self) = shift;
  return $self->matchscalar(shift || $_) if(@_ <= 1 && ref($_[0]) ne 'ARRAY');
  my($pa) = (@_ == 1 && ref($_[0]) eq 'ARRAY') ? shift : \@_;

  my(@ra);
  if(ref($pa->[0]) eq 'ARRAY') {
    @ra = map { [ @$_, $self->matchscalar($_->[0]) ] } @$pa;
  } else {
    @ra = map { [ $_, $self->matchscalar($_) ] } @$pa;
  }
  @ra = sort { $b->[$#{@$b}] <=> $a->[$#{@$a}] } @ra;
  return wantarray ? @ra : \@ra;
}

sub matchscalar {
  my($self) = shift;
  my($expr) = $self->{matchexp};

  my($target) = (shift || $_);
  my($cnt) = 0;
  my($re, $ws) = @$expr;

  while($target =~ /$re/g) {
    return 0 if(!$^R->[0]);
    $cnt += $^R->[1];
    $ws &= $^R->[0];
  }
  
  return $ws ? 0 : $cnt;
}

1;
