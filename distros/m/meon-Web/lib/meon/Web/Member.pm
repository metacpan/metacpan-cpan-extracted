package meon::Web::Member;

use Moose;
use 5.010;

use Path::Class 'file';
use DateTime;
use XML::LibXML 'XML_TEXT_NODE';
use Email::Valid;
use Carp 'croak';
use meon::Web::ResponseXML;
use meon::Web::env;
use DateTime::Format::Strptime;
use Data::UUID::LibUUID 'new_uuid_string';
use Email::MIME;
use Email::Sender::Simple qw(sendmail);
use Data::asXML;
use Scalar::Util;
use Catalyst::Authentication::Store::UserXML::User;

has 'members_folder' => (is=>'rw',isa=>'Any',required=>1);
has 'username'       => (is=>'rw',isa=>'Str',required=>1);
has 'xml'            => (is=>'ro', isa=>'XML::LibXML::Document', lazy => 1, builder => '_build_xml');
has 'member_meta'    => (is=>'ro', isa=>'XML::LibXML::Node',lazy=>1,builder=>'_build_member_meta');

my $dxml = Data::asXML->new(pretty => 0);

sub _build_xml {
    my ($self) = @_;

    return XML::LibXML->load_xml(
        location => $self->member_index_filename
    );
}

sub _build_member_meta {
    my ($self) = @_;

    my $xml = $self->xml;
    my $xpc = meon::Web::env->xpc;
    my ($member_meta) = $xpc->findnodes('//w:member-profile',$xml);
    return $member_meta;
}

sub _xc {
    my ($self) = @_;
    my $meta = $self->member_meta;
    my $xc = XML::LibXML::XPathContext->new($meta);
    $xc->registerNs('w', 'http://web.meon.eu/');
    return $xc;
}

sub exists {
    my ($self) = @_;
    return -r $self->member_index_filename;
}

sub set_member_meta {
    my ($self, $name, $value) = @_;

    my ($element) = $self->_xc->findnodes('//w:'.$name);

    my $encoded = 0;
    if (ref($value) && !blessed($value)) {
        $value = $dxml->encode($value);
        $encoded = 1;
    }

    if ($element) {
        foreach my $child ($element->childNodes()) {
            $element->removeChild($child);
        }
    }
    else {
        my $meta_element = $self->member_meta;
        $meta_element->appendText(q{ }x4);
        $element = $meta_element->addNewChild($meta_element->namespaceURI,$name);
        $meta_element->appendText("\n");
    }

    if ($encoded) {
        $element->setAttribute('encoded' => 1);
        $element->appendChild($value);
    }
    else {
        $element->appendText($value);
    }
}

sub get_member_meta {
    my ($self, $name) = @_;

    my $element = $self->get_member_meta_element($name);
    return undef unless $element;

    if ($element->getAttribute('encoded')) {
        ($element) = $self->_xc->findnodes('w:*',$element);
        return $dxml->decode($element)
    }
    else {
        return $element->textContent;
    }
}

sub get_member_meta_element {
    my ($self, $name) = @_;
    my ($element) = $self->_xc->findnodes('//w:'.$name);
    return $element;
}

sub delete_member_meta {
    my ($self, $name) = @_;
    my ($element) = $self->get_member_meta_element($name);
    return unless $element;

    my $meta = $self->member_meta;
    map { $meta->removeChild($_) }
    grep { $_->nodeType == XML_TEXT_NODE }
    grep { $_ }
    ($element->previousSibling(), $element->nextSibling());

    $meta->removeChild($element);
    $meta->appendText("\n");

    return $element;
}

sub create {
    my ($self, %args) = @_;

    my $filename = $self->member_index_filename;
    my $username = $self->username;
    my $name     = $args{name};
    my $email    = $args{email};
    my $sex      = $args{sex};
    my $address  = $args{address};
    my $lat      = $args{lat};
    my $lng      = $args{lng};
    my $reg_form = $args{registration_form};
    my $created  = DateTime->now('time_zone' => 'UTC')->iso8601;

    # FIXME instead of direct string interpolation, use setters so that XML special chars are properly escaped
    $filename->spew(qq{<?xml version="1.0" encoding="UTF-8"?>
<page
    xmlns:xhtml="http://www.w3.org/1999/xhtml"
    xmlns="http://web.meon.eu/"
    xmlns:w="http://web.meon.eu/"
>

<meta>
    <title></title>
    <user xmlns="http://search.cpan.org/perldoc?Catalyst%3A%3AAuthentication%3A%3AStore%3A%3AUserXML">
        <status>registration-pending</status>
        <username>$username</username>
        <password>***DISABLED***</password>
    </user>
</meta>

<content><div xmlns="http://www.w3.org/1999/xhtml">
<w:member-profile xmlns="http://web.meon.eu/">
    <dir-listing path="archive/"/>
    <public-listing>1</public-listing>
    <full-name></full-name>
    <email></email>
    <sex></sex>
    <email-validated>0</email-validated>
    <created>$created</created>
    <address></address>
    <lat></lat>
    <lng></lng>
    <registration-form></registration-form>
</w:member-profile>
</div></content>

</page>
});

    $self->set_member_meta('title',$name);
    $self->set_member_meta('full-name',$name);
    $self->set_member_meta('email',$email);
    $self->set_member_meta('sex',$sex);
    $self->set_member_meta('address',$address);
    $self->set_member_meta('lat',$lat);
    $self->set_member_meta('lng',$lng);
    $self->set_member_meta('registration-form',$reg_form);
    $self->store;
}

sub dir {
    my $self = shift;

    return Path::Class::dir($self->members_folder, $self->username);
}

sub member_index_filename {
    my $self = shift;

    return file($self->members_folder, $self->username, 'index.xml');
}

sub store {
    my $self = shift;

    my $filename = $self->member_index_filename;
    my $xml = $self->xml;
    $filename->spew($xml->toString);
}

sub _find_by_callback {
    my ($class, %args) = @_;

    my $members_folder = $args{members_folder};
    croak 'need members_folder as argument'
        unless $members_folder;
    $members_folder = Path::Class::dir($members_folder);
    my $callback = $args{callback};
    croak 'need callback as argument'
        unless $members_folder;

    foreach my $member_folder ($members_folder->children) {
        my $username = $member_folder->basename;
        my $member = meon::Web::Member->new(
            members_folder => $members_folder,
            username       => $username,
        );
        next unless $member->exists;
        return $member
            if $callback->($member);
    }

    return;
}

sub find_by_email {
    my ($class, %args) = @_;

    my $members_folder = $args{members_folder};
    croak 'need members_folder as argument'
        unless $members_folder;
    $members_folder = Path::Class::dir($members_folder);
    my $email = $args{email};
    croak 'need email as argument'
        unless $members_folder;

    return $class->_find_by_callback(
        members_folder => $members_folder,
        callback       => sub {
            return 1 if $_[0]->plain_email eq $email;
        },
    );
}

sub find_by_token {
    my ($class, %args) = @_;

    my $members_folder = $args{members_folder};
    croak 'need members_folder as argument'
        unless $members_folder;
    $members_folder = Path::Class::dir($members_folder);
    my $token = $args{token};
    croak 'need token as argument'
        unless $members_folder;

    return $class->_find_by_callback(
        members_folder => $members_folder,
        callback       => sub {
            return 1 if $_[0]->valid_token($token);
        },
    );
}

sub email {
    my $self = shift;
    return $self->get_member_meta('email');
}

sub plain_email {
    my $self = shift;
    return Email::Valid->address($self->get_member_meta('email')).'';
}

sub valid_token {
    my ($self, $token) = @_;
    return unless $token;

    my $member_token = $self->get_member_meta('token');
    return unless $member_token;

    my $valid_until = DateTime::Format::Strptime->new(
        pattern   => '%FT%T',
    )->parse_datetime($self->get_member_meta('token-valid'));
    return unless $valid_until;
    return unless DateTime->now < $valid_until;

    return 0 unless $token eq $member_token;

    $self->delete_member_meta('token');
    $self->delete_member_meta('token-valid');
    $self->store;

    return 1;
}

sub set_token {
    my ($self, $hours) = @_;

    $hours //= 4;
    my $token = new_uuid_string(4);
    my $token_valid = DateTime->now->add(hours => $hours);

    $self->set_member_meta('token',$token);
    $self->set_member_meta('token-valid',$token_valid);
    $self->store;
    return $token;
}

sub send_password_reset {
    my ($self, $from, $change_pw_url) = @_;

    croak 'need from' unless $from;
    croak 'need change_pw_url' unless $change_pw_url;

    my $token = $self->set_token;
    $change_pw_url->query_param('auth-token' => $token);
    $change_pw_url = $change_pw_url->absolute;

    my $display_name  = $self->get_member_meta('full-name') // 'Madam or Sir';
    my $body = qq{Dear $display_name,

here is your one-time authentication token url for resetting your password:

$change_pw_url

Best regards
Support team
};
    my $email = Email::MIME->create(
        header_str => [
            From    => $from,
            To      => $self->email,
            Subject => 'Your password reset',
        ],
        attributes => {
            content_type => "text/plain",
            charset      => "UTF-8",
            encoding     => "8bit",
        },
        body_str => $body,
    );
    sendmail($email->as_string);
}

sub last_name {
    my ($self) = @_;

    my $full_name = $self->get_member_meta('full-name');
    return undef unless defined($full_name);
    $full_name =~ s/\s+$//;   # remove trailing space
    $full_name =~ s/,.+?$//;  # remove title
    my @names = split(/\s+/,$full_name);
    return $names[-1];
}

sub user {
    my ($self) = @_;
    return Catalyst::Authentication::Store::UserXML::User->new({
        xml_filename => $self->member_index_filename,
        xml          => $self->xml,
    });
}

sub expires {
    my ($self) = @_;
    my $expires = DateTime::Format::Strptime->new(
        pattern   => '%F',
    )->parse_datetime($self->get_member_meta('expires'));
    return $expires;
}

sub extend_expiration_by_1y {
    my ($self) = @_;
    my $now = DateTime->now;
    my $expires = $self->expires;
    $expires = $now
        if (!$expires || $expires < $now);
    $expires->add('years' => 1);
    $self->set_member_meta('expires',$expires->strftime('%Y-%m-%d'));
    $self->user->set_status('active');
}

sub shred_password {
    my ($self) = @_;
    my $xml = $self->xml;
    my $xpc = meon::Web::env->xpc;
    my ($pw_el) = $xpc->findnodes('//u:password',$xml);
    $pw_el->removeChildNodes();
    $pw_el->appendText('***');

}

sub is_active {
    my ($self) = @_;
    return $self->user->status eq 'active';
}

sub section {
    my ($self) = @_;
    return lc(substr($self->last_name // '-',0,1))
}

__PACKAGE__->meta->make_immutable;

1;
