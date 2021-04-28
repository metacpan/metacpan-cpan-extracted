package MARC::Moose::Parser::MarcxmlSaxHandler;
# ABSTRACT: SAX handler for parsing MARXML records
$MARC::Moose::Parser::MarcxmlSaxHandler::VERSION = '1.0.44';
use strict;
use warnings;

use XML::SAX;
use base qw( XML::SAX::Base );

use MARC::Moose::Field::Control;
use MARC::Moose::Field::Std;


sub new {
    my $class = shift;
    return bless {}, ref($class) || $class;
}

sub start_element {
    my ($self, $element) = @_;
    my $name = $element->{Name};
    $self->{data} = '';
    if ( $name eq 'record' ) {
        $self->{record} = MARC::Moose::Record->new();
        $self->{fields} = [];
    }
    elsif ( $name eq 'controlfield' ) {
        $self->{field} = MARC::Moose::Field::Control->new(
            tag => $element->{Attributes}{'{}tag'}{Value} );
    }
    elsif ( $name eq 'datafield' ) {
        my $attr = $element->{Attributes};
        my $ind1 = $attr->{'{}ind1'}{Value};
        $ind1 = ' ' unless defined($ind1);
        my $ind2 = $attr->{'{}ind2'}{Value};
        $ind2 = ' ' unless defined($ind2);
        $self->{field} = MARC::Moose::Field::Std->new(
            tag  => $attr->{'{}tag'}{Value},
            ind1 => $ind1,
            ind2 => $ind2,
        );
    }
    elsif ( $name eq 'subfield' ) {
        $self->{code} = $element->{Attributes}{'{}code'}{Value}
    }
}


sub end_element {
    my ($self, $element) = @_;
    my $name = $element->{Name};

    if ( $name eq 'leader' ) {
        my $record = $self->{record};
        $record->_leader( $self->{data} );
    }
    elsif ( $name eq 'controlfield' ) {
        my $field = $self->{field};
        $field->value( $self->{data} );
        push @{$self->{fields}}, $field;
    }
    elsif ( $name eq 'datafield' ) {
        push @{$self->{fields}}, $self->{field};
    }
    elsif ( $name eq 'subfield' ) {
        my $field = $self->{field};
        push @{$field->{subf}}, [ $self->{code}, $self->{data} ];
    }
    elsif ( $name eq 'record' ) {
        my $record = $self->{record};
        $record->fields( $self->{fields} );
    }
}


sub characters {
    my ($self, $characters) = @_;
    $self->{data} .= $characters->{Data};
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MARC::Moose::Parser::MarcxmlSaxHandler - SAX handler for parsing MARXML records

=head1 VERSION

version 1.0.44

=head1 AUTHOR

Frédéric Demians <f.demians@tamil.fr>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by Frédéric Demians.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
