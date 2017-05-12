#!perl
#
# The copyright notice and plain old documentation (POD)
# are at the end of this file.
#
# see POD documentation at end
#
package Tie::Eudora;

use strict;
use warnings;
use warnings::register;
use 5.001;

use vars qw($VERSION $DATE $FILE);
$VERSION = '0.01';
$DATE = '2004/05/29';
$FILE = __FILE__;

####
# Software Diamonds Modules
#
use Data::Startup;
use Tie::Layers qw(is_handle);

use vars qw(@ISA @EXPORT_OK);
@ISA = qw(Tie::Layers Exporter);
@EXPORT_OK = qw(is_handle encode_field decode_field
                encode_record decode_record);

my $default_options;

######
# Configuration
#
sub config
{
     $default_options = defaults() unless $default_options;
     my $options; 
     if( UNIVERSAL::isa($_[0],__PACKAGE__) ) {
         my $self = shift;
         $options = $self->{'Tie::Eudora'}->{options};
     }
     elsif( ref($_[0]) eq 'HASH' ) {
         $options = shift;  
     }
     else {
         $options = $default_options;
     }
     Data::Startup::config($options,@_);
}

#######
# Object used to set default, startup, options values.
#
sub defaults
{
   my $class =  UNIVERSAL::isa($_[0],__PACKAGE__) ? shift : '';
   my %options = (
       EMAIL_SEPARATOR => 'From ???@??? ', # This is the Eudora e-mail separator
       query_ready => 1,
       warn => 1,
       debug => 0,
   );
   my $options = Data::Startup::override(\%options,@_);
   $options = bless $options, $class if $class;
   $options;      
}



#######
# Object used to set default, startup, options values.
#
sub new
{
   my $class = shift;
   $class = ref($class) if ref($class);
   my $self = {};
   $self->{'Tie::Eudora'}->{options} = defaults(@_); 
   bless $self,$class;
}


######
#  Started with CPAN::Tarzip::TIEHANDLE which
#  still retains a faint resemblence.
#
sub TIEHANDLE
{
     my $class = shift @_;

     #########
     # create new object of $class
     # 
     # If there is ref($class) than $class
     # is an object whose class is ref($class).
     # 
     $class = ref($class) if ref($class);
     my $self = bless {}, $class;
     $self->{'Tie::Eudora'}->{options} = defaults(@_);

     #######
     # parse layers options
     # 
     my $layers_options = $self->{'Tie::Eudora'}->{options}->{'Tie::Layers'};
     delete $self->{'Tie::Eudora'}->{options}->{'Tie::Layers'};
     $layers_options = {} unless $layers_options;
     $layers_options->{print_layers} = [
         \&encode_record,
         \&encode_field,
     ];
     $layers_options->{read_layers}  = [
         \&decode_record,
         \&decode_field,
     ];
     $layers_options->{read_record} = \&read_record;
     $layers_options->{print_record} = \&print_record;
     $self->Tie::Layers::TIEHANDLE( $layers_options );
}


###########
###########
# 
# The following code is the field encoding and decoding layer 2
#
##########
##########


#####
# 
# encodes a email record
#
#
sub encode_field
{
    my $event;
    my $self = UNIVERSAL::isa($_[0],'Tie::Layers') ? shift : Tie::Eudora->new();

    my ($fields) = @_;
    unless( $fields ) {
        $event = "No inputs\n";
        goto EVENT;
    }
    my $encoded_fields = '';
    my $body = ${$fields}[-1];
    for( my $i = 0; $i < @$fields - 2; $i += 2) {
        $encoded_fields .= "$fields->[$i]: $fields->[$i+1]\n";
    }
    while( chomp($encoded_fields) ) { };
    $encoded_fields .= "\n\n" . $body;
  
    return \$encoded_fields;

EVENT:
     if($self->{'Tie::Eudora'}->{warn}) {
         warn($event);
     }
     $self->{current_event} .= $event;
     $self->{current_event} .= "\tTie::Eudora::encode_field() $VERSION\n";
     $self->{current_event};
}


##########
# Decode an email record.
#
sub decode_field
{ 
    my $event;
    my $self = UNIVERSAL::isa($_[0],'Tie::Layers') ? shift : Tie::Eudora->new();
    my $debug = $self->{'Tie::Eudora'}->{options}->{debug};

    ###########
    # Parse the e-mail header and body    
    #    
    my ($encoded_fields) = @_;
    unless( $encoded_fields ) {
        $event = "No inputs\n";
        goto EVENT;
    }
    my ($header,$body) = ${$encoded_fields} =~ /^(.*?\n)\n(.*)$/s;
    if($debug && !$header) {
        $event = "No header.\n";
        goto EVENT;
    } 
    if($debug && !$body) {
        $event = "No Body!\n";
        goto EVENT;
    }
    my @fields = split /^([\w\-]+): */mo, $header;
    if($debug && !@fields) {
        $event = "No header fields\n";
        goto EVENT;
    }
    shift @fields; # cause split makes 1st element empty!
    for( my $i=0; $i < @fields; $i += 2) {
        chomp $fields[$i+1];
    }
    push @fields, ('X-Body',$body);
    return \@fields;

EVENT:
     if($self->{'Tie::Eudora'}->{warn}) {
         warn($event);
     }
     $self->{current_event} .= $event;
     $self->{current_event} .= "\tTie::Eudora::encode_field() $VERSION\n";
     $self->{current_event};
}

###########
###########
# 
# The following code is the record encoding and decoding layer 1
#
##########
##########


#########
# This function un escapes the record separator
#
sub decode_record
{
    my $event;
    my $self = UNIVERSAL::isa($_[0],'Tie::Layers') ? shift : Tie::Eudora->new();

    my ($record) = @_;
    unless( $record ) {
        $event = "No inputs\n";
        goto EVENT;
    }
    my $EMAIL_SEPARATOR = $self->{'Tie::Eudora'}->{options}->{EMAIL_SEPARATOR};
    $$record =~ s/\Q${EMAIL_SEPARATOR}\E$//;
    $$record =~ s/\015\012|\012\015/\012/g;  # replace LFCR or CRLF with a LF
    $$record =~ s/\012|\015/\n/g;   # replace CR or LF with logical \n 
    return $record;

EVENT:
     if($self->{'Tie::Eudora'}->{warn}) {
         warn($event);
     }
     $self->{current_event} .= $event;
     $self->{current_event} .= "\tTie::Form::decode_record() $VERSION\n";
     $self->{current_event};
}



#############
# encode the record
#
sub encode_record
{
    my $event;
    my $self = UNIVERSAL::isa($_[0],'Tie::Layers') ? shift : Tie::Eudora->new();

    my ($encoded_fields) = @_;
    unless( $encoded_fields ) {
        $event = "No inputs\n";
        goto EVENT;
    }
    my $EMAIL_SEPARATOR = $self->{'Tie::Eudora'}->{options}->{EMAIL_SEPARATOR};


    $$encoded_fields = $EMAIL_SEPARATOR  . $$encoded_fields;

    return $encoded_fields;

EVENT:
     if($self->{'Tie::Eudora'}->{warn}) {
         warn($event);
     }
     $self->{current_event} .= $event;
     $self->{current_event} .= "\tTie::Eudora::encode_record() $VERSION\n";
     $self->{current_event};

} 



###########
###########
# 
# The following code is the record read print layer 0
#
##########
##########

####
#
#
sub read_record
{
    my ($self) = @_;

    local($/);
    $/ = $self->{'Tie::Eudora'}->{options}->{EMAIL_SEPARATOR};
    my ($fh) = $self->{'Tie::Layers'}->{FH};
    return '' unless $fh;

    #####
    # 1st record is empty since the record separator is a 
    # leading record separator    
    #
    <$fh> if tell($fh) == 0;
    my $record = <$fh>;
    return '' unless $record;
    'X-Pickup-Date: '  . $record;
}


####
#
#
sub print_record
{
    my($self, $buf) = @_;
    my $fh = $self->{'Tie::Layers'}->{FH};
    my $EMAIL_SEPARATOR = $self->{'Tie::Eudora'}->{options}->{EMAIL_SEPARATOR};
    $buf =~ s/\Q${EMAIL_SEPARATOR}X-Pickup-Date: \E/${EMAIL_SEPARATOR}/g;
    print $fh $buf;
}


1;

__END__


=head1 NAME

Tie::Eudora - encode/decode emails, read/write emails in Eudora mailbox files

=head1 SYNOPSIS

 ####
 # Subroutine interface
 #
 \$encoded_email  = decode_record(\$mailbox_email); 
 \@email          = decode_field(\$encoded_email);

 \$encoded_email  = encode_field (\@email);
 \$mailbox_email  = encode_record(\$encoded_email);

 #####
 # Object Interface
 # 
 $eudora = Tie::Form->new(@options);

 \$encoded_email   = $eudora->decode_record(\$record); 
 \@email           = $eudora->decode_field(\$encoded_email);

 \$encoded_email   = $eudora->encode_field (\@email);
 \$mailbox_email   = $eudora->encode_record(\$encoded_email);

 $mailbox_email    = $eudora->get_record();
 $success          = $eudora->put_record($mailbox_email);

 ####
 # use file subroutines to write/read Eudora mailbox files
 #
 tie *MAILBOX, 'Tie::Eudora';
 open MAILBOX,'>',$mbx;
 print MAILBOX @mailbox;
 close MAILBOX;

 open MAILBOX,'<',$mbx;
 @mailbox = <MAILBOX>;
 close MAILBOX;

=head1 DESCRIPTION

The C<Tie::Eudora> program module provides a File Handle Tie package
for reading and writing of Eudora mailbox files. 
The C<Tie::Eudora> package handles each email in Eudora
mailbox files as a record.
Each record is read and written not as a scalar text string but
as an array of C<field-name, field-body> pairs corresponding
to the header and body fields in the email.

=head2 Email Array

An email array, C<@email>, is an array of C<field-name, field-body> pairs
where the even index array members are the C<field-name> and
the odd index array members are the field-values.
The C<field-name, field-body> pairs, except for the last pair,
are as specified in RFC 822, http://www.ietf.org/rfc/rfc822.txt,
and are in the order that they appear in an C<$encoded_email> encoded in
accordance with RFC 822.
The last C<field-name, field-body> pair has a C<field-name> of
'X-Body' and the C<field-body> contents is the body of the C<$encoded_email>.

=head2 Mailbox Array

A mailbox array, C<@mailbox>, is a list of references to email arrays.

=head1 REQUIREMENTS

=head2 Eudora Mailbox Format

A C<@mailbox> array, written using the appropriate C<Tie::Eudora> package
file subroutines, shall[1] produce a Eudora mailbox file that can
be read by I<Eudora 5.0>.
One appropriate use of the C<Tie::Eudora> package subroutines to create
a Eudora mailbox file is
as follows:

 tie *MAILBOX, 'Tie::Eudora';
 open MAILBOX,'>',$mbx;
 print MAILBOX @Write_mailbox;
 close MAILBOX;

=head2 Eudora Mailbox Lossless

The C<@read_mailbox> array from reading a mailbox file in accordance
with L<Eudora Mailbox Format|/Eudora Mailbox Format> using the 
appropriate C<Tie::Eudora> package
file subroutines, shall[1] be exactly the same as the
mailbox array C<@write_mailbox> used to write the Eudora mailbox
file. 
One appropriate use of the C<Tie::Eudora> package subroutines to read
a Eudora mailbox file is
as follows:

 tie *MAILBOX, 'Tie::Eudora';
 open MAILBOX,'<',$mbx;
 @read_mailbox = <MAILBOX>;
 close MAILBOX;

=head2 RFC822 Email Format

A C<@mailbox> array, written using the C<Tie::Eudora> package
file subroutines, shall[1] create a Eudora mailbox file that can
be read by Eudora 5.0.
A typical use of the C<Tie::Eudora> package subroutines are
as follows:

 tie *MAILBOX, 'Tie::Eudora';
 open MAILBOX,'>',$mbx;
 print MAILBOX @Write_mailbox;
 close MAILBOX;

=head2 RFC822 Email Lossless

The C<@read_mailbox> array from reading a mailbox file in accordance
with L<Eudora[1]|/Eudora[1]> using the C<Tie::Eudora> package
file subroutines, shall[1] be exactly the same as the
mailbox array C<@write_mailbox> used to write the Eudora mailbox
file. 

 tie *MAILBOX, 'Tie::Eudora';
 open MAILBOX,'<',$mbx;
 @read_mailbox = <MAILBOX>;
 close MAILBOX;



=head1 DEMONSTRATION

 #########
 # perl Eudora.d
 ###

~~~~~~ Demonstration overview ~~~~~

The results from executing the Perl Code 
follow on the next lines as comments. For example,

 2 + 2
 # 4

~~~~~~ The demonstration follows ~~~~~

     use File::Package;
     use File::SmartNL;
     use File::Spec;
     use Data::Dumper;
     $Data::Dumper::Sortkeys = 1; # dump hashes sorted
     $Data::Dumper::Terse = 1; # avoid Varn Variables

     my $uut = 'Tie::Eudora'; # Unit Under Test
     my $fp = 'File::Package';
     my $snl = 'File::SmartNL';
     my $loaded;

     my (@fields);  # force context

     my $mbx = 'Eudora1.mbx';

 ##################
 # Load UUT
 # 

 my $errors = $fp->load_package($uut, qw(is_handle encode_field decode_field
                 encode_record decode_record));
 $errors

 # ''
 # 

 ##################
 # Tie::Eudora Version 0.01 loaded
 # 

 $fp->is_package_loaded($uut)

 # 1
 # 

 ##################
 # Write Eudora Mailbox
 # 

     tie *MAILBOX, 'Tie::Eudora';
     open MAILBOX,'>',$mbx;
     print MAILBOX @test_data;
     close MAILBOX;
 $snl->fin($mbx)

 # 'From ???@??? Wed Jul 24 20:20:19 2002
 # X-Persona: <support@SoftwareDiamonds.com>
 # Return-Path: somebody@compuserve.com
 # Delivered-To: support@SoftwareDiamonds.com
 # Received: (qmail 7321 invoked from network); 24 Jul 2002 17:26:21 -0000
 # Received: from unknown (HELO mail.hbhosting.com) (66.28.88.4)
 #   by mail.ixpres.com with SMTP; 24 Jul 2002 17:26:21 -0000
 # Received: (qmail 17747 invoked by uid 89); 24 Jul 2002 17:38:56 -0000
 # Delivered-To: softwarediamonds.com-support@softwarediamonds.com
 # Received: (qmail 17745 invoked from network); 24 Jul 2002 17:38:56 -0000
 # Received: from unknown (HELO compuserve.com) (66.28.118.5)
 #   by 66.28.88.9 with SMTP; 24 Jul 2002 17:38:56 -0000
 # X-Mailer: SoftwareDiamonds.com/software/ Inetdia::sdmailit sdmailit() 1.0.005 May 9, 2002
 # Date: Wed, 24 Jul 2002 12:30:37 -0500
 # To: support@SoftwareDiamonds.com
 # From: somebody@compuserve.com
 # Subject: *~~* Software Diamonds sdform.pl *~~*
 # 
 # Comments:
 # i read an interesting article many years ago about the effects of drugs on spiders in National Geographic Magazine. %0Ait showed webs woven by spiders ""under the influence.""  spiders high on marijuana wove bad webs; spiders on LSD wove exceptionally geometrical webs.%0Aanyone know how i can locate the date of and issue this appeared in?%0A %0Amany thanks in advance to someone who has walked at least a mile in my shoes.
 # ^
 # 
 # Email:
 # sombody@compuserve.com
 # ^
 # 
 # REMOTE_ADDR:
 # 216.192.88.155
 # ^
 # 
 # HTTP_USER_AGENT:
 # Mozilla/4.0 (compatible; MSIE 5.0; Windows 98; DigExt)
 # ^
 # 
 # HTTP_REFERER:
 # http://www.spiderdiamonds.com/spider.htm
 # ^
 # 
 # From ???@??? Wed Sep 25 21:49:29 2002
 # X-Persona: <support@SoftwareDiamonds.com>
 # Return-Path: <everybody@hotmail.com>
 # Delivered-To: support@SoftwareDiamonds.com
 # Received: (qmail 24171 invoked from network); 25 Sep 2002 20:59:11 -0000
 # Received: from unknown (HELO mail.hbhosting.com) (66.28.88.4)
 #   by mail.ixpres.com with SMTP; 25 Sep 2002 20:59:11 -0000
 # Received: (qmail 75277 invoked by uid 89); 25 Sep 2002 21:10:22 -0000
 # Delivered-To: softwarediamonds.com-support@softwarediamonds.com
 # Received: (qmail 75275 invoked from network); 25 Sep 2002 21:10:22 -0000
 # Received: from unknown (HELO hotmail.com) (66.28.118.5)
 #   by 66.28.88.9 with SMTP; 25 Sep 2002 21:10:22 -0000
 # X-Mailer: SoftwareDiamonds.com/software/ Inetdia::sdmailit sdmailit() 1.0.005 May 9, 2002
 # Date: Wed, 25 Sep 2002 16:06:27 -0500
 # To: support@SoftwareDiamonds.com
 # From: everybody@hotmail.com
 # Subject: *~~* Software Diamonds sdform.pl *~~*
 # 
 # 
 # Comments:
 # Can I order a personalized stamp pad (name and address??
 # ^
 # 
 # Email:
 # everybody@hotmail.com
 # ^
 # 
 # Name:
 # Paul
 # ^
 # 
 # REMOTE_ADDR:
 # 24.165.157.193
 # ^
 # 
 # HTTP_USER_AGENT:
 # Mozilla/4.0 (compatible; MSIE 5.5; Windows 98; Win 9x 4.90)
 # ^
 # 
 # HTTP_REFERER:
 # http://stationary.merchantdiamonds.com/
 # ^
 # 
 # From ???@??? Tue Dec 31 10:19:58 2002
 # X-Persona: <support@SoftwareDiamonds.com>
 # Return-Path: <girl@hotmail.com>
 # Delivered-To: support@SoftwareDiamonds.com
 # Received: (qmail 6236 invoked from network); 31 Dec 2002 09:04:00 -0000
 # Received: from one.nospam.ixpres.com (216.240.160.191)
 #   by mail.ixpres.com with SMTP; 31 Dec 2002 09:04:00 -0000
 # Received: (qmail 18721 invoked by uid 106); 30 Dec 2002 10:03:56 -0000
 # Received: from unknown (HELO mail.hbhosting.com) (66.28.88.4)
 #   by one.nospam.ixpres.com with SMTP; 30 Dec 2002 10:03:55 -0000
 # Received: (qmail 91583 invoked by uid 89); 31 Dec 2002 09:05:52 -0000
 # Received: (qmail 91581 invoked from network); 31 Dec 2002 09:05:52 -0000
 # Received: from unknown (HELO hotmail.com) (66.28.118.5)
 #   by zeus with SMTP; 31 Dec 2002 09:05:52 -0000
 # X-Spam-Status: No, hits=2.9 required=8.0 source=66.28.88.4 from=janigeorg@hotmail.com addr=1
 # Delivered-To: softwarediamonds.com-support@softwarediamonds.com
 # X-Mailer: SoftwareDiamonds.com/software/ Inetdia::sdmailit sdmailit() 1.0.005 May 9, 2002
 # Date: Tue, 31 Dec 2002 03:20:52 -0600
 # To: support@SoftwareDiamonds.com
 # From: girl@hotmail.com
 # Subject: *~~* Software Diamonds sdform.pl *~~*
 # X-Qmail-Scanner-Message-ID: <104124263551318713@one.nospam.ixpres.com>
 # X-AntiVirus: checked by Vexira MailArmor (version: 2.0.1.6; VAE: 6.17.0.2; VDF: 6.17.0.10; host: one.nospam.ixpres.com)
 # 
 # 
 # Email:
 # girl@hotmail.com
 # ^
 # 
 # Tutorial:
 # *~~* Better Health thru Biochemistry *~~*
 # ^
 # 
 # REMOTE_ADDR:
 # 81.26.160.109
 # ^
 # 
 # HTTP_USER_AGENT:
 # Mozilla/4.0 (compatible; MSIE 5.0; Windows 98; DigExt)
 # ^
 # 
 # HTTP_REFERER:
 # http://camera.merchantdiamonds.com/
 # ^
 # 
 # '
 # 

 ##################
 # Read Eudora Mailbox
 # 

     open MAILBOX,'<',$mbx;
     @fields = <MAILBOX>;
     close MAILBOX;
 [@fields]

 # [
 #           [
 #             'X-Pickup-Date',
 #             'Wed Jul 24 20:20:19 2002',
 #             'X-Persona',
 #             '<support@SoftwareDiamonds.com>',
 #             'Return-Path',
 #             'somebody@compuserve.com',
 #             'Delivered-To',
 #             'support@SoftwareDiamonds.com',
 #             'Received',
 #             '(qmail 7321 invoked from network); 24 Jul 2002 17:26:21 -0000',
 #             'Received',
 #             'from unknown (HELO mail.hbhosting.com) (66.28.88.4)
 #   by mail.ixpres.com with SMTP; 24 Jul 2002 17:26:21 -0000',
 #             'Received',
 #             '(qmail 17747 invoked by uid 89); 24 Jul 2002 17:38:56 -0000',
 #             'Delivered-To',
 #             'softwarediamonds.com-support@softwarediamonds.com',
 #             'Received',
 #             '(qmail 17745 invoked from network); 24 Jul 2002 17:38:56 -0000',
 #             'Received',
 #             'from unknown (HELO compuserve.com) (66.28.118.5)
 #   by 66.28.88.9 with SMTP; 24 Jul 2002 17:38:56 -0000',
 #             'X-Mailer',
 #             'SoftwareDiamonds.com/software/ Inetdia::sdmailit sdmailit() 1.0.005 May 9, 2002',
 #             'Date',
 #             'Wed, 24 Jul 2002 12:30:37 -0500',
 #             'To',
 #             'support@SoftwareDiamonds.com',
 #             'From',
 #             'somebody@compuserve.com',
 #             'Subject',
 #             '*~~* Software Diamonds sdform.pl *~~*',
 #             'X-Body',
 #             'Comments:
 # i read an interesting article many years ago about the effects of drugs on spiders in National Geographic Magazine. %0Ait showed webs woven by spiders ""under the influence.""  spiders high on marijuana wove bad webs; spiders on LSD wove exceptionally geometrical webs.%0Aanyone know how i can locate the date of and issue this appeared in?%0A %0Amany thanks in advance to someone who has walked at least a mile in my shoes.
 # ^
 # 
 # Email:
 # sombody@compuserve.com
 # ^
 # 
 # REMOTE_ADDR:
 # 216.192.88.155
 # ^
 # 
 # HTTP_USER_AGENT:
 # Mozilla/4.0 (compatible; MSIE 5.0; Windows 98; DigExt)
 # ^
 # 
 # HTTP_REFERER:
 # http://www.spiderdiamonds.com/spider.htm
 # ^
 # 
 # '
 #           ],
 #           [
 #             'X-Pickup-Date',
 #             'Wed Sep 25 21:49:29 2002',
 #             'X-Persona',
 #             '<support@SoftwareDiamonds.com>',
 #             'Return-Path',
 #             '<everybody@hotmail.com>',
 #             'Delivered-To',
 #             'support@SoftwareDiamonds.com',
 #             'Received',
 #             '(qmail 24171 invoked from network); 25 Sep 2002 20:59:11 -0000',
 #             'Received',
 #             'from unknown (HELO mail.hbhosting.com) (66.28.88.4)
 #   by mail.ixpres.com with SMTP; 25 Sep 2002 20:59:11 -0000',
 #             'Received',
 #             '(qmail 75277 invoked by uid 89); 25 Sep 2002 21:10:22 -0000',
 #             'Delivered-To',
 #             'softwarediamonds.com-support@softwarediamonds.com',
 #             'Received',
 #             '(qmail 75275 invoked from network); 25 Sep 2002 21:10:22 -0000',
 #             'Received',
 #             'from unknown (HELO hotmail.com) (66.28.118.5)
 #   by 66.28.88.9 with SMTP; 25 Sep 2002 21:10:22 -0000',
 #             'X-Mailer',
 #             'SoftwareDiamonds.com/software/ Inetdia::sdmailit sdmailit() 1.0.005 May 9, 2002',
 #             'Date',
 #             'Wed, 25 Sep 2002 16:06:27 -0500',
 #             'To',
 #             'support@SoftwareDiamonds.com',
 #             'From',
 #             'everybody@hotmail.com',
 #             'Subject',
 #             '*~~* Software Diamonds sdform.pl *~~*',
 #             'X-Body',
 #             '
 # Comments:
 # Can I order a personalized stamp pad (name and address??
 # ^
 # 
 # Email:
 # everybody@hotmail.com
 # ^
 # 
 # Name:
 # Paul
 # ^
 # 
 # REMOTE_ADDR:
 # 24.165.157.193
 # ^
 # 
 # HTTP_USER_AGENT:
 # Mozilla/4.0 (compatible; MSIE 5.5; Windows 98; Win 9x 4.90)
 # ^
 # 
 # HTTP_REFERER:
 # http://stationary.merchantdiamonds.com/
 # ^
 # 
 # '
 #           ],
 #           [
 #             'X-Pickup-Date',
 #             'Tue Dec 31 10:19:58 2002',
 #             'X-Persona',
 #             '<support@SoftwareDiamonds.com>',
 #             'Return-Path',
 #             '<girl@hotmail.com>',
 #             'Delivered-To',
 #             'support@SoftwareDiamonds.com',
 #             'Received',
 #             '(qmail 6236 invoked from network); 31 Dec 2002 09:04:00 -0000',
 #             'Received',
 #             'from one.nospam.ixpres.com (216.240.160.191)
 #   by mail.ixpres.com with SMTP; 31 Dec 2002 09:04:00 -0000',
 #             'Received',
 #             '(qmail 18721 invoked by uid 106); 30 Dec 2002 10:03:56 -0000',
 #             'Received',
 #             'from unknown (HELO mail.hbhosting.com) (66.28.88.4)
 #   by one.nospam.ixpres.com with SMTP; 30 Dec 2002 10:03:55 -0000',
 #             'Received',
 #             '(qmail 91583 invoked by uid 89); 31 Dec 2002 09:05:52 -0000',
 #             'Received',
 #             '(qmail 91581 invoked from network); 31 Dec 2002 09:05:52 -0000',
 #             'Received',
 #             'from unknown (HELO hotmail.com) (66.28.118.5)
 #   by zeus with SMTP; 31 Dec 2002 09:05:52 -0000',
 #             'X-Spam-Status',
 #             'No, hits=2.9 required=8.0 source=66.28.88.4 from=janigeorg@hotmail.com addr=1',
 #             'Delivered-To',
 #             'softwarediamonds.com-support@softwarediamonds.com',
 #             'X-Mailer',
 #             'SoftwareDiamonds.com/software/ Inetdia::sdmailit sdmailit() 1.0.005 May 9, 2002',
 #             'Date',
 #             'Tue, 31 Dec 2002 03:20:52 -0600',
 #             'To',
 #             'support@SoftwareDiamonds.com',
 #             'From',
 #             'girl@hotmail.com',
 #             'Subject',
 #             '*~~* Software Diamonds sdform.pl *~~*',
 #             'X-Qmail-Scanner-Message-ID',
 #             '<104124263551318713@one.nospam.ixpres.com>',
 #             'X-AntiVirus',
 #             'checked by Vexira MailArmor (version: 2.0.1.6; VAE: 6.17.0.2; VDF: 6.17.0.10; host: one.nospam.ixpres.com)',
 #             'X-Body',
 #             '
 # Email:
 # girl@hotmail.com
 # ^
 # 
 # Tutorial:
 # *~~* Better Health thru Biochemistry *~~*
 # ^
 # 
 # REMOTE_ADDR:
 # 81.26.160.109
 # ^
 # 
 # HTTP_USER_AGENT:
 # Mozilla/4.0 (compatible; MSIE 5.0; Windows 98; DigExt)
 # ^
 # 
 # HTTP_REFERER:
 # http://camera.merchantdiamonds.com/
 # ^
 # 
 # '
 #           ]
 #         ]
 # 

 ##################
 # Object encode email fields
 # 

 my $eudora = new Tie::Eudora
 my $email = ${$eudora->encode_field($test_data[0])}

 # 'X-Pickup-Date: Wed Jul 24 20:20:19 2002
 # X-Persona: <support@SoftwareDiamonds.com>
 # Return-Path: somebody@compuserve.com
 # Delivered-To: support@SoftwareDiamonds.com
 # Received: (qmail 7321 invoked from network); 24 Jul 2002 17:26:21 -0000
 # Received: from unknown (HELO mail.hbhosting.com) (66.28.88.4)
 #   by mail.ixpres.com with SMTP; 24 Jul 2002 17:26:21 -0000
 # Received: (qmail 17747 invoked by uid 89); 24 Jul 2002 17:38:56 -0000
 # Delivered-To: softwarediamonds.com-support@softwarediamonds.com
 # Received: (qmail 17745 invoked from network); 24 Jul 2002 17:38:56 -0000
 # Received: from unknown (HELO compuserve.com) (66.28.118.5)
 #   by 66.28.88.9 with SMTP; 24 Jul 2002 17:38:56 -0000
 # X-Mailer: SoftwareDiamonds.com/software/ Inetdia::sdmailit sdmailit() 1.0.005 May 9, 2002
 # Date: Wed, 24 Jul 2002 12:30:37 -0500
 # To: support@SoftwareDiamonds.com
 # From: somebody@compuserve.com
 # Subject: *~~* Software Diamonds sdform.pl *~~*
 # 
 # Comments:
 # i read an interesting article many years ago about the effects of drugs on spiders in National Geographic Magazine. %0Ait showed webs woven by spiders ""under the influence.""  spiders high on marijuana wove bad webs; spiders on LSD wove exceptionally geometrical webs.%0Aanyone know how i can locate the date of and issue this appeared in?%0A %0Amany thanks in advance to someone who has walked at least a mile in my shoes.
 # ^
 # 
 # Email:
 # sombody@compuserve.com
 # ^
 # 
 # REMOTE_ADDR:
 # 216.192.88.155
 # ^
 # 
 # HTTP_USER_AGENT:
 # Mozilla/4.0 (compatible; MSIE 5.0; Windows 98; DigExt)
 # ^
 # 
 # HTTP_REFERER:
 # http://www.spiderdiamonds.com/spider.htm
 # ^
 # 
 # '
 # 

 ##################
 # Object decode email fields
 # 

 $eudora->decode_field(\$email)

 # [
 #           'X-Pickup-Date',
 #           'Wed Jul 24 20:20:19 2002',
 #           'X-Persona',
 #           '<support@SoftwareDiamonds.com>',
 #           'Return-Path',
 #           'somebody@compuserve.com',
 #           'Delivered-To',
 #           'support@SoftwareDiamonds.com',
 #           'Received',
 #           '(qmail 7321 invoked from network); 24 Jul 2002 17:26:21 -0000',
 #           'Received',
 #           'from unknown (HELO mail.hbhosting.com) (66.28.88.4)
 #   by mail.ixpres.com with SMTP; 24 Jul 2002 17:26:21 -0000',
 #           'Received',
 #           '(qmail 17747 invoked by uid 89); 24 Jul 2002 17:38:56 -0000',
 #           'Delivered-To',
 #           'softwarediamonds.com-support@softwarediamonds.com',
 #           'Received',
 #           '(qmail 17745 invoked from network); 24 Jul 2002 17:38:56 -0000',
 #           'Received',
 #           'from unknown (HELO compuserve.com) (66.28.118.5)
 #   by 66.28.88.9 with SMTP; 24 Jul 2002 17:38:56 -0000',
 #           'X-Mailer',
 #           'SoftwareDiamonds.com/software/ Inetdia::sdmailit sdmailit() 1.0.005 May 9, 2002',
 #           'Date',
 #           'Wed, 24 Jul 2002 12:30:37 -0500',
 #           'To',
 #           'support@SoftwareDiamonds.com',
 #           'From',
 #           'somebody@compuserve.com',
 #           'Subject',
 #           '*~~* Software Diamonds sdform.pl *~~*',
 #           'X-Body',
 #           'Comments:
 # i read an interesting article many years ago about the effects of drugs on spiders in National Geographic Magazine. %0Ait showed webs woven by spiders ""under the influence.""  spiders high on marijuana wove bad webs; spiders on LSD wove exceptionally geometrical webs.%0Aanyone know how i can locate the date of and issue this appeared in?%0A %0Amany thanks in advance to someone who has walked at least a mile in my shoes.
 # ^
 # 
 # Email:
 # sombody@compuserve.com
 # ^
 # 
 # REMOTE_ADDR:
 # 216.192.88.155
 # ^
 # 
 # HTTP_USER_AGENT:
 # Mozilla/4.0 (compatible; MSIE 5.0; Windows 98; DigExt)
 # ^
 # 
 # HTTP_REFERER:
 # http://www.spiderdiamonds.com/spider.htm
 # ^
 # 
 # '
 #         ]
 # 

 ##################
 # Subroutine encode email fields
 # 

 $email = ${encode_field($test_data[0])}

 # 'X-Pickup-Date: Wed Jul 24 20:20:19 2002
 # X-Persona: <support@SoftwareDiamonds.com>
 # Return-Path: somebody@compuserve.com
 # Delivered-To: support@SoftwareDiamonds.com
 # Received: (qmail 7321 invoked from network); 24 Jul 2002 17:26:21 -0000
 # Received: from unknown (HELO mail.hbhosting.com) (66.28.88.4)
 #   by mail.ixpres.com with SMTP; 24 Jul 2002 17:26:21 -0000
 # Received: (qmail 17747 invoked by uid 89); 24 Jul 2002 17:38:56 -0000
 # Delivered-To: softwarediamonds.com-support@softwarediamonds.com
 # Received: (qmail 17745 invoked from network); 24 Jul 2002 17:38:56 -0000
 # Received: from unknown (HELO compuserve.com) (66.28.118.5)
 #   by 66.28.88.9 with SMTP; 24 Jul 2002 17:38:56 -0000
 # X-Mailer: SoftwareDiamonds.com/software/ Inetdia::sdmailit sdmailit() 1.0.005 May 9, 2002
 # Date: Wed, 24 Jul 2002 12:30:37 -0500
 # To: support@SoftwareDiamonds.com
 # From: somebody@compuserve.com
 # Subject: *~~* Software Diamonds sdform.pl *~~*
 # 
 # Comments:
 # i read an interesting article many years ago about the effects of drugs on spiders in National Geographic Magazine. %0Ait showed webs woven by spiders ""under the influence.""  spiders high on marijuana wove bad webs; spiders on LSD wove exceptionally geometrical webs.%0Aanyone know how i can locate the date of and issue this appeared in?%0A %0Amany thanks in advance to someone who has walked at least a mile in my shoes.
 # ^
 # 
 # Email:
 # sombody@compuserve.com
 # ^
 # 
 # REMOTE_ADDR:
 # 216.192.88.155
 # ^
 # 
 # HTTP_USER_AGENT:
 # Mozilla/4.0 (compatible; MSIE 5.0; Windows 98; DigExt)
 # ^
 # 
 # HTTP_REFERER:
 # http://www.spiderdiamonds.com/spider.htm
 # ^
 # 
 # '
 # 

 ##################
 # Subroutine decode email fields
 # 

 decode_field(\$email)

 # [
 #           'X-Pickup-Date',
 #           'Wed Jul 24 20:20:19 2002',
 #           'X-Persona',
 #           '<support@SoftwareDiamonds.com>',
 #           'Return-Path',
 #           'somebody@compuserve.com',
 #           'Delivered-To',
 #           'support@SoftwareDiamonds.com',
 #           'Received',
 #           '(qmail 7321 invoked from network); 24 Jul 2002 17:26:21 -0000',
 #           'Received',
 #           'from unknown (HELO mail.hbhosting.com) (66.28.88.4)
 #   by mail.ixpres.com with SMTP; 24 Jul 2002 17:26:21 -0000',
 #           'Received',
 #           '(qmail 17747 invoked by uid 89); 24 Jul 2002 17:38:56 -0000',
 #           'Delivered-To',
 #           'softwarediamonds.com-support@softwarediamonds.com',
 #           'Received',
 #           '(qmail 17745 invoked from network); 24 Jul 2002 17:38:56 -0000',
 #           'Received',
 #           'from unknown (HELO compuserve.com) (66.28.118.5)
 #   by 66.28.88.9 with SMTP; 24 Jul 2002 17:38:56 -0000',
 #           'X-Mailer',
 #           'SoftwareDiamonds.com/software/ Inetdia::sdmailit sdmailit() 1.0.005 May 9, 2002',
 #           'Date',
 #           'Wed, 24 Jul 2002 12:30:37 -0500',
 #           'To',
 #           'support@SoftwareDiamonds.com',
 #           'From',
 #           'somebody@compuserve.com',
 #           'Subject',
 #           '*~~* Software Diamonds sdform.pl *~~*',
 #           'X-Body',
 #           'Comments:
 # i read an interesting article many years ago about the effects of drugs on spiders in National Geographic Magazine. %0Ait showed webs woven by spiders ""under the influence.""  spiders high on marijuana wove bad webs; spiders on LSD wove exceptionally geometrical webs.%0Aanyone know how i can locate the date of and issue this appeared in?%0A %0Amany thanks in advance to someone who has walked at least a mile in my shoes.
 # ^
 # 
 # Email:
 # sombody@compuserve.com
 # ^
 # 
 # REMOTE_ADDR:
 # 216.192.88.155
 # ^
 # 
 # HTTP_USER_AGENT:
 # Mozilla/4.0 (compatible; MSIE 5.0; Windows 98; DigExt)
 # ^
 # 
 # HTTP_REFERER:
 # http://www.spiderdiamonds.com/spider.htm
 # ^
 # 
 # '
 #         ]
 # 

=head1 QUALITY ASSURANCE

The module C<t::Tie::Eudora> is the Software
Test Description(STD) module for the C<Tie::CVS>
program module. 

To generate all the test output files, 
run the generated test script,
run the demonstration script,
execute the following in any directory:

 tmake -verbose -demo -run -test_verbose -pm=t::Tie::Eudora

Note that F<tmake.pl> must be in the execution path C<$ENV{PATH}>
and the "t" directory on the same level as the "lib" that
contains the C<Tie::Eudora> program module.
The C<tmake> subroutine is in the C<Test::STDmaker|Test::STDmaker>
distribution file.

=head1 NOTES

=head2 Binding Requirements

In accordance with the License, Software Diamonds
is not liable for any requirement, binding or otherwise.

=head2 Author

The author, holder of the copyright and maintainer is

E<lt>support@SoftwareDiamonds.comE<gt>

=head2 Copyright

copyright © 2003 SoftwareDiamonds.com

=head2 License

Software Diamonds permits the redistribution
and use in source and binary forms, with or
without modification, provided that the 
following conditions are met: 

=over 4

=item 1

Redistributions of source code, modified or unmodified
must retain the above copyright notice, this list of
conditions and the following disclaimer. 

=item 2

Redistributions in binary form must 
reproduce the above copyright notice,
this list of conditions and the following 
disclaimer in the documentation and/or
other materials provided with the
distribution.

=item 3

Commercial installation of the binary or source
must visually present to the installer 
the above copyright notice,
this list of conditions intact,
that the original source is available
at http://softwarediamonds.com
and provide means
for the installer to actively accept
the list of conditions; 
otherwise, a license fee must be paid to
Softwareware Diamonds.

=back

SOFTWARE DIAMONDS, http://www.SoftwareDiamonds.com,
PROVIDES THIS SOFTWARE 
'AS IS' AND ANY EXPRESS OR IMPLIED WARRANTIES,
INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT
SHALL SOFTWARE DIAMONDS BE LIABLE FOR ANY DIRECT,
INDIRECT, INCIDENTAL, SPECIAL,EXEMPLARY, OR 
CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE,DATA, OR PROFITS; OR BUSINESS
INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
OR TORT (INCLUDING USE OF THIS SOFTWARE, EVEN IF
ADVISED OF NEGLIGENCE OR OTHERWISE) ARISING IN
ANY WAY OUT OF THE POSSIBILITY OF SUCH DAMAGE.

=head1 SEE ALSO

=over 4

=item RFC 821, http://www.ietf.org/rfc/rfc821.txt

=item RFC 822, http://www.ietf.org/rfc/rfc822.txt

=item L<Tie::Layers|Tie::Layers>

=item L<Test::STDmaker|Test::STDmaker>

=item L<Tie::Forms|Tie::Form>

=item L<Tie::Eudora|Tie::CSV>

=item L<Data::Query|Data::Query>

=back

=cut

### end of program module  ######



