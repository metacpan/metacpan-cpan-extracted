package Web::Components::Role::Email;

use 5.010001;
use namespace::autoclean;
use version; our $VERSION = qv( sprintf '0.3.%d', q$Rev: 1 $ =~ /\d+/gmx );

use Email::MIME;
use Encode                     qw( encode );
use File::DataClass::Constants qw( EXCEPTION_CLASS TRUE );
use File::DataClass::Functions qw( ensure_class_loaded is_hashref );
use File::DataClass::IO;
use MIME::Types;
use Scalar::Util               qw( blessed weaken );
use Try::Tiny;
use Unexpected::Functions      qw( Unspecified throw );
use Moo::Role;

requires qw( config log );

with 'Web::Components::Role::TT';

# Private subroutines
my $_add_attachments = sub {
   my ($args, $email) = @_;

   my $types = MIME::Types->new( only_complete => TRUE );
   my $part  = Email::MIME->create
      ( attributes => $email->{attributes}, body => delete $email->{body} );

   $email->{parts} = [ $part ];

   for my $name (sort keys %{ $args->{attachments} }) {
      my $path = io( $args->{attachments}->{ $name } )->binary->lock;
      my $mime = $types->mimeTypeOf( my $file = $path->basename );
      my $attr = { content_type => $mime->type,
                   encoding     => $mime->encoding,
                   filename     => $file,
                   name         => $name };

      $part = Email::MIME->create( attributes => $attr, body => $path->all );
      push @{ $email->{parts} }, $part;
   }

   return;
};

my $_make_f = sub {
   my ($obj, $f) = @_; weaken $obj; return sub { $obj->$f( @_ ) };
};

my $_stash_functions = sub {
   my ($self, $obj, $stash, $funcs) = @_; defined $obj or return;

   $funcs //= []; $funcs->[ 0 ] or push @{ $funcs }, 'loc';

   for my $f (@{ $funcs }) { $stash->{ $f } = $_make_f->( $obj, $f ) }

   return;
};

my $_get_email_body = sub {
   my ($self, $args) = @_; my $obj = delete $args->{subprovider};

   exists $args->{body} and defined $args->{body} and return $args->{body};

   $args->{template} or throw Unspecified, [ 'template' ];

   my $stash = $args->{stash} //= {}; $stash->{page} //= {};

   $stash->{page}->{layout} //= $args->{template};

   $_stash_functions->( $self, $obj, $stash, $args->{functions} );

   return $self->render_template( $stash );
};

my $_create_email = sub {
   my ($self, $args) = @_; $args->{email} and return $args->{email};

   my $conf     = $self->config;
   my $attr     = $conf->can( 'email_attr' ) ? $conf->email_attr : {};
   my $email    = { attributes => { %{ $attr }, %{ $args->{attributes} // {}}}};
   my $from     = $args->{from} or throw Unspecified, [ 'from' ];
   my $to       = $args->{to  } or throw Unspecified, [ 'to'   ];
   my $encoding = $email->{attributes}->{charset};
   my $subject  = $args->{subject} // 'No subject';

   try   { $subject = encode( 'MIME-Header', $subject, TRUE ) }
   catch { throw 'Cannot encode subject as MIME-Header: [_1]', [ $_ ] };

   $email->{header} = [ From => $from, To => $to, Subject => $subject ];
   $email->{body  } = $_get_email_body->( $self, $args );

   try   {
      $encoding and $email->{body} = encode( $encoding, $email->{body}, TRUE );
   }
   catch { throw 'Cannot encode body as [_1]: [_2]', [ $encoding, $_ ] };

   exists $args->{attachments} and $_add_attachments->( $args, $email );

   return Email::MIME->create( %{ $email } );
};

my $_transport_email = sub {
   my ($self, $args) = @_; $args->{email} or throw Unspecified, [ 'email' ];

   my $attr = {}; my $conf = $self->config;

   $conf->can( 'transport_attr' ) and $attr = { %{ $conf->transport_attr } };

   exists $args->{transport_attr}
      and $attr = { %{ $attr }, %{ $args->{transport_attr} } };
   exists $args->{host} and $attr->{host} = $args->{host};

   $attr->{host} //= 'localhost'; my $class = delete $attr->{class};

   $class = $args->{mailer} // $class // 'SMTP';

   if ('+' eq substr $class, 0, 1) { $class = substr $class, 1 }
   else { $class = "Email::Sender::Transport::${class}" }

   ensure_class_loaded $class;

   my $mailer    = $class->new( $attr );
   my $send_args = { from => $args->{from}, to => $args->{to} };
   my $result;

   try   { $result = $mailer->send( $args->{email}, $send_args ) }
   catch { throw $_ };

   $result->can( 'failure' ) and throw $result->message;

   (blessed $result and $result->isa( 'Email::Sender::Success' ))
      or throw 'Send failed: [_1]', [ $result ];

   return ($result->can( 'message' ) and defined $result->message
           and length $result->message) ? $result->message : 'OK Message sent';
};

# Public methods
sub send_email {
   my ($self, @args) = @_;

   defined $args[ 0 ] or throw Unspecified, [ 'email args' ];

   my $args = (is_hashref $args[ 0 ]) ? $args[ 0 ] : { @args };

   $args->{email} = $_create_email->( $self, $args );

   return $_transport_email->( $self, $args );
}

sub try_to_send_email {
   my ($self, @args) = @_; my $res;

   try   { $res = $self->send_email( @args ) }
   catch { $self->log->error( $res = $_ ) };

   return $res;
}

1;

__END__

=pod

=encoding utf-8

=begin html

<a href="https://travis-ci.org/pjfl/p5-web-components-role-email"><img src="https://travis-ci.org/pjfl/p5-web-components-role-email.svg?branch=master" alt="Travis CI Badge"></a>
<a href="https://roxsoft.co.uk/coverage/report/web-components-role-email/latest"><img src="https://roxsoft.co.uk/coverage/badge/web-components-role-email/latest" alt="Coverage Badge"></a>
<a href="http://badge.fury.io/pl/Web-Components-Role-Email"><img src="https://badge.fury.io/pl/Web-Components-Role-Email.svg" alt="CPAN Badge"></a>
<a href="http://cpants.cpanauthors.org/dist/Web-Components-Role-Email"><img src="http://cpants.cpanauthors.org/dist/Web-Components-Role-Email.png" alt="Kwalitee Badge"></a>

=end html

=head1 Name

Web::Components::Role::Email - Role for sending emails

=head1 Synopsis

   use Moo;

   with 'Web::Components::Role::Email';

   my $post = { attributes      => {
                   charset      => 'UTF-8',
                   content_type => 'text/html' },
                body            => 'Message body text',
                from            => 'Senders email address',
                host            => 'localhost',
                mailer          => 'SMTP',
                subject         => 'Email subject string',
                to              => 'Recipients email address' };

   $recipient = $self->send_email( $post );

=head1 Description

Supports multiple transports, attachments and multilingual templates for
message bodies

=head1 Configuration and Environment

Defines no attributes

=head1 Subroutines/Methods

=head2 send_email

   $result_message = $self->send_email( @args );

Sends emails. Returns the recipient address, throws on error. The
C<@args> can be a list of keys and values or a hash reference. The attributes
defined are;

=over 3

=item C<attachments>

A hash reference whose key / value pairs are the attachment name and path
name. Encoding and content type are derived from the file name
extension

=item C<attributes>

A hash reference that is applied to the email when it is created. Typical keys
are; C<content_type> and C<charset>. See L<Email::MIME>. This is merged onto
the C<email_attr> configuration hash reference if it exists

=item C<body>

Text for the body of the email message

=item C<from>

Email address of the sender

=item C<host>

Which host should send the email. Defaults to C<localhost>

=item C<mailer>

Which mailer should be used to send the email. Defaults to C<SMTP>

=item C<stash>

Hash reference used by the template rendering to supply values for variable
replacement

=item C<subject>

Subject string. Defaults to I<No Subject>

=item C<subprovider>

If this object reference exists and an email is generated from a template then
it is expected to provide a C<loc> function which will be make callable from
the template

=item C<functions>

A list of functions provided by the L</subprovider> object. This list of
functions will be bound into the stash instead of the default C<loc> function

=item C<template>

If it exists then the template is rendered and used as the body contents.
See the L<layout|Web::Components::Role::TT/templates> attribute

=item C<to>

Email address of the recipient

=item C<transport_attr>

A hash reference passed to the transport constructor. This is merged in
with the C<transport_attr> configuration hash reference if it exists

=back

=head2 C<try_to_send_email>

Just like L</send_email> but logs at the error level instead of throwing

=head1 Diagnostics

None

=head1 Dependencies

=over 3

=item L<Email::MIME>

=item L<Email::Sender>

=item L<Encode>

=item L<MIME::Types>

=item L<Moo>

=item L<Unexpected>

=item L<Web::Components::Role::TT>

=back

=head1 Incompatibilities

There are no known incompatibilities in this module

=head1 Bugs and Limitations

There are no known bugs in this module. Please report problems to
http://rt.cpan.org/NoAuth/Bugs.html?Dist=Web-Components-Role-Email.
Patches are welcome

=head1 Acknowledgements

Larry Wall - For the Perl programming language

=head1 Author

Peter Flanigan, C<< <pjfl@cpan.org> >>

=head1 License and Copyright

Copyright (c) 2017 Peter Flanigan. All rights reserved

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself. See L<perlartistic>

This program is distributed in the hope that it will be useful,
but WITHOUT WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE

=cut

# Local Variables:
# mode: perl
# tab-width: 3
# End:
# vim: expandtab shiftwidth=3:
