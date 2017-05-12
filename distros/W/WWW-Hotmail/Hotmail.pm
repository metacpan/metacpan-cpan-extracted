package WWW::Hotmail;

use Carp qw(croak);
use base 'WWW::Mechanize';
use 5.006;
use strict;
use warnings;

our $VERSION = '0.10';

our $croak_on_error = 0;
our $errstr = '';
our $errhtml = '';

sub new {
    my $class = shift;
	# avoid complaints from M$ by using IE 6.0
    my $self = $class->SUPER::new(agent => 'Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.1)');
    $self->cookie_jar({});
	return $self;
}

sub login {
	my ($self,$email,$pass) = @_;
	unless ($email =~ m/\@([^.]+)\.(.+)/) {
		$errstr = 'You must supply full email addres as the username';
		croak $errstr if $croak_on_error;
		$self->error2html();
		return undef;
	}
	my $domain = lc("$1_$2");
	my $resp = $self->get('http://www.hotmail.com/');
    $resp->is_success || do {
		$errstr = $resp->as_string();
		croak $errstr if $croak_on_error;
		$errhtml = $resp->error_as_HTML;
		return undef;
	};
	# bypass the js detection page
	if ($self->{content} =~ m/<form.*(hiddenform|fmHF).*action=\"(\S+)\".*>/i) {
		$self->form_name($1);
		$self->submit();
	}
	
	$self->form_name('f1');
	# this SHOULD cover charter.com, compaq.net, hotmail.com, msn.com, passport.com, and webtv.net
	# all this java regex crap is needed just for this feature. Maybe this can be done better?
	if ($self->{content} =~ m#name="f1".*action="([^"]+)"#i) {
	#if ($self->{content} =~ m#name="$domain" action="([^"]+)"#) {
		# current_form returns a HTML::Form obj
		$self->current_form()->action($1);
	} else {
		$errstr = 'hotmail format changed or email domain not used with Hotmail';
		croak $errstr if $croak_on_error;
		$self->error2html();
		return undef;
	}
    $self->field(login => $email);
    $self->field(passwd => $pass);
	$resp = $self->submit();
    $resp->is_success || do {
		$errstr = $resp->as_string;
		croak $errstr if $croak_on_error;
		$errhtml = $resp->error_as_HTML;
		return undef;
	};
    #$self->{content} =~ /URL=(.+)"/ or do {
    $self->{content} =~ /replace\(\"(.+?)\"\)/ or do {
		$errstr = 'Hotmail format changed!';
		croak $errstr if $croak_on_error;
		$self->error2html();
		return undef;
	};
    $self->get($1);
	
	# look for the base url for the mailbox
	if ($self->{content} =~ m/_UM\s*=\s*"([^"]+)";?/) {
		$self->{_WWWHotmail_base} = $1;
	} elsif ($self->{content} =~ m!http://login\.passport\.net/uilogin\.srf!) {
	   	$errstr = 'Couldn\'t log in to Hotmail, username or password incorrect';
		croak $errstr if $croak_on_error;
		$self->error2html();
		return undef;
	} else {
	   	$errstr = 'Couldn\'t log in to Hotmail';
		croak $errstr if $croak_on_error;
		$self->error2html();
		return undef;
	}

	$self->{_WWWHotmail_logged_in} = 1;
	
	return 1;
}

sub messages {
    my $self = shift;
	unless (defined($self->{_WWWHotmail_logged_in})) {
		$errstr = 'Not logged in!';
		croak $errstr if $croak_on_error;
		$self->error2html();
		return ();
	}
	my $last_page = 1;
	my $i = 1;
	$self->{_WWWHotmail_msgs} = ();
	# traverse all pages
    while ($i <= $last_page) {
		# sorting avoids getting the same message twice
		$self->get('/cgi-bin/HoTMaiL?'.$self->{_WWWHotmail_base}."&page=$i&Sort=rDate");
		# this finds the ->| link (last page)
		if ($i == 1 && $self->{content} =~ m/'page=(\d+)'/i) {
			$last_page = $1;
		}
		# replace javascript junk
		# and adapt it to grab 'from' AND 'subjects'
		# TODO this can be done better
		my $content = $self->content();
		$content =~ s/\r|\n|&nbsp;//g;
		$content =~ s/javascript\:G\('([^']+)'\)">([^<]+)<\/a><\/td><td>([^<]+)<\/td>/$1">$2|$3<\/a>/gi;
		$self->update_html($content);
		push(@{$self->{_WWWHotmail_msgs}}, map {
			my $x = WWW::Hotmail::Message->new;
			$x->{_WWW_Hotmail_msg} = $_;
			$x->{_WWW_Hotmail_parent} = $self;
			$x;
		} grep { $_->url() =~ /getmsg/ } @{$self->links});
		$i++;
	}
    return @{$self->{_WWWHotmail_msgs}};
}

sub compose {
	my ($self,%args) = @_;
	my @argkeys = ('to','cc','bcc','subject','body');
	$self->get('/cgi-bin/compose?'.$self->{_WWWHotmail_base});

	$self->form_name('composeform');
	# fill in the form fields
	for(@argkeys) {
		# flatten arrays
		if (ref($args{$_}) eq 'ARRAY') {
			$args{$_} = join(',',@{$args{$_}});
		}
		$self->field($_ => delete $args{$_});
	}
	# warn them of mistakes
	for my $bad (keys %args) {
		warn "unknown key '$bad' passed to compose";
	}
	$self->field(_HMaction => 'Send');
	$self->submit();
	unless($self->content() =~ m/Your message has been sent to/) {
		$errstr = 'Your message failed to send';
		croak $errstr if $croak_on_error;
		$self->error2html();
		$self->form_name('composeform');
		$self->field(_HMaction => 'Cancel');
		$self->submit();
		return undef;
	}
	return 1;
}

sub error2html {
	shift if (ref($_[0]));
	my $body = shift || $errstr;
$errhtml = <<EOM;
<HTML>
<HEAD><TITLE>Error</TITLE></HEAD>
<BODY>
<H1>Error</H1>
$body
</BODY>
</HTML>
EOM
}

package WWW::Hotmail::Message;
@WWW::Hotmail::Message::ISA = qw(WWW::Hotmail);

use Mail::Audit;

# TODO this can also be done better
sub from { (split(/\|/, shift->{_WWW_Hotmail_msg}->text()))[0] }

sub subject { (split(/\|/, shift->{_WWW_Hotmail_msg}->text()))[1] }

sub _link { shift->{_WWW_Hotmail_msg} }

sub retrieve {
    my $self = shift;
    my $resp = $self->{_WWW_Hotmail_parent}->get($self->_link()->url().'&raw=0');
    $resp->is_success || do {
		$errstr = $resp->as_string;
		croak $errstr if $croak_on_error;
		$errhtml = $resp->error_as_HTML;
		return undef;
	};
	
	# fix Hotmail's conversions
	my $content = $self->{_WWW_Hotmail_parent}->content();
	$content =~ s/&lt;/</gi;
	$content =~ s/&gt;/>/gi;
	$content =~ s/&quot;/"/gi;
	$content =~ s/&amp;/&/gi;

	# clip the top and bottom
	my @mail = split(/\n/,$content);
    shift @mail;
	pop @mail until $mail[-1] =~ m|</pre>|;
	pop @mail;
	# repair line endings
	@mail = map { $_."\n" } @mail;
    my $msg = Mail::Audit->new(data => \@mail);
	# set this option for them
	$msg->noexit(1);
	return $msg;
}

sub delete {
    my $self = shift;
    my $resp = $self->{_WWW_Hotmail_parent}->get($self->_link()->url());
    $resp->is_success || do { 
		$errstr = $resp->as_string;
		croak $errstr if $croak_on_error;
		$errhtml = $resp->error_as_HTML;
		return undef;
	};
	# fix java junk
	my $content = $self->{_WWW_Hotmail_parent}->content();
	$content =~ s/href="#" onclick="/href="/gis;
	$content =~ s/G\('([^']+)'\);return false;/$1/gis;
	$self->{_WWW_Hotmail_parent}->update_html($content);
	# loop through links and find the delete link
    for (@{$self->{_WWW_Hotmail_parent}->links()}) {
		# the delete link
		if ($_->[0] && $_->[0] =~ m/action=move&tobox=F000000004/i) {
			$self->{_WWW_Hotmail_parent}->get($_->url());
			last;
		}
   }
   return 1;
}

1;
__END__

=head1 NAME

WWW::Hotmail - Connect to Hotmail, download, delete and send messages

=head1 SYNOPSIS

  use WWW::Hotmail;
  
  my $hotmail = WWW::Hotmail->new();
  
  $hotmail->login('foo@hotmail.com', "bar")
   or die $WWW::Hotmail::errstr;
  
  my @msgs = $hotmail->messages();
  die $WWW::Hotmail::errstr if ($!);

  print "You have ".scalar(@msgs)." messages\n";

  for (@msgs) {
  	print "messge from ".$_->from."\n";
	# retrieve the message from hotmail
  	my $mail = $_->retrieve;
	# deliver it locally
	$mail->accept;
	# forward the message
	$mail->resend('myother@email.address.com');
	# delete it from the inbox
  	$_->delete;
  }
  
  $hotmail->compose(
    to      => ['user@email.com','otheruser@otheremail.com'],
    subject => 'Hello Person!',
    body    => q[Dear Person,
  
  I am writing today to tell you about something important.

  Thanks for all your support.
  
  Sincerely,
  Other Person
  ]) or die $WWW::Hotmail::errstr;

=head1 DESCRIPTION

This module is a partial replacement for the C<gotmail> script
(http://ssl.usu.edu/paul/gotmail/), so if this doesn't do what you want,
try that instead.

Create a new C<WWW::Hotmail> object with C<new>, and then log in with
your MSN username and password with the C<login> method.

=head1 METHODS

=head2 login

Make sure to add the domain to your username, for example foo@hotmail.com.
Then this will allow you to use the C<messages> method to look at the mail
in your inbox. The login method does not retrieve messages on login.  The
messages method does that now.

=head2 messages

This method returns a list of C<WWW::Hotmail::Message>s; each message
supports four methods: C<subject> gives you the subject of the email,
just because it was stunningly easy to implement. C<retrieve> retrieves
an email into a C<Mail::Audit> object - see L<Mail::Audit> for more
details. C<from> gives you the from field. Finally C<delete> moves it
to your trash.

=head2 compose

You can use the C<compose> message to send a message through the 
account you are currently logged in to.  You should be able to use
this method as many times and as often as you like during the life
of the C<WWW::Hotmail> object.  As its argument, it takes a hash whose
keys are C<to>, C<cc>, C<bcc>, C<subject>, C<body>.  Newlines should
work fine in the C<body> argument.  Any field can be an array; it will
be joined with a comma.  This function returns 1 on success and undef 
on failure.  Check $WWW::Hotmail::errstr for errors, or use 
$WWW::Hotmail::errhtml for an html version of the error.

=head1 NOTES

This module used to croak errors for you.  If you would like this behavior,
then add $WWW::Hotmail::croak_on_error = 1; to your script.  It will not
croak html.

This module should work with email addresses at charter.com, compaq.net,
hotmail.com, msn.com, passport.com, and webtv.net

This module is reasonably fragile. It seems to work, but I haven't
tested edge cases. If it breaks, you get to keep both pieces. I hope
to improve it in the future, but this is enough for release.

=head1 SEE ALSO

L<WWW::Mechanize>, L<Mail::Audit>, C<gotmail>

=head1 AUTHOR

David Davis, E<lt>xantus@cpan.orgE<gt>
- I've taken ownership of this module, please direct all questions to me.

=head1 ORIGINAL AUTHOR

Simon Cozens, E<lt>simon@kasei.comE<gt>

=head1 CONTRIBUTIONS

David M. Bradford E<lt>dave@tinypig.comE<gt>
- Added the ability to send messages via hotmail.

=head1 COPYRIGHT AND LICENSE

Copyright 2003-2004 by Kasei
Copyright 2004 by David Davis

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
