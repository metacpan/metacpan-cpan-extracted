package WWW::Topica::Mail;

use strict;

=pod

=head1 NAME 

WWW::Topica::Mail - parse a single Topica mailing list mail

=head1 SYNOPSIS

    my $index = WWW::Topic::Index->new($index_html);
    
    foreach my $mess_id ($index->message_ids) {
        # the mail has some information and also provides a link to the reply ...
        my $mail  = WWW::Topica::Mail->new($topica->fetch_mail($mess_id), $mess_id);
        # which has other information (like the un-htmled mail and the email address) ...            
        my $reply = WWW::Topica::Reply->new($topica->fetch_reply($mail->id, $mail->eto), $mail->id, $mail->eto);
    }
    
    print "Next offset is ".$index->next."\n";
    print "Previous offset is ".$index->prev."\n";

=head1 DESCRIPTION

Used to parse a single message page from Topica.com's mailing list indexes.

Message pages have the subject and the date and time of the mail being sent as 
well as a full name of each sender.

=head1 METHODS

=cut


=head2 new <page html> <id>

Takes the page html and the message-id and parses the html.

=cut


sub new {
    my ($class, $html, $id) = @_;
    
    my $self = { id => $id };
    
    bless $self, $class;
    
    $self->parse($html);
    
    return $self;
}


=head2 parse <html>

Parse the html to get message ids and next & prev offsets.

=cut

sub parse {
    my ($self, $html) = @_;

    
    ($self->{eto},undef,$self->{from})    =  ($html =~ m!window.open\('/lists/[^/]+/read/post.html\?mode\=replytosender\&mid=\d+\&eto\=([^']+)'(.+?)return true">(.+?)</A>!s);
    if (!defined $self->{eto}) {
        ($self->{from}) = ($html =~ m!<FONT FACE\="Geneva,Verdana,Sans-Serif" SIZE\="-2">&nbsp;([^<]+)</FONT>!s);
    }
    (undef,$self->{date})  =  ($html =~ m!http://lists.topica.com/lists/read/images/icon_clock.gif(.+?)<NOBR>(.+?)&nbsp;<\/NOBR>!s);    
    (undef, $self->{subject}) = ($html =~ m!<FONT CLASS\="headline"(.+?)COLOR="#990099"><B>(.+?)</B>!s);
    ($self->{body}) = ($html =~ m!            <FONT FACE\="Geneva,Verdana,Sans-Serif" SIZE\="-2">(.+?)</FONT>!s);

}

=head2 id

Get the id of this mail

=cut

sub id {
    return $_[0]->{id};
}

=head2 eto

Get the eto of the next reply we need to get

=cut

sub eto {
    my $self = shift;
    
    return $self->{eto};

}

=head2 date

Get the date of this mail

=cut

sub date {
    my $date = $_[0]->{date} || "";
    
    return $date;
}

=head2 subject

The subject of the mail

=cut

sub subject {
    my $subject = $_[0]->{subject} || "";
    return $subject;
}

=head2 from

Get the name of the person it was from

=cut 

sub from {
    my $from =  $_[0]->{from} || "";
    return $from;
}

=head2 body 

Get the body of the mail.

=cut

sub body {
    my $body = $_[0]->{body} || "";
    return $body;
}

1;

=head1 AUTHOR

Simon Wistow <simon@thegestalt.org>

=head1 COPYRIGHT

Copyright (c) 2004, Simon Wistow

=cut



