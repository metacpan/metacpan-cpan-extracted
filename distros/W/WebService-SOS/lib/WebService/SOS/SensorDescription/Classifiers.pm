package WebService::SOS::SensorDescription::Classifiers;
use XML::Rabbit;

has_xpath_value       name => './@name';
has_xpath_value definition => './sml:Term/@definition';
has_xpath_value      value => './sml:Term/sml:value';

finalize_class();
