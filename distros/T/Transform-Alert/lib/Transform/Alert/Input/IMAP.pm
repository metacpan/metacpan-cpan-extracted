package Transform::Alert::Input::IMAP;

our $VERSION = '1.00'; # VERSION
# ABSTRACT: Transform alerts from IMAP messages

use sanity;
use Moo;
use MooX::Types::MooseLike::Base qw(Str ArrayRef InstanceOf Maybe);

use Mail::IMAPClient;
use Email::MIME;
use List::AllUtils 'first';

with 'Transform::Alert::Input';

# Stolen from connopts
has parsed_folder => (
   is        => 'ro',
   isa       => Str,
   predicate => 1,
);

has _conn => (
   is        => 'rw',
   isa       => Maybe[InstanceOf['Mail::IMAPClient']],
   lazy      => 1,
   default   => sub {
      my $self = shift;
      Mail::IMAPClient->new( %{$self->connopts} ) || do {
         $self->log->error('IMAP New/Connect/Login failed: '.$@);
         return;
      };
   },
   predicate => 1,
   clearer   => 1,
);
has _list => (
   is        => 'rw',
   isa       => ArrayRef[Str],
   predicate => 1,
   clearer   => 1,
);

around BUILDARGS => sub {
   my ($orig, $self) = (shift, shift);
   my $hash = shift;
   $hash = { $hash, @_ } unless ref $hash;

   $hash->{parsed_folder} = delete $hash->{connopts}{parsedfolder} if exists $hash->{connopts}{parsedfolder};

   $orig->($self, $hash);
};

sub open {
   my $self = shift;
   my $imap = $self->_conn ||
      # maybe+default+error still creates an undef attr, which would pass an 'exists' check on predicate
      do { $self->_clear_conn; return; };

   # figure out which state it's in
   unless ($imap->IsSelected) {
      if    (not $imap->IsConnected) {
         $imap->connect || do { $self->log->error('IMAP Connect/Login failed: '.$imap->LastError); return; };
      }
      elsif (not $imap->IsAuthenticated) {
         $imap->login   || do { $self->log->error('IMAP Login failed: '        .$imap->LastError); return; };
      }

      # might not have a folder set (or might have a specific Folder option)
      if (!$imap->IsSelected || $self->connopts->{folder}) {
         $imap->select($self->connopts->{folder} || 'Inbox') || do { $self->log->error('IMAP Select failed: '.$imap->LastError); return; };
      }
   }

   my $msgs = ($self->has_parsed_folder ? $imap->messages : $imap->unseen) || do {
      $self->log->error('IMAP Messages failed: '.$imap->LastError);
      return;
   };
   $self->_list($msgs);

   return 1;
}

sub opened {
   my $self = shift;
   $self->_has_conn and $self->_conn and $self->_conn->IsSelected;
}

sub get {
   my $self = shift;
   my $uid  = shift @{$self->_list};
   my $imap = $self->_conn ||
      # maybe+default+error still creates an undef attr, which would pass an 'exists' check on predicate
      do { $self->_clear_conn; return; };

   my $msg = $imap->message_string($uid) || do { $self->log->error('Error grabbing IMAP message '.$uid.': '.$imap->LastError); return; };
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

   # Move message
   if ($self->has_parsed_folder) {
      $imap->move( $self->parsed_folder, $uid ) || do { $self->log->error('Error moving IMAP message '.$uid.': '.$imap->LastError); return; };
   }
   # (if not, message_string will auto-set the Seen flag.)

   return (\$msg, $hash);
}

sub eof {
   my $self = shift;
   return not ($self->_has_list and @{$self->_list});
}

sub close {
   my $self = shift;
   my $imap = $self->_conn || do {
      # maybe+default+error still creates an undef attr, which would pass an 'exists' check on predicate
      $self->_clear_list;
      $self->_clear_conn;
      return;
   };

   $self->_clear_list;
   my $is_valid = $self->opened;

   # valid connection
   if ($is_valid) {
      $imap->close  || $self->log->warn('Error closing IMAP: '       .$imap->LastError);
   }
   # open or valid connection
   if ($imap->IsConnected) {
      $imap->logout || $self->log->warn('Error logging out of IMAP: '.$imap->LastError);
   }
   # invalid connection
   $self->_clear_conn unless ($is_valid);

   return 1;
}

42;

__END__

=pod

=encoding utf-8

=head1 NAME

Transform::Alert::Input::IMAP - Transform alerts from IMAP messages

=head1 SYNOPSIS

    # In your configuration
    <Input test>
       Type      IMAP
       Interval  60  # seconds (default)
 
       <ConnOpts>
          ParsedFolder  Finished
 
          # See Mail::IMAPClient Parameters
          Server   mail.foobar.org
          User     bob
          Password mail4fun
          Folder   Inbox
          Uid      1
          # ...etc...
       </ConnOpts>
       # <Template> tags...
    </Input>

=head1 DESCRIPTION

This input type will read a IMAP mailbox and process each message through the input template engine.  If it finds a match, the results of the
match are sent to one or more outputs, depending on the group configuration.

See L<Mail::IMAPClient|Mail::IMAPClient/Parameters> for a list of the ConnOpts section parameters.

The C<<< ParsedFolder >>> option is special.  If set, it will move all parsed messages to that folder.  If not, it will rely on the Unread flag to
figure out which messages have been parsed or not parsed.

The C<<< Folder >>> option (from L<Mail::IMAPClient>) can be specified to use a different folder than the default Inbox.

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

You are responsible for setting up any archivingE<sol>deletion protocols for the mailbox, as this module will save everything (and potentially
fill up the box).

The raw message isn't kept for the Munger.  If you really need it, you can implement an input RE template of C<<< (?<RAWMSG>[\s\S]+) >>>, and parse
out the email message yourself.

This class is persistent, keeping the L<Mail::IMAPClient> object until shutdown.  However, it will still disconnect on close, and will clear
the object on error.

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
