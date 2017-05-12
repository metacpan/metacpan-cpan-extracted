package WebService::SOS::Exception;
use XML::Rabbit::Root 0.1.0;

has 'exception' => (
    is         => 'ro',
    isa        => 'Bool',
    lazy_build => 1,
);

sub _build_exception {
    my ($self) = @_;
    return if $self->exceptionCode eq '';
    return 1;
}

has_xpath_value 'exceptionCode' => '/ows:ExceptionReport/ows:Exception/@exceptionCode';
has_xpath_value       'locator' => '/ows:ExceptionReport/ows:Exception/@locator';
has_xpath_value 'exceptionText' => '/ows:ExceptionReport/ows:Exception/ows:ExceptionText';

finalize_class();
