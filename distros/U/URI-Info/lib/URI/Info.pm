package URI::Info;

use 5.010001;
use strict;
use warnings;
use Log::ger;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-06-21'; # DATE
our $DIST = 'URI-Info'; # DIST
our $VERSION = '0.004'; # VERSION

my $p = "URI::Info::Plugin::";
sub new {
    my ($class, %args) = @_;

    for (keys %args) {
        die "Unknown argument '$_', known arguments are include_plugins, exclude_plugins"
            unless /\A(include_plugins|exclude_plugins)\z/;
    }
    if (!defined($args{include_plugins}) && !defined($args{exclude_plugins})
        && defined $ENV{URI_INFO_PLUGINS} && length $ENV{URI_INFO_PLUGINS}) {
        $args{include_plugins} = undef;
        $args{exclude_plugins} = [];
        my @elems = split /\s*,\s*/, $ENV{URI_INFO_PLUGINS};
        my ($exclude_sign, $plugin, $args);
        $args = [];
        while (@elems) {
            my $elem = shift @elems;
            if ($elem =~ /\A([+-])(.+)/) {
                if (defined $plugin) {
                    # add previous plugin
                    my $key = $exclude_sign eq '-' ? 'exclude_plugins' : 'include_plugins';
                    $args{$key} //= [];
                    push @{$args{$key}}, $plugin . (@$args ? "=".join(",", @$args) : "");
                }
                ($exclude_sign, $plugin) = ($1, $2);
            } else {
                push @$args, $elem;
            }
        }
        # add last plugin
        die "[URI::Info] Invalid syntax in URI_INFO_PLUGINS variable: no plugins specified, only args"
            unless defined $plugin;
        my $key = $exclude_sign eq '-' ? 'exclude_plugins' : 'include_plugins';
        $args{$key} //= [];
        push @{$args{$key}}, $plugin . (@$args ? "=".join(",", @$args) : "");
    }

    unless (defined $args{include_plugins}) {
        require Module::List::Wildcard;
        my $mods = Module::List::Wildcard::list_modules($p, {list_modules=>1, recurse=>1});
        $args{include_plugins} = [map {my $mod=$_; $mod=~s/\A\Q$p\E//; $mod} sort keys %$mods];
    }

    my $self = bless \%args, $class;

    $self->{plugin_objs_by_host} = {}; # key=host, value=[plugin_obj1, ...]

    $self->_load_plugins;
    $self;
}

sub _load_plugins {
    require Module::List::Wildcard;
    require Module::Path::More;
    require String::Wildcard::Bash;

    my $self = shift;

    my %exclude_plugins;
    if ($self->{exclude_plugins} && @{ $self->{exclude_plugins} }) {
        for my $prefix (@{ $self->{exclude_plugins} }) {
            if (ref $prefix) {
                die "[URI::Info] exclude_plugins entry cannot be array/reference: $prefix";
            }
            if ($prefix eq '' || $prefix =~ /::\z/ ||
                    String::Wildcard::Bash::contains_wildcard($prefix)) {
                my $mods = Module::List::Wildcard::list_modules(
                    "${p}$prefix", {list_modules=>1, wildcard=>1});
                for (keys %$mods) {
                    s/\A\Q$p\E//;
                    $exclude_plugins{$_}++;
                }
            } else {
                my $path = Module::Path::More::module_path(
                    module=>"${p}$prefix");
                if ($path) {
                    $exclude_plugins{$prefix}++;
                }
            }
        }
    }

    for my $entry (@{ $self->{include_plugins} }) {
        my ($prefix, $args);
        if (ref $entry eq 'ARRAY') {
            $prefix = $entry->[0];
            $args = $entry->[1];
        } elsif ($entry =~ /\A(\w+(?:::\w+)*)=(.*)\z/) {
            $prefix = $1;
            $args = [split /\s*,\s*/, $2];
        } else {
            $prefix = $entry;
            $args = {};
        }
        my @plugins;
        if ($prefix eq '' || $prefix =~ /::\z/ ||
                String::Wildcard::Bash::contains_wildcard($prefix)) {
            my $mods = Module::List::Wildcard::list_modules(
                "${p}$prefix", {list_modules=>1, wildcard=>1});
            for (keys %$mods) {
                my $mod = $_;
                s/\A\Q$p\E//;
                if ($exclude_plugins{$_}) {
                    log_debug "[URI::Info] plugin '$_' is excluded (matches $prefix)";
                    next;
                }
                log_debug "[URI::Info] Loading plugin module $mod ...";
                (my $mod_pm = "$mod.pm") =~ s!::!/!g;
                require $mod_pm;
                $self->_activate_plugin($mod, $args);
            }
        } else {
            my $mod = "${p}$prefix";
            my $path = Module::Path::More::module_path(module=>$mod);
            if ($path) {
                if ($exclude_plugins{$prefix}) {
                    log_debug "[URI::Info] plugin '$mod' is excluded";
                    next;
                }
                log_debug "[URI::Info] Loading plugin module $mod ...";
                (my $mod_pm = "$mod.pm") =~ s!::!/!g;
                require $mod_pm;
                $self->_activate_plugin($mod, $args);
            } else {
                die "[URI::Info] plugin '$mod' cannot be found";
            }
        }
    }
}

# this will install plugins by host
sub _activate_plugin {
    my ($self, $mod, $args) = @_;

    # module must already be loaded at this point

    # instantiate plugin object
    my $plugin_obj  = $mod->new(
        ref $args eq 'HASH' ? %$args : @{$args // []});
    my $plugin_meta = $plugin_obj->meta;
    my $plugin_host0 = $plugin_meta->{host};

    my @plugin_hosts;
    if (ref $plugin_host0 eq 'ARRAY') {
        @plugin_hosts = @$plugin_host0;
    } elsif (ref $plugin_host0 eq 'CODE') {
        @plugin_hosts = $plugin_host0->();
    } elsif (!ref($plugin_host0)) {
        @plugin_hosts = ($plugin_host0);
    } else {
        die "[URI::Info] invalid plugin host '$plugin_host0', must be array/code/scalar";
    }

    for my $plugin_host (@plugin_hosts) {
        $self->{plugin_objs_by_host}{$plugin_host} //= [];
        push @{ $self->{plugin_objs_by_host}{$plugin_host} }, $plugin_obj;
    }
}

sub _call_plugins {
    my ($self, $meth, $stash) = @_;

    my $host0 = $stash->{url}->host;
    my @hosts;
    push @hosts, $host0;
    while ($host0 =~ s/\A[\w-]+(?:\.|\z)//) {
        push @hosts, $host0;
    }
    for my $host (@hosts) {
        my $plugin_objs = $self->{plugin_objs_by_host}{$host};
        next unless $plugin_objs;
        for my $plugin_obj (@$plugin_objs) {
            log_trace "[URI::Info] Calling plugin %s %s", ref($plugin_obj), $meth;
            $plugin_obj->$meth($stash);
            # XXX currently ignore return value
        }
    }
}

sub info {
    require URI::URL;
    require URI::QueryParam;

    my ($self, $url) = @_;
    my $stash = {
        url => URI::URL->new($url),
        res => {
            url => $url,
        },
    };
    $self->_call_plugins('get_info', $stash);
    $stash->{res};
}

sub uri_info {
    state $obj = __PACKAGE__->new;
    $obj->info($_);
}

1;
# ABSTRACT: Extract various information from a URI (URL)

__END__

=pod

=encoding UTF-8

=head1 NAME

URI::Info - Extract various information from a URI (URL)

=head1 VERSION

This document describes version 0.004 of URI::Info (from Perl distribution URI-Info), released on 2023-06-21.

=head1 SYNOPSIS

 use URI::Info;

 my $info = URI::Info->new(
     # include_plugins => ['Search::*'],  # only use these plugins. by default, all plugins will be loaded
     # exclude_plugins => [...],          # don't use certain plugins
 );

 my $res = $info->info("https://www.google.com/search?safe=off&oq=kathy+griffin");
 # => {
 #        host => "www.google.com",
 #        is_search=>1,
 #        search_engine=>"Google",
 #        search_string=>"kathy griffin",
 # }

=head1 DESCRIPTION

This module (and its plugins) will let you extract various information from a
piece of URI (URL) string.

Keywords: URI parser, URL parser, search string extractor

=head1 FUNCTIONS

=head2 uri_info

Usage:

 my $hashref = uri_info($uri);

Return a hash of extracted pieces of information from a C<$uri> string. Will
consult the plugins to do the hard work. All the installed plugins will be used.
To customize the set of plugins to use, use the OO interface.

=head1 METHODS

=head2 new

Usage:

 my $uinfo = URI::Info->new(%args);

Constructor. Known arguments (C<*> marks required arguments):

=over

=item * include_plugins

Array of plugins (names or wildcard patterns or names+arguments) to include.
Plugin name is module name under C<URI::Info::Plugin::> without the prefix,
e.g.:

 SearchQuery::tokopedia

Wildcard pattern is a pattern containing wildcard characters, e.g:

 SearchQuery::toko*
 SearchQuery::**

See L<Module::List::Wildcard> for more details on the wildcard behavior,
particularly the difference between C<*> and C<**>.

Name+argument is either: 1) a string containing plugin name followed by C<=>
followed by a comma-separated list of arguments, or; 2) a 2-element arrayref
where the first element is plugin name or wildcard pattern, and the second
element is an arrayref or hashref of arguments to instantiate the plugin with.
Examples:

 SearchQuery::tokopedia=foo,1,bar,2
 ['SearchQuery::tokopedia', {foo=>1, bar=>2, ...}]

If C<include_plugins> is unspecified, will list all installed modules under
C<URI::Info::Plugin::> and include them all.

=item * exclude_plugins

Array of plugins (names or wildcard patterns) to exclude.

Takes precedence over C<include_plugins> argument.

Default is empty array.

=back

=head2 info

Usage:

 my $hashref = $uinfo->info($url);

Example:

 my $hashref = $uinfo->info("https://www.google.com/search?q=foo+bar");
 # => {url=>"https://www.google.com/search?q=foo+bar", is_search=>1, search_type=>'search', search_query=>'foo bar'}

=head1 ENVIRONMENT

=head2 URI_INFO_PLUGINS

This can be used to include/exclude plugins when C<include_plugins> *and*
C<exclude_plugins> attributes are not set. The syntax is:

 -Plugin1ToExclude,+Plugin2ToInclude,arg1,val1,...,+Plugin3ToInclude

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/URI-Info>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-URI-Info>.

=head1 SEE ALSO

L<URI::ParseSearchString>. For extracting search query terms, this module is
much more concise albeit not plugin-based. Last update is 2013.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 CONTRIBUTOR

=for stopwords Steven Haryanto

Steven Haryanto <stevenharyanto@gmail.com>

=head1 CONTRIBUTING


To contribute, you can send patches by email/via RT, or send pull requests on
GitHub.

Most of the time, you don't need to build the distribution yourself. You can
simply modify the code, then test via:

 % prove -l

If you want to build the distribution (e.g. to try to install it locally on your
system), you can install L<Dist::Zilla>,
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>,
L<Pod::Weaver::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla- and/or Pod::Weaver plugins. Any additional steps required beyond
that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023, 2021 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=URI-Info>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
