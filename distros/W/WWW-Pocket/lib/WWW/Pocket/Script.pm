package WWW::Pocket::Script;
our $AUTHORITY = 'cpan:DOY';
$WWW::Pocket::Script::VERSION = '0.03';
use Moose;

use Getopt::Long 'GetOptionsFromArray';
use JSON::PP;
use List::Util 'sum';
use Path::Class;
use URI;
use Pod::Usage;

use WWW::Pocket;

has consumer_key => (
    is        => 'ro',
    isa       => 'Str',
    lazy      => 1,
    default   => sub { die "consumer_key is required to authenticate" },
    predicate => '_has_consumer_key',
);

has redirect_uri => (
    is      => 'ro',
    isa     => 'Str',
    default => 'https://getpocket.com/',
);

has credentials_file => (
    is      => 'ro',
    isa     => 'Str',
    default => "$ENV{HOME}/.pocket",
);

has pocket => (
    is      => 'ro',
    isa     => 'WWW::Pocket',
    lazy    => 1,
    default => sub {
        my $self = shift;

        my $credentials_file = file($self->credentials_file);
        if (-e $credentials_file) {
            return $self->_apply_credentials($credentials_file);
        }
        else {
            return $self->_authenticate;
        }
    },
);

sub run {
    my $self = shift;
    my @argv = @_;

    my $method = shift @argv;
    if ($self->_method_is_command($method)) {
        return $self->$method(@argv);
    }
    else {
        pod2usage(-verbose => 2);
    }
}

sub _method_is_command {
    my $self = shift;
    my ($name) = @_;

    return unless $name;
    return if $name eq 'run' || $name eq 'meta';
    return if $name =~ /^_/;
    my $method = $self->meta->find_method_by_name($name);
    return unless $method;
    return if $method->isa('Class::MOP::Method::Accessor');

    return 1;
}

# Display quick usage help on this script.
sub help {
    my $self = shift;
    pod2usage(-verbose => 1);
}

# Display comprehensive help about this script.
sub man {
    my $self = shift;
    pod2usage(-verbose => 2);
}



sub authenticate {
    my $self = shift;
    $self->pocket;
}

sub _apply_credentials {
    my $self = shift;
    my ($file) = @_;

    my ($consumer_key, $access_token, $username) = $file->slurp(chomp => 1);
    return WWW::Pocket->new(
        consumer_key => $consumer_key,
        access_token => $access_token,
        username     => $username,
    );
}

sub _authenticate {
    my $self = shift;

    my $consumer_key = $self->_has_consumer_key
        ? $self->consumer_key
        : $self->_prompt_for_consumer_key;

    my $pocket = WWW::Pocket->new(consumer_key => $consumer_key);

    my $redirect_uri = $self->redirect_uri;
    my ($url, $code) = $pocket->start_authentication($redirect_uri);

    print "Visit $url and log in. When you're done, press enter to continue.\n";
    <STDIN>;

    $pocket->finish_authentication($code);

    my $fh = file($self->credentials_file)->openw;
    $fh->write($pocket->consumer_key . "\n");
    $fh->write($pocket->access_token . "\n");
    $fh->write($pocket->username . "\n");
    $fh->close;

    return $pocket;
}

sub _prompt_for_consumer_key {
    my $self = shift;

    print "Consumer key required. You can sign up for a consumer key as a\n" .
        "Pocket developer at https://getpocket.com/developer/apps/new.\n";

    print "Enter your consumer key: ";
    my $key = <STDIN>;

    # Trim start and end.
    $key =~ s/^\s*(.*)\s*$/$1/;
    # print "Key entered: '$key'\n";

    return $key;
}

sub list {
    my $self = shift;
    my @argv = @_;

    my ($params) = $self->_parse_retrieve_options(@argv);
    my %params = (
        $self->_default_search_params,
        %$params,
    );

    print "$_\n" for $self->_retrieve_urls(%params);
}

sub words {
    my $self = shift;
    my @argv = @_;

    my ($params) = $self->_parse_retrieve_options(@argv);
    my %params = (
        $self->_default_search_params,
        %$params,
    );

    my $word_count = sum($self->_retrieve_field('word_count', %params)) || 0;
    print "$word_count\n";
}

sub search {
    my $self = shift;
    my @argv = @_;

    my ($params, $extra_argv) = $self->_parse_retrieve_options(@argv);
    my ($search) = @$extra_argv;
    my %params = (
        $self->_default_search_params,
        %$params,
        search => $search,
    );

    print "$_\n" for $self->_retrieve_urls(%params);
}

sub favorites {
    my $self = shift;
    my @argv = @_;

    my ($params) = $self->_parse_retrieve_options(@argv);
    my %params = (
        $self->_default_search_params,
        state => 'all',
        %$params,
        favorite => 1,
    );

    print "$_\n" for $self->_retrieve_urls(%params);
}

sub retrieve_raw {
    my $self = shift;
    my @argv = @_;

    my ($state, $favorite, $tag, $contentType, $sort, $detailType);
    my ($search, $domain, $since, $count, $offset);
    GetOptionsFromArray(
        \@argv,
        "state=s"       => \$state,
        "favorite!"     => sub { $favorite = $_[1] ? '1' : '0' },
        "tag=s"         => \$tag,
        "contentType=s" => \$contentType,
        "sort=s"        => \$sort,
        "detailType=s"  => \$detailType,
        "search=s"      => \$search,
        "domain=s"      => \$domain,
        "since=i"       => \$since,
        "count=i"       => \$count,
        "offset=i"      => \$offset,
    ) or die "???";

    my %params = (
        (defined($state)       ? (state       => $state)       : ()),
        (defined($favorite)    ? (favorite    => $favorite)    : ()),
        (defined($tag)         ? (tag         => $tag)         : ()),
        (defined($contentType) ? (contentType => $contentType) : ()),
        (defined($sort)        ? (sort        => $sort)        : ()),
        (defined($detailType)  ? (detailType  => $detailType)  : ()),
        (defined($search)      ? (search      => $search)      : ()),
        (defined($domain)      ? (domain      => $domain)      : ()),
        (defined($since)       ? (since       => $since)       : ()),
        (defined($count)       ? (count       => $count)       : ()),
        (defined($offset)      ? (offset      => $offset)      : ()),
    );

    $self->_pretty_print($self->pocket->retrieve(%params));
}

sub _parse_retrieve_options {
    my $self = shift;
    my @argv = @_;

    my ($unread, $archive, $all, @tags);
    GetOptionsFromArray(
        \@argv,
        "unread"  => \$unread,
        "archive" => \$archive,
        "all"     => \$all,
        "tag=s"   => \@tags,
    ) or die "???";

    return (
        {
            ($unread  ? (state => 'unread')         : ()),
            ($archive ? (state => 'archive')        : ()),
            ($all     ? (state => 'all')            : ()),
            (@tags    ? (tag   => join(',', @tags)) : ()),
        },
        [ @argv ],
    );
}

sub _default_search_params {
    my $self = shift;

    return (
        sort       => 'oldest',
        detailType => 'simple',
    );
}

sub _retrieve_urls {
    my $self = shift;
    my %params = @_;

    $self->_retrieve_field('resolved_url', %params);
}

sub _retrieve_field {
    my $self = shift;
    my ($field, %params) = @_;

    my $response = $self->pocket->retrieve(%params);
    my $list = $response->{list};
    return unless ref($list) && ref($list) eq 'HASH';

    return map {
        $_->{$field}
    } sort {
        $a->{sort_id} <=> $b->{sort_id}
    } values %$list;
}

sub _pretty_print {
    my $self = shift;
    my ($data) = @_;

    print JSON::PP->new->utf8->pretty->canonical->encode($data), "\n";
}

sub add {
    my $self = shift;
    my ($url, $title) = @_;

    $self->pocket->add(
        url   => $url,
        title => $title,
    );
    print "Page Saved!\n";
}

sub archive {
    my $self = shift;
    my ($url) = @_;

    $self->_modify('archive', $url);
    print "Page archived!\n";
}

sub readd {
    my $self = shift;
    my ($url) = @_;

    $self->_modify('readd', $url);
    print "Page added!\n";
}

sub favorite {
    my $self = shift;
    my ($url) = @_;

    $self->_modify('favorite', $url);
    print "Page favorited!\n";
}

sub unfavorite {
    my $self = shift;
    my ($url) = @_;

    $self->_modify('unfavorite', $url);
    print "Page unfavorited!\n";
}

sub delete {
    my $self = shift;
    my ($url) = @_;

    $self->_modify('delete', $url);
    print "Page deleted!\n";
}

sub _modify {
    my $self = shift;
    my ($action, $url) = @_;

    $self->pocket->modify(
        actions => [
            {
                action  => $action,
                item_id => $self->_get_id_for_url($url),
            },
        ],
    );
}

sub _get_id_for_url {
    my $self = shift;
    my ($url) = @_;

    my $response = $self->pocket->retrieve(
        domain => URI->new($url)->host,
        state  => 'all',
    );
    my $list = $response->{list};
    return unless ref($list) && ref($list) eq 'HASH';

    for my $item (values %$list) {
        return $item->{item_id}
            if $item->{resolved_url} eq $url
            || $item->{given_url} eq $url;
    }

    return;
}

__PACKAGE__->meta->make_immutable;
no Moose;

=begin Pod::Coverage

  add
  archive
  authenticate
  delete
  favorite
  favorites
  help
  list
  man
  readd
  retrieve_raw
  run
  search
  unfavorite
  words

=end Pod::Coverage

=cut

1;
