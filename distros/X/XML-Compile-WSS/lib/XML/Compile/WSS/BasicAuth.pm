# Copyrights 2011-2017 by [Mark Overmeer].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.02.
use warnings;
use strict;

package XML::Compile::WSS::BasicAuth;
use vars '$VERSION';
$VERSION = '1.14';

use base 'XML::Compile::WSS';

use Log::Report  'xml-compile-wss';

use XML::Compile::WSS::Util qw/:wss11 :utp11 WSM10_BASE64/;

use Digest::SHA  qw/sha1_base64/;
use Encode       qw/encode/;
use MIME::Base64 qw/encode_base64/;
use POSIX        qw/strftime/;


my @nonce_chars = ('A'..'Z', 'a'..'z', '0'..'9');
sub _random_nonce() { join '', map $nonce_chars[rand @nonce_chars], 1..5 }

sub init($)
{   my ($self, $args) = @_;
    $args->{wss_version} ||= '1.1';
    $self->SUPER::init($args);

    $self->{XCWB_username} = $args->{username}
        or error __"no username provided for basic authentication";

    $self->{XCWB_password} = $args->{password}
        or error __x"no password provided for basic authentication";

    my $n     = $args->{nonce};
    my $nonce = ref $n eq 'CODE' ? $n
              : defined $n && $n eq 'RANDOM' ? \&_random_nonce
              :    sub { $n };

    $self->{XCWB_nonce}    = $nonce;
    $self->{XCWB_wsu_id}   = $args->{wsu_Id}   || $args->{wsu_id};
    $self->{XCWB_created}  = $args->{created};
    $self->{XCWB_pwformat} = $args->{pwformat} || UTP11_PTEXT;
    $self;
}

#----------------------------------

sub username() {shift->{XCWB_username}}
sub password() {shift->{XCWB_password}}
sub nonce()    {shift->{XCWB_nonce}->() }
sub wsuId()    {shift->{XCWB_wsu_id}  }
sub created()  {shift->{XCWB_created} }
sub pwformat() {shift->{XCWB_pwformat}}

sub prepareWriting($)
{   my ($self, $schema) = @_;
    $self->SUPER::prepareWriting($schema);
    return if $self->{XCWB_login};

    my $nonce_type = $schema->findName('wsse:Nonce') ;
    my $w_nonce    = $schema->writer($nonce_type, include_namespaces => 0);
    my $make_nonce = sub {
        my ($doc, $nonce) = @_;
        my $enc = encode_base64 $nonce;
        chomp $enc;
        $w_nonce->($doc, {_ => $enc, EncodingType => WSM10_BASE64});
    };

    my $created_type = $schema->findName('wsu:Created');
    my $w_created    = $schema->writer($created_type, include_namespaces => 0);
    my $make_created = sub {
        my ($doc, $created) = @_;
        $w_created->($doc, $created);
    };

    my $pw_type = $schema->findName('wsse:Password');
    my $w_pw    = $schema->writer($pw_type, include_namespaces => 0);
    my $make_pw = sub {
        my ($doc, $password, $pwformat) = @_;
        $w_pw->($doc, {_ => $password, Type => $pwformat});
    };

    # UsernameToken is allowed to have an "wsu:Id" attribute
    # We set up the writer with a hook to add that particular attribute.
    my $un_type = $schema->findName('wsse:UsernameToken');
    my $make_un = $schema->writer($un_type, include_namespaces => 1,
      , hook => $self->writerHookWsuId('wsse:UsernameTokenType'));
    $schema->prefixFor(WSU_10);  # to get ns-decl

    $self->{XCWB_login} = sub {
        my ($doc, $data) = @_;

        my %login =
          ( wsu_Id        => $self->wsuId
          , wsse_Username => $self->username
          );

        my $now      = delete $data->{wsu_Created} || $self->created;
        my $created  = $self->dateTime($now) || '';
        $login{$created_type} = $make_created->($doc, $created) if $created;

        my $nonce    = delete $data->{wsse_Nonce}  || $self->nonce || '';
        $login{$nonce_type} = $make_nonce->($doc, $nonce)
            if length $nonce;

        my $pwformat = $self->pwformat;
        my $password = $self->password;
        $created  = $created->{_} if ref $created eq 'HASH';
        $password = sha1_base64(encode utf8 => "$nonce$created$password").'='
            if $pwformat eq UTP11_PDIGEST;

        $login{$pw_type}  = $make_pw->($doc, $password, $pwformat);
        $data->{$un_type} = $make_un->($doc, \%login);
        $data;
    };
}

sub create($$)
{   my ($self, $doc, $data) = @_;
    $self->SUPER::create($doc, $data);
    $self->{XCWB_login}->($doc, $data);
}

1;
