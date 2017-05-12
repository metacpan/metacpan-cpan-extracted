package Win32::SqlServer::DTS::Task::SendEmail;

=head1 NAME

Win32::SqlServer::DTS::Task::SendEmail - a subclass of Win32::SqlServer::DTS::Task that represents a DTSSendMailTask object.

=head1 SYNOPSIS

    use warnings;
    use strict;
    use Win32::SqlServer::DTS::Application;
    use Test::More;
    use XML::Simple;

    my $xml    = XML::Simple->new();
    my $config = $xml->XMLin('test-config.xml');

    my $app = Win32::SqlServer::DTS::Application->new( $config->{credential} );

    my $package = $app->get_db_package(
        {
            id               => '',
            version_id       => '',
            name             => $config->{package},
            package_password => ''
        }
    );

	my $iterator = $package->get_send_emails();

    while ( my $send_mail = $iterator->() ) {

        print $send_mail->to_string, "\n";

    }


=head1 DESCRIPTION

C<Win32::SqlServer::DTS::Task::SendEmail> represents a DTS SendMail task object.

=head2 EXPORT

Nothing.

=cut

use strict;
use warnings;
use Carp;
use base qw(Win32::SqlServer::DTS::Task Class::Accessor);
use Hash::Util qw(lock_keys);
our $VERSION = '0.13'; # VERSION

=head2 METHODS

All methods from L<Win32::SqlServer::DTS::Task|Win32::SqlServer::DTS::Task> are also available.

=cut

__PACKAGE__->follow_best_practice;
__PACKAGE__->mk_ro_accessors(
    qw(message_text cc_line attachments profile_password profile subject to_line)
);

our %attrib_convertion = (
    cc_line          => 'CCLine',
    attachments      => 'FileAttachments',
    message_text     => 'MessageText',
    profile_password => 'Password',
    profile          => 'Profile',
    save_sent        => 'SaveMailInSentItemsFolder',
    is_nt_service    => 'IsNTService',
    subject          => 'Subject',
    to_line          => 'ToLine'
);

=head3 new

Overrides the superclass C<Win32::SqlServer::DTS::Task> method C<new> to define the following attributes:

=over

=item *

cc_line

=item *

attachments

=item *

message_text

=item *

profile_password

=item *

profile

=item *

save_sent

=item *

is_nt_service

=item *

subject

=item *

to_line

=back

=cut

sub new {

    my $class = shift;
    my $self  = $class->SUPER::new(@_);

    my $sibling = $self->get_sibling();

    foreach my $attrib ( keys(%attrib_convertion) ) {

        $self->{$attrib} = $sibling->{ $attrib_convertion{$attrib} };
    }

    lock_keys( %{$self} );

    return $self;

}

=head3 is_nt_service

Returns true or false (1 or 0) whether the caller is a Microsoft Windows NT 4.0 or Microsoft Windows 2000 
Service. Returns true only if the program that calls the package Execute method is installed as a 
Windows NT 4.0 or Windows 2000 Service.

=cut

sub is_nt_service {

    my $self = shift;
    return $self->{is_nt_service};

}

=head3 save_sent

Returns true or false (1 or 0) whether to save outgoing e-mail messages in the Sent Items folder.

=cut

sub save_sent {

    my $self = shift;
    return $self->{save_sent};

}

=head3 to_string

Overrides superclass C<Win32::SqlServer::DTS::Task> method C<to_string> to return strings for all defined attributes
of the object.

=cut

sub to_string {

    my $self = shift;

    my $properties_string =
        "\tName: "
      . $self->get_name
      . "\r\n\tDescription: "
      . $self->get_description
      . "\r\n\tCC line: "
      . $self->get_cc_line
      . "\r\n\tAttachments: "
      . $self->get_attachments
      . "\r\n\tIs a NT service? "
      . ( ( $self->is_nt_service ) ? 'true' : 'false' )
      . "\r\n\tMessage:\r\n"
      . $self->get_message_text
      . "\r\n\tProfile password: "
      . $self->get_profile_password
      . "\r\n\tProfile: "
      . $self->get_profile
      . "\r\n\tSave message in sent folder? "
      . ( ( $self->save_sent ) ? 'true' : 'false' )
      . "\r\n\tSubject: "
      . $self->get_subject
      . "\r\n\tTo line: "
      . $self->get_to_line;

    return $properties_string;

}

1;

__END__

=head3 get_message_text

Returns a string with the message text defined, including new line characters.

=head3 get_cc_line

Returns a string with the email addresses included in the I<CC> field of the email. Email are separated by semicolons.

=head3 get_attachments

Returns the complete pathname and filename of the attachments, separated by semicolons.

=head3 get_profile_password

Returns a string with the defined profile password, if used.

=head3 get_profile

Returns a string with the profile being used to send the email.

=head3 get_subject

Returns a string with the subject of the email

=head3 get_to_line

Returns a string with all email addresses defined in the I<To> field of the email. Addresses are separated by
semicolon characters.

=head1 CAVEATS

This class is incomplete. The methods defined for the original SendMailTask class are not defined here, except for
those used as get/setter methods.

=head1 SEE ALSO

=over

=item *
L<Win32::OLE> at C<perldoc>.

=item *
MSDN on Microsoft website and MS SQL Server 2000 Books Online are a reference about using DTS'
object hierarchy, but one will need to convert examples written in VBScript to Perl code.

=back

=head1 AUTHOR

Alceu Rodrigues de Freitas Junior, E<lt>arfreitas@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Alceu Rodrigues de Freitas Junior

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
