package Transform::Alert::Output::Email;

our $VERSION = '1.00'; # VERSION
# ABSTRACT: Transform alerts to emails

use sanity;
use Moo;
use MooX::Types::MooseLike::Base qw(Str ConsumerOf);

use Email::Sender::Simple 'sendmail';
use Email::Abstract;
use Class::Load 'load_class';

use namespace::clean;

with 'Transform::Alert::Output';

has transport_class => (
   is      => 'ro',
   isa     => Str,
   default => sub { 'SMTP::Persistent' }
);

has _transport => (
   is        => 'rw',
   isa       => ConsumerOf['Email::Sender::Transport'],
   lazy      => 1,
   default   => sub {
      my $self = shift;
      
      # load the transport class
      my $class = 'Email::Sender::Transport::'.$self->transport_class;
      load_class $class;
      return $class->new( %{$self->connopts} );
   },
   predicate => 1,   
);

around BUILDARGS => sub {
   my ($orig, $self) = (shift, shift);
   my $hash = shift;
   $hash = { $hash, @_ } unless ref $hash;

   $hash->{transport_class} = delete $hash->{connopts}{transportclass} if exists $hash->{connopts}{transportclass};
   
   $orig->($self, $hash);
};

sub open   { shift->_transport; }
sub opened { shift->_has_transport; }

sub send {
   my ($self, $msg) = @_;
   my $email = Email::Abstract->new($msg);  # string ref
   
   unless (eval { sendmail($email, { transport => $self->_transport }) }) {
      $self->log->error('Error sending Email message: '.$@);
      return;
   }
   return 1;
}

sub close { 1; }

42;

__END__

=pod

=encoding utf-8

=head1 NAME

Transform::Alert::Output::Email - Transform alerts to emails

=head1 SYNOPSIS

    # In your configuration
    <Output test>
       Type          Email
       TemplateFile  outputs/test.tt
 
       <ConnOpts>
          TransportClass  SMTP::Persistent  # default
 
          # See Email::Sender::Manual::QuickStart
          # and Email::Sender::Transport::<TransportClass>
          Host  mail.foobar.org
          Helo  TransformAlert
       </ConnOpts>
    </Output>

=head1 DESCRIPTION

This output type will send an email for each converted input.

See L<Email::Sender> for a list of the ConnOpts section parameters.  (Specifically, the appropriate transport class.)

If you didn't guess, the C<<< TransportClass >>> option maps to a C<<< Email::Sender::Transport::* >>> class.

=head1 CAVEATS

This class is persistent, keeping the Transport object until shutdown.  How that translates in terms of connections is dependent on the
Transport class chosen.  (In other words, the non-persistent SMTP transport class is still going to tear down the TCP connection before each
message sent.)

=head1 AVAILABILITY

The project homepage is L<https://github.com/SineSwiper/Transform-Alert/wiki>.

The latest version of this module is available from the Comprehensive Perl
Archive Network (CPAN). Visit L<http://www.perl.com/CPAN/> to find a CPAN
site near you, or see L<https://metacpan.org/module/Transform::Alert/>.

=head1 AUTHOR

Brendan Byrd <BBYRD@CPAN.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by Brendan Byrd.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
