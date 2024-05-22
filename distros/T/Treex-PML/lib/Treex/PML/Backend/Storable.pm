package Treex::PML::Backend::Storable;
use Treex::PML;
use Storable qw(nstore_fd fd_retrieve);
use Treex::PML::IO qw( close_backend);
use strict;

use vars qw($VERSION);
BEGIN {
  $VERSION='2.28'; # version template
}
use UNIVERSAL::DOES;
use Scalar::Util qw(blessed reftype refaddr);

sub test {
  my ($f,$encoding)=@_;
  if (ref($f)) {
    return $f->getline()=~/^pst0/;
  } else {
    my $fh = open_backend($f,"r");
    my $test = $fh && test($fh,$encoding);
    close_backend($fh);
    return $test;
  }
}

sub open_backend {
  Treex::PML::IO::open_backend(@_[0,1]);
}

sub read {
  my ($fd,$fs)=@_;
  binmode($fd);
  my $restore = fd_retrieve($fd);

  my $api_version = $restore->[6];
  unless ($Treex::PML::COMPATIBLE_API_VERSION{ $api_version }) {
    $api_version='0.001' unless defined $api_version;
    warn "Warning: the binary file ".$fs->filename." is a dump of structures created by possibly incompatible Treex::PML API version $api_version (the current Treex::PML API version is $Treex::PML::API_VERSION)\n";
  }

  # support for old Fslib-based documents:
  if (ref($restore->[0]) eq 'FSFormat' and not defined($Fslib::VERSION)) {
    # upgrade to Treex::PML
    # warn "Warning: Detected Fslib-based file and Fslib is not loaded: upgrading to Treex::PML!\n";
    upgrade_from_fslib($restore);
  }

  $fs->changeTail(@{$restore->[2]});
  $fs->[13]=$restore->[3]; # metaData
  my $appData = delete $fs->[13]->{'StorableBackend:savedAppData'};
  if ($appData) {
    $fs->changeAppData($_,$appData->{$_}) foreach keys(%$appData);
  }
  $fs->changePatterns(@{$restore->[4]});
  $fs->changeHint($restore->[5]);

  # place to update some internal stuff if necessary
  my $schema = $fs->metaData('schema');
  if (ref($schema) and !$schema->{-api_version}) {
    $schema->convert_from_hash();
    $schema->post_process();
  }
  $fs->changeFS($restore->[0]);
  $fs->changeTrees(@{$restore->[1]});
  $fs->FS->renew_specials();

#  $fs->_weakenLinks;
}


sub write {
  my ($fd,$fs)=@_;
  binmode($fd);
  my $metaData = { %{$fs->[13]} };
  my $ref = $fs->appData('ref');
  $metaData->{'StorableBackend:savedAppData'}||={};
  foreach my $savedAppData ($metaData->{'StorableBackend:savedAppData'}) {
    $savedAppData->{'id-hash'} = $fs->appData('id-hash');
    $savedAppData->{'ref'} = {
      map {
        my $val = $ref->{$_};
        UNIVERSAL::DOES::does($val,'Treex::PML::Instance') ? ($_ => $val) : ()
      } keys %$ref
    } if ref $ref;
  }
  nstore_fd([$fs->FS,
             $fs->treeList,
             [$fs->tail],
             $metaData,
             [$fs->patterns],
             $fs->hint,
             $Treex::PML::API_VERSION
            ],$fd);
}

sub upgrade_from_fslib {
  my @next = @_;
  my %seen;
  $seen{refaddr($_)}=1 for @next;
  while (@next) {
    my $object = shift @next;
    my $ref = ref($object);
    next unless $ref;
    my $is  = blessed($object);
    if (defined $is) {
      if ($is =~ /^Treex/) {
      } elsif ($is eq 'FSNode') {
        bless $object, 'Treex::PML::Node';
      } elsif ($is eq 'Fslib::Type') {
        bless $object, 'Treex::PML::Backend::Storable::CopmpatType';
      } elsif ($is =~ /^Fslib::(.*)$/) {
        bless $object, qq{Treex::PML::$1};
      } elsif ($is =~ /^PMLSchema(::.*)?$/) {
        bless $object, qq{Treex::PML::Schema$1};
      } elsif ($is eq 'FSFile') {
        bless $object, 'Treex::PML::Document';
      } elsif ($is eq 'FSFormat') {
        bless $object, 'Treex::PML::FSFormat';
      } elsif ($is eq 'PMLInstance') {
        bless $object, 'Treex::PML::Instance';
      }
      $ref = reftype($object);
    }
    for (($ref eq 'HASH') ? values(%$object)
           : ($ref eq 'ARRAY') ? @$object
           : ($ref eq 'SCALAR') ? $$object : ()) {
      my $key = refaddr($_) || next;
      push @next, $_ unless ($seen{$key}++);
    }
  }
}

package Treex::PML::Backend::Storable::CopmpatType;
use Carp;
use warnings;
use strict;
use vars qw($AUTOLOAD);
# This is handler for obsoleted class 'Fslib::Type'
# which has no API-compatible counterpart in Treex::PML.
# The object is a pair (ARRAYref) containing PML schema and type declaration.
sub schema {
  my ($self)=@_;
  return $self->[0];
}
sub type_decl {
  my ($self)=@_;
  return $self->[1];
}
# delegate every method to the type
sub AUTOLOAD {
  my $self = shift;
  croak "$self is not an object" unless ref($self);
  my $name = $AUTOLOAD;
  $name =~ s/.*://;   # strip fully-qualified portion
  return $self->[1]->$name(@_);
}

1;
__END__


=pod

=head1 NAME

Treex::PML::Backend::Storable - I/O backend for data dumps via the Perl Storable module.

=head1 DESCRIPTION

This module implements a Treex::PML input/output backend for binary
dumps of the in-memory representation of Treex::PML::Document objects
using the Perl module Storable.

=head1 SYNOPSIS

use Treex::PML;
Treex::PML::AddBackends(qw(Storable))

my $document = Treex::PML::Factory->createDocumentFromFile('input.pls');
...
$document->save();

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006-2010 by Petr Pajas, 2010-2024 Jan Stepanek

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.2 or,
at your option, any later version of Perl 5 you may have available.

=cut
