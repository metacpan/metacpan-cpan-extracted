package WebService::SOS::Capabilities::Parameter;
use XML::Rabbit;

has_xpath_value name => './@name';
has_xpath_value_list AllowedValues => './ows:AllowedValues/ows:Value';

finalize_class();
