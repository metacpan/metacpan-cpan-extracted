package UMMF::MOF::Format::IDLIdentifier1;

use 5.6.1;
use strict;
#use warnings;


our $AUTHOR = q{ ks.perl@kurtstephens.com 2003/05/25 };
our $VERSION = do { my @r = (q$Revision: 1.2 $ =~ /\d+/g); sprintf "%d." . "%03d" x $#r, @r };

=head1 NAME

UMMF::MOF::Format::IDLIdentifier1 - A transformer for MOF 1.4 IDL Identifier Format 1.

=head1 SYNOPSIS

  use UMMF::MOF::Format::IDLIdentifier1;

  my $x = UMMF::MOF::Format::IDLIdentifier1->new;
  $x->transform('DSTC pty ltd') eq 'DSTCPtyLtd';

=head1 DESCRIPTION

=head1 USAGE

=head1 EXPORT

None exported.

=head1 AUTHOR

Kurt Stephens, ks.perl@kurtstephens.com 2003/05/25

=head1 SEE ALSO

L<UMMF|UMMF>

=head1 VERSION

$Revision: 1.2 $

=head1 METHODS

=cut

####################################################################################

use base qw(UMMF::MOF::Format::IDLIdentifierBase);

####################################################################################


sub transform
{
  my ($self, $x) = @_;
  
  my $w = $self->split_words($x);
  
  my $y = join('', map(ucfirst, @$w));

  print STDERR "'$x' => '$y'\n";

  $y;
}

####################################################################################


sub UNIT_TEST
{
  my ($self) = @_;

  $self ||= __PACKAGE__;

  $self->SUPER::UNIT_TEST
  (
   [
    [ 'foo',               'Foo' ],
    [ 'foo_bar',           'FooBar' ],
    [ 'ALPHAbeticalOrder', 'ALPHAbeticalOrder' ],
    [ '-a1B2c3-d4-',       'A1B2c3D4' ],
    [ 'DSTC pty ltd',      'DSTCPtyLtd' ],
    ]
   );		   
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

