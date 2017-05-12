package WWW::Mail15;
use Carp;
use base 'WWW::Mechanize';
use 5.006;
use strict;
use warnings;

our $VERSION = '0.01';

sub new {
    my $class = shift;
    my $self = $class->SUPER::new();
    $self->cookie_jar({});
    return $self;
}

sub login {
    my ($self,$user,$pass) = @_;
    my $resp = $self->get("http://www.mail15.com/");
    $resp->is_success || croak $resp->error_as_HTML;
    $self->form(2);
    $self->field(user    => $user);
    $self->field(pass    => $pass);
    $resp = $self->submit();
    $resp->is_success || croak $resp->error_as_HTML;
    die "cannot login! (format changed?)" if $self->res->header('title') !~ /Folders list/;
    $self->get($self->res->request->uri);
    $self->{_folders} = $self->parse_folders;
    croak "Couldn't read folder list " unless $self->{_folders};
    return 1;
}

sub folders {
    my $self = shift;
    croak "Not logged in!" unless $self->{_folders};
    return map { keys %{$_} } @{$self->{_folders}};
}

sub read_folder {
    my ($self,$fnum) = @_;
    croak "Not logged in!" unless $self->{_folders};
    my($resp) = $self->get(values %{$self->{_folders}[$fnum]});
    $resp->is_success || croak $resp->error_as_HTML;
    $self->{_folder_mails}->{$fnum} = $self->parse_mails;
}
 
sub parse_folders{
	my($self) = @_;
	my(@p) = (grep { $$_[0] =~ /mailbox\.php.*mailb/ } @{$self->links});
	my(@folders);
	foreach my $folder (@p){
		push @folders , {$$folder[1] => $$folder[0]};
	}
	return \@folders;
}

sub parse_mails {
	my($self) = @_;
	my(@p) = (grep { $$_[0] =~ /message\.php.*index/ } @{$self->links});
	my(@mails);
	for (my $i=0; $i<$#p ; $i+=2) {
		push @mails , WWW::Mail15::Message->new  ($self,$p[$i]->[0],$p[$i]->[1],$p[$i+1]->[1]);
	}
	return \@mails;
}

sub get_mail {
	my($self, $fnum, $mnum) = @_;
	return $self->{_folder_mails}->{$fnum}->[$mnum];
}

package WWW::Mail15::Message;
@WWW::Mail15::Message::ISA = qw(WWW::Mail15);

use Mail::Audit;

sub new {
    my ($class,$parent,$url,$from,$subj) = @_;
    
    my $self = $class->SUPER::new();
    $self -> {_parent} = $parent;
    $self -> {_url}    = $url;
    $self -> {_from}   = $from;
    $self -> {_subj}   = $subj;
	     
    return $self;
}


sub subject { $_[0]->{_subj} }

sub retrieve {
    my $self = shift;
    my $resp = $self->{_parent}->get($self-> {_url});
    $resp->is_success || croak $resp->error_as_HTML;
    my($text) =  $self->{_parent}->content() =~ /<pre>(.*)<\/pre>/si;
    
    return Mail::Audit->new(data => \$text);
}


sub delete {
    my $self = shift;
}

1;
__END__

=head1 NAME

WWW::Mail15 - Connect to Mail15 service and download messages

=head1 SYNOPSIS

  use WWW::Mail15;
  my $browser = new WWW::Mail15;
  $browser->login("foo", "bar");
  print $browser->folders;
  $browser->read_folder(0); # usually the inbox
  print $browser->get_mail(0,0)->subject;
  #get the data, and audit it
  print $browser->get_mail(0,0)->retrieve->accept;

=head1 DESCRIPTION


Create a new C<WWW::Mail15> object with C<new>, and then log in with
your Mail15 username and password. This will allow you to use the
C<folders> method to look at the list of folders, C<read_folder> to get messages
list inside a folder, and C<get_mail> to actually get the message data in form of
C<WWW::Mail15::Message> which supports these methods: 
=over 4

C<subject>
gives you the subject of the email,

C<from>
gives you the sender  of the email,

C<retrieve>
turns the email into a C<Mail::Audit> object - see L<Mail::Audit> for more
details. 

C<delete>
moves it to your trash.

=head1 SEE ALSO

L<WWW::Mechanize>, L<Mail::Audit>

=head1 NOTE

Code template is shamelessly stolen from WWW::Hotmail module.

=head1 AUTHOR

Sir Reflog, E<lt>reflog@mail15.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2003 by Sir Reflog

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
