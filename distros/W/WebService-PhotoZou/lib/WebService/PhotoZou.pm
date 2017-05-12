package WebService::PhotoZou;
use strict;
use warnings;
use base qw(Class::Accessor::Fast);

use Carp;
use HTTP::Request::Common;
use LWP::UserAgent;
use XML::Simple;

our $VERSION = '0.01';

my %API_ROOT = (
    jp  => 'http://api.photozou.jp/rest/',
    com => 'http://api.photozou.com/rest/',
);

__PACKAGE__->mk_accessors(qw/username password errors/);

sub new {
    my ($class, %opt) = @_;
    my $site = $opt{site} || 'jp';
    my $api_root = $API_ROOT{$site};
    croak("unknown site $site") unless $api_root;
    my ($host) = $api_root =~ m!^http://(.*?)/!;
    my $self = bless {
        username => $opt{username} || '',
        password => $opt{password} || '',
        api_root => $api_root,
        host     => $host,
    }, $class;
    $self;
}

sub ua {
    my $self = shift;
    if (@_) {
        $self->{ua} = shift;
    } else {
        $self->{ua} and return $self->{ua};
        $self->{ua} = LWP::UserAgent->new;
        $self->{ua}->agent(__PACKAGE__."/$VERSION");
    }
    $self->{ua};
}

sub _request {
    my ($self, $url, %param) = @_;
    $self->ua->credentials("$self->{host}:80", 'photo', $self->username, $self->password);
    my $req = (grep { ref $_ eq 'ARRAY' } values %param)
        ? POST($self->{api_root}.$url, Content_Type => 'form-data', Content => [%param])
        : POST($self->{api_root}.$url, [%param]);
    my $res = $self->ua->request($req);
    croak("request failed.\n".$res->status_line) if $res->is_error;
    $res->content;
}

sub _to_result {
    my ($self, $xml, %opt) = @_;
    if (exists $opt{ForceArray}) {
        push @{$opt{ForceArray}}, 'err';
    } else {
        $opt{ForceArray} = ['err'];
    }
    my $result = XML::Simple::XMLin($xml, %opt);
    if ($result->{stat} eq 'fail') {
        $self->{errors} = $result->{err};
        return;
    }
    $result;
}

sub nop {
    my $self = shift;
    my $content = $self->_request('nop');
    my $res = $self->_to_result($content) or return;
    $res->{stat};
}

sub photo_add {
    my ($self, %param) = @_;
    croak('paramater photo is required') unless exists $param{photo};
    croak('paramater album_id is required') unless exists $param{album_id};
    $param{photo} = [$param{photo}];
    my $content = $self->_request('photo_add', %param);
    my $res = $self->_to_result($content) or return;
    $res->{photo_id};
}

sub photo_add_album {
    my ($self, %param) = @_;
    croak('paramater name is required') unless exists $param{name};
    my $content = $self->_request('photo_add_album', %param);
    my $res = $self->_to_result($content) or return;
    $res->{album_id};
}

sub photo_album {
    my $self = shift;
    my $content = $self->_request('photo_album');
    my $res = $self->_to_result($content,
        KeyAttr    => 'album',
        ForceArray => ['album'],
    ) or return;
    $res->{info}->{album} || [];
}

sub search_public {
    my ($self, %param) = @_;
    my $content = $self->_request('search_public', %param);
    my $res = $self->_to_result($content, ForceArray => ['photo']) or return;
    $res->{info}->{photo} || [];
}

sub user_group {
    my $self = shift;
    my $content = $self->_request('user_group');
    my $res = $self->_to_result($content,
        keyAttr    => 'user_group',
        ForceArray => ['user_group'],
    ) or return;
    $res->{info}->{user_group} || [];
}

sub errormsg {
    my $self = shift;
    my $msg;
    for my $error (@{$self->errors}) {
        $msg .= "$error->{code}: $error->{msg}\n";
    }
    $msg;
}

1;
__END__

=head1 NAME

WebService::PhotoZou - Easy-to-use Interface for PhotoZou Web Services

=head1 SYNOPSIS

  use WebService::PhotoZou;

  my $api = WebService::PhotoZou->new(
      username => $username,
      password => $password,
      site     => 'jp',      # if you use photozou.com, set 'com'.
  );

  my $photo_id = $api->photo_add(
      photo       => $filename, # required
      album_id    => $album_id, # required
      photo_title => $title,
      tag         => $tag,
      comment     => $comment,
      date_type   => 'date',    # 'exif' or 'date'
      year        => $year,     # required when date_type is 'date'
      month       => $month,    # required when date_type is 'date'
      day         => $day,      # required when date_type is 'date'
  ) or die $api->errormsg;

  my $album_id = $api->photo_add_album(
      name                   => $name,        # required
      description            => $description,
      perm_type              => 'allow',      # 'allow' or 'deny'
      perm_type2             => 'user_group', # 'net' or 'everyone' or 'all or 'user_group'
      perm_id                => $perm_id,     # you can set it when you set perm_type2 'user_group'
      order_type             => 'upload',     # 'upload' or 'date' or 'comment' or 'file_name'
      copyright_type         => 'normal',     # 'normal' or 'creativecommons'
      copyright_commercial   => 'yes',        # 'yes' or 'no'
      copyright_modification => 'yes',        # 'yes' or 'no' or 'share'
  ) or die $api->errormsg;

  my $albums = $api->photo_album or die $api->errormsg;
  for my $album (@{$albums}) {
      $album->{album_id};
      $album->{user_id};
      $album->{name};
      $album->{description};
      $album->{perm_type};
      $album->{perm_type2};
      $album->{perm_id};
      $album->{order_type};
      $album->{photo_num};
  }

  my $photos = $api->search_public(
      type                    => 'photo',  # 'photo' or 'video' or 'all'
      order_type              => 'date',   # 'date' or 'favorite'
      keyword                 => $keyword,
      copyright               => 'normal', # 'normal' or 'creativecommons' or 'all'
      copyright_commercial    => 'yes',    # you can set 'yes' or 'no' when you set copyright 'creativecommons'
      copyright_modifications => 'yes',    # you can set 'yes' or 'no' or 'share' when you set copyright 'creativecommons'
      limit                   => 1000,
      offset                  => 0,
  ) or die $api->errormsg;
  for my $photo (@{$photos}) {
      $photo->{photo_id};
      $photo->{user_id};
      $photo->{album_id};
      $photo->{photo_title};
      $photo->{favorite_num};
      $photo->{comment_num};
      $photo->{copyright};
      $photo->{copyright_commercial};
      $photo->{copyright_modifications};
      $photo->{regist_time};
      $photo->{url};
      $photo->{image_url};
      $photo->{original_image_url};
      $photo->{thumbnail_image_url};
  }

  my $groups = $api->user_group or die $api->errormsg;
  for my $group (@{$groups}) {
      $group->{group_id};
      $group->{name};
      $group->{user_num};
  }

=head1 DESCRIPTION

This module priovides you an Object Oriented interface for PhotoZou Web Services.

PhotoZou (http://photozou.jp/) is a Internet-based service that
can easily share photo and album.

=head1 METHODS

All API methods returns undef on failure.
You can get error objects by errors or get formatted message by errormsg.

=head2 new([%options])

Returns an instance of this module.
The following option can be set:

  username
  password
  site     # 'jp' or 'com'

=head2 ua([$ua])

Set or get an LWP::UserAgent instance.

=head2 username([$username])

Accessor for username.

=head2 password([$password])

Accessor for password.

=head2 photo_add(%options)

Add photo/movie.
Returns added photo/movie's id.
The following option can be set:

  photo       # must be set filename.
  album_id    # required
  photo_title
  tag
  comment
  date_type   # 'exif' or 'date'
  year        # required when date_type is 'date'
  month       # required when date_type is 'date'
  day         # required when date_type is 'date'

See the official API documents about detail of options and return values.

=head2 photo_add_album(%options)

Add album.
Returns added album's id.
The following option can be set:

  name                   # required
  description
  perm_type              # 'allow' or 'deny'
  perm_type2             # 'net' or 'everyone' or 'all or 'user_group'
  perm_id                # you can set when you set perm_type2 'user_group'
  order_type             # 'upload' or 'date' or 'comment' or 'file_name'
  copyright_type         # 'normal' or 'creativecommons'
  copyright_commercial   # 'yes' or 'no'
  copyright_modification # 'yes' or 'no' or 'share'

=head2 photo_album

Returns your albums list.
The hashref contains the following fields:

  album_id
  user_id
  name
  description
  perm_type
  perm_type2
  perm_id
  order_type
  photo_num

=head2 search_public(%options)

Search public photo/movie.
The following option can be set:

  type                    # 'photo' or 'video' or 'all'
  order_type              # 'date' or 'favorite'
  keyword
  copyright               # 'normal' or 'creativecommons' or 'all'
  copyright_commercial    # you can set 'yes' or 'no' when you set copyright 'creativecommons'
  copyright_modifications # you can set 'yes' or 'no' or 'share' when you set copyright 'creativecommons'
  limit
  offset

Returns result objects as arrayref.
The hashref contains the following fields:

  photo_id
  user_id
  album_id
  photo_title
  favorite_num
  comment_num
  copyright
  copyright_commercial
  copyright_modifications
  regist_time
  url
  image_url
  original_image_url
  thumbnail_image_url

=head2 user_group

Returns your user groups as arrayref.
The hashref contains the following fields:

  group_id
  name
  user_num

=head2 errors

Returns hashref of error objects as arrayref. The hashref contains the following fields:

  code
  msg

=head2 errormsg

Returns formatted error message.

=head2 nop

API test method.

=head1 AUTHOR

Jiro Nishiguchi E<lt>jiro@cpan.orgE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=over 4

=item * http://photozou.jp/

=item * http://photozou.jp/basic/api

=item * http://photozou.com/

=item * http://photozou.com/basic/api

=back

=cut
