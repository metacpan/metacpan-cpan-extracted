package XML::Parser::ClinicalTrials::Study::Contact;
$XML::Parser::ClinicalTrials::Study::Contact::VERSION = '1.20150818';
use strict;
use warnings;

use XML::Rabbit;

has_xpath_value email     => './email';
has_xpath_value last_name => './last_name';
has_xpath_value role      => './role';
has_xpath_value phone     => './phone';
has_xpath_value phone_ext => './phone_ext';

finalize_class();
__END__
=pod

=head1 NAME

XML::Parser::ClinicalTrials::Study::Contact - XML representation of ClinicalTrials study contact data

=head1 SYNOPSIS and DESCRIPTION

See L<XML::Parser::ClinicalTrials::Study>.

=head1 ACCESSORS

Contact instances have several simple value accessors.

=head2 Value Accessors

These accessors provide simple values. When a value is not present in the XML
file, this accessor will return the empty string.

=over 4

=item * email

=item * last_name

=item * role

=item * phone

=item * phone_ext

=back

=head1 AUTHOR

chromatic E<lt>chromatic@cpan.orgE<gt>, sponsored by Golden Guru
(L<http://goldenguru.com/>).

=head1 LICENSE

This library is free software; you can redistribute it and/or modify it under
