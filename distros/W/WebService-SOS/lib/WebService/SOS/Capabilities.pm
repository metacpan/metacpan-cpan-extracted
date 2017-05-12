package WebService::SOS::Capabilities;
use XML::Rabbit::Root 0.1.0;

# Service Identification

has_xpath_value              Title => '/sos:Capabilities/ows:ServiceIdentification/ows:Title';
has_xpath_value           Abstract => '/sos:Capabilities/ows:ServiceIdentification/ows:Abstract';
has_xpath_value        ServiceType => '/sos:Capabilities/ows:ServiceIdentification/ows:ServiceType';
has_xpath_value ServiceTypeVersion => '/sos:Capabilities/ows:ServiceIdentification/ows:ServiceTypeVersion';
has_xpath_value               Fees => '/sos:Capabilities/ows:ServiceIdentification/ows:Fees';
has_xpath_value  AccessConstraints => '/sos:Capabilities/ows:ServiceIdentification/ows:AccessConstraints';
has_xpath_value_list      Keywords => '/sos:Capabilities/ows:ServiceIdentification/ows:Keywords/ows:Keyword';


# Service Provider Description

has_xpath_value          ProviderName => '/sos:Capabilities/ows:ServiceProvider/ows:ProviderName';
has_xpath_value          ProviderSite => '/sos:Capabilities/ows:ServiceProvider/ows:ProviderSite/@xlink:href';
has_xpath_value        IndividualName => '/sos:Capabilities/ows:ServiceProvider/ows:ServiceContact/ows:IndividualName';
has_xpath_value          PositionName => '/sos:Capabilities/ows:ServiceProvider/ows:ServiceContact/ows:PositionName';
has_xpath_value                 Voice => '/sos:Capabilities/ows:ServiceProvider/ows:ServiceContact/ows:ContactInfo/ows:Phone/ows:Voice';
has_xpath_value         DeliveryPoint => '/sos:Capabilities/ows:ServiceProvider/ows:ServiceContact/ows:ContactInfo/ows:Address/ows:DeliveryPoint';
has_xpath_value                  City => '/sos:Capabilities/ows:ServiceProvider/ows:ServiceContact/ows:ContactInfo/ows:Address/ows:City';
has_xpath_value    AdministrativeArea => '/sos:Capabilities/ows:ServiceProvider/ows:ServiceContact/ows:ContactInfo/ows:Address/ows:AdministrativeArea';
has_xpath_value            PostalCode => '/sos:Capabilities/ows:ServiceProvider/ows:ServiceContact/ows:ContactInfo/ows:Address/ows:PostalCode';
has_xpath_value               Country => '/sos:Capabilities/ows:ServiceProvider/ows:ServiceContact/ows:ContactInfo/ows:Address/ows:Country';
has_xpath_value ElectronicMailAddress => '/sos:Capabilities/ows:ServiceProvider/ows:ServiceContact/ows:ContactInfo/ows:Address/ows:ElectronicMailAddress';


# Operations Metadata

has_xpath_object_list Operations => '/sos:Capabilities/ows:OperationsMetadata/ows:Operation' => 'WebService::SOS::Capabilities::Operation';


# Observation Offerings

has_xpath_object_list Offerings => '/sos:Capabilities/sos:Contents/sos:ObservationOfferingList/sos:ObservationOffering' => 'WebService::SOS::Capabilities::Offering';


finalize_class();
