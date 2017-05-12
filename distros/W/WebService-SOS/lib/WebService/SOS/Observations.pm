package WebService::SOS::Observations;
use XML::Rabbit::Root 0.1.0;

add_xpath_namespace 'ows' => 'http://www.opengis.net/ows/1.1';
add_xpath_namespace 'om' => 'http://www.opengis.net/om/1.0';

has_xpath_value description => './gml:description';
has_xpath_value name => './gml:name';

has_xpath_value             lowerCorner => './om:member/om:Observation/gml:boundedBy/gml:Envelope/gml:lowerCorner'; 
has_xpath_value             upperCorner => './om:member/om:Observation/gml:boundedBy/gml:Envelope/gml:upperCorner'; 
has_xpath_value               beginTime => './om:member/om:Observation/om:samplingTime/gml:TimePeriod/gml:beginPosition'; 
has_xpath_value                 endTime => './om:member/om:Observation/om:samplingTime/gml:TimePeriod/gml:endPosition'; 
has_xpath_value               procedure => './om:member/om:Observation/om:procedure/@xlink:href'; 
has_xpath_value_list observedProperties => './om:member/om:Observation/om:observedProperty/swe:CompositePhenomenon/swe:component/@xlink:href'; 
has_xpath_value       featureOfInterest => './om:member/om:Observation/om:featureOfInterest/@xlink:href';
has_xpath_value            elementCount => './om:member/om:Observation/om:result/swe:DataArray/swe:elementCount/swe:Count/swe:value';
has_xpath_value_list          fieldList => './om:member/om:Observation/om:result/swe:DataArray/swe:elementType/swe:DataRecord/swe:field/@name';
has_xpath_value          blockSeparator => './om:member/om:Observation/om:result/swe:DataArray/swe:encoding/swe:TextBlock/@blockSeparator';
has_xpath_value        decimalSeparator => './om:member/om:Observation/om:result/swe:DataArray/swe:encoding/swe:TextBlock/@decimalSeparator';
has_xpath_value          tokenSeparator => './om:member/om:Observation/om:result/swe:DataArray/swe:encoding/swe:TextBlock/@tokenSeparator';
has_xpath_value               allValues => './om:member/om:Observation/om:result/swe:DataArray/swe:values';

has_xpath_object_list fields => './om:member/om:Observation/om:result/swe:DataArray/swe:elementType/swe:DataRecord/swe:field' => 'WebService::SOS::SWEField';

has 'exception' => (
    is => 'ro',
    isa => 'Bool',
    default => 0,
);

has 'values' => (
    is => 'ro',
    isa => 'ArrayRef',
    lazy_build => 1,
);

sub _build_values {
    my $self = shift;
    my @valueBlocks = split $self->blockSeparator, $self->allValues;
    
    my @values;
    for my $valueBlock (@valueBlocks) {
        my @value = split $self->tokenSeparator, $valueBlock;
        my %fields;
        my $fieldnum = 0;
        for my $fieldval (@value) {
            my $fieldname = @{$self->fieldList}[$fieldnum];
            $fields{$fieldname} = $fieldval;
            $fieldnum++;
        }
        push @values, \%fields;
    }
    return \@values;
}

finalize_class();
