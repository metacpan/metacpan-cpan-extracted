use Moops;

# nonoh call script (c) Nei<anti.teamidiot.de>

=head1 NAME

WebService::Nonoh - make nonoh calls from Perl

=head1 VERSION

version 0.1

=head1 SYNOPSIS

    my $no = WebService::Nonoh->new(
        service => 'nonoh.net',
        user    => $username,
        pass    => $password,
        printer => sub { print +shift, ': ', @_, "\n" }
    );
    $no->login;
    $no->bala;
    $no->call('+1234567', '+7654321');
    $no->login;
    $no->sms($username, '+7654321', "Hello Mr.");
    $no->logout;

=head1 DESCRIPTION

You can use L<Nonoh|http://www.nonoh.net/> or a compatible web
service, many of L<betamax|http://backsla.sh/betamax> might work. This
module allows you to send SMS or connect calls from Perl. Please also
see L<nonoh> for the docs of command line app.

Warning: The websites do have a captcha if you're unlucky. Then this
script also won't work...

=cut

class WebService::Nonoh 0.1 {
    use warnings;
    use utf8;
    use LWP::ConnCache;
    use WWW::Mechanize;
    use HTML::Parser;
    use CGI;
    use Text::Balanced qw(extract_bracketed extract_quotelike extract_codeblock);
    use JSON::PP;
    use XML::LibXML;
    use Hash::Util qw(lock_ref_keys_plus lock_keys);
    use MIME::Base64;
    use Crypt::CBC;
    use Crypt::Rijndael;
    use constant INFO	=> 'INFO';
    use constant STATUS => 'STATUS';

    sub HI {
	my $status = shift;
	print @_, ($status eq INFO ? ' ...' : ''), "\n"
    }

=head1 METHODS

=head2 new

create new webservice object. the following settings must be specified:

=over

=item service

website address of service to use, e.g. C<nonoh.net>

=item user

username for log in

=item pass

password for your account

=item printer

connect a function here that is called to print any status messages or
progress information. default is to use Perl's C<print> function

=back

=cut

    has service => (is => 'ro');
    has user	=> (is => 'ro');
    has pass	=> (is => 'ro');
    has printer => (is => 'ro', default => sub{\&HI});

=head2 run

command line helper function, please see L<nonoh>

=cut

    sub run {
	if (@ARGV && $ARGV[0] eq '') {
	    splice @ARGV, 0, 1, do "$ENV{HOME}/.nonohrc"
	}
	my ($service, $user, $pass, $from, $to, $msg) = @ARGV;
	die "USAGE: $0 SERVICE USER PASS [FROM TO [MESSAGE]]\n" unless @ARGV >= 3;
	die "USAGE: $0 SERVICE USER PASS FROM TO\n" if @ARGV == 4;
	die "USAGE: $0 SERVICE USER PASS FROM TO MESSAGE\n" if @ARGV >= 7;
	my $o = __PACKAGE__->new(
	    service => $service,
	    user => $user,
	    pass => $pass
	   );
	$o->login;
	if ($msg) {
	    $o->sms($from, $to, $msg);
	}
	elsif ($from) {
	    $o->call($from, $to);
	}
	else {
	    $o->bala(1);
	}
	$o->logout;
    }

    method base { 'https://www.' . $self->service }

    method rebuild {
	$self->{mech} = WWW::Mechanize->new(autocheck => 1, stack_depth => 0);
	$self->{mech}->conn_cache(LWP::ConnCache->new());
	$self->{script} = [];
	$self->{hp} = HTML::Parser->new(
	    start_h => [
		sub { shift->handler(text => $self->{script}, '@{dtext}') }, 'self' ],
	    end_h => [
		sub { shift->handler(text => undef) }, 'self' ]);
	$self->{hp}->report_tags('script');
    }

    method _script_parse($content) {
	@{ $self->{script} } = ();
	$self->{hp}->parse($content);
    }

    method BUILD {
	$self->rebuild;
	$self->{lx} = XML::LibXML->new();
	$self->{lx}->recover(2);
    }

=head2 login

issue log-in request to website

=cut

    method login {
	$self->{mech}->get($self->base . '/login/');
	$self->printer->( INFO, 'checking with ', $self->service );
	$self->_script_parse($self->{mech}->content);
	my ($key, $pass);
	for (@{$self->{script}}) {
	    if (/getDecValue\((["'])([^"']+)\1,\s*(["'])([^"']+)\3\)/) {
		($key, $pass) = ($2, $4);
		last;
	    }
	}
	if ($key) {
	    $key = Crypt::CBC
		->new(-key => $pass, -cipher => 'Rijndael')
		    ->decrypt(decode_base64($key));
	    my $doc = $self->{lx}->parse_html_string($self->{mech}->content, { suppress_errors => 1 });
	    my (@hiddens) = $doc->findnodes(qq{//div[\@class="myloginform"][\@id="$key"]//input[\@type="hidden"][\@id=\@name]});
	    my %form_hidden = map { $_->findvalue('@name') => $_->findvalue('@value') } @hiddens;
	    my $nr = 1;
	FORM: for my $form ($self->{mech}->forms) {
		for my $name (keys %form_hidden) {
		    unless (defined $form->value($name) &&
				$form->value($name) eq $form_hidden{$name}) {
			next FORM;
		    }
		}
		last;
	    }
	    continue {
		++$nr;
	    }
	    $self->printer->( INFO, "choosing form $nr" );
	    $self->{mech}->submit_form(
		form_number => $nr,
		fields => +{
		    'login[username]' => $self->user,
		    'login[password]' => $self->pass,
		});
	}
	else {
	    $self->printer->( INFO, 'no key found, maybe they are using a new encryption!!!' );
	    $self->{mech}->submit_form(
		with_fields => +{
		    'login[username]' => $self->user,
		    'login[password]' => $self->pass,
		});
	}

	$self->printer->( INFO, 'log in ', $self->user );
    }

=head2 sms

send SMS, following parameters are expected:

=over

=item I<$from>

a "from" address (must be registered in the web interface first)

=item I<$to>

phone number to send SMS message to

=item I<$message>

the message content

=back

=cut

    #====== SMS =======
    method sms($from, $to, $msg) {
	$self->{mech}->get($self->base . '/web_sms/');

	$self->{mech}->submit_form(
	    with_fields => {
		message => $msg,
		callerid => $from,
		phonenumber => $to,
	    });

	$self->printer->( INFO, 'sms ', $from, ' --> ', $to );
	$self->printer->( STATUS, $msg );

	my $doc = $self->{lx}->parse_html_string($self->{mech}->content, { suppress_errors => 1 });
	for ($doc->findnodes('//span[contains(@class, "error")]')) {
	    $self->printer->( STATUS, '>>', $_->textContent )
	}
	for ($doc->findnodes('//div[contains(@class, "notification")]/div/text()[normalize-space(.)!=""]')) {
	    $self->printer->( STATUS, $_->findvalue('normalize-space(.)') );
	}
    }
    #==================

=head2 call

establish a call between two phone numbers, following parameters are expected:

=over

=item I<$from>

the number that should be called first, in international format

=item I<$to>

the number that should be called after the first one has been picked
up.

=back

=cut

    #====== CALL ======
    method call($from, $to) {
	$self->{mech}->get($self->base . '/phone_to_phone/') unless $self->{mech}->uri =~ '/phone_to_phone';

	my $cl = $self->{mech}->form_with_fields('country_from', 'country_to');
	my $from_cl = join '|', $cl->find_input('country_from')->possible_values;
	my $to_cl = join '|', $cl->find_input('country_to')->possible_values;
	my ($p_from, $n_from) = $from =~ /^(?:\+|00)($from_cl)(\d+)$/;
	my ($p_to, $n_to) = $to =~ /^(?:\+|00)($to_cl)(\d+)$/;

	$self->{mech}->submit_form(
	    with_fields => {
 		phonenumber_from => $n_from,
 		phonenumber_to => $n_to,
		prefix_from => "+$p_from",
		prefix_to => "+$p_to",
		country_from => $p_from,
		country_to => $p_to,
	    });

	$self->printer->( INFO, 'calling ', "+$p_from $n_from", ' --> ', "+$p_to $n_to" );

	$self->_script_parse($self->{mech}->content);

	my (@errors, @conn, @fin);
	for (@{$self->{script}}) {
	    my $ref = /WebCall/ ? \@conn : [];
	    while (/errormessages\.push/g) {
		my $arg = (extract_bracketed($_))[0];
		$arg = substr $arg, 1, -1;
		$arg = (extract_quotelike($arg))[5];
		push @errors, $arg;
	    }
	    while (/\$\.ajax/g) {
		my %st;
		my $arg = (extract_bracketed($_))[0];
		$arg = substr $arg, 1, -1;
		$arg = (extract_codeblock($arg))[0];
		$arg = substr $arg, 1, -1;
		while ($arg =~ /(\w+)\s*:/g) {
		    my ($key) = $1;
		    if (my $val = (extract_quotelike($arg))[5]) {
			$st{$key} = $val;
		    } else {
			scalar $arg =~ /\G\s*\w+/gc;
			(extract_bracketed($arg));
			(extract_codeblock($arg));
		    }
		}
		push @$ref, lock_keys %st;
		if (/function createFinalConnection/gc) {
		    $ref = \@fin;
		} elsif (/function createNewConnection/gc) {
		    $ref = \@conn;
		}
	    }
	}

	my $orig_flush = $|;
	$|=1;

	for (@conn, @fin) {
	    sleep 1;
	    my $q = new CGI ($_->{data});
	    $self->{mech}->post($_->{url}, [
		map { my $n = $_; map { $n => $_ } $q->param($n) } $q->param ],
				'X-Requested-With' => 'XMLHttpRequest');
	    my $d = decode_json $self->{mech}->content;
	    lock_ref_keys_plus($d, qw(code endcause calculated_balance));
	    $self->printer->( STATUS, '',
		$d->{code}, '/', $d->{callstate}, "\t", join "\t", #(map {
#		    my $s = $_;
#		    "$s: " . join '/', @{$d}{
#			map {$s.'Side'.$_} qw(Tariff SetupCharge TariffIntervall)}
#		} qw(A B)),
		(map { "$_/".$d->{$_}." " } sort { $a cmp $b } keys %$d),
		    ) if defined $d->{code};
	    $self->printer->( STATUS, '>>', $errors[$d->{endcause}] ) if $d->{endcause};
	    $self->printer->( STATUS, 'balance: ', $d->{calculated_balance} )
		if defined $d->{calculated_balance};
	}
	$|=$orig_flush;

    }
    #==================

=head2 bala

this method enquires your balance and "free days" (free minutes to
selected destinations received after charging the account). if the
parameter I<$to_printer> is true, it will send output directly to the
printer, otherwise a pair of ($balance_string, $freedays_string) is
returned.

if log-in failed, two empty strings are returned.

=cut

    #====== BALA ======
    method bala($to_printer) {
	my $doc = $self->{lx}->parse_html_string($self->{mech}->content, { suppress_errors => 1 });
	my $res1 = $doc->findvalue('//span[@class="balance"] | //span[@class="low-balance"]');
	my $res2 = $doc->findvalue('//span[@class="freedays"]');
	if ($to_printer) {
	    $self->printer->( STATUS, $res1 );
	    $self->printer->( STATUS, $res2 );
	}
	else {
	    ($res1, $res2)
	}
    }

=head2 logout

issue log-out request to the website

=cut

    method logout {
	$self->{mech}->get($self->base . '/logout');
	$self->printer->( INFO, 'log out' );
    }
}

=head1 AUTHOR

Ailin Nemui E<lt>ailin at devio dot usE<gt>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Ailin Nemui.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

    1
