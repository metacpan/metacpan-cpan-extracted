use strict;
package inc;
our $VERSION = '0.06';

use 5.008001;

# use XXX;

my $perl_init;
my $perl_core;

sub new {
    my ($class, @spec) = @_;
    my $init = run_perl_eval($perl_init);
    my $self = bless {
        spec => \@spec,
        %$init,
    }, $class;
    return $self;
}

sub import {
    my ($class) = shift;
    return unless @_;
    my $self = $class->new(@_);
    @INC = $self->create_list;
    return;
}

sub list {
    my ($class) = shift;
    die "'inc->list()' requires at least one argument"
        unless @_;
    my $self = $class->new(@_);
    return $self->create_list;
}

sub create_list {
    my ($self) = shift;
    my $list = $self->{list} = [];
    $self->{inc} = [@INC];
    while (my $next = $self->parse_spec) {
        my ($name, @args) = @$next;
        if ($name =~ m!/!) {
            push @$list, $name;
        }
        else {
            my $method = "inc_$name";
            die "No 'inc' support found for '$name'"
                unless $self->can($method);
            push @$list, $self->$method(@args);
        }
    }
    return @$list;
}

sub parse_spec {
    my ($self) = @_;
    my $next = $self->get_next_spec or return;
    return [$next] if $next =~ m!/!;
    die "Invalid spec string '$next'"
      unless $next =~ /^(\-?)(\w+)(?:=(.*))?$/;
    my $name = $2;
    $name = "not_$name" if $1;
    my @args = $3 ? split /,/, $3 : ();
    return [$name, @args];
}

sub get_next_spec {
    my ($self) = @_;
    while (@{$self->{spec}}) {
        my $next = shift @{$self->{spec}};
        next unless length $next;
        if ($next =~ /:/) {
            # XXX This parse is flimsy:
            my @rest;
            ($next, @rest) = split /:/, $next;
            unshift @{$self->{spec}}, @rest;
            next unless $next;
        }
        return $next;
    }
    return;
}

sub lookup {
    my ($modpath, @inc) = @_;
    for (@inc) {
        my $path = "$_/$modpath";
        if (-e $path) {
            open my $fh, '<', $path
                or die "Can't open '$path' for input:\n$!";
            return $fh;
        }
    }
    return;
}

sub run_perl_eval {
    my ($perl, @argv) = @_;
    local $ENV{PERL5OPT};

    my $out = qx!$^X -e '$perl' @argv!;
    my $data = eval $out;
    die $@ if $@;
    return $data;
}

sub only_find {
    my ($self, $hash) = @_;
    return sub {
        my ($this, $modpath) = @_;
        (my $modname = $modpath) =~ s!/!::!g;
        $modname =~ s!\.pm$!!;
        return unless $hash->{$modname};
        return lookup($modpath, @{$self->{INC}});
    }
}

sub regex_find {
    my ($self, $regex) = @_;
    return sub {
        my ($this, $modpath) = @_;
        (my $modname = $modpath) =~ s!/!::!g;
        $modname =~ s!\.pm$!!;
        return unless $modname =~ $regex;
        return lookup($modpath, @{$self->{INC}});
    }
}

#------------------------------------------------------------------------------
# Smart Objects
#------------------------------------------------------------------------------
sub inc_blib {
    return 'blib/lib', 'blib/arch';
}

sub inc_cache {
    my ($self) = @_;
    die "inc 'cache' object not yet implemented";
    return ();
}

sub inc_core {
    my ($self, $version) = @_;
    $version ||= $Config::Config{version};
    my $hash = $self->{"corelists/$version"} ||=
        run_perl_eval $perl_core, $version;
    $self->only_find($hash);
}

sub inc_cwd {
    my ($self) = @_;
    return (
        $self->{cwd},
    );
}

sub inc_deps {
    my ($self, @module) = @_;
    die "inc 'deps' object not yet implemented";
}

sub inc_dot {
    my ($self) = @_;
    return (
        $self->{curdir},
    );
}

my $hash_dzil;
sub inc_dzil {
    my ($self) = @_;
    local $ENV{PERL5OPT};
    $hash_dzil ||= +{ map { chomp; ($_, 1) } `dzil listdeps` };
    $self->only_find($hash_dzil);
}

sub inc_inc {
    my ($self) = @_;
    return @{$self->{inc}};
}

sub inc_INC {
    my ($self) = @_;
    return @{$self->{INC}};
}

sub inc_LC {
    my ($self) = @_;
    $self->inc_core('5.8.1');
}

sub inc_lib {
    return run_perl_eval <<'...';
use Cwd;
print q{"} . Cwd::abs_path(q{lib}) . q{"};
...
}

sub inc_meta {
    my ($self) = @_;
    die "inc 'meta' object not yet implemented";
}

sub inc_none {
    return ();
}

sub inc_not {
    my ($self, @args) = @_;
    die "inc 'not' object requires one regex"
        unless @args == 1;
    my $regex = qr/$args[0]/;
    $self->{list} = [grep {ref or not($regex)} @{$self->{list}}];
    return ();
}

sub inc_ok {
    my ($self, @args) = @_;
    die "inc 'ok' object requires one regex"
        unless @args == 1;
    my $regex = qr/$args[0]/;
    $self->regex_find($regex);
}

sub inc_perl5lib {
    return () unless defined $ENV{PERL5LIB};
    return split /:/, $ENV{PERL5LIB};
}

sub inc_priv {
    my ($self) = @_;
    return (
        $self->{archlib},
        $self->{privlib},
    );
}

sub inc_not_priv {
    my ($self) = @_;
    $self->{list} = [grep {
        ref or not(
            $_ eq $self->{archlib} or
            $_ eq $self->{priv}
        )
    } @{$self->{list}}];
    return ();
}

sub inc_site {
    my ($self) = @_;
    return (
        $self->{sitearch},
        $self->{sitelib},
    );
}

sub inc_not_site {
    my ($self) = @_;
    $self->{list} = [grep {
        ref or not(
            $_ eq $self->{sitearch} or
            $_ eq $self->{sitelib}
        )
    } @{$self->{list}}];
    return ();
}

sub inc_show {
    my ($self) = @_;
    for (@{$self->{list}}) {
        print "$_\n";
    }
    return ();
}

sub inc_zild {
    my ($self) = @_;
    die "inc 'zild' object not yet implemented";
}

#------------------------------------------------------------------------------
# Perl scripts to run externally, so as not to load unintended modules into the
# main process:
#------------------------------------------------------------------------------
$perl_init = <<'...';
use Data::Dumper();
use Cwd();
use Config();
use File::Spec;
$Data::Dumper::Terse = 1;
print Data::Dumper::Dumper +{
    INC => \@INC,
    archlib => $Config::Config{archlib},
    privlib => $Config::Config{privlib},
    sitearch => $Config::Config{sitearch},
    sitelib => $Config::Config{sitelib},
    curdir => File::Spec->curdir,
    cwd => Cwd::cwd,
};
...

$perl_core = <<'...';
use Module::CoreList();
use version();
use Data::Dumper();

my $version = shift @ARGV;
$version = version->parse($version)->numify;
$Data::Dumper::Terse = 1;
print Data::Dumper::Dumper $Module::CoreList::version{$version};
...

1;
