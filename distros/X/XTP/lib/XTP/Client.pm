package XTP::Client 0.001;
our $VERSION;

use 5.016;
use warnings;
use Carp qw(croak carp);
use Date::Parse;
use Extism;
use JSON::PP qw(decode_json encode_json);
use LWP::UserAgent;

sub __request {
    my ($self, $path, $opt) = @_;
    $opt //= {};
    $opt->{method} = 'POST' if exists $opt->{body} && !$opt->{method};
    $opt->{method} //= 'GET';
    $opt->{headers}{Authorization} = "Bearer $self->{token}";
    my $ua = LWP::UserAgent->new;
    $ua->agent("Perl-XTP-Client/$VERSION");
    my $req = HTTP::Request->new($opt->{method} => "$self->{baseUrl}$path", HTTP::Headers->new(%{$opt->{headers}}), $opt->{body});
    $ua->request($req)
}

sub _request {
    my $res = __request(@_);
    $res->is_success or die "request failed " . $res->content;
    $res->content
}

sub _json_request {
    my ($self, $path, $opt) = @_;
    $opt //= {};
    if (exists $opt->{body}) {
        $opt->{body} = eval {
            encode_json($opt->{body})
        };
        if ($@) {
            die "Body could not be encoded to json\n";
        }
        $opt->{headers}{'Content-Type'} //= 'application/json; charset=utf-8';
    }
    my $res = $self->__request($path, $opt);
    my $content = eval {
        decode_json($res->content)
    };
    if ($@) {
        if ($res->is_success) {
            die "Invalid JSON received\n";
        }
        die "Request failed\n";
    } elsif (!$res->is_success) {
        $content->{message} //= "Code: ".$res->code;
        die "$content->{message}\n";
    }
    $content
}

sub new {
    my ($name, $opt) = @_;
    my %opt = %$opt;
    $opt{token} or croak 'token is required to instantiate an XTP client';
    $opt{appId} or croak 'appid is required to instantiate an XTP client';
    $opt{baseUrl} //= 'https://xtp.dylibso.com';
    my $self = bless \%opt, $name;
    my $content = eval {
        $self->_json_request("/api/v1/apps/$self->{appId}/extension-points")
    };
    if ($@) {
        chomp $@;
        croak "Loading extension-points failed: $@";
    }
    #foreach my $extpoint (@{$content->{objects}}) {
    #    print "extname $extpoint->{name} id $extpoint->{id}\n";
    #}
    $self->{extpoints} = {map {("$_->{name}" => $_)} @{$content->{objects}}};
    return $self; 
}

sub _getBindings {
    my ($self, $extid, $guestkey) = @_;
    my $content = eval {
        $self->_json_request("/api/v1/extension-points/$extid/bindings/$guestkey")
    };
    if ($@) {
        chomp $@;
        croak "Loading bindings failed: $@";
    }
    $content
}

sub _getLatestBinding {
    my ($bindings) = @_;
    my $latestbinding;
    my $latestdate = 0;
    while(my ($binding, $value) = each %$bindings) {
        my $updatedAt = str2time($value->{updatedAt});
        if ($updatedAt > $latestdate) {
            $latestdate = $updatedAt;
            $latestbinding = $binding;
        }
    }
    $latestbinding
}

sub _getPluginSource {
    my ($self, $extid, $guestkey, $bindingname) = @_;
    my $bindings = $self->_getBindings($extid, $guestkey);
    my $resolvedBindingName = $bindingname || _getLatestBinding($bindings);
    if (!$resolvedBindingName || ! exists $bindings->{$resolvedBindingName}) {
        return undef;
    }
    my $contentAddress = $bindings->{$resolvedBindingName}{contentAddress};
    $contentAddress or do {
        return undef;
    };
    my $path = "/tmp/xtp/$contentAddress";
    if (-f $path) {
        my $artifactContent = do { local(@ARGV, $/) = $path; <> };
        return $artifactContent if ($artifactContent);
    }
    my $artifactContent = eval {
        $self->_request("/api/v1/c/$contentAddress")
    };
    if ($@) {
        croak "Downloading Wasm failed";
    }
    if (-d "/tmp/xtp" || mkdir("/tmp/xtp", 0755)) {
        open(my $fh, '>', $path);
        print $fh $artifactContent;
    }
    $artifactContent
}

sub getPlugin {
    my ($self, $extname, $guestkey, %options) = @_;
    my $extid = $self->{extpoints}{$extname}{id};
    my $bindingname //= $options{bindingName};
    my $pluginSource = $self->_getPluginSource($extid, $guestkey, $bindingname);
    $pluginSource or croak 'Failed to find plugin';
    my $extismoptions = $options{extism} // $self->{extism};
    my $plugin = eval {
        Extism::Plugin->new($pluginSource, $extismoptions)
    };
    if ($@) {
        my ($reason) = $@ =~ /^(.+)\sat.+line\s\d+/;
        croak $reason;
    }
    $plugin
}

sub inviteGuest {
    my ($self, $opt) = @_;
    my %opt = %$opt;
    $opt{guestKey} or croak 'guestkey is required to invite a guest';
    ($opt{deliveryMethod} // '') =~ /^(?:email|link)$/ or croak 'deliveryMethod must be email or link';
    if ($opt{deliveryMethod} eq 'email') {
        $opt{name} // croak "name is required when deliveryMethod is email";
    }
    my $response = eval {
        $self->_json_request("/api/v1/apps/$self->{appId}/guests", {
            body => \%opt
        })
    };
    if ($@) {
        chomp $@;
        croak "Failed to invite guest: $@";
    }
    $response
}

1;
