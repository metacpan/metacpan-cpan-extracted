package WWW::Google::Contacts::Type::Base;
{
    $WWW::Google::Contacts::Type::Base::VERSION = '0.39';
}

use Moose;

extends 'WWW::Google::Contacts::Base';

sub search_field {
    return undef;
}

no Moose;
__PACKAGE__->meta->make_immutable;
1;
__END__
