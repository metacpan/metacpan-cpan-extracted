package UMMF::Core::Diff;

use 5.6.1;
use strict;
#use warnings;

our $AUTHOR = q{ kstephens@users.sourceforge.net 2006/05/11 };
our $VERSION = do { my @r = (q$Revision: 1.22 $ =~ /\d+/g); sprintf "%d." . "%03d" x $#r, @r };

=head1 NAME

UMMF::Core::Diff - Diffs to Objects

=head1 SYNOPSIS

  use UMMF::Core::Diff;
  UMMF::Core::Diff->new->diff($model1, $model2);

=head1 DESCRIPTION


=head1 USAGE

=head1 EXPORT

None exported.

=head1 AUTHOR

Kurt Stephens, kstephens@users.sourceforge.net 2003/04/14

=head1 SEE ALSO

L<UMMF::Core::MetaModel|UMMF::Core::MetaModel>.

=head1 VERSION

$Revision: 1.22 $

=head1 METHODS

=cut


#######################################################################

use base qw(UMMF::Core::Object);

#######################################################################

use UMMF::Core::Util qw(:all);

use Carp qw(confess);

#######################################################################

sub initialize
{
  my ($self) = @_;

  $self->SUPER::initialize;

  $self->{'action'} ||= [ ];
  $self->{'stop_on_first_diff'} = 0;

  $self;
}


sub diff
{
  my ($self, $obj1, $obj2) = @_;

  $self->{'visited'} = { };
  $self->{'obj1obj2'} = { };
  $self->{'obj2obj1'} = { };

  eval {
    $self->diff_1($obj1, $obj2, '');
  };
  my $exc = $@;

  $self->{'visited'} = { };
  $self->{'obj1obj2'} = { };
  $self->{'obj2obj1'} = { };

  die $exc if $exc && $exc !~ /UMMF::Core::Diff::STOP/;

  $self->{'action'};
}


sub add_diff
{
  my ($self, @opts) = @_;

  push(@{$self->{'action'}}, \@opts);

  die 'UMMF::Core::DiFF::STOP' if $self->{'stop_on_first_diff'};
}


sub diff_1
{
  my ($self, $obj1, $obj2, $path) = @_;
  
  my $ref1 = ref($obj1);
  my $ref2 = ref($obj2);
  
  if ( ! ($ref1 || $ref2) ) {
    $self->add_diff('diff', 'value', $path, $obj1, $obj2) unless $obj1 eq $obj2;
    return;
  } elsif ( $ref1 ne $ref2 ) {
    $self->add_diff('diff', 'ref', $path, $ref1, $ref2) unless $ref1 eq $ref2;
  } elsif ( $self->{'visted'}{$obj1, $obj1} ) {
    return;
  } elsif ( $obj1 eq $obj2 ) {
    return;
  } else {
    $self->{'visited'}{$obj1, $obj2} = 1;

    $self->{'obj1obj2'}{$obj1} = $obj2;
    $self->{'obj2obj1'}{$obj2} = $obj1;
    if ( $ref1 eq 'ARRAY' ) {
      my $i = -1;
      for my $sub1 ( @$obj1 ) {
	++ $i;
	my $p = "${path}[$i]";
	if ( $i >= @$obj2 ) {
	  $self->add_diff('delete', 'ARRAY', $p, $obj1->[$i]);
	} else {
	  my $sub2 = $obj2->[$i];
	  $self->diff_1($sub1, $sub2, $p);
	}
      }
      $i = @$obj1;
      while ( $i < @$obj2 ) {
	my $p = "${path}[$i]";
	$self->add_diff('add', 'ARRAY', $p, $obj2->[$i]);
	++ $i;
      }
    } elsif ( $ref1 eq 'HASH' ) {
      for my $key1 ( keys %$obj1 ) {
	my $p = "${path}{$key1}"; 
	unless ( exists $obj2->{$key1} ) {
	  $self->add_diff('delete', 'HASH', $p, $obj1->{$key1});
	} else {
	  my $sub1 = $obj1->{$key1};
	  my $sub2 = $obj2->{$key1};
	  $self->diff_1($sub1, $sub2, $p);
	}
      }
      for my $key2 ( keys %$obj2 ) {
	my $p = "${path}{$key2}"; 
	unless ( exists $obj1->{$key2} ) {
	  $self->add_diff('add', 'HASH', $p, $obj2->{$key2});
	} else {
	  my $sub1 = $obj1->{$key2};
	  my $sub2 = $obj2->{$key2};
	  $self->diff_1($sub1, $sub2, $p);
	}
      }
    } elsif ( $ref1 eq 'Set::Object' ) {
      push @{$self->{'Set::Object'}}, [ $obj1, $obj2 ]
    }
  }

  if ( $ref1 ) {
    if ( $obj1 =~ /=ARRAY/ ) {
      $obj1 = [ @$obj1 ];
      $obj2 = [ @$obj2 ];
      $self->diff_1($obj1, $obj2);
    }
    elsif ( $obj1 =~ /=HASH/ ) {
      $obj1 = { %$obj1 };
      delete $obj1->{grep(! /^[.]/, keys %$obj1)};
      $obj2 = { %$obj2 };
      delete $obj1->{grep(! /^[.]/, keys %$obj2)};
      $self->diff_2($obj1, $obj2);
    }
  }

  $self;
}


sub TEST
{
  my ($self) = @_;
  $self ||= __PACKAGE__;

  assert_equal($self->new->diff(1, 1), []);
  assert_equal($self->new->diff(1, 2), [ [ 'diff', 'value', '', 1, 2 ] ]);

  assert_equal($self->new->diff([ 1 ], [ 1 ]), [ ]);

  assert_equal($self->new->diff([ 1 ], [ 2 ]), [ [ 'diff', 'value', '[0]', 1, 2 ] ]);

  assert_equal($self->new->diff([ 1 ], [ 1, 2 ]), [ [ 'add', 'ARRAY', '[1]', 2 ] ]);

  assert_equal($self->new->diff([ 1, 2 ], [ 1 ]), [ [ 'delete', 'ARRAY', '[1]', 2 ] ]);
}


sub assert_equal
{
  my ($a, $b) = @_;

  use Data::Dumper;

  $a = Data::Dumper->new([ $a ], [qw($x)])->Dump;
  $b = Data::Dumper->new([ $b ], [qw($x)])->Dump;
  die "assert_equal $a $b " unless $a eq $b;
}

#######################################################################


1;

#######################################################################


### Keep these comments at end of file: kstephens@users.sourceforge.net 2003/04/06 ###
### Local Variables: ###
### mode:perl ###
### perl-indent-level:2 ###
### perl-continued-statement-offset:0 ###
### perl-brace-offset:0 ###
### perl-label-offset:0 ###
### End: ###

