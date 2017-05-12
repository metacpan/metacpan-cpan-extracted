package WebService::SOS::SensorDescription;
use XML::Rabbit::Root 0.1.0;

add_xpath_namespace sml => 'http://www.opengis.net/sensorML/1.0.1';

has_xpath_value                    id => '/sml:SensorML/sml:member/sml:System/@gml:id';
has_xpath_value           description => '/sml:SensorML/sml:member/sml:System/gml:description';
has_xpath_value_list         keywords => '/sml:SensorML/sml:member/sml:System/sml:keywords/sml:KeywordList/sml:keyword';

has_xpath_object_list     identifiers => '/sml:SensorML/sml:member/sml:System/sml:identification/sml:IdentifierList/sml:identifier' => 'WebService::SOS::SensorDescription::Identifiers';

has_xpath_object_list     classifiers => '/sml:SensorML/sml:member/sml:System/sml:classification/sml:ClassifierList/sml:classifier' => 'WebService::SOS::SensorDescription::Classifiers';

has_xpath_value         beginPosition => '/sml:SensorML/sml:member/sml:System/sml:validTime/gml:TimePeriod/gml:beginPosition';
has_xpath_value           endPosition => '/sml:SensorML/sml:member/sml:System/sml:validTime/gml:TimePeriod/gml:endPosition';

has_xpath_value       characteristics => '/sml:SensorML/sml:member/sml:System/sml:characteristics';

has_xpath_value        individualName => '/sml:SensorML/sml:member/sml:System/sml:contact/sml:ResponsibleParty/sml:individualName';
has_xpath_value      organizationName => '/sml:SensorML/sml:member/sml:System/sml:contact/sml:ResponsibleParty/sml:organizationName';
has_xpath_value electronicMailAddress => '/sml:SensorML/sml:member/sml:System/sml:contact/sml:ResponsibleParty/sml:contactInfo/sml:address/sml:electronicMailAddress';
has_xpath_value        onlineResource => '/sml:SensorML/sml:member/sml:System/sml:contact/sml:ResponsibleParty/sml:contactInfo/@xlink:href';

has_xpath_value              location => '/sml:SensorML/sml:member/sml:System/sml:location/gml:Point/gml:coordinates';

has_xpath_object_list          fields => '/sml:SensorML/sml:member/sml:System/sml:outputs/sml:OutputList/sml:output/swe:DataArray/swe:elementType/swe:DataRecord/swe:field' => 'WebService::SOS::SWEField';

finalize_class();
