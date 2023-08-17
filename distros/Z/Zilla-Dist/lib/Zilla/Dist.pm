use strict; use warnings;
package Zilla::Dist;
our $VERSION = '0.1.18';

use version;
use File::Share;
use Hash::Merge 'merge';
use IO::All;
use YAML::PP;

Hash::Merge::set_behavior('RIGHT_PRECEDENT');

sub new {
    my $class = shift;
    bless {@_}, $class;
}

sub run {
    my ($self, @args) = @_;
    @args = ('help') unless @args;
    @args = ('version') if "@args" =~ /^(-v|--version)$/;
    my $cmd = lc(shift @args);
    if ($cmd =~ /^(?:
        test|install|release|update|prereqs|clean|
        dist|distdir|distshell|disttest|
        cpan|cpanshell
    )$/x) {
        unshift @args, $cmd;
        $cmd = 'make';
    }
    my $method = "do_$cmd";
    $self->usage, return unless $self->can($method);
    $self->{meta} = $self->get_meta;
    $self->$method(@args);
}

sub get_meta {
    my ($self) = @_;
    my $meta = -f 'Meta'
      ? eval { YAML::PP::LoadFile('Meta') } || {}
      : {};
    if (my $base_file = delete($meta->{base})) {
        my $base = YAML::PP::LoadFile($base_file);
        $meta = merge($base, $meta);
    }
    return $meta;
}

sub do_make {
    my ($self, @args) = @_;
    my @cmd = ('make', '-f', $self->find_sharefile('Makefile'), @args);
    system(@cmd) == 0
        or die "'@cmd' failed: $!\n";
}

sub do_makefile {
    my ($self, @args) = @_;
    print $self->find_sharefile('Makefile'), "\n";
}

sub do_copy {
    my ($self, $file, $target) = @_;
    $target ||= $file;

    my $file_content = io->file($self->find_sharefile($file))->all;
    io->file($target)->print($file_content);

    print "Zilla::Dist copied shared '$file' to '$target'\n";
}

sub do_version {
    my ($self, @args) = @_;
    print "$VERSION\n";
}

sub update_makefile {
    my ($self, $makefile_path) = @_;
    my $makefile_content = io->file($self->find_sharefile('Makefile'))->all;
    io->file($makefile_path)->print($makefile_content);
}

sub do_sharedir {
    my ($self, @args) = @_;
    print $self->find_sharedir . "\n";
}

my $default = {
    branch => 'master',
};
sub do_meta {
    my ($self, $key) = @_;
    my $keys = [ split '/', $key ];
    my $meta = $self->{meta};
    my $value = $meta;
    for my $k (@$keys) {
        return unless ref($value) eq 'HASH';
        $value = $value->{$k} || $default->{$k};
        last unless defined $value;
    }
    if (defined $value) {
        if (not ref $value) {
            print "$value\n";
        }
        elsif (ref($value) eq 'ARRAY') {
            print "$_\n" for @$value;
        }
        elsif (ref($value) eq 'HASH') {
            for my $kk (sort keys %$value) {
                print "$kk\n" unless $kk =~ /^(?:perl)$/;
            }
        }
        else {
            print "$value\n";
        }
    }
}

sub do_changes {
    my ($self, $key, $value) = @_;
    return if $self->{meta}{'=zild'}{no_changes_yaml};
    my @changes = YAML::PP::LoadFile('Changes');
    $self->validate_changes(\@changes);
    return unless @changes;
    if ($value) {
        chomp $value;
        die unless length $value;
        my $text = io->file('Changes')->all or die;
        my $line = sprintf "%-8s %s", "$key:", $value;
        $text =~ s/^$key:.*/$line/m or die;
        io->file('Changes')->print($text);
    }
    else {
        $value = $changes[0]{$key} or return;
        print "$value\n";
    }
}

sub error {
    die "Error: $_[0]\n";
}

sub validate_changes {
    my ($self, $changes) = @_;
    return if $self->{meta}{'=zild'}{no_changes_yaml};

    scalar(@$changes) or error "Changes file is empty";

    for (my $i = 1; $i <= @$changes; $i++) {
        my $entry = $changes->[$i - 1];
        ref($entry) eq 'HASH'
            or error "Changes entry #$i is not a hash";
        my @keys = keys %$entry;
        @keys == 3
            or error "Changes entry #$i doesn't have 3 keys";
        for my $key (qw(version date changes)) {
            error "Changes entry #$i is missing field '$key'"
                unless exists $entry->{$key};
            error "Changes entry #$i has undefined field '$key'"
                unless defined $entry->{$key} or $key eq 'date';
            if (defined $entry->{$key}) {
                if ($key eq 'changes') {
                    error "Changes entry #$i field '$key' should be an array"
                        unless ref($entry->{$key}) eq 'ARRAY';
                    my $change_list = $entry->{changes};
                    for my $change_entry (@$change_list) {
                        error "Changes entry #$i has non-scalar 'changes' entry"
                            if ref $change_entry;
                    }
                }
                else {
                    error "Changes entry #$i field '$key' should be a scalar"
                        if ref($entry->{$key});
                }
            }
        }
    }
    if (@$changes >= 2) {
        my $changes1 = join '%^&*', @{$changes->[0]{changes}};
        my $changes2 = join '%^&*', @{$changes->[1]{changes}};
        error "2 most recent Changes messages cannot be the same!"
            if $changes1 eq $changes2;
        my $v0 = $changes->[0]{version};
        my $v1 = $changes->[1]{version};
        error "latest Changes version ($v0) is not greater than previous ($v1)"
            unless version->parse($v0) > version->parse($v1);
    }
}

sub find_sharefile {
    my ($self, $file) = @_;
    my $path = $self->find_sharedir . '/' . $file;
    -e $path or die "Can't find shared Zilla::Dist file '$file'";
    return $path;
}

sub find_sharedir {
    my ($self) = @_;
    my $sharedir = File::Share::dist_dir('Zilla-Dist');
    -d $sharedir or die "Can't find Zilla::Dist share dir";
    return $sharedir;
}

sub do_webhooks {
    my ($self) = @_;
    return unless $ENV{PERL_ZILLA_DIST_GIT_HUB_WEBHOOKS};
    return unless -d '.git';
    my $path = '.git/zilla-dist/webhooks';
    my $travis = io->file("$path/travis");
    my $irc = io->file("$path/irc");
    for my $hook (qw(travis irc)) {
        my $file = io->file("$path/$hook");
        if ($file->exists) {
            my $hook_version = $file->chomp->getline;
            my $api_version = '0.0.95';
            next if
                version->parse($hook_version) >=
                version->parse($api_version);
        }
        my $method = "webhook_command_$hook";
        my $command = $self->$method or next;
        print "Running: '$command'\n";
        system($command) == 0
            or die "Error: command failed '$command': $!";
        io->file("$path/$hook")->assert->print($VERSION);
    }
}

sub webhook_command_travis {
    my ($self) = @_;
    return "git hub travis-enable";
}

sub webhook_command_irc {
    my ($self) = @_;
    my $irc;
    return unless $irc = $self->{meta}{devel}{irc};
    return unless $irc =~ /^(\w\S*)#(\w\S*)$/;
    return "git hub irc-enable $2 $1";
}

sub do_years {
    my ($self, $key, $value) = @_;
    my %hash = eval {
        map {($_ => 1)} grep {$_} map {
            $_->{date} =~ /(\d{4})/;
            $1;
        } (YAML::PP::LoadFile('Changes'));
    };
    return if $@;
    print join(' ', sort keys %hash) . "\n";
}

sub usage {
    print <<'...';

Usage:

    zild make <rule>    # Run `make <rule>` with Zilla::Dist Makefile
    zild meta <key>     # Print Meta value for a key
    zild copy <file> <dest>  # Copy a shared file
    zild version        # Print Zilla::Dist version

The following commands are aliases for `zild make <cmd>`

    zild test           zild dist           zild cpan
    zild install        zild distdir        zild cpanshell
    zild release        zild distshell
    zild update         zild disttest
    zild clean

Internal commands issued by the Makefile:

    zild sharedir       # Print the location of the Zilla::Dist share dir
    zild makefile       # Print the location of the Zilla::Dist 'Makefile'
    zild changes <key> [<value>]

...
}

1;
