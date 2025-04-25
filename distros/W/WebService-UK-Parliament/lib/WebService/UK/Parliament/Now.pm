package WebService::UK::Parliament::Now;

use Mojo::Base 'WebService::UK::Parliament::Base';

has public_url => "https://now-api.parliament.uk/swagger/v1/swagger.json";

has private_url => "swagger/now-api.json";

has base_url => 'https://now-api.parliament.uk/';

1;

__END__

=head1 NAME

WebService::UK::Parliament::Now - Query the UK Parliament Now API

=head1 VERSION

Version 1.01

=cut

=head1 SYNOPSIS

	use WebService::UK::Parliament::Now;

	my $client = WebService::UK::Parliament::Now->new();

	my $data = $client->$endpoint($params);

=cut

=head1 DESCRIPTION

The following documentation is automatically generated using the UK Parliament OpenAPI specification.

Get data from the annunciator system.

=cut

=head1 Sections

=cut

=head2 Message

=cut

=head3 getMessagemessagecurrent

Return the current message by annunciator type

=cut

=head4 Method

get

=cut

=head4 Path

/api/Message/message/{annunciator}/current

=cut

=head4 Parameters

=over

=item annunciator

Current message by annunciator

string

CommonsMain
LordsMain
Security

=back

=cut

=head3 getMessagemessage

Return the most recent message by annunciator after date time specified

=cut

=head4 Method

get

=cut

=head4 Path

/api/Message/message/{annunciator}/{date}

=cut

=head4 Parameters

=over

=item annunciator

Message by annunciator type

string

CommonsMain
LordsMain
Security

=item date

First message after date time specified

string

format: date-time

=back

=cut

=head1 AUTHOR

LNATION, C<< <thisusedtobeanemail at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-webservice-uk-parliament at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=WebService-UK-Parliament>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WebService::UK::Parliament


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=WebService-UK-Parliament>

=item * Search CPAN

L<https://metacpan.org/release/WebService-UK-Parliament>

=back

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

The first ticehurst bathroom experience

This software is Copyright (c) 2022->2025 by LNATION.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
