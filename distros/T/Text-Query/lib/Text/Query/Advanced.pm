# Backwards-compatibility and speed stub for Text::Query

package Text::Query::Advanced;

use strict;
use vars qw(@ISA $VERSION);
$VERSION = '0.09';
use Text::Query;
@ISA=qw(Text::Query);

#use base 'Text::Query';

sub new {
  my $class=shift;
  $class->SUPER::new (@_,-mode => 'advanced_text');
}

sub match {
    my($self) = shift;
    my($expr) = $self->{matchexp};

    return $expr->(shift || $_) if(@_ <= 1 && ref($_[0]) ne 'ARRAY');

    my($pa) = (@_ == 1 && ref($_[0]) eq 'ARRAY') ? shift : \@_;

    my(@ra);
    if(ref($pa->[0]) eq 'ARRAY') {
	@ra = grep { $expr->($_[0]) } @$pa;
    } else {
	@ra = grep { $expr->($_) } @$pa;
    }
    return wantarray ? @ra : \@ra;
}

sub matchscalar {
    my($self) = shift;

    return $self->{matchexp}->(shift || $_);
}

1;
