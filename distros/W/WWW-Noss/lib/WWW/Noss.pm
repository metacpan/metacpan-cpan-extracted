package WWW::Noss;
use 5.016;
use strict;
use warnings;
our $VERSION = '2.02';

use Cwd;
use Getopt::Long qw(GetOptionsFromArray);
use File::Basename;
use File::Copy;
use File::Spec;
use File::Temp qw(tempfile);
use List::Util qw(max uniq);
use POSIX qw(strftime);
use Pod::Usage;
use Term::ANSIColor;

use JSON;

use WWW::Noss::Curl qw(curl curl_error http_status_string);
use WWW::Noss::DB;
use WWW::Noss::FeedConfig;
use WWW::Noss::FeedReader qw(discover_feeds);
use WWW::Noss::GroupConfig;
use WWW::Noss::Home qw(home);
use WWW::Noss::Lynx qw(lynx_dump);
use WWW::Noss::OPML;
use WWW::Noss::TextToHtml qw(escape_html);
use WWW::Noss::Util qw(dir resolve_url);

my $PRGNAM = 'noss';
my $PRGVER = $VERSION;

# TODO: Command aliases?
# TODO: "open" feed setting? (command to use for opening post URLs)

# TODO: Have list --limit ... only show the latest posts rather than earliest

my %COMMANDS = (
    'update'   => \&update,
    'reload'   => \&reload,
    'read'     => \&read_post,
    'open'     => \&open_post,
    'cat'      => \&cat,
    'list'     => \&look,
    'unread'   => \&unread,
    'mark'     => \&mark,
    'post'     => \&post,
    'feeds'    => \&feeds,
    'groups'   => \&groups,
    'clean'    => \&clean,
    'discover' => \&discover,
    'export'   => \&export_opml,
    'import'   => \&import_opml,
    'help'     => \&help,
);

my $DOT_LOCAL  = File::Spec->catfile(home, '.local/share');
my $DOT_CONFIG = File::Spec->catfile(home, '.config');

my $DEFAULT_AGENT = "$PRGNAM/$PRGVER ($^O; perl $^V)";
my $DEFAULT_PAGER = $^O eq 'MSWin32' ? 'more' : 'less';
my $DEFAULT_FORKS = 10;
my $DEFAULT_WIDTH = 80;

my %VALID_SORTS = map { $_ => 1 } qw(
    feed
    title
    date
);

my $Z_FMT = '%c';
my $Z_UNK = strftime($Z_FMT, localtime 0) =~ s/\w/?/gr;

my $RATE_RX = qr/^\d+[kmg]?$/i;

my %POST_FMT_CODES = (
    '%' => sub { '%' },
    'f' => sub { $_[0]->{ feed     } },
    'i' => sub { $_[0]->{ nossid   } },
    't' => sub { $_[0]->{ displaytitle } // ''},
    'u' => sub { $_[0]->{ link     } // 'N/A' },
    'a' => sub { $_[0]->{ author   } // 'N/A' },
    'c' => sub { join ', ', @{ $_[0]->{ category } } },
    's' => sub { $_[0]->{ status } eq 'read' ? 'r' : 'U' },
    'S' => sub { $_[0]->{ status } eq 'read' ? 'read' : 'unread' },
    'P' => sub { $_[0]->{ summary } // '' },
    'C' => sub {
        strftime('%c', localtime($_[0]->{ updated } // $_[0]->{ published } // return 'N/A'))
    },
    'd' => sub {
        strftime('%d', localtime($_[0]->{ updated } // $_[0]->{ published } // return '??'))
    },
    'w' => sub {
        strftime('%a', localtime($_[0]->{ updated } // $_[0]->{ published } // return '???'))
    },
    'W' => sub {
        strftime('%A', localtime($_[0]->{ updated } // $_[0]->{ published } // return '???'))
    },
    'm' => sub {
        strftime('%b', localtime($_[0]->{ updated } // $_[0]->{ published } // return '???'))
    },
    'M' => sub {
        strftime('%B', localtime($_[0]->{ updated } // $_[0]->{ published } // return '???'))
    },
    'n' => sub {
        strftime('%m', localtime($_[0]->{ updated } // $_[0]->{ published } // return '??'))
    },
    'y' => sub {
        strftime('%g', localtime($_[0]->{ updated } // $_[0]->{ published } // return '??'))
    },
    'Y' => sub {
        strftime('%G', localtime($_[0]->{ updated } // $_[0]->{ published } // return '????'))
    },
    'z' => sub {
        my $t = $_[0]->{ updated } // $_[0]->{ published };
        if (defined $t) {
            return strftime($Z_FMT, localtime $t);
        } else {
            return $Z_UNK;
        }
    },
);

my %FEED_FMT_CODES = (
    '%' => sub { '%' },
    'f' => sub { $_[0]->{ nossname    } },
    'l' => sub { $_[0]->{ nosslink    } },
    't' => sub { $_[0]->{ title       } // '' },
    'u' => sub { $_[0]->{ link        } // 'N/A' },
    'e' => sub { $_[0]->{ description } // '' },
    'a' => sub { $_[0]->{ author      } // 'N/A' },
    'c' => sub { join ', ', @{ $_[0]->{ category } // [] } },
    'p' => sub { $_[0]->{ posts } // 0},
    'r' => sub { ($_[0]->{ posts } // 0) - ($_[0]->{ unread } // 0) },
    'U' => sub { $_[0]->{ unread } // 0},
    'C' => sub {
        strftime('%c', localtime($_[0]->{ updated } // return 'N/A'))
    },
    'd' => sub {
        strftime('%d', localtime($_[0]->{ updated } // return '??'))
    },
    'w' => sub {
        strftime('%a', localtime($_[0]->{ updated } // return '???'))
    },
    'W' => sub {
        strftime('%A', localtime($_[0]->{ updated } // return '???'))
    },
    'm' => sub {
        strftime('%b', localtime($_[0]->{ updated } // return '???'))
    },
    'M' => sub {
        strftime('%B', localtime($_[0]->{ updated } // return '???'))
    },
    'n' => sub {
        strftime('%m', localtime($_[0]->{ updated } // return '??'))
    },
    'y' => sub {
        strftime('%g', localtime($_[0]->{ updated } // return '??'))
    },
    'Y' => sub {
        strftime('%G', localtime($_[0]->{ updated } // return '????'))
    },
    'z' => sub {
        my $t = $_[0]->{ updated };
        if (defined $t) {
            return strftime($Z_FMT, localtime $t);
        } else {
            return $Z_UNK;
        }
    },
);

my $DEFAULT_READ_FMT = <<'HERE';
<h1>%f - %t</h1>

<div>
%P
</div>

<p>
Link: %u
</p>

<p>
Updated: %z
</p>

HERE

my $DEFAULT_POST_FMT = <<'HERE';
<14>%f<0>:<15>%i<0>
  <16>Title<0>:   %t
  <16>Link<0>:    %u
  <16>Author<0>:  %a
  <16>Tags<0>:    %c
  <16>Updated<0>: %z
  <16>Status<0>:  %S
HERE

my $DEFAULT_FEED_FMT = <<'HERE';
<14>%f<0>
  <16>Title<0>:   %t
  <16>Source<0>:  %l
  <16>Link<0>:    %u
  <16>Author<0>:  %a
  <16>Updated<0>: %z
  <16>Posts<0>:   %p
  <16>Unread<0>:  %U/%p

HERE

my %DOESNT_NEED_FEED = map { $_ => 1 } qw(
    discover import help
);

my $COLOR_CODE_RX = qr/(?:1[0-6]|[0-9])/;

my %COLOR_CODES = (
    0  => 'clear',
    1  => 'black',
    2  => 'red',
    3  => 'green',
    4  => 'yellow',
    5  => 'blue',
    6  => 'magenta',
    7  => 'cyan',
    8  => 'white',
    9  => 'bold black',
    10 => 'bold red',
    11 => 'bold green',
    12 => 'bold yellow',
    13 => 'bold blue',
    14 => 'bold magenta',
    15 => 'bold cyan',
    16 => 'bold white',
);

sub _HELP  {

    my ($fh, $rt) = @_;

    pod2usage(
        -exitval => 'NOEXIT',
        -verbose => 99,
        -sections => 'SYNOPSIS',
        -output => \$fh,
    );

    if (defined $rt) {
        exit $rt;
    }

}

sub _VER {

    my ($fh, $rt) = @_;

    print { $fh } <<"HERE";
$PRGNAM - $PRGVER

Copyright (C) 2025-2026 Samuel Young

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.
HERE

    if (defined $rt) {
        exit $rt;
    }

}

sub _set_z_fmt {

    my ($z) = @_;

    $Z_FMT = $z;
    $Z_UNK = strftime($Z_FMT, localtime 0) =~ s/\w/?/gr;

}

sub _default_data_dir {

    my $data;

    if (exists $ENV{ NOSS_DATA }) {
        $data = $ENV{ NOSS_DATA };
    } elsif (exists $ENV{ XDG_DATA_HOME } and -d $ENV{ XDG_DATA_HOME }) {
        $data = File::Spec->catfile($ENV{ XDG_DATA_HOME }, $PRGNAM);
    } elsif (-d $DOT_LOCAL) {
        $data = File::Spec->catfile($DOT_LOCAL, $PRGNAM);
    } else {
        $data = File::Spec->catfile(home, ".$PRGNAM");
    }

    return $data;

}

sub _default_config {

    my $cf;

    if (exists $ENV{ NOSS_CONFIG }) {
        return $ENV{ NOSS_CONFIG };
    }

    if (exists $ENV{ XDG_CONFIG_HOME }) {

        $cf = File::Spec->catfile(
            $ENV{ XDG_CONFIG_HOME },
            $PRGNAM,
            "$PRGNAM.conf"
        );
        return $cf if -f $cf;

        $cf = File::Spec->catfile(
            $ENV{ XDG_CONFIG_HOME },
            "$PRGNAM.conf"
        );
        return $cf if -f $cf;

    }

    if (-d $DOT_CONFIG) {

        $cf = File::Spec->catfile(
            $DOT_CONFIG,
            $PRGNAM,
            "$PRGNAM.conf"
        );
        return $cf if -f $cf;

        $cf = File::Spec->catfile(
            $DOT_CONFIG,
            "$PRGNAM.conf"
        );
        return $cf if -f $cf;

    }

    $cf = File::Spec->catfile(home, ".$PRGNAM.conf");

    return $cf if -f $cf;

    return undef;

}

sub _default_feeds {

    my $ff;

    if (exists $ENV{ NOSS_FEEDS }) {
        return $ENV{ NOSS_FEEDS };
    }

    if (exists $ENV{ XDG_CONFIG_HOME }) {

        $ff = File::Spec->catfile(
            $ENV{ XDG_CONFIG_HOME },
            $PRGNAM,
            "$PRGNAM.feeds"
        );
        return $ff if -f $ff;

        $ff = File::Spec->catfile(
            $ENV{ XDG_CONFIG_HOME },
            "$PRGNAM.feeds"
        );
        return $ff if -f $ff;

    }

    if (-d $DOT_CONFIG) {

        $ff = File::Spec->catfile(
            $DOT_CONFIG,
            $PRGNAM,
            "$PRGNAM.feeds"
        );
        return $ff if -f $ff;

        $ff = File::Spec->catfile(
            $DOT_CONFIG,
            "$PRGNAM.feeds"
        );
        return $ff if -f $ff;

    }

    $ff = File::Spec->catfile(home, ".$PRGNAM.feeds");
    return $ff if -f $ff;

    return undef;

}

sub _read_config {

    my ($self) = @_;

    my $cd = dirname(File::Spec->rel2abs($self->{ ConfFile }));

    open my $fh, '<', $self->{ ConfFile }
        or die "Failed to open $self->{ ConfFile } for reading: $!\n";
    my $slurp = do { local $/ = undef; readline $fh };
    close $fh;

    my $json_obj = JSON->new->relaxed;
    my $json = $json_obj->decode($slurp);

    unless (ref $json eq 'HASH') {
        die "$self->{ ConfFile } is not a valid $PRGNAM configuration file\n";
    }

    if (defined $json->{ feeds }) {
        if (not ref $json->{ feeds }) {
            my $p = $json->{ feeds } =~ s/^~/@{[ home ]}/r;
            $self->{ FeedFile } //=
                File::Spec->file_name_is_absolute($p)
                ? $json->{ feeds }
                : File::Spec->catfile($cd, $p);
        } else {
            warn "'feeds' is not a string, ignoring\n";
        }
    }

    if (defined $json->{ data }) {
        if (not ref $json->{ data }) {
            my $p = $json->{ data } =~ s/^~/@{[ home ]}/r;
            $self->{ DataDir } //=
                File::Spec->file_name_is_absolute($p)
                ? $json->{ data }
                : File::Spec->catfile($cd, $p);
        } else {
            warn "'data' is not a string, ignoring\n";
        }
    }

    if (defined $json->{ downloads }) {
        if ($json->{ downloads } =~ /^\d+$/) {
            $self->{ Forks } //= $json->{ downloads };
        } else {
            warn "'downloads' ($json->{ downloads }) is not an integar, ignoring\n";
        }
    }

    if (defined $json->{ pager }) {
        if (not ref $self->{ pager }) {
            $self->{ Pager } //= $json->{ pager };
        } else {
            warn "'pager' is not a string, ignoring\n";
        }
    }

    if (defined $json->{ browser }) {
        if (not ref $self->{ browser }) {
            $self->{ Browser } //= $json->{ browser };
        } else {
            warn "'browser' is not a string, ignoring\n";
        }
    }

    if (defined $json->{ limit_rate }) {
        if ($self->{ RateLimit } =~ $RATE_RX) {
            $self->{ RateLimit } //= $json->{ limit_rate };
        } else {
            warn "limit_rate' ($json->{ limit_rate }) is not a valid speed, ignoring\n";
        }
    }

    if (defined $json->{ user_agent }) {
        if (ref $json->{ user_agent }) {
            warn "'user_agent' is not a string, ignoring\n";
        } else {
            $self->{ UserAgent } //= $json->{ user_agent };
        }
    }

    if (defined $json->{ timeout }) {
        if ($json->{ timeout } =~ /^\d+(\.\d+)?$/) {
            $self->{ Timeout } //= $json->{ timeout };
        } else {
            warn "'timeout' ($json->{ timeout }) is not numerical, ignoring\n";
        }
    }

    if (defined $json->{ proxy }) {
        if (ref $json->{ proxy }) {
            warn "'proxy' is not a string, ignoring\n";
        } else {
            $self->{ Proxy } //= $json->{ proxy };
        }
    }

    if (defined $json->{ proxy_user }) {
        if ($json->{ proxy_user } =~ /^[^:]+:[^:]+$/) {
            $self->{ ProxyUser } //= $json->{ proxy_user };
        } else {
            warn "'proxy_user' ($json->{ proxy_user }) is not a valid proxy user string, ignoring\n";
        }
    }

    if (defined $json->{ sort }) {
        if (exists $VALID_SORTS{ $json->{ sort } }) {
            $self->{ Sort } //= $json->{ sort };
        } else {
            warn sprintf "'sort' must be one of the following: %s\n", join(', ', sort keys %VALID_SORTS);
        }
    }

    if (defined $json->{ line_width }) {
        if ($json->{ line_width } =~ /^\d+$/ and $json->{ line_width } > 0) {
            $self->{ LineWidth } //= $json->{ line_width };
        } else {
            warn "'line_width' must be an integar greater than 0, ignoring\n";
        }
    }

    if (defined $json->{ list_format }) {
        if (ref $json->{ list_format }) {
            warn "'list_format' is not a format string, ignoring\n";
        } else {
            $self->{ ListFmt } //= $json->{ list_format };
        }
    }

    if (defined $json->{ read_format }) {
        if (ref $json->{ read_format }) {
            warn "'read_format' is not a format string, ignoring\n";
        } else {
            $self->{ ReadFmt } //= $json->{ read_format };
        }
    }

    if (defined $json->{ post_format }) {
        if (ref $json->{ post_format }) {
            warn "'post_format' is not a format string, ignoring\n";
        } else {
            $self->{ PostFmt } //= $json->{ post_format };
        }
    }

    if (defined $json->{ feeds_format }) {
        if (ref $json->{ feeds_format }) {
            warn "'feeds_format' is not a format string, ignoring\n";
        } else {
            $self->{ FeedsFmt } //= $json->{ feeds_fmt };
        }
    }

    if (defined $json->{ autoclean }) {
        $self->{ AutoClean } //= !! $json->{ autoclean };
    }

    if (defined $json->{ time_format }) {
        if (ref $json->{ time_format }) {
            warn "'time_format' is not a format string, ignoring\n";
        } else {
            $self->{ TimeFmt } //= $json->{ time_format };
        }
    }

    if (defined $json->{ list_limit }) {
        if ($json->{ list_limit } =~ /^-?\d+$/) {
            $self->{ ListLimit } //= $json->{ list_limit };
        } else {
            warn "'list_limit' ($json->{ list_limit }) is not an integar, ignoring\n";
        }
    }

    if (defined $json->{ colors }) {
        if (ref $json->{ colors } ne 'HASH') {
            warn "'colors' is not a key-value map, ignoring\n";
        } else {
            for my $k (keys %{ $json->{ colors } }) {
                if (not exists $self->{ ColorMap }{ $k }) {
                    warn "'$k' is not a valid color code, ignoring\n";
                    next;
                }
                $self->{ ColorMap }{ $k } = $json->{ colors }{ $k };
            }
        }
    }

    if (defined $json->{ list_unread_format }) {
        if (ref $json->{ list_unread_format }) {
            warn "'list_unread_format' is not a format string, ignoring\n";
        } else {
            $self->{ ListUnreadFmt } //= $json->{ list_unread_format };
        }
    }

    if (defined $json->{ colored_output }) {
        # If true, set to undef so that noss can automatically disable the use
        # of color when not writing to a terminal.
        $self->{ UseColor } //= $json->{ colored_output } ? undef : 0;
    }

    return 1;

}

# Note to a confused future self:
# When adding a new feed parameter, the following locations should be updated:
# * This _feed_params subroutine
# * BaseConfig attributes
# * FeedConfig group attribute initialization
# * (Base|Feed|Group)Config documentation
# * FeedConfig tests
# * Feed configuration section in manual
sub _feed_params {

    my ($ref) = @_;

    my %params;

    if (defined $ref->{ limit }) {
        if ($ref->{ limit } =~ /^\d+$/) {
            $params{ limit } = $ref->{ limit };
        } else {
            warn "'limit' ($ref->{ limit }) is not an integar, ignoring\n";
        }
    }

    if (defined $ref->{ respect_skip }) {
        $params{ respect_skip } = !! $ref->{ respect_skip };
    }

    if (defined $ref->{ include_title }) {
        if (ref $ref->{ include_title } eq 'ARRAY') {
            $params{ include_title } = [ map { _arg2rx($_) } @{ $ref->{ include_title } } ];
        } elsif (not ref $ref->{ include_title }) {
            $params{ include_title } = [ _arg2rx($ref->{ include_title }) ];
        } else {
            warn "'include_title' is not an array or string, ignoring\n";
        }
    }

    if (defined $ref->{ exclude_title }) {
        if (ref $ref->{ exclude_title } eq 'ARRAY') {
            $params{ exclude_title } = [ map { _arg2rx($_) } @{ $ref->{ exclude_title } } ];
        } elsif (not ref $ref->{ exclude_title }) {
            $params{ exclude_title } = [ _arg2rx($ref->{ exclude_title }) ];
        } else {
            warn "'exclude_title' is not an array or string, ignoring\n";
        }
    }

    if (defined $ref->{ include_content }) {
        if (ref $ref->{ include_content } eq 'ARRAY') {
            $params{ include_content } = [ map { _arg2rx($_) } @{ $ref->{ include_content } } ];
        } elsif (not ref $ref->{ include_content }) {
            $params{ include_content } = [ _arg2rx($ref->{ include_content }) ];
        } else {
            warn "'include_content' is not an array or string, ignoring\n";
        }
    }

    if (defined $ref->{ exclude_content }) {
        if (ref $ref->{ exclude_content } eq 'ARRAY') {
            $params{ exclude_content } = [ map { _arg2rx($_) } @{ $ref->{ exclude_content } } ];
        } elsif (not ref $ref->{ exclude_content }) {
            $params{ exclude_content } = [ _arg2rx($ref->{ exclude_content }) ];
        } else {
            warn "'exclude_content' is not an array or string, ignoring\n";
        }
    }

    if (defined $ref->{ include_tags }) {
        if (ref $ref->{ include_tags } eq 'ARRAY') {
            $params{ include_tags } = $ref->{ include_tags };
        } elsif (not ref $ref->{ include_tags }) {
            $params{ include_tags } = [ $ref->{ include_tags } ];
        } else {
            warn "'include_tags' is not an array or string, ignoring\n";
        }
    }

    if (defined $ref->{ exclude_tags }) {
        if (ref $ref->{ exclude_tags } eq 'ARRAY') {
            $params{ exclude_tags } = $ref->{ exclude_tags };
        } elsif (not ref $ref->{ exclude_tags }) {
            $params{ exclude_tags } = [ $ref->{ exclude_tags } ];
        } else {
            warn "'exclude_tags' is not an array or string, ignoring\n";
        }
    }

    if (defined $ref->{ autoread }) {
        $params{ autoread } = !! $ref->{ autoread };
    }

    if (defined $ref->{ default_update }) {
        $params{ default_update } = !! $ref->{ default_update };
    }

    if (defined $ref->{ hidden }) {
        $params{ hidden } = !! $ref->{ hidden };
    }

    return %params;

}

sub _read_feed_file {

    my ($self) = @_;

    open my $fh, '<', $self->{ FeedFile }
        or die "Failed to open $self->{ FeedFile } for reading: $!\n";
    my $slurp = do { local $/ = undef; readline $fh };
    close $fh;

    my $json_obj = JSON->new->relaxed;
    my $json = $json_obj->decode($slurp);

    unless (ref $json eq 'HASH') {
        die "$self->{ FeedFile } is not a valid feed file\n";
    }

    unless (exists $json->{ feeds }) {
        die "Failed to read $self->{ FeedFile }: missing 'feeds' list\n";
    }

    my $feeds   = $json->{ feeds  };
    my $groups  = $json->{ groups }  // {};
    my $default = $json->{ default } // {};

    unless (ref $feeds eq 'HASH') {
        die "Failed to read $self->{ FeedFile }: 'feeds' must be a key-value map\n";
    }

    unless (ref $groups eq 'HASH') {
        die "Failed to read $self->{ FeedFile }: 'groups' must be a key-value map\n";
    }

    unless (ref $default eq 'HASH') {
        die "Failed to read $self->{ FeedFile }: 'default' must be a key-value map\n";
    }

    for my $k (keys %$groups) {
        unless ($k =~ /^\w+$/) {
            warn "'$k' is not a valid feed group: name contains invalid characters, ignoring\n";
            delete $groups->{ $k };
        }
        if (exists $feeds->{ $k }) {
            die "'$k' is both the name of a feed and group\n";
        }
    }

    for my $k (keys %$feeds) {
        unless ($k =~ /^\w+$/) {
            warn "'$k' is not a valid feed name: contains invalid characters, ignoring\n";
            delete $feeds->{ $k };
        }
    }


    if (%$default) {
        my %params = _feed_params($default);
        $self->{ DefaultGroup } = WWW::Noss::GroupConfig->new(
            name => ':all',
            feeds => [ keys %$feeds ],
            %params
        );
    }

    for my $k (keys %$groups) {
        my $g = $groups->{ $k };

        if (ref $g eq 'ARRAY') {
            $g = { feeds => $g };
        } elsif (ref $g ne 'HASH') {
            warn "'$k' is neither a feed list or key-value map, skipping\n";
            next;
        }

        unless (ref $g->{ feeds } eq 'ARRAY') {
            warn "'$k' group does not contain a feed list, skipping\n";
            next;
        }

        my %params = _feed_params($g);

        $self->{ Groups }{ $k } = WWW::Noss::GroupConfig->new(
            name => $k,
            feeds => $g->{ feeds },
            %params
        );

    }

    for my $k (keys %$feeds) {
        my $f = $feeds->{ $k };

        if (not ref $f and defined $f) {
            $f = { feed => $f };
        } elsif (ref $f ne 'HASH') {
            warn "'$k' is neither a feed link or a key-value map, skipping\n";
            next;
        }

        unless (exists $f->{ feed }) {
            warn "'$k' feed does not contain a feed link, skipping\n";
            next;
        }

        if (ref $f->{ feed } or not defined $f->{ feed }) {
            warn "'$k' feed link is not a string, skipping\n";
            next;
        }

        my @groups = grep { $_->has_feed($k) } values %{ $self->{ Groups } };

        my %params = _feed_params($f);

        $self->{ Feeds }{ $k } = WWW::Noss::FeedConfig->new(
            name => $k,
            feed => $f->{ feed },
            default => $self->{ DefaultGroup },
            groups => \@groups,
            path => File::Spec->catfile($self->{ FeedDir }, "$k.feed"),
            etag => File::Spec->catfile($self->{ EtagDir }, "$k.etag"),
            retry_cache => File::Spec->catfile($self->{ RetryDir }, "$k.retry"),
            %params
        );

    }

    unless (%{ $self->{ Feeds } }) {
        die "$PRGNAM found no feeds in $self->{ FeedFile }\n";
    }

    return 1;

}

sub _arg2rx {

    my ($str) = @_;

    if ($str =~ /^\/(.*)\/$/) {
        return qr/$1/i;
    } else {
        return qr/\Q$str\E/i;
    }

}

sub _fmt {

    my ($fmt, $codes, $colors) = @_;
    $colors //= {};

    $fmt .= "\n" unless $fmt =~ /\n$/;

    my @subs;
    my $colored = 0;

    $fmt =~ s{(?<Fmt>%(?:[+\-]?\d+)?.)|(?<Color><$COLOR_CODE_RX>)}{
        if (defined $+{ Fmt }) {
            my $code = substr $+{ Fmt }, 1;
            my $c = chop $code;
            unless (exists $codes->{ $c }) {
                die "'%$code$c' is not a valid formatting code\n";
            }
            push @subs, $codes->{ $c };
            '%' . $code . 's';
        } else {
            my $code = substr $+{ Color }, 1, -1;
            if (not exists $colors->{ $code }) {
                $+{ Color };
            } else {
                $colored = 1;
                color($colors->{ $code });
            }
        }
    }ge;

    if ($colored) {
        $fmt .= color('reset');
    }

    return sub { sprintf $fmt, map { $_->($_[0]) } @subs };

}

sub _rm_color_codes {

    my ($str) = @_;

    return $str =~ s/<$COLOR_CODE_RX>//gr;

}

sub err {

    my ($self, @args) = @_;

    my $err = join '', @args;

    if ($self->{ UseColor } and -t STDERR) {
        warn colored($err, 'bold red') . "\n";
    } else {
        warn "$err\n";
    }

}

sub _get_feed {

    my ($self, $feed) = @_;

    if ($feed->feed =~ /^file:\/\//) {

        my $f = $feed->feed =~ s/^file:\/\///r;

        $f =~ s/^~/@{[ home ]}/;

        unless (File::Spec->file_name_is_absolute($f)) {
            $f = File::Spec->catfile(
                dirname($self->{ FeedFile }),
                $f
            );
        }

        copy($f, $feed->path)
            or die sprintf "Failed to copy %s to %s: %s\n", $f, $feed->path, $!;
        # Copy over access and mod times
        utime((stat($f))[8, 9], $feed->path);

        return $feed->path;

    } elsif ($feed->feed =~ /^shell:\/\//) {

        my $cmd = $feed->feed =~ s/^shell:\/\///r;

        open my $fh, '>', $feed->path
            or die sprintf "Failed to open %s for writing: %s\n", $feed->path, $!;

        # cd into feed file directory, so that shell command is ran from said
        # directory.
        my $cwd = cwd;

        chdir dirname($self->{ FeedFile })
            or die "Failed to chdir to $self->{ FeedFile }: $!\n";

        my $qx = qx/$cmd/;

        unless ($? >> 8 == 0) {
            chdir $cwd or die "Failed to chdir to $cwd: $!\n";
            die "Failed to execute '$cmd'\n";
        }

        print { $fh } $qx;

        close $fh;

        chdir $cwd or die "Failed to chdir to $cwd: $!\n";

        return $feed->path;

    # Otherwise, just try to curl the URL
    } else {

        my ($rt, $resp, $head) = curl(
            $feed->feed,
            $feed->path,
            verbose => 0,
            remote_time => 1,
            etag_save => $feed->etag,
            limit_rate => $self->{ RateLimit },
            user_agent => $self->{ UserAgent },
            timeout => $self->{ Timeout },
            fail => 1,
            proxy => $self->{ Proxy },
            proxy_user => $self->{ ProxyUser },
            (
                !$self->{ Unconditional } && -f $feed->path
                ? (
                    time_cond => $feed->path,
                    etag_compare => (-s $feed->etag ? $feed->etag : undef),
                )
                : ()
            ),
            redirect => 1,
            compressed => 1,
        );

        if (defined $resp and $resp->[1] eq '429') {
            my $retry = $head->{ 'retry-after' };
            if (defined $retry and $retry =~ /^\d+$/) {
                $feed->set_retry($retry + time);
            }
        }

        if ($rt != 0) {
            my $e;
            if (defined $resp and $resp->[1] =~ /^[45]/) {
                $e = "$resp->[1] " . ($resp->[2] || http_status_string($resp->[1]));
            } else {
                $e = curl_error($rt);
            }
            die "$e\n";
        }

        return $feed->path;

    }

}

sub update {

    my ($self) = @_;

    require Parallel::ForkManager;

    # --hard implies --unconditional
    if ($self->{ HardReload }) {
        $self->{ Unconditional } = 1;
    }

    my @updates;

    if (@{ $self->{ Args } }) {
        my %feedset;
        for my $arg (@{ $self->{ Args } }) {
            if (exists $self->{ Feeds }{ $arg }) {
                $feedset{ $arg } = 1;
            } elsif ($self->{ Groups }{ $arg }) {
                for my $k (@{ $self->{ Groups }{ $arg }->feeds }) {
                    $feedset{ $k } = 1;
                }
            } else {
                warn "'$arg' is not the name of a feed or feed group, skipping\n";
            }
        }
        @updates = keys %feedset;
    } elsif ($self->{ NonDefaults }) {
        @updates = keys %{ $self->{ Feeds } };
    } else {
        @updates =
            grep { $self->{ Feeds }{ $_ }->default_update }
            keys %{ $self->{ Feeds } };
    }

    if ($self->{ NewOnly }) {
        @updates = grep { !$self->{ DB }->has_feed($_) } @updates;
    }

    unless (@updates) {
        die "No feeds can be updated\n";
    }

    @updates = map { [ $_, $self->{ DB }->skip($_) ] } @updates;

    my @change;

    my $pm = Parallel::ForkManager->new($self->{ Forks });
    $pm->run_on_finish(sub {
        push @change, ${ $_[5] } if defined $_[5];
    });
    DOWNLOAD: for my $u (@updates) {

        $pm->start and next DOWNLOAD;

        my ($name, $skip) = @$u;
        my $feed = $self->{ Feeds }{ $name };

        if ($feed->respect_skip and !$self->{ Unconditional } and $skip) {
            say "Skipping $name";
            $pm->finish;
            last;
        }

        if ($feed->respect_skip and !$self->{ Unconditional } and !$feed->can_we_retry) {
            say "Skipping $name; performed too many requests";
            $pm->finish;
            last;
        }

        my $changed = 0;

        my $oldmod = -f $feed->path ? (stat($feed->path))[9] : 0;

        eval { $self->_get_feed($feed) };

        if ($@ ne '' or not -f $feed->path) {
            my $e = $@ || 'unknown error';
            chomp $e;
            $self->err(sprintf "Failed to fetch %s: %s", $feed->feed, $e);
        } else {
            printf "Fetched %s\n", $feed->feed;
            my $newmod = (stat($feed->path))[9];
            $changed = $newmod != $oldmod;
        }

        if ($self->{ HardReload }) {
            $pm->finish(0, \$name);
        } else {
            $pm->finish(0, $changed ? \$name : undef);
        }

    }

    $pm->wait_all_children;

    my %feed_updates;

    for my $c (@change) {

        my $new = eval {
            if ($self->{ HardReload }) {
                $self->{ DB }->del_feeds($c);
            }
            $self->{ DB }->load_feed($self->{ Feeds }{ $c });
        };

        if ($@ ne '') {
            my $e = $@;
            chomp $e;
            $self->err("Error updating $c: $e, skipping");
            next;
        }

        next if $new == 0;
        $feed_updates{ $c } = $new;

    }

    if (%feed_updates) {
        for my $k (sort keys %feed_updates) {
            say "$k: $feed_updates{ $k } new posts";
        }
    } else {
        say "No new posts";
    }

    return 1;

}

sub reload {

    my ($self) = @_;

    my @reloads;

    if (@{ $self->{ Args } }) {
        my %feedset;
        for my $arg (@{ $self->{ Args } }) {
            if (exists $self->{ Feeds }{ $arg }) {
                $feedset{ $arg } = 1;
            } elsif (exists $self->{ Groups }{ $arg }) {
                for my $k (@{ $self->{ Groups }{ $arg }->feeds }) {
                    $feedset{ $k } = 1;
                }
            } else {
                warn "'$arg' is not the name of a feed or feed group, skipping\n";
            }
        }

        for my $f (keys %feedset) {
            if (-f $self->{ Feeds }{ $f }->path) {
                push @reloads, $f;
            } else {
                $self->err("'$f' does not have a local feed file, skipping");
            }
        }

    } else {
        @reloads =
            grep { -f $self->{ Feeds }{ $_ }->path }
            keys %{ $self->{ Feeds } };
    }

    unless (@reloads) {
        say "No feeds to reload";
        return 1;
    }

    my %feed_updates;

    for my $r (@reloads) {

        my $new = eval {
            if ($self->{ HardReload }) {
                $self->{ DB }->del_feeds($r);
            }
            $self->{ DB }->load_feed($self->{ Feeds }{ $r });
        };

        unless (defined $new) {
            my $e = $@;
            chomp $e;
            if ($e ne '') {
                $self->err("Failed to reload $r: $e, skipping");
            } else {
                $self->err("Failed to reload $r, skipping");
            }
            next;
        }

        next if $new == 0;
        $feed_updates{ $r } = $new;

    }

    if (%feed_updates) {
        for my $k (sort keys %feed_updates) {
            say "$k: $feed_updates{ $k } new posts";
        }
    } else {
        say "No new posts";
    }

    return 1;

}

sub read_post {

    my ($self) = @_;

    my $feed_name = shift @{ $self->{ Args} };

    unless (defined $feed_name) {
        die "'$self->{ Cmd }' requires a feed name as argument\n";
    }

    unless (exists $self->{ Feeds }{ $feed_name }) {
        die "'$feed_name' is not the name of a feed\n";
    }

    my $id = shift @{ $self->{ Args } };

    my $post;

    if (defined $id) {
        if ($id !~ /^-?\d+$/) {
            die "Post ID must be an integar\n";
        }
        $post = $self->{ DB }->post($feed_name, $id);
        unless (defined $post) {
            die "'$feed_name:$id' does not exist\n";
        }
    } else {
        $post = $self->{ DB }->first_unread($feed_name);
        unless (defined $post) {
            say "$feed_name has no unread posts, please manually specify a post ID";
            return 1;
        }
    }

    $self->{ ReadFmt } = _rm_color_codes($self->{ ReadFmt });

    my $fmt = do {
        my %fmt_codes = %POST_FMT_CODES;
        for my $f (keys %fmt_codes) {
            next if $f eq 'P';
            $fmt_codes{ $f } = sub {
                escape_html($POST_FMT_CODES{ $f }->($_[0]))
            };
        }
        _fmt($self->{ ReadFmt }, \%fmt_codes);
    };

    my $dump;

    if ($self->{ ReadHtml }) {

        $dump = $fmt->($post);

    } else {

        my ($tmp_html_fh, $tmp_html_nm) = tempfile(UNLINK => 1);
        print { $tmp_html_fh } $fmt->($post);
        close $tmp_html_fh;

        $dump = lynx_dump($tmp_html_nm, width => $self->{ LineWidth });

    }


    if ($self->{ Stdout }) {

        say $dump;

    } else {

        my ($tmp_lynx_fh, $tmp_lynx_nm) = tempfile(UNLINK => 1);
        print { $tmp_lynx_fh } $dump;
        close $tmp_lynx_fh;

        system "$self->{ Pager } $tmp_lynx_nm";

        unless ($? >> 8 == 0) {
            die "Failed to run less on $tmp_lynx_nm\n";
        }

    }

    unless ($self->{ NoMark }) {
        $self->{ DB }->mark('read', $feed_name, $post->{ nossid })
            or die "Failed to mark '$feed_name:$post->{ nossid }' as read";
    }

    return 1;


}

sub open_post {

    my ($self) = @_;

    my $feed_name = shift @{ $self->{ Args} };

    unless (defined $feed_name) {
        die "'open' requires a feed name as argument\n";
    }

    unless (exists $self->{ Feeds }{ $feed_name }) {
        die "'$feed_name' is not the name of a feed\n";
    }

    my $id = shift @{ $self->{ Args } };

    my $post;
    my $url;

    if (not defined $id) {
        my $feed_info = $self->{ DB }->feed($feed_name);
        if (not defined $feed_info) {
            die "$feed_name does not exist in noss's database, perhaps try running the update command?\n";
        }
        $url = $feed_info->{ link };
        if (not defined $url) {
            die "$feed_name does not have a homepage URL\n";
        }
    } else {
        if ($id !~ /^-?\d+$/) {
            die "Post ID must be an integar\n";
        }
        $post = $self->{ DB }->post($feed_name, $id);
        if (not defined $post) {
            die "'$feed_name:$id' does not exist\n";
        }
        $url = $post->{ link };
        if (not defined $url) {
            die "Cannot open $feed_name:$id: Has no post URL\n";
        }
    }

    system "$self->{ Browser } $url";

    unless ($? >> 8 == 0) {
        die "Failed to open $url with $self->{ Browser }\n";
    }

    if (defined $id and not $self->{ NoMark }) {
        $self->{ DB }->mark('read', $feed_name, $post->{ nossid })
            or die "Failed to mark '$feed_name:$id' as read";
    }

    return 1;

}

sub cat {

    my ($self) = @_;

    $self->{ Stdout } = 1;
    $self->read_post;

    return 1;

}

sub look {

    my ($self) = @_;

    my @feeds;

    if (@{ $self->{ Args } }) {
        my %feedset;
        for my $arg (@{ $self->{ Args } }) {
            if (exists $self->{ Feeds }{ $arg }) {
                $feedset{ $arg } = 1;
            } elsif (exists $self->{ Groups }{ $arg }) {
                for my $k (@{ $self->{ Groups }{ $arg }->feeds }) {
                    $feedset{ $k } = 1;
                }
            } else {
                warn "'$arg' is not the name of a feed or feed group, skipping\n";
            }
        }
        @feeds = keys %feedset;
    } elsif ($self->{ ShowHidden }) {
        @feeds = keys %{ $self->{ Feeds } };
    } else {
        @feeds =
            grep { not $self->{ Feeds }{ $_ }->hidden }
            keys %{ $self->{ Feeds } };
    }

    my $titlerx =
        defined $self->{ Title }
        ? _arg2rx($self->{ Title })
        : undef;
    my @contrx = map { _arg2rx($_) } @{ $self->{ Content } };

    unless (@feeds) {
        return 1;
    }

    my $idlen   = length($self->{ DB }->largest_id(@feeds) // 0);
    my $feedlen = max(map { length } @feeds) // 1;

    my $readfmt = do {
        my $fmt = $self->{ ListFmt };
        if (not defined $fmt) {
            $fmt = sprintf "<7>%%s <6>%%-%df <3>%%%di <8>%%t", $feedlen, $idlen;
        }
        if (!$self->{ UseColor }) {
            $fmt = _rm_color_codes($fmt);
        }
        _fmt($fmt, \%POST_FMT_CODES, $self->{ ColorMap });
    };
    my $unreadfmt = do {
        my $fmt = $self->{ ListUnreadFmt };
        if (not defined $fmt) {
            if (defined $self->{ ListFmt }) {
                $fmt = $self->{ ListFmt };
            } else {
                $fmt = sprintf "<15>%%s <14>%%-%df <11>%%%di <16>%%t", $feedlen, $idlen;
            }
        }
        if (!$self->{ UseColor }) {
            $fmt = _rm_color_codes($fmt);
        }
        _fmt($fmt, \%POST_FMT_CODES, $self->{ ColorMap });
    };

    my $callback = sub {
        print $_[0]->{ status } eq 'read'
              ? $readfmt->($_[0])
              : $unreadfmt->($_[0]);
    };

    $self->{ DB }->look(
        title => $titlerx,
        feeds => \@feeds,
        status => $self->{ Status },
        tags => [ map { qr/\Q$_\E/i } @{ $self->{ Tags } } ],
        content => \@contrx,
        order => $self->{ Sort },
        reverse => $self->{ Reverse },
        limit => $self->{ ListLimit },
        callback => $callback,
    );

    return 1;

}

sub unread {

    my ($self) = @_;

    $self->{ Status } = 'unread';

    $self->look;

    return 1;

}

sub mark {

    my ($self) = @_;

    my $status = shift @{ $self->{ Args } };

    unless (defined $status) {
        die "'mark' requires a status as argument\n";
    }

    unless ($status =~ /^(un)?read$/) {
        die "status must either be 'read' or 'unread'\n";
    }

    my @feeds;
    my @posts;

    my $targ = shift @{ $self->{ Args } };

    if (not defined $targ and not $self->{ MarkAll }) {
        die "mark requires a feed name or group as argument\n";
    } elsif (defined $targ and $self->{ MarkAll }) {
        die "mark --all should not be given a feed name or group as argument\n";
    }

    if ($self->{ MarkAll }) {
        @feeds = keys %{ $self->{ Feeds } };
        @posts = ();
    } elsif (exists $self->{ Groups }{ $targ }) {
        @feeds = @{ $self->{ Groups }{ $targ }->feeds };
        @posts = ();
    } elsif (exists $self->{ Feeds }{ $targ }) {
        @feeds = ($targ);
        for my $p (@{ $self->{ Args } }) {
            unless ($p =~ /^(?<from>\d+)(-(?<to>\d+))?$/) {
                die "'$p' is not a post argument\n";
            }
            push @posts, $+{ from } .. $+{ to } // $+{ from };
        }
    } else {
        die "'$targ' is not the name of a feed or group\n";
    }

    my $num = 0;

    for my $f (@feeds) {
        my $n = $self->{ DB }->mark($status, $f, @posts);
        $num += $n;
    }

    say "$num posts updated";

    return 1;

}

sub post {

    my ($self) = @_;

    my $feed = shift @{ $self->{ Args } };
    my $id   = shift @{ $self->{ Args } };

    if (not defined $feed or not defined $id) {
        die "post requires a feed name and post ID as argument\n";
    }

    unless (exists $self->{ Feeds }{ $feed }) {
        die "'$feed' is not the name of a feed\n";
    }

    unless ($id =~ /^-?\d+$/) {
        die "Post ID must be an integar\n";
    }

    my $post = $self->{ DB }->post($feed, $id);

    unless (defined $post) {
        die "'$feed:$id' does not exist\n";
    }

    if (!$self->{ UseColor }) {
        $self->{ PostFmt } = _rm_color_codes($self->{ PostFmt });
    }

    my $fmt = _fmt(
        $self->{ PostFmt },
        \%POST_FMT_CODES,
        $self->{ ColorMap }
    );

    print $fmt->($post);

    return 1;

}

sub feeds {

    my ($self) = @_;

    my @feeds;

    if (@{ $self->{ Args } }) {
        my %feedset;
        for my $a (@{ $self->{ Args } }) {
            if (exists $self->{ Feeds }{ $a }) {
                $feedset{ $a } = 1;
            } elsif (exists $self->{ Groups }{ $a }) {
                for my $f (@{ $self->{ Groups }{ $a }->feeds }) {
                    $feedset{ $f } = 1;
                }
            } else {
                warn "'$a' is not the name of a feed or group, skipping\n";
            }
        }
        @feeds = sort keys %feedset;
    } else {
        @feeds = sort keys %{ $self->{ Feeds } };
    }

    unless (@feeds) {
        die "No feeds can be printed\n";
    }

    if (!$self->{ UseColor }) {
        $self->{ FeedsFmt } = _rm_color_codes($self->{ FeedsFmt });
    }

    my $cb = _fmt($self->{ FeedsFmt }, \%FEED_FMT_CODES, $self->{ ColorMap });

    for my $n (@feeds) {

        my $f = $self->{ DB }->feed($n, post_info => 1);

        $f //= {
            nossname => $self->{ Feeds }{ $n }->name,
            nosslink => $self->{ Feeds }{ $n }->feed,
        };

        print $cb->($f);

    }

    return 1;

}

sub groups {

    my ($self) = @_;

    my @groups;

    if (@{ $self->{ Args } }) {
        for my $a (@{ $self->{ Args } }) {
            if (exists $self->{ Groups }{ $a }) {
                push @groups, $a;
            } else {
                warn "'$a' is not the name of a feed group, skipping\n";
            }
        }
    } else {
        @groups = sort keys %{ $self->{ Groups } };
    }

    unless (@groups) {
        die "No feed groups can be printed\n";
    }

    for my $i (0 .. $#groups) {

        my @feeds =
            grep { exists $self->{ Feeds }{ $_ } }
            @{ $self->{ Groups }{ $groups[$i] }->feeds };

        @feeds = ('(none)') unless @feeds;

        say $groups[$i];

        unless ($self->{ Brief }) {
            for my $f (@feeds) {
                say "  $f";
            }
            print "\n" unless $i == $#groups;
        }

    }

    return 1;

}

sub clean {

    my ($self) = @_;

    for my $f (dir($self->{ FeedDir })) {

        next unless $f =~ /\.feed$/;

        my $feed = (fileparse($f, qr/\.[^.]*/))[0];

        unless (exists $self->{ Feeds }{ $feed }) {
            unlink $f or warn "Failed to unlink $f\n";
        }

    }

    for my $f (dir($self->{ EtagDir })) {

        next unless $f =~ /\.etag/;

        my $feed = (fileparse($f, qr/\.[^.]*/))[0];

        unless (exists $self->{ Feeds }{ $feed }) {
            unlink $f or warn "Failed to unlink $f\n";
        }

    }

    my @dbfeeds = $self->{ DB }->feeds;

    my @clean =
        grep { not exists $self->{ Feeds }{ $_ } }
        map { $_->{ nossname } }
        $self->{ DB }->feeds;

    if (@clean) {
        $self->{ DB }->del_feeds(@clean);
    }

    $self->{ DB }->vacuum;

    return 1;

}

sub discover {

    my ($self) = @_;

    my $url = shift @{ $self->{ Args } };
    if (not defined $url) {
        die "discover requires a URL as argument\n";
    }

    my $tmp = do {
        my ($h, $p) = tempfile(UNLINK => 1);
        close $h;
        $p;
    };

    my ($rt, undef, undef) = curl(
        $url, $tmp,
        user_agent => $self->{ UserAgent },
        limit_rate => $self->{ RateLimit },
        timeout => $self->{ Timeout },
        fail => 1,
        proxy => $self->{ Proxy },
        proxy_user => $self->{ ProxyUser },
        redirect => 1,
    );

    if ($rt != 0) {
        die sprintf "Failed to curl %s: %s\n", $url, curl_error($rt);
    }

    my @feeds = discover_feeds($tmp);
    if (!@feeds) {
        say "No feeds found in $url";
        return 1;
    }

    @feeds = uniq sort map { resolve_url($_, $url) } @feeds;
    for my $f (@feeds) {
        say $f;
    }

    return 1;

}

sub export_opml {

    my ($self) = @_;

    my $to = shift @{ $self->{ Args } };

    my @feeds;

    for my $f (values %{ $self->{ Feeds } }) {
        next if $f->feed =~ /^(file|shell):\/\// and !$self->{ ExportSpec };
        push @feeds, {
            title   => $f->name,
            xml_url => $f->feed,
            groups  => [ map { $_->name } @{ $f->groups } ],
        };
    }

    my $opml = WWW::Noss::OPML->from_perl(
        title => "$PRGNAM Feed List",
        feeds => \@feeds,
    );

    if (defined $to) {
        $opml->to_file($to, folders => !$self->{ NoGroups });
        say "Wrote OPML to $to";
    } else {
        $opml->to_fh(*STDOUT, folders => !$self->{ NoGroups });
    }

    return 1;

}

# TODO: --merge option?
sub import_opml {

    my ($self) = @_;

    my $file = shift @{ $self->{ Args } };

    unless (defined $file) {
        die "import requires an OPML file as argument\n";
    }

    my $to = shift @{ $self->{ Args } };

    my $json = {
        default => {},
        groups  => {},
        feeds   => {},
    };

    my $opml = WWW::Noss::OPML->from_xml($file);

    my %groupset =
        map { $_ =~ s/\W//gr => {} }
        map { @{ $_->{ groups } // [] } }
        @{ $opml->feeds };

    for my $f (@{ $opml->feeds }) {

        my $name = $f->{ title } =~ s/\W//gr;

        if (exists $json->{ feeds }{ $name } and $f->{ xml_url } ne $json->{ feeds }{ $name }) {
            warn "'$name' feed name conflict, $json->{ feeds }{ $name } will be lost\n";
        }

        if (exists $groupset{ $name }) {
            warn "'$name' group name conflict, $name group will be lost\n";
            delete $groupset{ $name };
        }

        $json->{ feeds }{ $name } = $f->{ xml_url };

        for my $g (@{ $f->{ groups } // [] }) {
            $g =~ s/\W//g;
            next unless exists $groupset{ $g };
            $groupset{ $g }->{ $name } = 1;
        }

    }

    unless ($self->{ NoGroups }) {
        for my $g (keys %groupset) {
            $json->{ groups }{ $g } = [ sort keys %{ $groupset{ $g } } ];
        }
    }

    my $json_obj = JSON->new->pretty->canonical;

    if (defined $to) {
        open my $fh, '>', $to
            or die "Failed to open $to for writing: $!\n";
        print { $fh } $json_obj->encode($json);
        close $fh;
        say "Wrote JSON to $to";
    } else {
        print $json_obj->encode($json);
    }

    return 1;

}

sub help {

    my ($self) = @_;

    my $cmd = shift @{ $self->{ Args } };

    if (not defined $cmd) {
        pod2usage(
            -exitval => 'NOEXIT',
            -verbose => 99,
            -sections => [
                'NAME', 'SYNOPSIS', 'DESCRIPTION', 'COMMANDS',
                'GLOBAL OPTIONS', 'CONFIGURATION', 'ENVIRONMENT'
            ],
            -output  => \*STDOUT,
        );
        return 1;
    }

    $cmd = lc $cmd;

    if (not exists $COMMANDS{ $cmd }) {
        die "'$cmd' is not a command\n";
    }

    pod2usage(
        -exitval  => 'NOEXIT',
        -verbose  => 99,
        -sections => "COMMANDS/$cmd",
        -output   => \*STDOUT,
    );

    return 1;

}

sub init {

    my ($class, @argv) = @_;

    my $self = {
        Cmd           => undef,
        Args          => [],
        DataDir       => undef,
        FeedDir       => undef,
        EtagDir       => undef,
        FeedFile      => undef,
        ConfFile      => undef,
        Feeds         => {},
        Groups        => {},
        DefaultGroup  => undef,
        DB            => undef,
        AutoClean     => undef,
        TimeFmt       => undef,
        UseColor      => undef,
        ColorMap      => { %COLOR_CODES },
        RetryDir      => undef,
        # update
        NewOnly       => 0,
        NonDefaults   => 0,
        Forks         => undef,
        Unconditional => 0,
        RateLimit     => undef,
        UserAgent     => undef,
        Timeout       => undef,
        Proxy         => undef,
        ProxyUser     => undef,
        HardReload    => 0, # reload, too
        # read
        Pager         => undef,
        NoMark        => 0, # open, too
        Stdout        => 0,
        LineWidth     => undef,
        ReadFmt       => undef,
        ReadHtml      => 0,
        # open
        Browser       => undef,
        # look/unread
        Title         => undef,
        Tags          => [],
        Status        => undef, # look only
        Content       => [],
        Sort          => undef,
        Reverse       => 0,
        ListLimit     => undef,
        ShowHidden    => 0,
        ListFmt       => undef,
        ListUnreadFmt => undef,
        # mark
        MarkAll       => 0,
        # post
        PostFmt       => undef,
        # feeds
        Brief         => 0, # groups, too
        FeedsFmt      => undef,
        # export/import
        NoGroups      => 0,
        ExportSpec    => 0,
    };

    Getopt::Long::config('bundling');
    Getopt::Long::config('pass_through');
    GetOptionsFromArray(\@argv,
        'config|c=s'      => \$self->{ ConfFile },
        'data|D=s'        => \$self->{ DataDir },
        'feeds|f=s'       => \$self->{ FeedFile },
        'autoclean|A:s'   => sub {
            if ($_[1] eq '' or $_[1] eq '1') {
                $self->{ AutoClean } = 1;
            } elsif ($_[1] eq '0') {
                $self->{ AutoClean } = 0;
            } else {
                $self->{ AutoClean } = 1;
                unshift @argv, $_[1];
            }
        },
        'time-format|z=s' => \$self->{ TimeFmt },
        'color|C:s'       => sub {
            if ($_[1] eq '' or $_[1] eq '1') {
                $self->{ UseColor } = 1;
            } elsif ($_[1] eq '0') {
                $self->{ UseColor } = 0;
            } else {
                $self->{ UseColor } = 1;
                unshift @argv, $_[1];
            }
        },
        'no-color'        => sub { $self->{ UseColor } = 0 },
        # update
        'new-only'        => \$self->{ NewOnly },
        'non-defaults'    => \$self->{ NonDefaults },
        'downloads=i'     => \$self->{ Forks },
        'unconditional'   => \$self->{ Unconditional },
        'limit-rate=s'    => \$self->{ RateLimit },
        'user-agent=s'    => \$self->{ UserAgent },
        'timeout=f'       => \$self->{ Timeout },
        'proxy=s'         => \$self->{ Proxy },
        'proxy-user=s'    => \$self->{ ProxyUser },
        'hard'            => \$self->{ HardReload },
        # read
        'pager=s'         => \$self->{ Pager },
        'no-mark'         => \$self->{ NoMark }, # open, too
        'stdout'          => \$self->{ Stdout },
        'width=i'         => \$self->{ LineWidth },
        'read-format=s'   => \$self->{ ReadFmt },
        'html'            => \$self->{ ReadHtml },
        # open
        'browser=s'       => \$self->{ Browser },
        # look/unread
        'title=s'         => \$self->{ Title },
        'tag=s'           =>  $self->{ Tags },
        'status=s'        => \$self->{ Status }, # look only
        'content=s'       =>  $self->{ Content },
        'sort=s'          => \$self->{ Sort },
        'reverse'         => \$self->{ Reverse },
        'list-limit=i'    => \$self->{ ListLimit },
        'hidden'          => \$self->{ ShowHidden },
        'list-format=s'   => sub {
            $self->{ ListFmt } = $_[1];
            $self->{ ListUnreadFmt } = $_[1];
        },
        # mark
        'all'             => \$self->{ MarkAll },
        # post
        'post-format=s'   => \$self->{ PostFmt },
        # feeds
        'brief'           => \$self->{ Brief }, # groups, too
        'feeds-format=s'  => \$self->{ FeedsFmt },
        # export/import
        'no-groups'       => \$self->{ NoGroups },
        'export-special'  => \$self->{ ExportSpec },
        # misc
        'help|h'    => sub { _HELP(*STDOUT, 0) },
        'version|v' => sub { _VER(*STDOUT, 0)  },
        '<>' => sub {
            if (not defined $self->{ Cmd } and $_[0] !~ /^-/) {
                $self->{ Cmd } = $_[0];
            } else {
                if ($_[0] =~ /^-\d+$/) {
                    # So that negative post arguments (-1, -2, etc.) do not get
                    # treated like CLI flags.
                    push @{ $self->{ Args } }, $_[0];
                } elsif ($_[0] !~ /^-/) {
                    push @{ $self->{ Args } }, $_[0];
                } else {
                    warn "Unknown option: $_[0]\n";
                    _HELP(*STDERR, 1);
                }
            }
        },
    ) or _HELP(*STDERR, 1);

    bless $self, $class;

    if (not defined $self->{ Cmd }) {
        _HELP(*STDERR, 0);
    }

    unless (exists $COMMANDS{ $self->{ Cmd } }) {
        die "'$self->{ Cmd }' is not a valid command\n";
    }

    $self->{ ConfFile } //= _default_config;

    if ($self->{ Brief } and $self->{ Cmd } eq 'feeds') {
        $self->{ FeedsFmt } = '%f';
    }

    if (defined $self->{ ConfFile }) {
        $self->_read_config;
    }

    $self->{ DataDir } //= _default_data_dir;

    unless (-d $self->{ DataDir }) {
        mkdir $self->{ DataDir }
            or die "Failed to mkdir $self->{ DataDir }: $!\n";
    }

    $self->{ FeedDir } = File::Spec->catfile(
        $self->{ DataDir },
        'feeds'
    );

    unless (-d $self->{ FeedDir }) {
        mkdir $self->{ FeedDir }
            or die "Failed to mkdir $self->{ FeedDir }: $!\n";
    }

    $self->{ EtagDir } = File::Spec->catfile(
        $self->{ DataDir }, 'etag'
    );
    unless (-d $self->{ EtagDir }) {
        mkdir $self->{ EtagDir }
            or die "Failed to mkdir $self->{ EtagDir }: $!\n";
    }

    $self->{ RetryDir } = File::Spec->catfile(
        $self->{ DataDir }, 'retry'
    );
    if (not -d $self->{ RetryDir }) {
        unlink $self->{ RetryDir } if -f $self->{ RetryDir };
        mkdir $self->{ RetryDir }
            or die "Failed to mkdir $self->{ RetryDir }: $!\n";
    }

    unless (exists $DOESNT_NEED_FEED{ $self->{ Cmd } }) {
        $self->{ FeedFile } //= _default_feeds;
        unless (defined $self->{ FeedFile }) {
            die "$PRGNAM could not find a feeds file to read a feed list from\n";
        }
        unless (-f $self->{ FeedFile }) {
            die "$self->{ FeedFile } does not exist\n";
        }
        # For _get_url 'file://' links, to know the file's relative directory if
        # the url is not absolute.
        $self->{ FeedFile } = File::Spec->rel2abs($self->{ FeedFile });
        $self->_read_feed_file;
    }

    $self->{ Forks } //= $DEFAULT_FORKS;

    unless ($self->{ Forks } > 0) {
        die "Download count must be greater than 0\n";
    }

    $self->{ AutoClean } //= 0;
    $self->{ UserAgent } //= $DEFAULT_AGENT;
    $self->{ Pager }     //= $ENV{ PAGER }   // $DEFAULT_PAGER;
    $self->{ Browser }   //= $ENV{ BROWSER } // 'lynx';
    $self->{ ListLimit } //= 0;
    $self->{ LineWidth } //= $DEFAULT_WIDTH;
    $self->{ ReadFmt }   //= $DEFAULT_READ_FMT;
    $self->{ PostFmt }   //= $DEFAULT_POST_FMT;
    $self->{ FeedsFmt }  //= $DEFAULT_FEED_FMT;

    unless ($self->{ LineWidth } > 0) {
        die "width must be greater than 0\n";
    }

    if (defined $self->{ Status } and $self->{ Status } !~ /^(un)?read$/) {
        die "status must either be 'read' or 'unread'\n";
    }

    $self->{ Sort } //= 'date';

    unless (exists $VALID_SORTS{ $self->{ Sort } }) {
        die sprintf
            "--sort must be one of the following: %s\n",
            join(', ', sort keys %VALID_SORTS);
    }

    if (defined $self->{ RateLimit } and $self->{ RateLimit } !~ $RATE_RX) {
        die "Invalid argument to --limit-rate\n";
    }

    unless ($DOESNT_NEED_FEED{ $self->{ Cmd } }) {
        $self->{ DB } = WWW::Noss::DB->new(
            File::Spec->catfile($self->{ DataDir }, 'database.sqlite3')
        );
    }

    if (defined $self->{ TimeFmt }) {
        _set_z_fmt($self->{ TimeFmt });
    }

    if (not defined $self->{ UseColor }) {
        if (-t STDOUT) {
            $self->{ UseColor } = 1;
        } else {
            $self->{ UseColor } = 0;
        }
    }

    # Windows terminals do not support ANSI color codes.
    if ($^O eq 'MSWin32') {
        $self->{ UseColor } = 0;
    }

    if (not defined $self->{ Timeout }) {
        $self->{ Timeout } = 45;
    }

    return $self;

}

sub run {

    my ($self) = @_;

    $COMMANDS{ $self->{ Cmd } }->($self);

    if ($self->{ AutoClean } and not $DOESNT_NEED_FEED{ $self->{ Cmd } }) {
        $self->clean;
    }

    # Delete outdated retry caches
    my $now = time;
    for my $f (values %{ $self->{ Feeds } }) {
        my $retry = $f->retry;
        next if not defined $retry;
        if ($now >= $retry) {
            unlink $f->retry_cache
                or warn sprintf "Failed to unlink %s: %s\n", $f->retry_cache, $!;
        }
    }

    return 1;

}

1;

=head1 NAME

WWW::Noss - RSS/Atom feed reader and aggregator

=head1 USAGE

  use WWW::Noss;

  my $noss = WWW::Noss->init(@ARGV);
  $noss->run;

=head1 DESCRIPTION

B<WWW::Noss> is the backend module providing L<noss>'s functionality. This is
a private module, please consult the L<noss> manual for user documentation.

=head1 METHODS

=over 4

=item $noss = WWW::Noss->init(@argv)

Reads command-line arguments from C<@argv> and returns a blessed B<WWW::Noss>
object. You would usually pass C<@ARGV> to it.

Consult the L<noss> manual for documentation on what options/arguments are
available.

=item $noss->run()

Runs L<noss> based on the parameters processed during C<init()>.

=item $noss->update()

Method implementing the C<update> command.

=item $noss->reload()

Method implementing the C<reload> command.

=item $noss->read_post()

Method implementing the C<read> command.

=item $noss->open_post()

Method implementing the C<open> command.

=item $noss->cat()

Method implementing the C<cat> command.

=item $noss->look()

Method implementing the C<list> command.

=item $noss->unread()

Method implementing the C<unread> command.

=item $noss->mark()

Method implementing the C<mark> command.

=item $noss->post()

Method implementing the C<post> command.

=item $noss->feeds()

Method implementing the C<feeds> command.

=item $noss->groups()

Method implementing the C<groups> command.

=item $noss->clean()

Method implementing the C<clean> command.

=item $noss->discover()

Method implementing the C<discover> command.

=item $noss->export_opml()

Method implementing the C<export> command.

=item $noss->import_opml()

Method implementing the C<import> command.

=item $noss->help()

Method implementing the C<help> command.

=back

=head1 AUTHOR

Written by Samuel Young, E<lt>samyoung12788@gmail.comE<gt>.

This project's source can be found on its
L<Codeberg page|https://codeberg.org/1-1sam/noss.git>. Comments and pull
requests are welcome!

=head1 COPYRIGHT

Copyright (C) 2025-2026 Samuel Young

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

=head1 SEE ALSO

L<noss>

=cut

# vim: expandtab shiftwidth=4
