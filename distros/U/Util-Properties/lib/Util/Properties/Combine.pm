package Util::Properties::Combine;

#use warnings;
use strict;
use Carp qw(croak carp confess cluck);

=head1 NAME

Util::Properties::Combine - Util::Properties descendant, with summing & comparison methods

=head1 DESCRIPTION

The idea is to have Util::Properties objects with summing (all the field are summed or substracted) and comparison (<=, >=) although Properties are not orderable. Comparing, summing will be done on all the properties fields

=head1 SYNOPSIS

use Util::Properties::Combine;

my $pc1 = Util::Properties::Combine->new(file=>'file1.properties');

my $pc2 = Util::Properties::Combine->new(file=>'file2.properties');

my $p = Util::Properties::Combine->new(file=>'file.properties');

$pc1+=$p

if($pc1 <= $pc2){
...
}

=head1 FUNCTIONS

=head1 METHODS

=head1 BUGS

Please report any bugs or feature requests to
C<bug-util-properties@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Util-Properties>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2006 Alexandre Masselot, all rights reserved.

This program is released under the following license: gpl

=cut

use Util::Properties;
{
  use Object::InsideOut qw(Util::Properties);

  my @infoMessage :Field(Accessor => 'infoMessage');
  my %init_args :InitArgs = (
			    );
  sub _init :Init{
    my ($self, $h) = @_;

  }

  use overload (
		'+=' => \&__plusEqual,
		'-=' => \&__minusEqual,
		'<=' => \&__cmpLE,
		'>=' => \&__cmpGE,
	       );

  sub __plusEqual{
    my $self=shift;
    my $p=shift;

    my %visKeys;
    my %spl=$self->prop_list();
    foreach (keys %spl){
      next unless $p->prop_get($_);
      $self->prop_set($_, $self->prop_get($_)+$p->prop_get($_));
      $visKeys{$_}=1;
    }
    %spl=$p->prop_list();
    foreach (keys %spl){
      next if $visKeys{$_};
      $self->prop_set($_, $p->prop_get($_));
    }
   return $self;
  }

  sub __minusEqual{
    my $self=shift;
    my $p=shift;

    my %visKeys;
    my %spl=$self->prop_list();
    foreach (keys %spl){
      next unless $p->prop_get($_);
      $self->prop_set($_, $self->prop_get($_)-$p->prop_get($_));
      $visKeys{$_}=1;
    }
    %spl=$p->prop_list();
    foreach (keys %spl){
      next if $visKeys{$_};
      $self->prop_set($_, -$p->prop_get($_));
    }
   return $self;
  }

  sub __cmpGE{
    my $self=shift;
    my $p=shift;

    my %spl=$self->prop_list();
    my %ppl=$p->prop_list();

    foreach (keys %spl){
      next unless defined $ppl{$_};
      if($spl{$_}<$ppl{$_}){
	$self->infoMessage("$_: ($spl{$_}<$ppl{$_})");
	return 0;
      }
    }
    return 1;
  }

  sub __cmpLE{
    my $self=shift;
    my $p=shift;

    my %spl=$self->prop_list();
    my %ppl=$p->prop_list();

    foreach (keys %spl){
      next unless defined $ppl{$_};
      if($spl{$_}>$ppl{$_}){
	$self->infoMessage("$_: ($spl{$_}>$ppl{$_})");
	return 0;
      }
    }
    return 1;
  }
}
return 1; # End of Util::Properties
