package Transform::Alert::Input::POP3;

our $VERSION = '1.00'; # VERSION
# ABSTRACT: Transform alerts from POP3 messages

use sanity;
use Moo;
use MooX::Types::MooseLike::Base qw(Str Int ArrayRef HashRef InstanceOf Maybe);

use Net::POP3;
use Email::MIME;
use List::AllUtils 'first';

with 'Transform::Alert::Input';

# Stolen from connopts
has username => (
   is       => 'ro',
   isa      => Str,
   required => 1,
);
has password => (
   is       => 'ro',
   isa      => Str,
   required => 1,
);

has _conn => (
   is        => 'rw',
   isa       => Maybe[InstanceOf['Net::POP3']],
   lazy      => 1,
   default   => sub {
      my $self = shift;
      Net::POP3->new( %{$self->connopts} ) || do {
         $self->log->error('POP3 New failed: '.$@);
         return;
      };
   },
   predicate => 1,
   clearer   => 1,
);
has _list => (
   is        => 'rw',
   isa       => ArrayRef[Int],
   predicate => 1,
   clearer   => 1,
);

around BUILDARGS => sub {
   my ($orig, $self) = (shift, shift);
   my $hash = shift;
   $hash = { $hash, @_ } unless ref $hash;

   $hash->{username} = delete $hash->{connopts}{username};
   $hash->{password} = delete $hash->{connopts}{password};

   # Net::POP3 is a bit picky about its case-sensitivity
   foreach my $keyword (qw{ Host ResvPort Timeout Debug }) {
      $hash->{connopts}{$keyword} = delete $hash->{connopts}{lc $keyword} if (exists $hash->{connopts}{lc $keyword});
   }

   $orig->($self, $hash);
};

sub open {
   my $self = shift;
   my $pop  = $self->_conn ||
      # maybe+default+error still creates an undef attr, which would pass an 'exists' check on predicate
      do { $self->_clear_conn; return; };

   unless ( $pop->login($self->username, $self->password) ) {
      $self->log->error('POP3 Login failed: '.$pop->message);
      return;
   }

   my $msgnums = $pop->list;
   $self->_list([
      sort { $a <=> $b } keys %$msgnums
   ]);

   return 1;
}

sub opened {
   my $self = shift;
   return $self->_has_conn && $self->_conn->opened;
}

sub get {
   my $self = shift;
   my $num = shift @{$self->_list};
   my $pop = $self->_conn;

   my $amsg = $pop->get($num);
   unless ($amsg) {
      $self->log->error('Error grabbing POP3 message #'.$num.': '.$pop->message);
      return;
   }
   $pop->delete($num);

   my $msg = join '', @$amsg;
   $msg =~ s/\r//g;
   my $pmsg = Email::MIME->new($msg);
   my $body = eval { $pmsg->body_str } || do {
      my $part = first { $_ && $_->content_type =~ /^text\/plain/ } $pmsg->parts;
      $part ? $part->body_str : $pmsg->body_raw;
   };
   $body =~ s/\r//g;
   my $hash = {
      $pmsg->header_obj->header_pairs,
      BODY => $body,
   };

   return (\$msg, $hash);
}

sub eof {
   my $self = shift;
   return not ($self->_has_list and @{$self->_list});
}

sub close {
   my $self = shift;
   my $pop  = $self->_conn;

   $pop->quit if $self->opened;
   $self->_clear_list;
   $self->_clear_conn;
   return 1;
}

42;

__END__

=pod

=encoding utf-8

=head1 NAME

Transform::Alert::Input::POP3 - Transform alerts from POP3 messages

=head1 SYNOPSIS

    # In your configuration
    <Input test>
       Type      POP3
       Interval  60  # seconds (default)
 
       <ConnOpts>
          Username  bob
          Password  mail4fun
 
          # See Net::POP3->new
          Host     mail.foobar.org
          Port     110  # default
          Timeout  120  # default
       </ConnOpts>
       # <Template> tags...
    </Input>

=head1 DESCRIPTION

This input type will read a POP3 mailbox and process each message through the input template engine.  If it finds a match, the results of the
match are sent to one or more outputs, depending on the group configuration.

See L<Net::POP3> for a list of the ConnOpts section parameters.  The C<<< Username >>> and C<<< Password >>> options are included in this set, but not used
in the POP3 object's construction.

=head1 OUTPUTS

=head2 Text

Full text of the raw message, including headers.  All CRs are stripped.

=head2 Preparsed Hash

    {
       # Header pairs, as per Email::Simple::Header
       Email::Simple->new($msg)->header_obj->header_pairs,
 
       # decoded via Email::MIME->new($msg)
       # $pmsg->body_str, or body_str of the first text/plain part (if it croaks), or $pmsg->body_raw
       # (all \r are stripped)
       BODY => $str,
    }

=head1 CAVEATS

Special care should be made when using input templates on raw email messages.  For one, header order may change, which is difficult to
manage with REs.  For another, the message is probably MIME-encoded and would contain 80-character splits.  Use of Mungers here is B<highly>
recommended.

All messages are deleted from the system, whether it was matched or not.  If you need to save your messages, you should consider using
L<IMAP|Transform::Alert::Input::IMAP>.

The raw message isn't kept for the Munger.  If you really need it, you can implement an input RE template of C<<< (?<RAWMSG>[\s\S]+) >>>, and parse
out the email message yourself.

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
