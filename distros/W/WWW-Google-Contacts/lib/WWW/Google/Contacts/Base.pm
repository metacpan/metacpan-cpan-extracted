package WWW::Google::Contacts::Base;
{
    $WWW::Google::Contacts::Base::VERSION = '0.39';
}

use Moose;
use Scalar::Util qw( blessed );
use Try::Tiny;
use Data::Dumper;

sub xml_attributes {
    my $self = shift;
    return grep { $_->does('XmlField') } $self->meta->get_all_attributes;
}

sub get_xml_key {
    my ( $self, $field ) = @_;

    foreach my $attr ( $self->xml_attributes ) {
        my $name = $attr->name;
        my $val  = $self->$name;
        if ( $name eq $field ) {
            return $attr->xml_key;
        }
        elsif ( blessed($val) and $val->can("to_xml_hashref") ) {
            my $recurse = $val->get_xml_key($field);
            if ($recurse) {
                my $parent = $attr->xml_key;
                return { $parent => $recurse };
            }
        }
    }
    return undef;
}

sub to_xml_hashref {
    my $self = shift;

    my $to_return = {};
    foreach my $attr ( $self->xml_attributes ) {
        my $incl = $attr->include_in_xml;
        next unless $self->$incl;

        my $predicate = $attr->predicate;

        next
          if defined $predicate
          and not $self->$predicate
          and not $attr->is_lazy;

        my $name = $attr->name;
        my $val  = $self->$name;

        next if ( not $val );

        $to_return->{ $attr->xml_key } =
          ( blessed($val) and $val->can("to_xml_hashref") )
          ? $val->to_xml_hashref
          : ( ref($val) and ref($val) eq 'ARRAY' )
          ? [ map { $_->to_xml_hashref } @{$val} ]
          : $attr->has_to_xml ? do { my $code = $attr->to_xml; &$code($val) }
          : $attr->is_element ? [$val]
          :                     $val;
    }
    return $to_return;
}

sub set_from_server {
    my ( $self, $data ) = @_;

    foreach my $attr ( $self->xml_attributes ) {
        if ( defined $data->{ $attr->xml_key } ) {
            if ( my $writer = $attr->writer ) {

                # write attributes that are read only to the user
                $self->$writer( $data->{ $attr->xml_key } );
            }
            else {
                my $name = $attr->name;
                try {
                    $self->$name( $data->{ $attr->xml_key } );
                }
                catch {
                    my @err = split m{\n}, $_;
                    print "\nERROR - Failed to set attribute\n";
                    print "-------------------------------\n";
                    print "Attribute: " . $name . "\n";
                    print "Value: " . Dumper $data->{ $attr->xml_key };
                    print "Error: " . $err[0] . "\n";
                    print
"\nPlease include the above in an email bug report to magnus\@erixzon.com\n";
                    print
"Remove personal content in the 'value' hash, but please leave the structure intact.\n\n";
                    die "\n";
                };
            }
        }
    }
    return $self;
}

around BUILDARGS => sub {
    my $orig  = shift;
    my $class = shift;

    return $class->$orig() unless (@_);

    # let's see if we need to mangle xml fields
    my $data;
    if ( @_ > 1 ) {
        $data = {@_};
    }
    else {
        $data = shift @_;
    }

    foreach my $attr ( $class->xml_attributes ) {
        if ( defined $data->{ $attr->xml_key } ) {
            $data->{ $attr->name } = delete $data->{ $attr->xml_key };
        }
    }
    return $class->$orig($data);
};

no Moose;
__PACKAGE__->meta->make_immutable;
1;
__END__
