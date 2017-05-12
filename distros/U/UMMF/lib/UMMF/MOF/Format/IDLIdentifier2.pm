package UMMF::MOF::Format::IDLIdentifier2;

use 5.6.1;
use strict;
#use warnings;


our $AUTHOR = q{ ks.perl@kurtstephens.com 2003/05/25 };
our $VERSION = do { my @r = (q$Revision: 1.1 $ =~ /\d+/g); sprintf "%d." . "%03d" x $#r, @r };

=head1 NAME

UMMF::MOF::Format::IDLIdentifier2 - A transformer for MOF 1.4 IDL Identifier Format 2.

=head1 SYNOPSIS

  use UMMF::MOF::Format::IDLIdentifier2;

  my $x = UMMF::MOF::Format::IDLIdentifier2->new;
  $x->transform('DSTC pty ltd') eq 'dstc_pty_ltd';

=head1 DESCRIPTION

Implements the IDL Identifier Format 2 as described in MOF 1.4 p.5-45.

=head1 USAGE

=head1 EXPORT

None exported.

=head1 AUTHOR

Kurt Stephens, ks.perl@kurtstephens.com 2003/05/25

=head1 SEE ALSO

L<UMMF|UMMF>

=head1 VERSION

$Revision: 1.1 $

=head1 METHODS

=cut

####################################################################################

use base qw(UMMF::MOF::Format::IDLIdentifierBase);

####################################################################################


sub transform
{
  my ($self, $x) = @_;
  
  my $w = $self->split_words($x);
  
  my $y = join('_', map(lc, @$w));

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
    [ 'foo',               'foo' ],
    [ 'foo_bar',           'foo_bar' ],
    [ 'ALPHAbeticalOrder', 'alphabetical_order' ],
    [ '-a1B2c3-d4-',       'a1_b2c3_d4' ],
    [ 'DSTC pty ltd',      'dstc_pty_ltd' ],
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

