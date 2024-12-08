use Test2::V0;
use Test2::Require::Module 'Type::Tiny', '2.000000';
use Test2::Require::Module 'Email::Valid', '1.191';

package Customer {
    use Exporter 'import';

    use Types::Common -types;
    use Email::Valid;

    use kura Name  => StrLength[1, 255];
    use kura Email => sub { Email::Valid->address($_[0]) };

    use kura UnverifiedCustomer => Dict[ name => Str, email => Str ];
    use kura VerifiedCustomer   => Dict[ name => Name, email => Email ];
}

package Service {
    use Customer qw(VerifiedCustomer);

    sub send_email {
        my $customer = shift;

        unless (VerifiedCustomer->check($customer)) {
            return 'Invalid customer';
        }

        return "Email sent to $customer->{name} <$customer->{email}>";
    }
}

like (
    Service::send_email({ name => 'kobaken', email => 'kobaken@example.com' }),
    qr/Email sent to kobaken/
);

done_testing;
