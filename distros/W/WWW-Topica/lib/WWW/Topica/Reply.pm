package WWW::Topica::Reply;

use strict;

=pod

=head1 NAME 

WWW::Topica::Index - parse a single Topic mailing list index

=head1 SYNOPSIS

    my $index = WWW::Topic::Index->new($index_html);
    
    foreach my $message_id ($index->message_ids) {
        # the mail has some information and also provides a link to the reply ...
        my $mail  = WWW::Topica::Mail->new($topica->fetch_mail($mess_id), $mess_id);
        # which has other information (like the un-htmled mail and the email address) ...            
        my $reply = WWW::Topica::Reply->new($topica->fetch_reply($mail->id, $mail->eto), $mail->id, $mail->eto);
    }
    
    print "Next offset is ".$index->next."\n";
    print "Previous offset is ".$index->prev."\n";

=head1 DESCRIPTION

Used to parse a single reply page from Topica.com's mailing list indexes.

Reply pages have the body of the email (albeit quoted) and potentially a full email address.

=head1 METHODS

=cut


=head2 new <page html> <message id> <eto>

Takes the html of the page, the eto and the message-id and parses the html.

=cut


sub new {
    my ($class, $html, $id, $eto) = @_;
    
    my $self = { id=>$id, eto=>$eto };
    
    bless $self, $class;
    
    $self->parse($html);
    
    return $self;
}


=head2 parse <html>

Parse the html to get the subject, email address and body of the email.

=cut

sub parse {
    my ($self,$html) = @_;
    
    (undef, $self->{email}) = ($html =~ m!<INPUT TYPE\="hidden" NAME\="eto"(.+?)SIZE\="-2">(.+?)</FONT>!s);
    ($self->{subject})      = ($html =~ m!NAME\="subject" SIZE\=28 VALUE\="(.+?)"!s);    
    ($self->{body})         = ($html =~ m!<TEXTAREA NAME\="body" ROWS\=13 COLS\=70 WRAP\=AUTO>(.+?)</TEXTAREA>!s);

    return unless $self->{body};

    # the body is quoted as if ready to reply. So we need to clean that up.
    $self->{body} =~ s!^(.+?) wrote:!!sg;
    $self->{body} =~ s!^>\s?!!msg;

    
}

=head2 id

Get the message id

=cut

sub id {
    return $_[0]->{id};
}

=head2 eto

Get the message eto

=cut

sub eto {
    return $_[0]->{eto};
}

=head2 email 

Get the email address parsed out.

=cut

sub email {
    my $email = $_[0]->{email} || "";
    
    return $email;
}


=head2 subject 

Get the email subject parsed out.

=cut

sub subject {
    my $subject = $_[0]->{subject} || "";
    return $subject;
}

=head2 body

Get the email body parsed out.

=cut

sub body {
    return $_[0]->{body};
}


1;

=head1 AUTHOR

Simon Wistow <simon@thegestalt.org>

=head1 COPYRIGHT

Copyright (c) 2004, Simon Wistow

=cut




