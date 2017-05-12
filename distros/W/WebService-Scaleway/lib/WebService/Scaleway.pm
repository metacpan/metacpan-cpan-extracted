package WebService::Scaleway;

use 5.014000;
use strict;
use warnings;

our $VERSION = '0.001001';

use Carp qw/croak/;
use HTTP::Tiny;
use JSON::MaybeXS;
use Scalar::Util qw/blessed/;

my $ht = HTTP::Tiny->new(
	agent      => "WebService-Scaleway/$VERSION ",
	verify_SSL => 1,
);

# Instance of WebService::Scaleway with no API key
# Used to create tokens from email/password
my $dummy = '';
$dummy = bless \$dummy, __PACKAGE__;

sub _account ($) { "https://account.scaleway.com$_[0]"}
sub _api     ($) { "https://api.scaleway.com$_[0]" }

sub _request {
	my ($self, $method, $url, $opts) = @_;
	$opts->{headers} //= {};
	$opts->{headers}{'X-Auth-Token'} = $$self if $$self;
	$opts->{headers}{'Content-Type'} = 'application/json';
	my $ret = $ht->request($method, $url, $opts);
	die 'Request to Scaleway API server was unsuccessful: ' . $ret->{status} . ' ' . $ret->{reason} . '; ' . $ret->{content} unless $ret->{success};

	decode_json $ret->{content} if $ret->{status} != 204;
}

sub _get    { shift->_request(GET    => @_) }
sub _post   { shift->_request(POST   => @_) }
sub _patch  { shift->_request(PATCH  => @_) }
sub _put    { shift->_request(PUT    => @_) }
sub _delete { shift->_request(DELETE => @_) }

sub _tores {
	my @ret = map { bless $_, 'WebService::Scaleway::Resource' } @_;
	wantarray ? @ret : $ret[0]
}

sub new {
	my ($class, $token) = @_;
	$token = $dummy->create_token(@_[1..$#_])->id if @_ > 2;

	bless \$token, $class
}

BEGIN {
	my @account_res = qw/token organization user/;
	my @api_res = qw/server volume snapshot image ip security_group/;

	my %res = (
		map ({ $_ => _account "/${_}s" } @account_res),
		map  { $_ => _api     "/${_}s" } @api_res);

	my %create_parms = (
		token          => [qw/email password expires/],
		server         => [qw/name organization image volumes tags/],
		volume         => [qw/name organization volume_type size/],
		snapshot       => [qw/name organization volume_id/],
		image          => [qw/name organization root_volume arch/],
		ip             => [qw/     organization/],
		security_group => [qw/name organization description/],
	);

	sub dynsub {
		no strict 'refs';
		my $sub = pop;
		*$_ = $sub for @_
	}

	for my $res (keys %res) {
		dynsub $res, "get_$res", sub {
			local *__ANON__ = $res;
			_tores shift->_get("$res{$res}/$_[0]")->{$res}
		};

		dynsub $res.'s', "list_$res".'s', sub {
			local *__ANON__ = $res.'s';
			my @ret = _tores @{shift->_get($res{$res})->{$res.'s'}};
			wantarray ? @ret : $ret[0]
		};

		dynsub "delete_$res", sub {
			local *__ANON__ = "delete_$res";
			shift->_delete("$res{$res}/$_[0]")
		};

		dynsub "create_$res", sub {
			local *__ANON__ = "create_$res";
			my $self = shift;
			my $content = $_[0];
			if (blessed $content || ref $content ne 'HASH') {
				croak "create_$res does not understand positional parameters, pass a hashref instead\n" unless $create_parms{$res};
				my @parms = @{$create_parms{$res}};
				$content = { map {
					$parms[$_] => (blessed $_[$_] ? $_[$_]->id : $_[$_]) } 0 .. $#_ };
			}
			_tores $self->_post($res{$res},        { content => encode_json $content })->{$res}
		};

		dynsub "update_$res", sub {
			local *__ANON__ = "update_$res";
			my $data = blessed $_[1] ? {%{$_[1]}} : $_[1];
			shift->_put("$res{$res}/".$data->{id}, { content => encode_json $data })
		};
	}
}

sub security_group_rule {
	_tores shift->_get(_api "/security_groups/$_[0]/rules/$_[1]")->{rule}
}

sub security_group_rules {
	_tores @{shift->_get(_api "/security_groups/$_[0]/rules")->{rules}}
}

BEGIN {
	*get_security_group_rule  = \&security_group_rule;
	*list_security_group_rule = \&security_group_rules;
}

sub delete_security_group_rule {
	shift->_delete(_api "/security_groups/$_[0]/rules/$_[1]")
}

sub create_security_group_rule {
	my $self = shift;
	my $grp = shift;
	my $content = $_[0];
	unless (ref $content eq 'HASH') {
		my @parms = qw/organization action direction ip_range protocol dest_port_from/;
		$content = { map { $parms[$_] => $_[$_] } 0 .. $#_ };
	}
	$self->_post(_api "/security_groups/$grp/rules",        { content => encode_json $content })
}

sub update_security_group_rule {
	my $data = blessed $_[2] ? {%{$_[2]}} : $_[2];
	shift->_put (_api "/security_groups/$_[0]/rules/".$data->{id}, { content => encode_json $data })
}

sub server_actions {
	@{shift->_get(_api "/servers/$_[0]/action")->{actions}}
}

BEGIN { *list_server_actions = \&server_actions }

sub perform_server_action {
	my $content = encode_json { action => $_[2] };
	_tores shift->_post(_api "/servers/$_[0]/action", { content => $content })->{task};
}

sub refresh_token {
	_tores shift->_patch(_account "/tokens/$_[0]")->{token}
}

sub server_metadata {
	_tores $dummy->_get('http://169.254.42.42/conf?format=json')
}

package # hide from PAUSE
  WebService::Scaleway::Resource;

use overload '""' => sub { shift->id };

our $AUTOLOAD;
sub AUTOLOAD {
	my ($self) = @_;
	my ($attr) = $AUTOLOAD =~ m/::([^:]*)$/s;
	die "No such attribute: $attr" unless exists $self->{$attr};
	$self->{$attr}
}

sub can {
	my ($self, $sub) = @_;
	exists $self->{$sub} ? sub { shift->{$sub} } : undef
}

sub DESTROY {} # Don't call AUTOLOAD on destruction

1;
__END__

=encoding utf-8

=head1 NAME

WebService::Scaleway - Perl interface to Scaleway cloud server provider API

=head1 SYNOPSIS

  use WebService::Scaleway;
  my $token = ...; # API token here
  my $sw = WebService::Scaleway->new($token);
  my $org = $sw->organizations;

  # Create an IP, a volume, and use them for a new Debian Jessie server
  my $ip = $sw->create_ip($org);
  my $vol = $sw->create_volume('testvol', $org, 'l_ssd', 50_000_000_000);
  my ($debian) = grep { $_->name =~ /debian jessie/i } $sw->images;
  my $srv = $sw->create_server('testsrv', $org, $debian, {1 => $vol->id});

  # Now we have a server, an IP, and two volumes (the root volume with
  # Debian Jessie, and the extra volume we just created).

  # Change the server name
  $srv->{name} = 'Debian';
  $sw->update_server($srv);

  # Boot the server
  $sw->perform_server_action($srv, 'poweron');
  say "The server is now booting. To access it, do ssh root@", $ip->address;

=head1 DESCRIPTION

Scaleway is an IaaS provider that offers bare metal ARM cloud servers.
WebService::Scaleway is a Perl interface to the Scaleway API.

=head2 Constructors

WebService::Scaleway objects are defined by their authentication
token. There are two consructors:

=over

=item WebService::Scaleway->B<new>(I<$auth_token>)

Construct a WebService::Scaleway object from a given authentication
token.

=item WebService::Scaleway->B<new>(I<$email>, I<$password>)

Construct a WebService::Scaleway object from an authentication token
obtained by logging in with the given credentials.

=back

=head2 Listing resources

These methods return a list of all resources of a given type
associated to your account. Each resource is a blessed hashref with
C<AUTOLOAD>ed accessors (for example C<< $resource->{name} >> can be
written as C<< $resource->name >>) and that stringifies to the ID of
the resource: C<< $resource->id >>.

There is no difference between B<resources>() and
B<list_resources>().

=over

=item $self->B<tokens>

=item $self->B<list_tokens>

Official documentation: L<https://developer.scaleway.com/#tokens-tokens-get>.

=item $self->B<organizations>

=item $self->B<list_organizations>

Official documentation: L<https://developer.scaleway.com/#organizations-organizations>.

=item $self->B<servers>

=item $self->B<list_servers>

Official documentation: L<https://developer.scaleway.com/#servers-servers-get>.

=item $self->B<volumes>

=item $self->B<list_volumes>

Official documentation: L<https://developer.scaleway.com/#volumes-volumes-get>.

=item $self->B<snapshots>

=item $self->B<list_snapshots>

Official documentation: L<https://developer.scaleway.com/#snapshots-snapshots-get>.

=item $self->B<images>

=item $self->B<list_images>

Official documentation: L<https://developer.scaleway.com/#images-images-get>.

=item $self->B<ips>

=item $self->B<list_ips>

Official documentation: L<https://developer.scaleway.com/#ips-ips-get>.

=item $self->B<security_groups>

=item $self->B<list_security_groups>

Official documentation: L<https://developer.scaleway.com/#security-groups-security-groups-get>.

=item $self->B<security_group_rules>(I<$group_id>)

=item $self->B<list_security_group_rules>(I<$group_id>)

Official documentation: L<https://developer.scaleway.com/#security-groups-manage-rules-get>.

=back

=head2 Retrieving resources

These methods take the ID of a resource and return the resource as a
blessed hashref as described in the previous section.

You can pass a blessed hashref instead of a resource ID, and you'll
get a fresh version of the object passed. Useful if something updated
the object in the meantime.

There is no difference between B<resource>(I<$id>) and
B<get_resource>(I<$id>).

=over

=item $self->B<token>(I<$id>)

=item $self->B<get_token>(I<$id>)

Official documentation: L<https://developer.scaleway.com/#tokens-token-get>.

=item $self->B<user>(I<$id>)

=item $self->B<get_user>(I<$id>)

Official documentation: L<https://developer.scaleway.com/#users-user>.

=item $self->B<server>(I<$id>)

=item $self->B<get_server>(I<$id>)

Official documentation: L<https://developer.scaleway.com/#servers-server-get>.

=item $self->B<volume>(I<$id>)

=item $self->B<get_volume>(I<$id>)

Official documentation: L<https://developer.scaleway.com/#volumes-volume-get>.

=item $self->B<snapshot>(I<$id>)

=item $self->B<get_snapshot>(I<$id>)

Official documentation: L<https://developer.scaleway.com/#snapshots-snapshot-get>.

=item $self->B<image>(I<$id>)

=item $self->B<get_image>(I<$id>)

Official documentation: L<https://developer.scaleway.com/#images-operation-on-a-single-image-get>.

=item $self->B<ip>(I<$id>)

=item $self->B<get_ip>(I<$id>)

Official documentation: L<https://developer.scaleway.com/#ips-ip-get>.

=item $self->B<security_group>(I<$id>)

=item $self->B<get_security_group>(I<$id>)

Official documentation: L<https://developer.scaleway.com/#security-groups-operation-on-a-security-groups-get>.

=item $self->B<security_group_rule>(I<$group_id>, I<$rule_id>)

=item $self->B<get_security_group_rule>(I<$group_id>, I<$rule_id>)

Official documentation: L<https://developer.scaleway.com/#security-groups-operation-on-a-security-rule-get>.

=back

=head2 Deleting resources

These methods take the ID of a resource and delete it. They do not
return anything. You can pass a blessed hashref instead of a resource
ID.

=over

=item $self->B<delete_token>(I<$id>)

Official documentation: L<https://developer.scaleway.com/#tokens-token-delete>.

=item $self->B<delete_server>(I<$id>)

Official documentation: L<https://developer.scaleway.com/#servers-server-delete>.

=item $self->B<delete_volume>(I<$id>)

Official documentation: L<https://developer.scaleway.com/#volumes-volume-delete>.

=item $self->B<delete_snapshot>(I<$id>)

Official documentation: L<https://developer.scaleway.com/#snapshots-snapshot-delete>.

=item $self->B<delete_image>(I<$id>)

Official documentation: L<https://developer.scaleway.com/#images-operation-on-a-single-image-delete>.

=item $self->B<delete_ip>(I<$id>)

Official documentation: L<https://developer.scaleway.com/#ips-ip-delete>.

=item $self->B<delete_security_group>(I<$id>)

Official documentation: L<https://developer.scaleway.com/#security-groups-operation-on-a-security-groups-delete>.

=item $self->B<delete_security_group_rule>(I<$group_id>, I<$rule_id>)

Official documentation: L<https://developer.scaleway.com/#security-groups-operation-on-a-security-rule-delete>.

=back

=head2 Modifying resources

These methods take a hashref representing a resource that already
exists and update it. The value of C<< $resource->{id} >> is used for
identifying this resource on the remote end. Both blessed and
unblessed hashrefs are accepted. The updated resource is returned as a
blessed hashref as described in L</"Listing resources">.

=over

=item $self->B<update_server>(I<$resource>)

Official documentation: L<https://developer.scaleway.com/#servers-server-put>.

=item $self->B<update_snapshot>(I<$resource>)

Official documentation: L<https://developer.scaleway.com/#snapshots-snapshot-put>.

=item $self->B<update_image>(I<$resource>)

Official documentation: L<https://developer.scaleway.com/#images-operation-on-a-single-image-put>.

=item $self->B<update_ip>(I<$resource>)

Official documentation: L<https://developer.scaleway.com/#ips-ip-put>.

=item $self->B<update_security_group>(I<$resource>)

Official documentation: L<https://developer.scaleway.com/#security-groups-operation-on-a-security-groups-put>.

=item $self->B<update_security_group_rule>(I<$group_id>, I<$resource>)

Official documentation: L<https://developer.scaleway.com/#security-groups-operation-on-a-security-rule-put>.

=back

=head2 Creating resources

These methods take either a hash that is passed directly to the API or
a method-specific list of positional parameters. They create a new
resource and return it as a blessed hashref as described in
L</"Listing resources">.

When using positional parameters, you can pass a resource in blessed
hashref format where a resource ID is expected, unless the method's
documentation says otherwise.

Most of these methods require an organization ID. You can obtain it
with the B<organizations> method described above.

=over

=item $self->B<create_token>(I<\%data>)

=item $self->B<create_token>(I<$email>, I<$password>, [I<$expires>])

Authenticates a user against their username and password and returns
an authentication token. If I<$expires> (default: false) is true, the
token will expire.

This method is called internally by the two-argument constructor.

Official documentation: L<https://developer.scaleway.com/#tokens-tokens-get>.

=item $self->B<create_server>(I<\%data>)

=item $self->B<create_server>(I<$name>, I<$organization>, I<$image>, I<$volumes>, [I<$tags>])

Creates and returns a new server.

I<$name> is the server name. I<$organization> is the organization ID.
I<$image> is the image ID. I<$volumes> is a "sparse array" (hashref
from indexes to volume IDs, indexed from 1) of B<extra> volumes (that
is, volumes other than the root volume). I<$tags> is an optional
arrayref of tags.

For the I<$volumes> parameter you can pass hashrefs that describe
volumes instead of volume IDs. This will create new volumes. The
hashrefs are (presumably) passed to B<create_volume>. An example
inspired by the official documentation:

  $volumes = { 1 => {
    name         => "vol_demo",
    organization => "ecc1c86a-eabb-43a7-9c0a-77e371753c0a",
    size         => 10_000_000_000,
    volume_type  => "l_sdd",
  }};

Note that there B<may not> be any blessed hashrefs inside I<$volumes>.

Official documentation: L<https://developer.scaleway.com/#servers-servers-get>.

=item $self->B<create_volume>(I<\%data>)

=item $self->B<create_volume>(I<$name>, I<$organization>, I<$volume_type>, I<$size>)

Creates and returns a new volume. I<$volume_type> currently must be
C<l_ssd>. I<$size> is the size in bytes.

Official documentation: L<https://developer.scaleway.com/#volumes-volumes-get>.

=item $self->B<create_snapshot>(I<\%data>)

=item $self->B<create_snapshot>(I<$name>, I<$organization>, I<$volume_id>)

Creates and returns a snapshot of the volume I<$volume_id>.

Official documentation: L<https://developer.scaleway.com/#snapshots-snapshots-get>.

=item $self->B<create_image>(I<\%data>)

=item $self->B<create_image>(I<$name>, I<$organization>, I<$root_volume>, I<$arch>)

Creates and returns an image from the volume I<$root_volume>. I<$arch>
is the architecture of the image (currently must be C<"arm">).

Official documentation: L<https://developer.scaleway.com/#images-images-get>.

=item $self->B<create_ip>(I<\%data>)

=item $self->B<create_ip>(I<$organization>)

Official documentation: L<https://developer.scaleway.com/#ips-ips-get>.

=item $self->B<create_security_group>(I<\%data>)

=item $self->B<create_security_group>(I<$name>, I<$organization>, I<$description>)

Official documentation: L<https://developer.scaleway.com/#security-groups-security-groups-get>.

=item $self->B<create_security_group_rule>(I<$group_id>)

=item $self->B<create_security_group_rule>(I<$group_id>, I<$organization>, I<$action>, I<$direction>, I<$ip_range>, I<$protocol>, [<$dest_port_from>])


Official documentation: L<https://developer.scaleway.com/#security-groups-manage-rules-get>.

=back

=head2 Miscellaneous methods

These are methods that don't fit any previous category. Any use of
"blessed hashref" refers to the concept described in L</"Listing
resources">. Wherever a resource ID is expected, you can instead pass
a resource as a blessed hashref and the method will call C<< ->id >>
on it for you.

=over

=item $self->B<server_actions>(I<$server_id>)

=item $self->B<list_server_actions>(I<$server_id>)

Returns a list of strings representing possible actions you can
perform on the given server. Example actions are powering on/off a
server or rebooting it.

Official documentation: L<https://developer.scaleway.com/#servers-actions-get>

=item $self->B<perform_server_action>(I<$server_id>, I<$action>)

Performs an action on a server. I<$action> is one of the strings
returned by B<server_actions>. The function returns a blessed hashref
with information about the task.

This is not very useful, as this module does not currently offer any
function for tracking tasks.

Official documentation: L<https://developer.scaleway.com/#servers-actions-post>

=item $self->B<refresh_token>(I<$token_id>)

This method takes the ID of an expirable token, extends its expiration
date by 30 minutes, and returns the new token as a blessed hashref.

Official documentation: L<https://developer.scaleway.com/#tokens-token-patch>

=item $self->B<server_metadata>

This method can only be called from a Scaleway server. It returns
information about the server as a blessed hashref.

Official documentation: L<https://developer.scaleway.com/#metadata-c1-server-metadata>

=back

=head1 SEE ALSO

L<https://developer.scaleway.com/>

=head1 AUTHOR

Marius Gavrilescu, E<lt>marius@ieval.roE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2015 by Marius Gavrilescu

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.20.2 or,
at your option, any later version of Perl 5 you may have available.


=cut
