package UMMF::MOF::Format::IDLIdentifierBase;

use 5.6.1;
use strict;
#use warnings;


our $AUTHOR = q{ ks.perl@kurtstephens.com 2003/05/25 };
our $VERSION = do { my @r = (q$Revision: 1.1 $ =~ /\d+/g); sprintf "%d." . "%03d" x $#r, @r };

=head1 NAME

UMMF::MOF::Format::IDLIdentifierBase - A base class for MOF 1.4 ModelElement name transforms.

=head1 SYNOPSIS

  use base qw(UMMF::MOF::Format::IDLIndentifierBase);

=head1 DESCRIPTION

A base class for MOF 1.4 ModelElement name transforms for IDL Identifiers.

See MOF 1.4 p.5-44

=head1 USAGE

=head1 EXPORT

None exported.

=head1 AUTHOR

Kurt Stephens, ks.perl@kurtstephens.com 2003/05/25

=head1 SEE ALSO

L<UMMF::MOF::Format::IDLIdentifierBase1|UMMF::MOF::Format::IDLIdentifierBase1>

=head1 VERSION

$Revision: 1.1 $

=head1 METHODS

=cut

####################################################################################

use base qw(UMMF::Object);

####################################################################################

use Carp qw(confess);

####################################################################################


# See MOF 1.4 p. 5-44

sub split_words
{
  my ($self, $x) = @_;
    
  my @w;
  
  $x =~ s/([A-Z][A-Z0-9]*[a-z0-9]*|[a-z][a-z0-9]*)/push(@w, $1)/esg;
  
  wantarray ? @w : \@w;
}


sub transform
{
  confess("Subclass responsibility");
}


####################################################################################

sub UNIT_TEST
{
  my ($self, $tests) = @_;
  
  $self = $self->new unless ref($self);
  
  local $::tests = $tests;
  eval q{
    use Test::Simple tests => scalar @$::tests;
    
    for my $x ( @{$::tests} ) {
      ok($self->transform($x->[0]) eq $x->[1] );
    }
  }; die $@ if $@;
  
  
  $self;
}


####################################################################################

1;

####################################################################################


### Keep these comments at end of file: ks.perl@kurtstephens.com 2003/04/06 ###
### Local Variables: ###
### mode:perl ###
### perl-indent-level:2 ###
### perl-continued-statement-offset:0 ###
### perl-brace-offset:0 ###
### perl-label-offset:0 ###
### End: ###

