package VUser::Google::EmailSettings;
use warnings;
use strict;

# Copyright (C) 2009 Randy Smith, perlstalker at vuser dot org

our $VERSION = '0.1.0';

use Moose;

## Members
# Provisioning API
has 'user' => (is => 'rw',
	       required => 1,
	       isa => 'Str'
	       );

has 'google' => (is => 'rw',
		 isa => 'VUser::Google::ApiProtocol',
		 required => 1
		 );

has 'base_url' => (is => 'rw', isa => 'Str');

# Turn on deugging
has 'debug' => (is => 'rw', default => 0);

## Methods
sub CreateLabel {
}

sub CreateFilter {
}

sub CreateSendAsAlias {
}

sub UpdateWebClip {
}

sub UpdateForwarding {
}

sub UpdatePOP {
}

sub UpdateIMAP {
}

sub UpdateVacationResponder {
}

sub UpdateSignature {
}

sub UpdateLanguage {
}

sub UpdateGeneral {
}

## Util
#print out debugging to STDERR if debug is set
sub dprint
{
    my $self = shift;
    my $text = shift;
    my @args = @_;
    if( $self->debug and defined ($text) ) {
	print STDERR sprintf ("$text\n", @args);
    }
}


no Moose; # Clean up after the moose.

1;

__END__

=head1 NAME

VUser::Google::ProvisioningAPI::EmailSettings - Manage user email settings in Google Apps for Your Domain.

=head1 SYNOPSIS

 use VUser::Google::ApiProtocol::V2_0;
 use VUser::Google::EmailSettings::V2_0;
 
 ## Create a new connection
 my $google = VUser::Google::ApiProtocol::V2_0->new(
     domain   => 'your.google-apps-domain.com',
     admin    => 'admin_user',
     password => 'admin_user password',
 );
 
 my $settings = VUser::Google::EmailSettings::V2_0->new(
     google => $google,
     user   => 'username',
 );
 
 ## Create a new label
 $settings->CreateLabel('label' => 'newLabel');
 
 ## Create a new filter
 $settings->CreateFilter(
     'from'          => 'sender@example.com',
     'label'         => 'newLabel',
     'shouldArchive' => 1,
 );
 
 ## Create a new send-as alias
 $settings->CreateSendAsAlias(
     'name'     => 'Tech Support',
     'address'  => 'support@example.com',
 );
 
 ## Update the user's web clip setting
 $settings->UpdateWebClip('enable' => 0); # Turn off
 $settings->UpdateWebClip('enable' => 1); # Turn on
 
 ## Update forwarding
 $settings->UpdateForwarding(
     'enable'    => 1,
     'forwardTo' => 'someoneelse@example.com',
     'action'    => 'KEEP',
 );
 
 ## Update POP3 settings
 $settings->UpdatePOP(
     'enable'    => 1,
     'enableFor' => 'MAIL_FROM_NOW_ON',
     'action'    => 'KEEP',
 );
 
 ## Update IMAP settings
 $settings->UpdateIMAP('enable' => 1);
 
 ## Update user's vacation message
 $settings->UpdateVacationResponder(
     'enable'   => 1,
     'subject'  => "I'm not here right now",
     'message'  => "I've lost my mind and have gone to search for it.",
     'contactsOnly' => 1,
 );
 
 ## Update the user's signature
 $settings->UpdateSignature(
     'signature' => 'Joe Cool
555-5555'
 );
 $settings->UpdateSignature('signature' => ''); # clear sig
 
 ## Update the display language
 $settings->UpdateLanguage('language' => 'en-US');
 
 ## Update the user's general settings
 $settings->UpdateGeneral('pageSize' => 50);
 
 # You can set more than one at a time
 $settings->UpdateGeneral(
     'arrows'    => 1,
     'shortcuts' => 0,
 );

=head1 DESCRIPTION

This is the base class for the Email Settings API. It is not meant to be
used directly. Instead see the sub class for each version of the email
settings API.

=head1 MEMBERS

=head2 Read-write members

=over

=item base_url

The C<base_url> for the Email settings API calls. For example,
I<https://apps-apis.google.com/a/feeds/emailsettings/2.0/>.

=item debug

Turn on debugging output.

=item google

A VUser::Google::ApiProtocol object.

=item user

The user name of user to modify.

=back

=head1 METHODS

All of the calls to the Google API take a hash with the options
specified by Google. The keys for the hash and what is expected are listed
below. Specific versions my use different keys. In general, the keys will
match the names of the attributes in the API docs. See the docs for the
API version you are using for any differences.

B<Note:> Values that are "true"/"false" are set using Perl values for true
and false, i.e. zero for false and anything else for true.

=head2 new (%defaults)

Create a new EmailSettings object. Any read-write member may be set in the
call to C<new()>.

=head2 dprint ($message)

Prints C<$message> to STDERR if C<debug> is set to a true value.

=head2 CreateLabel (%options)

Create a new label.

=over

=item label

The label to create in Google Mail.

=back

=head2 CreateFilter

Create a new mail filter.

=over

=item from

The email must come from this address in order to be filtered.

=item to

The email must be sent to this address in order to be filtered.

=item subject

A string the email must have in its subject line to be filtered.

=item hasTheWord

A string the email can have anywhere in it's subject or body.

=item doesNotHaveTheWord

A string that the email cannot have anywhere in its subject or body.

=item hasAttachment

A boolean representing whether or not the email contains an attachment.

=item label

The name of the label to apply if a message matches the specified filter criteria.

=item shouldMarkAsRead

Whether to automatically mark the message as read if it matches the specified filter criteria

=item shouldArchive

Whether to automatically move the message to "Archived" state if it matches the specified filter criteria.

=back

=head2 CreateSendAsAlias

Create a gmail "Send-as alias."

=over

=item name

The name that will appear in the "From" field for this user.

=item address

The email address that appears as the origination address for emails sent by this user.

=item replyTo

I<(Optional)> If set, this address will be included as the reply-to address in emails sent using the alias.

=item makeDefault

I<(Optional)> If set to true, this alias will be become the new default alias to send-as for this user.

=back

=head2 UpdateWebClip

Update the user's "web clip" setting.

=over

=item enable

Whether to enable showing Web clips.

=back

=head2 UpdateForwarding

Update gmail forwarding settings.

=over

=item enable

Whether to enable forwarding of incoming mail.

=item forwardTo

The email will be forwarded to this address.

=item action

What Google Mail should do with its copy of the email after forwarding it on.

B<Allowed values:> "KEEP" (in inbox), "ARCHIVE", or "DELETE" (send to trash)

=back

=head2 UpdatePOP

Update the user's POP3 settings.

=over

=item enable

Whether to enable POP3 access.

=item enableFor

Whether to enable POP3 for all mail, or mail from now on.

B<Allowed values:> "ALL_MAIL", "MAIL_FROM_NOW_ON"

=item action

What Google Mail should do with its copy of the email after it is retrieved using POP.

B<Allowed values:> "KEEP" (in inbox), "ARCHIVE", or "DELETE" (send to trash)

=back

=head2 UpdateIMAP

Update the user's IMAP settings.

=over

=item enable

Whether to enable IMAP access.

=back

=head2 UpdateVactionResponder

Update the user's vacation auto-responder.

=over

=item enable

Whether to enable the vacation responder.

=item subject

The subject line of the vacation responder autoresponse.

=item message

The message body of the vacation responder autoresponse.

=item contactsOnly

Whether to only send the autoresponse to known contacts.

=back

=head2 UpdateSignature

Update the user's signature.

=over

=item signature

The signature to be appended to outgoing messages. Set the signature to
C<''> (the empty string) to clear the signature.

=back

=head2 UpdateLanguage

Update the display language.

=over

=item language

Google Mail's display language. This should be a language tag defined in
RFC 3066. See http://code.google.com/apis/apps/email_settings/developers_guide_protocol.html#GA_email_language_tags for a list of supported languages.

=back

=head2 UpdateGeneral

Update the user's general settings.

=over

=item pageSize

The number of conversations to be shown per page.

B<Allowed values:> 25, 50, 100

=item shortcuts

Whether to enable keyboard shortcuts.

=item arrows

Whether to display arrow-shaped personal indicators next to emails that were sent specifically to the user.

=item snippets

Whether to display snippets of messages in the inbox and when searching.

=item unicode

Whether to use UTF-8 (unicode) encoding for all outgoing messages, instead of the default text encoding.

=back

=head1 SEE ALSO

L<VUser::Google::EmailSettings::V2_0>, L<VUser::Google::ApiProtocol>

=over 4

=item Google Email Settings API

http://code.google.com/apis/apps/email_settings/developers_guide_protocol.html

=back

=head1 BUGS

Report bugs at http://code.google.com/p/vuser/issues/list.

=head1 AUTHOR

Randy Smith, perlstalker at vuser dot net

=head1 COPYRIGHT AND LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.5 or,
at your option, any later version of Perl 5 you may have available.

If you make useful modification, kindly consider emailing then to me for inclusion in a future version of this module.

=cut
