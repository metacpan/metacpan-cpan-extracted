package WebService::SOS::Capabilities::Offering;
use XML::Rabbit;

has_xpath_value                    name => './gml:name';
has_xpath_value             description => './gml:description';
has_xpath_value             lowerCorner => './gml:boundedBy/gml:Envelope/gml:lowerCorner';
has_xpath_value             upperCorner => './gml:boundedBy/gml:Envelope/gml:upperCorner';
has_xpath_value               beginTime => './sos:eventTime/gml:TimePeriod/gml:beginPosition';
has_xpath_value                 endTime => './sos:eventTime/gml:TimePeriod/gml:endPosition';
has_xpath_value               procedure => './sos:procedure/@xlink:href';
has_xpath_value       featureOfInterest => './sos:featureOfInterest/@xlink:href';
has_xpath_value          responseFormat => './sos:responseFormat';
has_xpath_value            responseMode => './sos:responseMode';
has_xpath_value_list observedProperties => './sos:observedProperty/@xlink:href';

finalize_class();
