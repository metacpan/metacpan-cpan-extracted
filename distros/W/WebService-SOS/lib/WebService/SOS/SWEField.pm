package WebService::SOS::SWEField;
use XML::Rabbit;

has_xpath_value name => './@name';
has_xpath_value quantity_definition => './swe:Quantity/@definition';
has_xpath_value time_definition => './swe:Time/@definition';
has_xpath_value uom => './swe:Quantity/swe:uom/@code';

finalize_class();
