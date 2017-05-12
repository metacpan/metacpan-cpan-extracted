%typemap = (
  'Fault/detail' => 'ZCS::Admin::Types::FaultDetail',
  'Fault/detail/Error' => 'ZCS::Admin::Types::FaultDetailError',
  'Fault/detail/Error/Code' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
  'Fault/detail/Error/Trace' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
  'context' => 'ZCS::Admin::Elements::context',
  'context/authToken' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
  'context/sessionId' => 'ZCS::Admin::Types::sessionId',
  'context/account' => 'ZCS::Admin::Types::AccountSpecifier',
  'context/change' => 'ZCS::Admin::Types::ChangeSpecifier',
  'context/targetServer' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
  'context/userAgent' => 'ZCS::Admin::Types::UserAgentSpecifier',
  'context/dl' => 'ZCS::Admin::Types::GetDlSpecifier',
);
