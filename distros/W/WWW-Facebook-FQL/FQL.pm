package WWW::Facebook::FQL;

=head1 NAME

WWW::Facebook::FQL - Simple interface to Facebook's FQL query language

=head1 SYNOPSIS

  use WWW::Facebook::FQL;

  ## Connect and log in:
  my $fb = new WWW::Facebook::FQL key => $public_key, private => $private_key;
  $fb->login($email, $password);

  ## Get your own name and pic back:
  $fb->query("SELECT name, pic FROM user WHERE uid=$fb->{uid}");

  ## Get your friends' names and pics:
  $fb->query("SELECT name, pic FROM user WHERE uid IN "
           . "(SELECT uid2 FROM friend WHERE uid1 = $fb->{uid})");

  ## Get results in manageable form:
  use JSON::Syck; # or whatever...
  $fb->format = 'JSON';
  my $arrayref = JSON::Syck::Load $fb->query("...");

=head1 DESCRIPTION

WWW::Facebook::FQL aims to make it easy to perform Facebook Query
Language (FQL) queries from a Perl program, rather than to reflect the
whole PHP Facebook API.  For those comfortable with SQL, this may be a
more comfortable interface.  Results are currently returned in the raw
JSON or XML format, but more palatable options may be available in the
future.

=cut

use URI::Escape;
use WWW::Mechanize;
use Digest::MD5 qw(md5_hex);
require Exporter;
use strict;

use vars qw($VERSION @ISA @EXPORT_OK %EXPORT_TAGS);
$VERSION = '0.03';

@EXPORT_OK = qw(%FIELDS %IXFIELDS);
%EXPORT_TAGS = (all => \@EXPORT_OK);
@ISA = qw(Exporter);

use vars qw($rest %FIELDS %IXFIELDS);
$rest = 'http://api.facebook.com/restserver.php';

sub dprint
{
    my $self = shift;
    my $lev = shift;
    if ($lev <= $self->{verbose}) {
        print STDERR @_;
    }
}

sub _sig
{
    my $secret = shift;
    md5_hex uri_unescape(join '', sort(@_), $secret);
}

sub get
{
    my $self = shift;
    ($self->{mech} ||= new WWW::Mechanize)->get(@_);
}

sub _request_nofail
{
    my $self = shift;
    my $resp = $self->_request(@_);
    die "Request failed:\n", $resp->decoded_content unless $resp->is_success;
    $resp;
}

sub _request
{
    my ($self, $method, %o) = @_;
    $o{format} ||= $self->{format};
    $method = "facebook.$method";
    my @params = ("api_key=$self->{key}",
                  "method=$method",
                  'v=1.0',
                  $self->{session_key} ? ('session_key='.$self->{session_key},
                                      'call_id='.(++$self->{callid})) : (),
                  map { "$_=".uri_escape($o{$_}) } keys %o);
    my $sig = _sig($self->{secret}, @params);
    my $url = "$rest?".join '&', @params, "sig=$sig\n";
    $self->dprint(1, $url);
    my $resp = $self->get("$rest?".join '&', @params, "sig=$sig");
    if (!$resp->is_success) {
        $self->dprint(0, "Request '$url' failed.\n");
    }
    ## avoid decoding content unless printed
    if ($self->{verbose} > 2) {
        $self->dprint(2, "RESPONSE ", '=' x 50, "\n", $resp->decoded_content,
                      "\n", '=' x 70, "\n");
    }
    $resp;
}

sub _get_auth_token
{
    my ($self) = @_;
    $self->{secret} = $self->{private};
    my $resp = $self->_request_nofail('auth.createToken', format => 'JSON');
    $self->{auth_token} = eval $resp->decoded_content;
}

sub _get_session
{
    my $self = shift;
    my $resp;
    {
        local $rest = $rest;
        $rest =~ s/^http/https/;
        $resp = $self->_request_nofail('auth.getSession', format => 'XML',
                                       auth_token => $self->{auth_token});
    }
    local $_ = $resp->decoded_content;
    for my $word (qw(uid session_key expires secret)) {
        ($self->{$word}) = /<$word>(.*?)<\/$word>/;
    }
    $self->dprint(1, "Session expires at ",
                  scalar localtime($self->{expires}), "\n");
}

=head2 C<$fb = new WWW::Facebook::FQL key =E<gt> value, ...>

Create a new Facebook FQL session for user $EMAIL with password $PASS.
Keyword arguments include

=over 4

=item email -- the email address of your Facebook account.

=item pass -- your password.

=item verbose -- A number controlling debugging information.

=item key -- The public part of your API key.

You need to sign up for this on Facebook by joining the "Developers"
group and requesting an API key.

=item private -- The private part of your API key.

=item format -- Data return format, either 'XML' (the default) or 'JSON'.

=back

WWW::Facebook::FQL reads default values from the file $HOME/.fqlrc if
it exists.  It should contain the innards of an argument list, and
will be evaluated like C<@args = eval "($FILE_CONTENTS)">.  The
constructor will I<not> prompt for any parameters; it is the calling
program's responsibility to get sensitive information from the user in
an appropriate way.

=cut

sub new
{
    my $class = shift;
    my @def = (format => 'XML', verbose => 0);
    if (-f "$ENV{HOME}/.fqlrc") {
        local $/;
        if (open IN, "$ENV{HOME}/.fqlrc") {
            my @tmp = eval '('.<IN>.')';
            push @def, @tmp unless $@;
            close IN;
        }
    }
    my %o = (@def, @_);
    my $self = bless \%o, $class;
    return undef unless $self->_get_auth_token;
    $self
}

sub login
{
    my $self = shift;
    ($self->{email}, $self->{pass}) = @_ if @_;
    my $mech = $self->{mech};
    $mech->get("http://www.facebook.com/login.php?api_key=$self->{key}&v=1.0&auth_token=$self->{auth_token}&hide_checkbox=1&skipcookie=1");
    die "Can't access login form:\n", $mech->res->decoded_content
        unless $mech->success;

    my $resp = $mech->submit_form(with_fields => {
        email => $self->{email},
        pass => $self->{pass}
    });
    die "Login failed:\n", $resp->decoded_content
        unless $resp->is_success;
    $self->dprint(2, "Logged in as $self->{email}\n");
    ## XXX check response
    if ($mech->content =~ /Terms of Service/) {
        $mech->submit_form(form_name => 'confirm_grant_form');
        die "TOS failed:\n", $mech->res->decoded_content
            unless $mech->res->is_success;
        $self->dprint(2, "Agreed to terms of service.");
    }
    ## Get session key
    $self->_get_session;
    $self;
}

=head2 C<$fb-E<gt>logout>

Log the current user out.

=cut

sub logout
{
    my $self = shift;
    $self->{mech}->get("http://www.facebook.com/logout.php?api_key=$self->{key}&v=1.0&auth_token=$self->{auth_token}&confirm=1");
    delete $self->{secret};
}

=head2 C<$result = $fb-E<gt>query($QUERY)

Perform FQL query $QUERY, returning the result in format $FORMAT
(either XML or JSON, JSON by default).  FQL is a lot like SQL, but
with its own set of weird and privacy-related restrictions; for a
description, see
L<http://developers.facebook.com/documentation.php?v=1.0&doc=fql>.

=cut

sub query
{
    my ($self, $q) = @_;
    if (!$self->{secret} || $self->{private} eq $self->{secret}) {
        print STDERR "Must log in before querying.\n";
        return;
    }
    $self->_request('fql.query', query => $q)->decoded_content;
}

=head2 ACCESSORS

=over

=item C<$fb-E<gt>uid> (read-only)

=item C<$fb-E<gt>email> (read-only)

=item C<$fb-E<gt>verbose> (read-write)

=item C<$fb-E<gt>format> (read-write)

=back

=cut

BEGIN {
    no strict;
    for (qw(uid email)) {
        eval "sub $_\n{ shift->{$_} }";
    }
    for (qw(verbose format)) {
        eval "sub $_ :lvalue { shift->{$_} }";
    }
}

BEGIN {
%FIELDS = (
    user => [qw(uid* first_name last_name name* pic_small pic_big
    pic_square pic affiliations profile_update_time timezone religion
    birthday sex hometown_location meeting_sex meeting_for
    relationship_status significant_other_id political
    current_location activities interests is_app_user music tv movies
    books quotes about_me hs_info education_history work_history
    notes_count wall_count status has_added_app)],

    friend => [qw(uid1* uid2*)],

    group => [qw(gid* name nid pic_small pic_big pic description
    group_type group_subtype recent_news creator update_time office
    website venue)],

    group_member => [qw(uid* gid* positions)],

    event => [qw(eid* name tagline nid pic_small pic_big pic host
    description event_type event_subtype start_time end_time creator
    update_time location venue)],

    event_member => [qw(uid* eid* rsvp_status)],

    photo => [qw(pid* aid* owner src_small src_big src link caption
    created)],

    album => [qw(aid* cover_pid* owner* name created modified
    description location size)],

    photo_tag => [qw(pid* subject* xcoord ycoord)],
);

for (keys %FIELDS) {
    $IXFIELDS{$_} = [grep /\*$/, @{$FIELDS{$_}}];
    s/\*$// for @{$FIELDS{$_}};
}

} ## END BEGIN

1;
__END__

=head2 C<%FIELDS> -- table_name -E<gt> [fields]

Map table names to available fields.  This is particularly useful
since FQL doesn't allow "SELECT *".

=head2 C<%IXFIELDS> -- table_name -E<gt> [indexed_fields]

Map table names to "indexable" fields, i.e. those fields that can be
part of a WHERE clause.

=head1 EXPORTS

C<%FIELDS> and C<%IXFIELDS> can be exported with the ':all' tag.

=head1 SEE ALSO

The canonical (PHP) API Documentation
(L<http://developers.facebook.com/documentation.php>), especially the
FQL document
(L<http://developers.facebook.com/documentation.php?v=1.0&doc=fql>).

L<WWW::Facebook::API> for bindings to the full API.

=head1 BUGS and TODO

Since FQL is so much like SQL, it might be cool to make
DBD::Facebook...

=head1 AUTHOR

Sean O'Rourke, E<lt>seano@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 by Sean O'Rourke

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
