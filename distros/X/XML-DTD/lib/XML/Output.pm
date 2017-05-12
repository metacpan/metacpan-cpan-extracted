package XML::Output;

use 5.008;
use strict;
use warnings;

our $VERSION = '0.09';

# Constructor
sub new {
  my $arg = shift;
  my $cfg = shift;

  my $cls = ref($arg) || $arg;
  my $obj = ref($arg) && $arg;

  my $self;
  if ($obj) {
    # Called as a copy constructor
    $self = { %$obj };
  } else {
    # Called as the main constructor
    $self = { };
    #$self->{'FH'} = (defined $cfg->{'fh'})?$cfg->{'fh'}:*STDOUT;
    $self->{'FH'} = $cfg->{'fh'};
    $self->{'STRACCUM'} = '' if (!defined $self->{'FH'});
    $self->{'INDENT'} = (defined $cfg->{'indent'})?$cfg->{'indent'}:2;
    $self->{'ENCODING'} = (defined $cfg->{'encoding'})?$cfg->{'encoding'}:
      'utf-8';
    $self->{'ATTRQUOTE'} = (defined $cfg->{'attrquote'})?$cfg->{'attrquote'}:
      '\'';
    # Mapping '&' to '&amp;' is excluded below because it does not
    # involve a simple substitution - replacement should not occur for
    # the '&' character initiating an entity reference
    $self->{'SUBST'} = {'<'  => '&lt;',
			'>'  => '&gt;',
			'\'' => '&apos;',
			'\"' => '&quot;'};
    $self->{'INIT'} = 1;
    $self->{'PCDATA'} = 0;
    $self->{'STACK'} = [];
  }
  bless $self, $cls;
  return $self;
}


# Print an element start tag
sub open {
  my $self = shift;
  my $name = shift;
  my $attr = shift;
  my $cnfg = shift;

  $self->{'PCDATA'} = 0;
  my $attq = (defined $cnfg->{'attrquote'})?$cnfg->{'attrquote'}:
    $self->{'ATTRQUOTE'};
  ##my $subst = (defined $cnfg->{'subst'})?$cnfg->{'subst'}:{};
  my $fh = $self->{'FH'};
  my $indent = ' ' x (@{$self->{'STACK'}} * $self->{'INDENT'});
  my $cr = ($self->{'INIT'} == 1)?'':"\n";
  $self->{'INIT'} = 0;
  my $str = $cr . $indent . "<$name";
  my ($k, $v, $sv);
  while ( ($k,$v) = each(%$attr) ) {
    if (defined $v) {
      $sv = $self->_cesubst($cnfg, $v);
      $str .= " $k=$attq$sv$attq";
    }
  }
  if (defined $cnfg->{'empty'} and $cnfg->{'empty'} == 1) {
    $str .= '/>';
  } else {
    $str .= '>';
    push @{$self->{'STACK'}}, $name;
  }
  if (defined $fh) {
    print $fh $str;
  } else {
    $self->{'STRACCUM'} .= $str;
  }
}


# Print an element end tag
sub close {
  my $self = shift;

  my $indent = ' ' x ((@{$self->{'STACK'}}-1) * $self->{'INDENT'});
  $indent = '' if ($self->{'PCDATA'} == 1);
  my $cr = ($self->{'PCDATA'} == 1)?'':"\n";
  my $name = pop @{$self->{'STACK'}};
  my $fh = $self->{'FH'};
  ##print $fh $cr . $indent . "</$name>";
  my $str = $cr . $indent . "</$name>";
  $self->{'PCDATA'} = 0;
  ##print $fh "\n" if (@{$self->{'STACK'}} == 0);
  $str .= "\n" if (@{$self->{'STACK'}} == 0);
  if (defined $fh) {
    print $fh $str;
  } else {
    $self->{'STRACCUM'} .= $str;
  }
}


# Print an empty tag
sub empty {
  my $self = shift;
  my $name = shift;
  my $attr = shift;
  my $cnfg = shift;

  my $ecnfg = (defined $cnfg)?{ %$cnfg }:{};
  $ecnfg->{'empty'} = 1;
  $self->open($name, $attr, $ecnfg);
  ##$self->{'PCDATA'} = 1;
  ##$self->close();
}


# Print #PCDATA
sub pcdata {
  my $self = shift;
  my $data = shift;
  my $cnfg = shift;

  $self->{'PCDATA'} = 1;
  my $fh = $self->{'FH'};
  my $str = $self->_cesubst($cnfg, $data);
  if (defined $fh) {
    print $fh $str;
  } else {
    $self->{'STRACCUM'} .= $str;
  }
}


# Print a comment
sub comment {
  my $self = shift;
  my $cmnt = shift;
  my $cnfg = shift;

  my $cr = ($self->{'INIT'} == 1)?'':"\n";
  $self->{'INIT'} = 0;
  my $str = "$cr<!-- $cmnt -->";
  my $fh = $self->{'FH'};
  if (defined $fh) {
    print $fh $str;
  } else {
    $self->{'STRACCUM'} .= $str;
  }
}


# Get the string accumlator value
sub xmlstr {
  my $self = shift;

  return $self->{'STRACCUM'};
}

# Substitute special characters with corresponding character entities
sub _cesubst {
  my $self = shift;
  my $cnfg = shift;
  my $text = shift;

  my $ssubst = { %{$self->{'SUBST'}} };
  my $csubst = (defined $cnfg->{'subst'})?$cnfg->{'subst'}:{};
  # Construct hash merging standard and user-defined substitutions
  my ($k,$v);
  while ( ($k,$v) = each(%$csubst) ) {
    $ssubst->{$k} = $v;
  }
  # Perform all substitutions
  while ( ($k,$v) = each(%$ssubst) ) {
    $text =~ s/$k/$v/gs;
  }
  #NB: Still need to take care of '&' not part of an entity ref
  return $text;
}


1;
__END__

=head1 NAME

XML::Output - Perl module for writing simple XML documents

=head1 SYNOPSIS

  use XML::Output;

  open(FH,'>file.xml');
  my $xo = new XML::Output({'fh' => *FH});
  $xo->open('tagname', {'attrname' => 'attrval'});
  $xo->pcdata('element content');
  $xo->close();
  close(FH);

=head1 ABSTRACT

  XML::Output is a Perl module for writing simple XML documents

=head1 DESCRIPTION

  XML::Output is a Perl module for writing simple XML document. The
  following methods are provided.

=over 4

=item B<new>

  $xo = new XML::Output;

Constructs a new XML::Output object.

=item B<open>

  $xo->open('tagname', {'attrname' => 'attrval'});

Open an element with specified name (and optional attributes)

=item B<close>

 $xo->close;

Close an element

=item B<empty>

 $xo->empty('tagname', {'attrname' => 'attrval'});

Insert an empty element with specified name (and optional attributes)

=item B<pcdata>

 $xo->pcdata('element content');

Insert text

=item B<comment>

 $xo->comment('comment text');

Insert a comment

=item B<xmlstr>

 print $xo->xmlstr;

Get a string representation of the constructed document

=back


=head1 SEE ALSO

L<XML::DTD>

=head1 AUTHOR

Brendt Wohlberg E<lt>wohl@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004-2010 by Brendt Wohlberg

This library is available under the terms of the GNU General Public
License (GPL), described in the GPL file included in this distribution.

=cut
