package TypeLibrary::FromXSD;

# ABSTRACT: create a Type::Tiny library of simpleTypes in .xsd files.

use strict;
use warnings;

use Moo;

use File::Basename;
use XML::LibXML;

use TypeLibrary::FromXSD::Element;

our $VERSION = 0.03;

has types       => (is => 'rwp');
has xsd         => (is => 'ro', required => 1);
has output      => (is => 'ro');
has namespace   => (is => 'ro');
has version_add => (is => 'ro', default => sub{ '0.01' } );

sub run {
    my ($self) = @_;

    my $tree      = XML::LibXML->new->parse_file( $self->xsd )->getDocumentElement;
    my @typeNodes = $tree->getElementsByTagName('xs:simpleType');

    my $out_fh    = *STDOUT;
    my $namespace = $self->namespace || 'Library'; 

    if ( $self->output ) {
        open $out_fh, '>', $self->output;
        $namespace = $self->namespace || basename $self->output;
        $namespace =~ s/\.pm\z//;
    }

    my @types;
    my %types_used;
    for my $node ( @typeNodes ) {
        my $element = TypeLibrary::FromXSD::Element->new(
            $node,
            validate => {
                date     => 'validate_date',
                dateTime => 'validate_datetime',
            },
        );

        push @types, $element;
        $types_used{ $element->orig_base }++;
    }

    my $declare = join ' ', map{ $_->name }@types;
    print $out_fh $self->_module_header( $namespace, $declare );
    
    if ( $types_used{date} || $types_used{dateTime} ) {
        print $out_fh "\nuse DateTime;\n\n";
    }

    for my $type ( @types ) {
        print $out_fh $type->type,"\n\n";
    }

    if ( $types_used{date} ) {
        print $out_fh $self->_validate_date_sub;
    }

    if ( $types_used{dateTime} ) {
        print $out_fh $self->_validate_datetime_sub;
    }

    print $out_fh "1;\n";
}

sub _module_header {
    my ($self, $ns, $declare) = @_;

    my $version = $self->version_add;
    if ( $self->output and -f $self->output ) {
        my $content = do{ local (@ARGV,$/) = $self->output; <> };
        ($version)  = $content =~ m{\$VERSION\s*=\s*(.*?);};
        $version   += $self->version_add;
    }

    qq*package $ns;

use strict;
use warnings;

use Type::Library
   -base,
   -declare => qw( $declare );
use Type::Utils -all;
use Types::Standard -types;

our \$VERSION = $version;
*;
}

sub _validate_date_sub {
    q*sub validate_date {
    my ($date) = @_;

    $date =~ s/\A-//;
    my ($year,$month,$day,$hour,$min) = split /[-Z+:]/, $date;

    eval {
        DateTime->new(
            year  => $year,
            month => $month,
            day   => $day,
        );
    } or return 0;

    return 0 if ( $hour and ( $hour < 0 or $hour > 12 ) );
    return 0 if ( $min  and ( $min < 0 or $min > 59 ) );

    return 1;
}

*;
}

sub _validate_datetime_sub {
    q*sub validate_datetime {
    my ($date) = @_;

    $date =~ s/\A-//;
    my ($year,$month,$day,$hour,$min) = split /[-Z+:]/, $date;

    eval {
        DateTime->new(
            year  => $year,
            month => $month,
            day   => $day,
        );
    } or return 0;

    return 0 if ( $hour and ( $hour < 0 or $hour > 12 ) );
    return 0 if ( $min  and ( $min < 0 or $min > 59 ) );

    return 1;
}

*;
}

1;

__END__

=pod

=head1 NAME

TypeLibrary::FromXSD - create a Type::Tiny library of simpleTypes in .xsd files.

=head1 VERSION

version 0.03

=head1 SYNOPSIS

  use TypeLibrary::FromXSD;
  
  my $generator = TypeLibrary::FromXSD->new(
    xsd    => '/path/to/file.xsd',
    output => '/path/to/Library.pm',
  );
  
  $generator->run;

=head1 DESCRIPTION

This module helps to create a library for types (using C<Type::Tiny>) based on a XML schema.
It searches for I<simpleType>s in the I<.xsd> file and creates a type for it.

=head1 METHODS

=head2 run

=head1 SUPPORTED TYPES

=head2 Date And DateTime

  <xs:simpleType name="ISODate">
    <xs:restriction base="xs:date"/>
  </xs:simpleType>
  <xs:simpleType name="ISODateTime">
    <xs:restriction base="xs:dateTime"/>
  </xs:simpleType>

create those types:

  declare ISODate =>
      as Str,
      where {
          ($_ =~ m{\A-?[0-9]{4,}-[0-9]{2}-[0-9]{2}(?:Z|[-+]?[0-2][0-9]:[0-5][0-9])?\z}) &&
          (validate_date( $_ )) # if an extra validation is passed
      };

=head2 Strings

  <xs:simpleType name="BEIIdentifier">
    <xs:restriction base="xs:string">
      <xs:pattern value="[A-Z]{6,6}[A-Z2-9][A-NP-Z0-9]([A-Z0-9]{3,3}){0,1}"/>
    </xs:restriction>
  </xs:simpleType>

=>

  declare BEIIdentifier =>
     as Str,
     where{
         ($_ =~ m![A-Z]{6,6}[A-Z2-9][A-NP-Z0-9]([A-Z0-9]{3,3}){0,1}!)
     };

=head2 Enumerations

  <xs:simpleType name="AddressType2Code">
    <xs:restriction base="xs:string">
      <xs:enumeration value="ADDR"/>
      <xs:enumeration value="PBOX"/>
      <xs:enumeration value="HOME"/>
      <xs:enumeration value="BIZZ"/>
      <xs:enumeration value="MLTO"/>
      <xs:enumeration value="DLVY"/>
    </xs:restriction>
  </xs:simpleType>

=>

  declare AddressType2Code => as enum ["ADDR","PBOX","HOME","BIZZ","MLTO","DLVY"];

=head2 Numbers

  <xs:simpleType name="CurrencyAndAmount_SimpleType">
    <xs:restriction base="xs:decimal">
      <xs:minInclusive value="0"/>
      <xs:fractionDigits value="5"/>
      <xs:totalDigits value="18"/>
    </xs:restriction>
  </xs:simpleType>

=>

  declare CurrencyAndAmount_SimpleType =>
      as Num,
      where {
          ($_ <= 0) &&
          (length( (split /\./, $_)[1] ) == 5) &&
          (tr/0123456789// == 18)
      };

=head1 AUTHOR

Renee Baecker <github@renee-baecker.de>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by Renee Baecker.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
