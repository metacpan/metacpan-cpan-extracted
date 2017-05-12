package WebService::Gyazo;

use strict;
use warnings;

use WebService::Gyazo::Image;

use LWP::UserAgent;
use LWP::Protocol::socks;
use HTTP::Request::Common;
use URI::Simple;

our $VERSION = 0.03;

use constant {
	HTTP_PROXY => 'http',
	SOCKS4_PROXY => 'socks4',
	SOCKS5_PROXY => 'socks',
	HTTPS_PROXY => 'https',
};

sub new {
	my ($self, %args) = @_;
	$self = bless(\%args, $self);

	return $self;
}

# Получить текст ошибки
sub error {
	my ($self) = @_;
	return ($self->{error}?$self->{error}:'N/A');
}

sub isError {
	my ($self) = @_;
	return ($self->{error}?1:0);
}

# Установить прокси
sub setProxy {
	my ($self, $proxyStr) = @_;
	
	# Если  был передан
	if ($proxyStr) {
		
		#  Выбираем из него ip и port
		#my ($protocol, $ip, $port) = $proxyStr =~ m#(\w+)://(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}):(\d{1,5})#;

		my $proxyUrl = URI::Simple->new($proxyStr);
		my ($protocol, $ip, $port) = ( $proxyUrl->protocol, $proxyUrl->host, ($proxyUrl->port || '80') );
		#print "\n\$protocol=$protocol\n\$ip=$ip\n\$port=$port\n";

		if ( defined($protocol) and defined($ip) and defined($port) ) {
			
			unless ( $protocol eq HTTP_PROXY or $protocol eq HTTPS_PROXY or $protocol eq SOCKS4_PROXY or $protocol eq SOCKS5_PROXY ) {
				$self->{error} = "Wrong protocol type [".$protocol."]";
				return 0;
			}

			# Проверяем правильность введённых значений
			if ( $port <= 65535 ) {
				$self->{proxy} = $protocol.'://'.$ip.':'.$port;
				return 1;
			} else {
				$self->{error} = 'Error proxy format!';
				return 0;
			}
		
		# Иначе возращяем отрицание
		} else {
			$self->{proxy} =  'Wrong proxy protocol, ip or port!';
			return 0;
		}
	
	} else {
		# Иначе возвращяем отрицание
		$self->{error} = 'Undefined proxy value!';
		return 0;
	}
}

# Назнначяем ID
sub setId {
	my ($self, $id) = @_;

	# Проверяем длинну ID
	if ( defined($id) and $id =~ m#^\w+$# and length($id) <= 14 ) {
		$self->{id} = $id;
		return 1;
	} else {
		# Иначе возращяем отрицание
		$self->{error} = 'Wrong id syntax!';
		return 0;
	}
}

# Загружаем файл
sub uploadFile {
	my ($self, $file) = @_;

	# Назначаем ID если он не был назначен
	unless ($self->{id}) {
		$self->{id} = time();
	}
	  
	# Проверяем был ли передан путь к файлу
	unless (defined $file) {
		$self->{error} = 'Wrong file location!';
		return 0;
	}
	
	# Проверяем, файл ли это
	unless (-f $file) {
		$self->{error} = 'It\'s not file!';
		return 0;
	}

	# Проверяем возможность считать файл
	unless (-r $file) {
		$self->{error} = 'File not readable!';
		return 0;
	}

	# создаём объект браузера
	$self->{ua} = LWP::UserAgent->new('agent' => 'Gyazo/'.$VERSION) unless (defined $self->{ua});

	# Назначаем прокси если он были передан
	$self->{ua}->proxy(['http'], $self->{proxy}.'/') if ($self->{proxy});

	# создаём объект для POST-запроса
	my $req = POST('http://gyazo.com/upload.cgi',
		'Content_Type' => 'form-data',
		'Content' => [
			'id' => $self->{id},
			'imagedata' => [$file],
		]
	);

	# выполняем POST-запрос и проверяем ответ
	my $res = $self->{ua}->request($req);
	if (my ($id) = ($res->content) =~ m#http://gyazo.com/(\w+)#is) {
		return WebService::Gyazo::Image->new(id => $id);
	} else {
		$self->{error} = "Cent parsed URL in the:\n".$res->as_string."\n";
		return 0;
	}
	
}

1;

__END__

=head1 NAME

WebService::Gyazo - perl image upload library for gyazo.com

=head1 SYNOPSIS

	use WebService::Gyazo;
	
	my $newUserId = time();

	my $upAgent = WebService::Gyazo->new(id => $newUserId);
	print "Set user id [".$newUserId."]\n";

	my $image = $upAgent->uploadFile('1.jpg');

	unless ($upAgent->isError) {
		print "Image uploaded [".$image->getImageUrl()."]\n";
	} else {
		print "Error:\n".$upAgent->error()."\n\n";
	}

=head1 DESCRIPTION

B<WebService::Gyazo> helps you to upload images to gyazo.com (via regular expressions and LWP).

=head1 METHODS

=head2 C<new>

	my $userID = time();
	my $wsd = WebService::Gyazo->new(id => $userID);

Constructs a new C<WebService::Gyazo> object.
Parameter id is optional, if the parameter is not passed, it will take the value of the time() function.

=head2 C<setProxy>

	my $proxy = 'http://1.2.3.4:8080';
	if ($wsd->setProxy($proxy)) {
		print "Proxy [".$proxy."] seted!";
	} else {
		print "Proxy not seted! Error [".$wsd->error."]";
	}

Set proxy C<1.2.3.4:8080> and protocol http for C<LWP::UserAgent> object.

=head2 C<error>

	print "Error [".$wsd->error."]" if ($wsd->isError);

This method return text of last error.

=head2 C<isError>

	print "Error [".$wsd->error."]" if ($wsd->isError);

This method return 1 if $wsd->{error} not undef, else return 0.

=head2 C<setId>

	my $newUserId = time();
	if ($wsd->setId($newUserId)) {
		print "User id [".$newUserId."] seted!";
	} else {
		print "User id not seted! Error [".$wsd->error."]";
	}

This method set new gyazo user id.

=head2 C<uploadFile>

	my $result = $upAgent->uploadFile('1.jpg');

	if (defined($result) and !$upAgent->isError) {
		print "Returned result[".$result->getImageUrl()."]\n";
	} else {
		print "Error:\n".$upAgent->error()."\n\n";
	}

This metod return object WebService::Gyazo::Image.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WebService::Gyazo

=head1 SEE ALSO

L<WebService::Gyazo::Image>, L<LWP::UserAgent>.

=head1 AUTHOR

SHok, <shok at cpan.org> (L<http://nig.org.ua/>)

=head1 COPYRIGHT

Copyright 2013-2014 by SHok

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut