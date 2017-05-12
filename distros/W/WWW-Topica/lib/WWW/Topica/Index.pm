package WWW::Topica::Index;

use strict;

=pod

=head1 NAME 

WWW::Topica::Index - parse a single Topic mailing list index

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

Used to parse a single index page from Topica.com's mailing list indexes.

=head1 METHODS

=cut


=head2 new <page html>

=cut


sub new {
    my ($class, $html) = @_;
    
    my $self = { };
    
    bless $self, $class;
    
    $self->parse($html);
    
    return $self;
}


=head2 parse <html>

Parse the html to get message ids and next & prev offsets.

=cut

sub parse {
    my ($self, $html) = @_;
    

    my $list = $self->{list};
    ($self->{prev}) = (    $html =~ m!<A HREF="/lists/[^/]+/read\?sort\=d\&start\=(\d+)"><IMG SRC="http://lists.topica.com/art/rewind\.gif"!m );
    
    ($self->{next}) = (    $html =~ m!<A HREF="/lists/[^/]+/read\?sort\=d\&start\=(\d+)"><IMG SRC="http://lists.topica.com/art/fastForward\.gif"!m );
    
    my (@message_ids) = ($html =~ m!/lists/[^/]+/read/message\.html\?mid\=(\d+)!gs);


    $self->{_message_ids} = \@message_ids;

}


=head2 message_ids

Return all the messge ids found on the page

=cut

sub message_ids {
    my $self = shift;    
    return @{$self->{_message_ids}};
}

=head2 prev 

Return the offset of the previous page or undef if there is none.

=cut

sub prev {
    return $_[0]->{prev};
}


=head2 next

Return the offset of the next page or undef if there is none.

=cut

sub next {
    return $_[0]->{next};
}
1;

=head1 AUTHOR

Simon Wistow <simon@thegestalt.org>

=head1 COPYRIGHT

Copyright (c) 2004, Simon Wistow

=cut



