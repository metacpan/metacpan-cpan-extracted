package Treex::PML::Schema::XMLNode;

use strict;
use warnings;

use vars qw($VERSION);
BEGIN {
  $VERSION='2.28'; # version template
}
no warnings 'uninitialized';
use Carp;
use Scalar::Util qw(weaken isweak);

use UNIVERSAL::DOES;

sub copy_decl {
  my ($self,$t)=@_;
  my $copy;
  if (ref $t->{-schema}) {
    $copy = Treex::PML::CloneValue($t,[$t->{-parent},$t->{-schema}], [$self,$self->{-schema}]);
  } else {
    $copy = Treex::PML::CloneValue($t,[$t->{-parent}], [$self]);
  }
  if (exists $self->{'-##'}) {
    $copy->{'-#'}=$self->{'-##'}++;
  }
  # we must do this here, otherwise any operation
  # that rewrites this value will create an unaccessible crircular reference
  Treex::PML::Schema::_traverse_data(
    $copy => sub {
      my ($val,$is_hash) = @_;
      weaken($val->{-parent}) if ref($val->{-parent}) and not isweak($val->{-parent});
      weaken($val->{-schema}) if ref($val->{-schema}) and not isweak($val->{-schema});
    },
    {
     $self->{-schema}=>1, $self=> 1 # do not recurse into these
    },
    1, # only hashes
  );
  return $copy;
}

sub serialize_attributes {
  my ($self,$opts)=@_;
  my $attributes = $self->{-attributes}||[];
  my @ret;
  for my $attr (@$attributes) {
    next if $attr=~/^xmlns/;
    my $value = $self->{$attr};
    if (!defined($value) and $attr eq 'name') { # FIXME: THIS IS A HACK
      $value = $self->{'-'.$attr};
    }
    if (defined $value) {
      push @ret, $attr, $value;
    }
  }
  return \@ret;
}

sub serialize_exclude_keys {}
sub serialize_get_children {
  my ($self,$opts)=@_;
  my %exclude;
  @exclude{
    @{$self->{-attributes}||[]},
      $self->serialize_exclude_keys($opts)
  }=();
  my @children = map {
    my $name = $_;
    my $val = $self->{$_};
    (ref($val) eq 'HASH')  ? ( map { [$name,$_] } grep { UNIVERSAL::DOES::does($_,'Treex::PML::Schema::XMLNode') } values(%{$val})) :
    (ref($val) eq 'ARRAY') ? ( map { [$name,$_] } grep { UNIVERSAL::DOES::does($_,'Treex::PML::Schema::XMLNode') } @{$val}) :
     (UNIVERSAL::DOES::does($val,'Treex::PML::Schema::XMLNode') or !ref($val)) ? [$name,$val] : ()
  } grep {!/^[-@]/ and !exists($exclude{$_})} keys %$self;
  return (
    (grep { !ref($_->[1]) } @children),
    sort { $a->[1]{'-#'} <=> $b->[1]{'-#'} } grep { ref($_->[1]) } @children
  )
}
sub serialize_children {
  my ($self,$opts,$children)=@_;
  my $writer = $opts->{writer} || croak __PACKAGE__."->serialize: missing required option 'writer'!\n";
  my $ns = $opts->{DefaultNs};
  $children ||= [$self->serialize_get_children($opts)];
  for my $child (@$children) {
    my ($key,$value) = @$child;
    if (UNIVERSAL::DOES::does($value,'Treex::PML::Schema::XMLNode')) {
      $value->serialize($opts);
    } else {
      my $tag = [$ns,$key];
      $writer->startTag($tag) if defined $key;
      $writer->characters($value);
      $writer->endTag($tag) if defined $key;
    }
  }
}
sub serialize {
  my ($self,$opts)=@_;
  my $writer = $opts->{writer} || croak __PACKAGE__."->serialize: missing required option 'writer'!\n";
  my $xml_name = $self->{-xml_name};
  if ($xml_name =~/^#/) {
    if ($xml_name =~/^#text/) {
      $writer->characters($self->{-value});
    } elsif ($xml_name =~/^#comment/) {
      my $value = $self->{-value};
      $value=~s/^ | $//g; # remove a leading and trailing space - XML::Writer addes them
      $writer->comment($value);
    } elsif ($xml_name =~/^#processing-instruction/) {
      $writer->pi($self->{-name}, $self->{-value});
    } elsif ($xml_name =~/^#other/) {
      $writer->raw($self->{-xml});
    } else {
      # ignoring
    }
  } elsif ($xml_name=~/^{(.*)}(.*)$/ or $xml_name=~/^()([^#].*)$/) {
    my ($ns,$name)=($1,$2);
    my $attrs = $self->serialize_attributes($opts) || [];
    my $prefix = $self->{-xml_prefix} || '';
    $ns ||= $opts->{DefaultNs};
    if (($ns ne $opts->{DefaultNs})) {
      $writer->addPrefix($ns => $prefix);
    }
    $writer->addPrefix($ns => $prefix);
    {
      my @children = $self->serialize_get_children($opts);
      if (@children) {
	$writer->startTag([$ns,$name], @$attrs);
	$self->serialize_children($opts,\@children);
	$writer->endTag([$ns,$name]);
      } else {
	$writer->emptyTag([$ns,$name], @$attrs);
      }
    }
  }
}

sub write {
  my ($self,$opts)=@_;
  my $fh;
  my $have_backup;
  my $filename = $opts->{filename};
  if (!defined($opts->{fh}) and
      !defined($opts->{string}) and
       defined($filename)) {
    unless ($opts->{no_backups}) {
      eval { Treex::PML::IO::rename_uri($filename,$filename."~"); $have_backup=1; } || carp($@);
    }
    $fh = Treex::PML::IO::open_backend($filename,'w')
      || die "Cannot open $filename for writing: $!";
    binmode $fh;
  }
  eval {
    my $writer = XML::Writer->new(
      OUTPUT => ($opts->{fh} || $opts->{string} || $fh ),
      DATA_MODE => $opts->{no_indent} ? 0 : 1,
      DATA_INDENT => $opts->{no_indent} ? 0 : 1,
      NAMESPACES => 1,
      PREFIX_MAP => {
	(Treex::PML::Schema->PML_SCHEMA_NS) => '',
      });
    $self->serialize({
      writer => $writer,
      DefaultNs => Treex::PML::Schema->PML_SCHEMA_NS,
    });
    $writer->end();
  };
  if ($@) {
    my $err=$@;
    $have_backup && eval { Treex::PML::IO::rename_uri($filename."~",$filename) };
    $err.=$@ if $@;
    carp("Error while saving schema: $err\n");
  }
  Treex::PML::IO::close_backend($fh) if $fh;
}

sub DESTROY {
  my ($self)=@_;
  %$self=(); # this should not be needed, but
             # without it, perl 5.10 leaks on weakened
             # structures, try:
             #   Scalar::Util::weaken({}) while 1

}


1;
__END__

=head1 NAME

Treex::PML::Schema::XMLNode - base class for Treex::PML::Schema components

=head1 SYNOPSIS

   use Treex::PML::Schema::XMLNode;

=head1 DESCRIPTION

A common base class for components of a Treex::PML::Schema object.

=head1 METHODS


=over 5

=item $self->copy_decl ($decl)

Creates a recursive copy of a given declaration, transfering it to the
current schema and parent-node if necessary.

=item $self->write ({option => value})

This method serializes an object based on XMLNode the class to XML. See Treex::PML::Schema->write for details.

=back

=head2 EXPORT

None by default.

=head1 SEE ALSO

L<Treex::PML::Schema>, L<Treex::PML::Schema::Reader>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008-2010 by Petr Pajas, 2010-2024 Jan Stepanek

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.2 or,
at your option, any later version of Perl 5 you may have available.

=head1 BUGS

None reported... yet.

=cut

