package VMS::Mail;

use strict;
use Carp;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

require Exporter;
require DynaLoader;

@ISA = qw(Exporter DynaLoader);
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.
@EXPORT = qw();
@EXPORT_OK = qw(&new &smg_read);
$VERSION = '0.06';

bootstrap VMS::Mail $VERSION;

# Preloaded methods go here.

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__
# Below is the documentation section.

=head1 NAME

VMS::Mail - VMS callable mail interface

=head1 SYNOPSIS

  use VMS::Mail;

Routine to initiate a new untyped object instance:

  $object = new VMS::Mail();

Routines to interact with mailfile contexts:

  $mailfile = new VMS::Mail();
  $href = $mailfile->mailfile_begin();
  $href = $mailfile->open();
  $href = $mailfile->close();
  $href = $mailfile->info_file();
  $href = $mailfile->compress();
  $href = $mailfile->purge_waste();
  $href = $mailfile->end();

Routines to interact with message contexts:

  $message = new VMS::Mail();
  $href = $message->message_begin();
  $href = $message->modify();
  $href = $message->info();
  $href = $message->get();
  $href = $message->select();
  $href = $message->delete();
  $href = $message->copy();
  $href = $message->end();

Routines to interact with send contexts:

  $send = new VMS::Mail();
  $href = $send->send_begin();
  $href = $send->abort();
  $href = $send->add_address();
  $href = $send->add_attribute();
  $href = $send->add_bodypart();
  $href = $send->message();
  $href = $send->end();

Routines to interact with user contexts:

  $user = new VMS::Mail();
  $href = $user->user_begin();
  $href = $user->delete_info();
  $href = $user->set_info();
  $href = $user->get_info();
  $href = $user->end();

One oddball routine that is here temporarily:
  $returned_string =
  VMS::Mail::smg_read($prompt [,$keydef_filename [,$default_keydef_filename]])

=head1 DESCRIPTION

This module supplies a complete interface to callable the VMSMail routines
for client-side access.

This is the first CPAN release. This module is brand new and certainly
has bugs. I will be testing it further and will release updates as I repair
problems. The purpose of this release is to provide external access to it
for peer review. I am very new to the module development process and would
welcome any constructive criticism.

=head2 Functions

=item new

This function returns a new VMS::Mail object. The object is 'untyped'.
Your next call should be to one of the context-type_begin methods to establish
a type and a vms-level context within the object.

=head2 Object methods

=item mailfile_begin

C<mailfile_begin> establishes an untyped object as a VMS MAILFILE context
object. Methods for mailfile objects can now be used from the object.
Output Items
  MAIL_DIRECTORY		String, 255

=item message_begin

C<message_begin> establishes an untyped object as a VMS MESSAGE context
object. Methods for message objects can now be used from the object.
Input items
  FILE_CTX		Context - object returned from new, then MAILFILE_BEGIN
Output Items
  SELECTED		Integer

=item send_begin

C<send_begin> establishes an untyped object as a VMS SEND context
object. Methods for send objects can now be used from the object.
Input items
  PERS_NAME		String, 127
  NO_PERS_NAME		Presence flag
  SIGFILE		String, 255
  NO_SIGFILE		Presence flag
  DEFAULT_TRANSPORT	String, 255
  NO_DEFAULT_TRANSPORT	Presence flag
Output Items
  COPY_FORWARD		Integer
  COPY_SEND		Integer
  COPY_REPLY		Integer
  SEND_USER		String, 255

=item user_begin

C<user_begin> establishes an untyped object as a VMS USER context
object. Methods for user objects can now be used from the object.
Output Items
  AUTO_PURGE		Integer
  CAPTIVE		Integer
  CC_PROMPT		Integer
  COPY_FORWARD		Integer
  COPY_REPLY		Integer
  COPY_SEND		Integer
  FORWARDING		String, 255
  FORM			String, 255
  FULL_DIRECTORY	String, 255
  NEW_MESSAGES		Integer
  PERSONAL_NAME		String, 127
  QUEUE			String, 255
  RETURN_USERNAME	String, 255
  RETURN_SIGFILE	String, 255
  RETURN_SUB_DIRECTORY	String, 255
  TRANSPORT		String, 255
  USER1			String, 255
  USER2			String, 255
  USER3			String, 255
  USER3			String, 255

=item end

C<end> completes a context-type_begin call and re-establishes the
calling object as an untyped object.

=item open

C<open>. Refer to the VMS Callable mail documentation.
Applies to MAILFILE objects.
Output Items
  WASTEBASKET		String, 255

=item close
C<close>. Refer to the VMS Callable mail documentation.
Applies to MAILFILE objects.
Input items
  FULL_CLOSE		Presence flag
Output Items
  DATA_RECLAIM		Integer
  DATA_SCAN		Integer
  INDEX_RECLAIM		Integer
  TOTAL_RECLAIM		Integer
  MESSAGES_DELETED	Integer

=item info_file

C<info_file>. Refer to the VMS Callable mail documentation.
Applies to MAILFILE objects.
Input items
  DEFAULT_NAME		String, 255
  NAME			String, 255
  FOLDER_ROUTINE	Callback - reference to a subroutine
Output Items
  DELETED_BYTES		Integer
  WASTEBASKET		String, 255
  RESULTSPEC		String, 255

=item compress

C<compress>. Refer to the VMS Callable mail documentation.
Applies to MAILFILE objects.
Input items
  FULL_CLOSE		Presence flag
  DEFAULT_NAME		String, 255
  NAME			String, 255
Output Items
  RESULTSPEC		String, 255


=item purge_waste

C<purge_waste>. Refer to the VMS Callable mail documentation.
Applies to MAILFILE objects.
Input items
  RECLAIM		Presence flag
Output Items
  DATA_RECLAIM		Integer
  DATA_SCAN		Integer
  INDEX_RECLAIM		Integer
  DELETED_BYTES		Integer
  TOTAL_RECLAIM		Integer
  MESSAGES_DELETED	Integer

=item modify
C<modify>. Refer to the VMS Callable mail documentation.
Applies to MAILFILE objects.
Input items
  DEFAULT_NAME		String, 255
  NAME			String, 255
  WASTEBASKET_NAME	String, 39
Output Items
  RESULTSPEC		String, 255

Applies to MESSAGE objects.
Input items
  BACK			Integer
  FLAGS			Bitvector - array reference
  ID			Integer
  NEXT			Integer
  UFLAGS		Integer
Output Items
  CURRENT_ID		Integer


=item info

C<info>. Refer to the VMS Callable mail documentation.
Applies to MESSAGE objects.
Input items
  BACK			Integer
  ID			Integer
  NEXT			Integer
Output Items
  BINARY_DATE		String, VMS Date & Time
  CC			String, 255
  CURRENT_ID		Integer
  DATE			String, 255
  EXTID			String, 255
  FROM			String, 255
  REPLY_PATH		String, 255
  RETURN_FLAGS		Bitvector - array reference
  SENDER		String, 255
  SIZE			Integer
  SUBJECT		String, 255
  TO			String, 255
  PARSE_QUOTES		Integer
  RETURN_UFLAGS		Integer

=item get

C<get>. Refer to the VMS Callable mail documentation.
Applies to MESSAGE objects.
Input items
  AUTO_NEWMAIL		Presence flag
  BACK			Integer
  UFLAGS		Integer
  CONTINUE		Presence flag
  ID			Integer
  NEXT			Integer
Output Items
  BINARY_DATE		String, VMS Date & Time
  CC			String, 255
  CURRENT_ID		Integer
  DATE			String, 255
  EXTID			String, 255
  FROM			String, 255
  RECORD		String, 255
  RECORD_TYPE		String, enumerated value
  REPLY_PATH		String, 255
  RETURN_FLAGS		Bitvector - array reference
  RETURN_UFLAGS		Integer
  SENDER		String, 255
  SIZE			Integer
  SUBJECT		String, 255
  TO			String, 255
  PARSE_QUOTES		Integer

=item select

C<select>. Refer to the VMS Callable mail documentation.
Applies to MESSAGE objects.
Input items
  BEFORE		String, 32
  CC_SUBSTRING		String, 255
  FLAGS			Bitvector - array reference
  FLAGS_MBZ		Bitvector - array reference
  FOLDER		String, 255
  FROM_SUBSTRING	String, 255
  SINCE			String, 32
  TO_SUBSTRING		String, 255
  SUBJ_SUBSTRING	String, 255
  UFLAGS		Integer
Output Items
  SELECTED		Integer

=item delete

C<delete>. Refer to the VMS Callable mail documentation.
Applies to MESSAGE objects.
Input items
  ID			Integer

=item copy

C<copy>. Refer to the VMS Callable mail documentation.
Applies to MESSAGE objects.
Input items
  BACK			Presence flag
  DEFAULT_NAME		String, 255
  DELETE		Presence flag
  ERASE			Presence flag
  FILE_ACTION		Callback - subroutine reference
  FILENAME		String, 255
  FOLDER		String, 255
  FOLDER_ACTION		Callback - subroutine reference
  ID			Integer
  NEXT			Presence flag
Output Items
  FILE_CREATED		Integer
  FOLDER_CREATED	Integer
  RESULTSPEC		Integer

=item abort

C<abort>. Refer to the VMS Callable mail documentation.
Applies to SEND objects.

=item add_address

C<add_address>. Refer to the VMS Callable mail documentation.
Applies to SEND objects.
Input items
  USERNAME		String, 255
  I_EN2("USERNAME_TYPE",MAIL$_SEND_USERNAME_TYPE, &c_username_type_enm)
  PARSE_QUOTES		Presence flag

=item add_attribute

C<add_attribute>. Refer to the VMS Callable mail documentation.
Applies to SEND objects.
Input items
  CC_LINE		String, 255
  FROM_LINE		String, 255
  SUBJECT		String, 255
  TO_LINE		String, 255
  UFLAGS		Integer

=item add_bodypart

C<add_bodypart>. Refer to the VMS Callable mail documentation.
Applies to SEND objects.
Input items
  DEFAULT_NAME		String, 255
  FILENAME		String, 255
  RECORD		String, 255
Output Items
  SEND_RESULTSPEC	String, 255

=item message

C<message>. Refer to the VMS Callable mail documentation.
Applies to SEND objects.
Input items
  I_CBK("ERROR_ENTRY", "USER_DATA",
  I_CBK("SUCCESS_ENTRY", "USER_DATA",

=item delete_info

C<delete_info>. Refer to the VMS Callable mail documentation.
Applies to USER objects.
Input items
  USERNAME		String, 31

=item set_info

C<set_info>. Refer to the VMS Callable mail documentation.
Applies to USER objects.
Input items
  CREATE_IF		Presence flag
  SET_AUTO_PURGE	Presence flag
  SET_NO_AUTO_PURGE	Presence flag
  SET_CC_PROMPT		Presence flag
  SET_NO_CC_PROMPT	Presence flag
  SET_COPY_FORWARD	Presence flag
  SET_NO_COPY_FORWARD	Presence flag
  SET_COPY_REPLY	Presence flag
  SET_NO_COPY_REPLY	Presence flag
  SET_COPY_SEND		Presence flag
  SET_NO_COPY_SEND	Presence flag
  SET_EDITOR		String, 255
  SET_NO_EDITOR		Presence flag
  SET_FORM		String, 255
  SET_NO_FORM		Presence flag
  SET_FORWARDING	String, 255
  SET_NO_FORWARDING	Presence flag
  SET_NEW_MESSAGES	Integer
  SET_QUEUE		String, 255
  SET_NO_QUEUE		Presence flag
  SET_SIGFILE		String, 255
  SET_NO_SIGFILE	Presence flag
  SET_SUB_DIRECTORY	String, 255
  SET_NO_SUB_DIRECTORY	Presence flag
  SET_PERSONAL_NAME	String, 127
  SET_NO_PERSONAL_NAME	Presence flag
  USERNAME		String, 31
  SET_USER1		String, 255
  SET_NO_USER1		Presence flag
  SET_USER2		String, 255
  SET_NO_USER2		Presence flag
  SET_USER3		String, 255
  SET_NO_USER3		Presence flag
  SET_TRANSPORT		String, 255
  SET_NO_TRANSPORT	Presence flag

=item get_info

C<get_info>. Refer to the VMS Callable mail documentation.
Applies to USER objects.
Input items
  FIRST			Presence flag
  NEXT			Presence flag
  USERNAME		String, 31
Output Items
  AUTO_PURGE		Integer
  CC_PROMPT		Integer
  COPY_FORWARD		Integer
  COPY_REPLY		Integer
  COPY_SEND		Integer
  EDITOR		String, 255
  FORM			String, 255
  FORWARDING		String, 255
  FULL_DIRECTORY	String, 255
  PERSONAL_NAME		String, 127
  QUEUE			String, 255
  RETURN_USERNAME	String, 255
  SIGFILE		String, 255
  SUB_DIRECTORY		String, 255
  USERNAME		String, 31
  NEW_MESSAGES		Integer
  TRANSPORT		String, 255
  USER1			String, 255
  USER2			String, 255
  USER3			String, 255
  USER3			String, 255

=head1 BUGS

This is an initial external release. There are certainly many bugs,
including, but not limited to: memory leakage, parameter mapping errors,
and access violations. No such bugs are known at the time of this writing,
but I am sure they are there....

=head1 EXAMPLES

An example to list information from your mail file

    #! perl -w
    use VMS::Mail;
    
    {
    $mailfile = new VMS::Mail();

    $ahref = $mailfile->mailfile_begin({},[MAIL_DIRECTORY]);
    if (defined($ahref)) {
      printf("  Mail directory is '%s'\n",$ahref->{MAIL_DIRECTORY});
    } else { die "Failure establishing mailfile context ($!)";

    $ahref = $mailfile->open({},[WASTEBASKET]);
    if (defined($ahref)) {
      printf("Mail file opened\n");
      printf("  Wastebasket folder is '%s'\n",$ahref->{WASTEBASKET});
    } else { die "Failure opening mail file ($!)";

    $rs = sub {
      my ($lstRef,$fldrname) = @_;
      defined($fldrname) && push @$lstRef,$fldrname;
      return(1); };
    $ahref = $mailfile->info_file({ FOLDER_ROUTINE => $rs,
                                    USER_DATA => $rfFlist=[]},
                   [WASTEBASKET,RESULTSPEC,
                    DELETED_BYTES]);
    if (defined($ahref)) {
      printf("  Folder list is (%s)",join(",",@$rfFlist));
      printf("  Wastebasket is '%s'\n",$ahref->{WASTEBASKET});
      printf("  Mail file is '%s'\n",$ahref->{RESULTSPEC});
      printf("  Mail file contains %d deleted bytes\n",$ahref->{DELETED_BYTES});
    } else { die "trying to get mailfile info ($!)";

    $ahref = $mailfile->close({FULL_CLOSE},
                              [TOTAL_RECLAIM,DATA_RECLAIM,DATA_SCAN,
                               INDEX_RECLAIM,MESSAGES_DELETED]);
    if (defined($ahref)) {
      printf("Closed mail file\n");
      printf("  Total reclaim was '%d'\n",$ahref->{TOTAL_RECLAIM});
      printf("  index reclaim was '%d'\n",$ahref->{INDEX_RECLAIM});
      printf("  data reclaim  was '%d'\n",$ahref->{DATA_RECLAIM});
      printf("  data scan     was '%d'\n",$ahref->{DATA_SCAN});
      printf("  messages deleted  '%d'\n",$ahref->{MESSAGES_DELETED});
    }
    $ahref = $mailfile->end({},[]);
    }

=head1 AUTHOR

David G. North, CCP <rold5@tditx.com>

=head1 SEE ALSO

perl(1).

=cut
