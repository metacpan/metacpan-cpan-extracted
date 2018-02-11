package WebService::Rajce;
# ABSTRACT: Perl module for rajce.net web API.
$WebService::Rajce::VERSION = '1.180380';
use 5.006;
use strict;
use warnings;

use WWW::Mechanize;
use XML::Simple;
use Digest::MD5 qw(md5_hex);
use Encode;
use Image::Magick;
use Carp;

use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

require Exporter;


our @ISA = qw(Exporter AutoLoader);
our @EXPORT = qw();

sub new {
	my $class = shift;
  my %passed_parms = @_;
	my $self  = {};
	$self->{API} = 'https://www.rajce.idnes.cz/liveAPI/index.php';
	$self->{XML} = '<?xml version="1.0" encoding="utf-8"?>';
	$self->{DEBUG} = $passed_parms{'debug'};
	$self->{KEEP_EXIF} = $passed_parms{'keep_exif'};
	$self->{BOT} = WWW::Mechanize->new(autocheck => 1, agent => 'github.com/petrkle/rajce - '.$VERSION);
	$self->{BOT}->env_proxy();
	$self->{BOT}->add_header('Accept-Encoding'=>'text/html');
	$self->{BOT}->add_header('Accept-Charset'=>'utf-8');
	$self->{BOT}->add_header('Accept-Language'=>'cs');
	$self->{BOT}->cookie_jar(HTTP::Cookies->new());

	$self->{ERRORS} = {
	'1' => 'Unknown error.',
	'2' => 'Invalid command.',
	'3' => 'Invalid login or password.',
	'4' => 'Bad login token.',
	'5' => 'Unknown or repeating column {colName}.',
	'6' => 'Not correct albumID.',
	'7' => 'Album not exist or logged user is not owner.',
	'8' => 'Bad album token.',
	'9' => 'Albumn cant have empty title.',
	'10' => 'Failed to create new album. (hard to say why ... probably an error on the server side).',
	'11' => 'Album not exist.',
	'12' => 'Non existing application.',
	'13' => 'Wrong application key.',
	'14' => 'File is not attached.',
	'15' => 'Already there is a newer version {version}.',
	'16' => 'Error when saving a file.',
	'17' => 'Illegal file extension {extension}.',
	'18' => 'Wrong version number of client.',
	'19' => 'No such object (target).',
	'20' => 'Missing name to protect the album.',
	'21' => 'Missing password to protect the album.',
	'22' => 'Error communication - arrived an empty file.',
	'23' => 'Some blocks of the video are missing.',
	'24' => 'User does not exist.',
	'25' => 'There is the correct userID or albumID.',
	'26' => 'Album not exist or is not belog to this user or isnt public.',
	'27' => 'Invalid clientVideoID.',
	'28' => 'Upload with a given number does not exist.',

	};

	bless($self, $class);
	return $self;
}

sub _debug{
	my ($self,$message) = @_;
	if($self->{DEBUG}){
		print encode("utf8",$message)."\n";
	}
}

sub login {
	my ($self,$mail,$password) = @_;

	my $login = {'request'=>{
			'command'=>['login'],
			'parameters'=>{
				'clientID'=>['Rajce.pm'],
				'currentVersion'=>[$VERSION],
				'lang'=>['cs_CZ'],
				'login'=>[$mail],
				'password'=>[md5_hex($password)]
			},
		}
	};

	my $xml = XMLout($login, KeepRoot => 1, XMLDecl => $self->{XML});
	$self->_debug($xml);
	my $sign = $self->{BOT}->post($self->{API}, {'data' => $xml});
	my $response = XMLin($sign->content());
	$self->_debug($sign->content());

	if($response->{errorCode}){
		confess($self->{ERRORS}{$response->{errorCode}});
	}

	$self->{sessionToken}=$response->{sessionToken};
	$self->{maxWidth}=$response->{maxWidth};
	$self->{maxHeight}=$response->{maxHeight};
	$self->{nick}=$response->{nick};
	return $response;
}

sub list {
	my ($self,$userid) = @_;

	my $listalbums = {'request'=>{
			'command'=>['getAlbumList'],
			'parameters'=>{
				'token'=>[$self->{sessionToken}],
				'userID'=>[$userid],
			},
		}
	};

	my $xml = XMLout($listalbums, KeepRoot => 1, XMLDecl => $self->{XML});
	$self->_debug($xml);
	my $albums = $self->{BOT}->post($self->{API}, {'data' => $xml});
	$self->_debug($albums->content());

return XMLin($albums->content());
}

sub photo_list {
	my ($self,$albumid) = @_;

	my $photolist = {'request'=>{
			'command'=>['getPhotoList'],
			'parameters'=>{
				'token'=>[$self->{sessionToken}],
				'albumID'=>[$albumid],
				'columns'=>{
					'column'=>[
						'date',
						'name',
						'description',
						'url',
						'thumbUrl',
						'thumbUrlBest',
						'urlBase']
				}
			}
		}
	};

	my $xml = XMLout($photolist, KeepRoot => 1, XMLDecl => $self->{XML});
	$self->_debug($xml);
	my $photos = $self->{BOT}->post($self->{API}, {'data' => $xml});
	$self->_debug($photos->content());

return XMLin($photos->content());
}

sub search_users {
	my ($self,$query,$skip,$limit) = @_;

	my $users = {'request'=>{
			'command'=>['searchUsers'],
			'parameters'=>{
				'token'=>[$self->{sessionToken}],
				'query'=>[$query],
				'skip'=>[$skip],
				'limit'=>[$limit],
				'columns'=>{
					'column'=>[
					'fullName',
					'albumCount',
					'viewCount']
				}
			}
		}
	};

	my $xml = XMLout($users, KeepRoot => 1, XMLDecl => $self->{XML});
	$self->_debug($xml);
	my $result = $self->{BOT}->post($self->{API},	{'data' => $xml});
	$self->_debug($result->content());

return XMLin($result->content());
}

sub get_url {
	my ($self,$target) = @_;

	my $geturl = {'request'=>{
			'command'=>['getUrl'],
			'parameters'=>{
				'token'=>[$self->{sessionToken}],
				'target'=>[$target],
			}
		}
	};

	my $xml = XMLout($geturl, KeepRoot => 1, XMLDecl => $self->{XML});
	$self->_debug($xml);
	my $result = $self->{BOT}->post($self->{API},	{'data' => $xml});
	my $response = XMLin($result->content());
	$self->_debug($response->content());

return $response->{url};
}


sub search_albums {
	my ($self,$query,$skip,$limit) = @_;

	my $albums = {'request'=>{
			'command'=>['searchAlbums'],
			'parameters'=>{
				'token'=>[$self->{sessionToken}],
				'query'=>[$query],
				'skip'=>[$skip],
				'limit'=>[$limit],
				'columns'=>{
					'column'=>[
						'description',
						'shortenedDescription',
						'viewCount',
						'mediaCount',
						'createDate']
				}
			},
		}
	};

	my $xml = XMLout($albums, KeepRoot => 1, XMLDecl => $self->{XML});
	$self->_debug($xml);
	my $response = $self->{BOT}->post($self->{API},	{'data' => $xml});
	$self->_debug($response->content());

return XMLin($response->content());
}


sub reg_url {
	my ($self) = @_;

	my $request = {'request'=>{
			'command'=>['getRegisterUrl']
		}
	};

	my $xml = XMLout($request, KeepRoot => 1, XMLDecl => $self->{XML});
	$self->_debug($xml);
	my $regurl = $self->{BOT}->post($self->{API},	{'data' => $xml});
	$self->_debug($regurl->content());

	my $response = XMLin($regurl->content());

	if($response->{errorCode}){
		confess($self->{ERRORS}{$response->{errorCode}});
	}

return $response->{url};
}

sub recover_url {
	my ($self) = @_;

	my $request = {'request'=>{
			'command'=>['getRecoverPasswordUrl']
		}
	};

	my $xml = XMLout($request, KeepRoot => 1, XMLDecl => $self->{XML});
	$self->_debug($xml);
	my $url = $self->{BOT}->post($self->{API}, {'data' => $xml});
	$self->_debug($url->content());

	my $response = XMLin($url->content());

	if($response->{errorCode}){
		confess($self->{ERRORS}{$response->{errorCode}});
	}

return $response->{url};
}

sub create_album {
	my ($self,$title,$desc) = @_;

	my $create = {'request'=>{
			'command'=>['createAlbum'],
			'parameters'=>{
				'token'=>[$self->{sessionToken}],
				'albumName'=>[decode("utf8",$title)],
				'albumDescription'=>[decode("utf8",$desc)],
				'albumVisible'=>[1],
			},
		}
	};

	my $xml = XMLout($create, KeepRoot => 1, XMLDecl => $self->{XML});
	$self->_debug($xml);
	my $album = $self->{BOT}->post($self->{API}, {'data' => $xml});
	$self->_debug($album->content());

	my $response = XMLin($album->content());
	if($response->{errorCode}){
		confess($self->{ERRORS}{$response->{errorCode}});
	}

return $response;
}

sub _open_album {
	my ($self,$album) = @_;

	my $request = {'request'=>{
			'command'=>['openAlbum'],
			'parameters'=>{
				'token'=>[$self->{sessionToken}],
				'albumID'=>[$album->{albumID}],
			},
		}
	};

	my $xml = XMLout($request, KeepRoot => 1, XMLDecl => $self->{XML});
	$self->_debug($xml);
	my $open = $self->{BOT}->post($self->{API},	{'data' => $xml});
	$self->_debug($open->content());

	my $response = XMLin($open->content());

	if($response->{errorCode}){
		confess($self->{ERRORS}{$response->{errorCode}});
	}

return $response;
}

sub _close_album {
	my ($self,$album) = @_;

	my $request = {'request'=>{
			'command'=>['closeAlbum'],
			'parameters'=>{
				'token'=>[$self->{sessionToken}],
				'albumToken'=>[$album->{albumToken}],
			},
		}
	};

	my $xml = XMLout($request, KeepRoot => 1, XMLDecl => $self->{XML});
	$self->_debug($xml);
	my $close = $self->{BOT}->post($self->{API}, {'data' => $xml});
	$self->_debug($close->content());

	my $response = XMLin($close->content());

	if($response->{errorCode}){
		confess($self->{ERRORS}{$response->{errorCode}});
	}

return $response;
}

sub add_photo {
	my ($self,$filename,$album) = @_;

	my $thumbsize = "100x100";

	my $thumb = new Image::Magick;
	$thumb->Read($filename);
	$thumb->AutoOrient();
	$thumb->Resize(geometry=>"$thumbsize^");
	$thumb->Crop(gravity=>"Center",geometry=>"$thumbsize");
	$thumb->Strip();

	my $pic = new Image::Magick;
	$pic->Read($filename);
	$pic->AutoOrient();
	$pic->Resize(geometry=>"$self->{maxWidth}x$self->{maxHeight}>");

	if(!$self->{KEEP_EXIF}){
		$pic->Strip();
	}

	my ($width, $height) = $pic->Get('width','height');
	
	my $request = {'request'=>{
			'command'=>['addPhoto'],
			'parameters'=>{
				'token'=>[$self->{sessionToken}],
				'albumToken'=>[$album->{albumToken}],
				'width'=>[$width],
				'height'=>[$height],
			},
		}
	};

	$self->_open_album($album);

	my $xml = XMLout($request, KeepRoot => 1,	XMLDecl => $self->{XML});
	$self->_debug($xml);

	my $picture = $self->{BOT}->post($self->{API},
		{'data' => $xml,
			'thumb' => [undef,$filename,Content => $thumb->ImageToBlob()],
			'photo' => [undef,$filename,Content => $pic->ImageToBlob()]},
		Content_Type => 'form-data');


	$self->_debug($picture->content());
	my $response = XMLin($picture->content());


	if($response->{errorCode}){
		confess($self->{ERRORS}{$response->{errorCode}});
	}

	$self->_close_album($album);

return $response;
}

sub get_albumurl {
	my ($self,$album) = @_;

	my $url = {'request'=>{
			'command'=>['getAlbumUrl'],
			'parameters'=>{
				'token'=>[$self->{sessionToken}],
				'albumToken'=>[$album->{albumToken}],
			}
		}
	};

	my $xml = XMLout($url, KeepRoot => 1, XMLDecl => $self->{XML});
	$self->_debug($xml);
	my $alb = $self->{BOT}->post($self->{API}, {'data' => $xml});
	$self->_debug($alb->content());
	my $response = XMLin($alb->content());

	if($response->{errorCode}){
		confess($self->{ERRORS}{$response->{errorCode}});
	}

return $response->{url};
}

1;

=pod

=encoding UTF-8

=head1 NAME

WebService::Rajce - Perl module for rajce.net web API.

=head1 VERSION

version 1.180380

=head1 SYNOPSIS

	use WebService::Rajce;
	my $rajce = new WebService::Rajce;
	$rajce->login($mail,$password);
	my $album = $rajce->create_album('Title','Description');
	$rajce->add_photo('/path/to/file.jpg',$album)

=head1 METHODS

=head2 my $rajce = new WebService::Rajce;

Create new object instance.

The C<debug> param turns on debug mode.

The C<keep_exif> param keep EXIF information in uploaded image.

=head2 $rajce->_debug($message);

Show debugging message.

=head2 $rajce->login($mail,$password);

Login to API.

=head2 $rajce->list($userid);

Get list of albums.
NOTICE - list other users albums not implemented in API yet

=head2 $rajce->photo_list($albumid);

Get list of images in album.

=head2 $rajce->search_users($query,$skip,$limit);

Get list of users.
NOTICE - not implemented in API yet

=head2 $rajce->get_url($target);

Get some URL from rajce.net
$target = 'user-profile' | 'email-notifications' | 'service-notifications' ;

=head2 $rajce->search_albums($query,$skip,$limit);

Get list of users.
NOTICE - not implemented in API yet

=head2 $rajce->reg_url();

Get URL where is form for creating new account on rajce.net.

=head2 $rajce->recover_url();

Get URL where is form for recover forget password.

=head2 $rajce->create_album($title,$desc);

Create new album.

=head2 $rajce->_open_album($album);

Open album for adding pictures.

=head2 $rajce->_close_album($album);

Close album after adding pictures.

=head2 $rajce->add_photo($filename,$album);

Add photo into gallery.

=head2 $rajce->get_albumurl($album);

Get URL of album.

=head1 SEE ALSO

https://rajce.net/static/doc/LiveApi.html

=head1 AUTHOR

Petr Kletecka <pek@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Petr Kletecka.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__END__

1;
