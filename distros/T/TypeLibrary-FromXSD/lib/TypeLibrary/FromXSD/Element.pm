package TypeLibrary::FromXSD::Element;

# ABSTRACT: Create a single type decleration from a simpleType xsd element

use Moo;

our $VERSION = 0.03;

has name         => (is => 'ro', required => 1);
has base         => (is => 'ro', required => 1);
has orig_base    => (is => 'ro' );
has enum         => (is => 'ro', predicate => 1);
has restrictions => (is => 'ro', predicate => 1);

sub type {
    my ($self) = @_;

    return sprintf "declare %s =>\n    as %s%s;", 
        $self->name,
        $self->_basetype,
        $self->_where,
}

sub _basetype {
    my ($self) = @_;

    return $self->base if !$self->has_enum;
    return sprintf "enum [%s]", join ",", map{ $_ =~ s/'/\'/g; "'$_'" } @{ $self->enum };
}

sub _where {
    my ($self) = @_;

    return '' if !$self->restrictions;
    return sprintf ",\n    where {\n        %s\n    }", 
               join " && \n        ", map{ "($_)" }@{ $self->restrictions };
}

sub BUILDARGS {
    my ($class, @args) = @_;

    return {@args} if @args > 1 && @args % 2 == 0;

    my $node = shift @args;

    my $extra_validations;
    if ( @args > 1 ) {
        my %args = @args;
        $extra_validations = delete $args{validate};
    }

    my %real_args;
    if ( $node ) {

        return {} if !ref $node || !$node->isa('XML::LibXML::Element');

        $real_args{name} = $node->findvalue('@name');

        my ($restrictions_node) = $node->findnodes('xs:restriction');

        my $base = $restrictions_node->findvalue('@base');

        my %base_map = (
            'xs:string'   => 'Str',
            'xs:decimal'  => 'Num',
            'xs:date'     => 'Str',
            'xs:dateTime' => 'Str',
        );

        $real_args{base} = $base_map{$base} || 'Str';

        my @restrictions = $restrictions_node->childNodes;
        for my $restriction ( @restrictions ) {

            my $node_name = $restriction->nodeName;

            if ( $node_name eq 'xs:enumeration' ) {
                push @{ $real_args{enum} }, $restriction->findvalue('@value');
            }
            elsif ( $node_name eq 'xs:minLength' ) {
                push @{ $real_args{restrictions} }, 'length($_) >= ' . $restriction->findvalue('@value');
            }
            elsif ( $node_name eq 'xs:maxLength' ) {
                push @{ $real_args{restrictions} }, 'length($_) <= ' . $restriction->findvalue('@value');
            }
            elsif ( $node_name eq 'xs:pattern' ) {
                my $pattern = $restriction->findvalue('@value');
                $pattern    =~ s/!/\!/g;
                push @{ $real_args{restrictions} }, sprintf '$_ =~ m!%s!', $pattern;
            }
            elsif ( $node_name eq 'xs:minInclusive' ) {
                push @{ $real_args{restrictions} }, '$_ >= ' . $restriction->findvalue('@value');
            }
            elsif ( $node_name eq 'xs:maxInclusive' ) {
                push @{ $real_args{restrictions} }, '$_ <= ' . $restriction->findvalue('@value');
            }
            elsif ( $node_name eq 'xs:fractionDigits' ) {
                push @{ $real_args{restrictions} }, 'length( (split /\./, $_)[1] ) == ' . $restriction->findvalue('@value');
            }
            elsif ( $node_name eq 'xs:totalDigits' ) {
                push @{ $real_args{restrictions} }, 'tr/0123456789// == ' . $restriction->findvalue('@value');
            }
        } 

        $base =~ s/^xs://;
        if ( $base eq 'date' ) {
            push @{ $real_args{restrictions} }, '$_ =~ m{\A-?[0-9]{4,}-[0-9]{2}-[0-9]{2}(?:Z|[-+]?[0-2][0-9]:[0-5][0-9])?\z}';
        }
        elsif ( $base eq 'dateTime' ) {
            push @{ $real_args{restrictions} }, 
                '$_ =~ m{\A-?[0-9]{4,}-[0-9]{2}-[0-9]{2}T[0-2][0-9]:[0-5][0-9]:[0-5][0-9](?:Z|[-+]?[0-2][0-9]:[0-5][0-9])?\z}';
        }

        if ( $base =~ m{\Adate(Time)?\z} and $extra_validations and $extra_validations->{$base} ) {
            push @{ $real_args{restrictions} }, $extra_validations->{$base} . '($_)';
        }

        $real_args{orig_base} = $base;
    }

    return \%real_args;
}

1;

__END__

=pod

=head1 NAME

TypeLibrary::FromXSD::Element - Create a single type decleration from a simpleType xsd element

=head1 VERSION

version 0.03

=head1 SYNOPSIS

  use TypeLibrary::FromXSD::Element;
  use XML::LibXML;

  my $xsd  = 'test.xsd';
  my $tree = XML::LibXML->new->parse_file( $xsd )->getDocumentElement;

  my @nodes = $tree->getElementsByTagName( 'xs:simpleType' );
  
  for my $xsd_node ( @nodes ) {
      my $element = TypeLibrary::FromXSD::Element->new( $xsd_node );
      
      # to provide additional validation methods
      # my $element = TypeLibrary::FromXSD::Element->new( $xsd_node, validate => { date => 'validate_date' } );
  
      print $element->type;
  }

=head1 METHODS

=head2 new

Create a I<Element> object, in contrast to other classes, this constructor
wants a single parameter - a simpleType node.

This class gets all needed attributes and subnodes to create the type
declaration.

=head2 type

prints the type declaration

=head1 NOTE

Please note that this distribution does not support all combinations of basetypes (xs:string, xs:decimal, ...) and other restrictions
(xs:minLength, xs:maxLength, ...) yet.

=head1 AUTHOR

Renee Baecker <github@renee-baecker.de>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by Renee Baecker.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
