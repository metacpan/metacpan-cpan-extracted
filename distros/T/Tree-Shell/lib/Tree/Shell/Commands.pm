package Tree::Shell::Commands;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-02-13'; # DATE
our $DIST = 'Tree-Shell'; # DIST
our $VERSION = '0.001'; # VERSION

use 5.010001;
use strict;
use warnings;
use Log::ger;

use Path::Naive qw();

our %SPEC;

$SPEC{':package'} = {
    v => 1.1,
    summary => 'treesh commands',
};

our $complete_path = sub {
    my %args = @_;
    my $shell = $args{-shell};

    my $word0 = $args{word};
    my ($dir, $word) = $word0 =~ m!(.*/)?(.*)!;
    $dir //= "";

    my $obj = $shell->state('objects')->{ $args{object} // $shell->state('curobj') // '' };
    return {message=>"No current object, please load some objects first"} unless $obj;

    my $cwd = $obj->{fs}->cwd;
    my @entries = $obj->{fs}->ls(
        length($dir) ? Path::Naive::concat_and_normalize_path($cwd, $dir)."/*" : undef);

    [map {(length($dir) ? $dir : "") . "$_->{name}/"} @entries];
};

my $complete_setting_name = sub {
    my %args = @_;
    my $shell = $args{-shell};

    [keys %{ $shell->known_settings }];
};

our $complete_object_name = sub {
    my %args = @_;
    my $shell = $args{-shell};

    [keys %{ $shell->state('objects') }];
};

my %arg0_object = (
    object => {
        schema => ['str*', match=>qr/\A\w+\z/],
        completion => $complete_object_name,
        req => 1,
        pos => 0,
    },
);

my %argopt_object = (
    object => {
        schema => ['str*', match=>qr/\A\w+\z/],
        cmdline_aliases => {o=>{}},
        completion => $complete_object_name,
    },
);

my %arg0_path = (
    path => {
        summary    => 'Path',
        schema     => ['str*'],
        req        => 1,
        pos        => 0,
        completion => $complete_path,
    },
);

my %arg0_paths = (
    paths => {
        summary    => 'Paths',
        schema     => ['array*', of=>'str*'],
        req        => 1,
        pos        => 0,
        slurpy     => 1,
        element_completion => $complete_path,
    },
);

my %argopt0_path = (
    path => {
        summary    => 'Path to node',
        schema     => ['str*'],
        pos        => 0,
        completion => $complete_path,
    },
);

my @drivers = qw(json yaml org);

$SPEC{loadobj} = {
    v => 1.1,
    summary => 'Load tree object',
    description => <<'_',

_
    args => {
        as => {
            schema => ['str*', {match => qr/\A\w+\z/}],
            pos => 0,
            req => 1,
        },
        driver => {
            schema => ['str*', {in=>\@drivers}],
            pos => 1,
            req => 1,
        },
        source => {
            schema => ['pathname*'],
            pos => 2,
            req => 1,
            completion => sub {
                require Complete::File;
                Complete::File::complete_file(@_);
            },
        },
        opts => {
            'x.name.is_plural' => 1,
            'x.name.singular' => 'opt',
            schema => ['hash*', {of=>'str*'}],
        },
    },
};
sub loadobj {
    require File::Slurper::Dash;

    my %args = @_;
    my $as     = $args{as};
    my $driver = $args{driver};
    my $source = $args{source};
    my $shell  = $args{-shell};

    if ($shell->state('objects')->{$as}) {
        return [412, "Object with named '$as' already loaded, perhaps choose another name?"];
    }

    my $fs;
    if ($driver eq 'json') {
        return [501, "Not implemented"];
        #require Data::CSel::WrapStruct;
        #require JSON::MaybeXS;
        #my $json = JSON::MaybeXS->new(allow_nonref=>1, canonical=>1);
        #my $data = $json->decode(File::Slurper::Dash::read_text($source));
        #$tree = Data::CSel::WrapStruct::wrap_struct($data);
    } elsif ($driver eq 'yaml') {
        return [501, "Not implemented"];
        #require Data::CSel::WrapStruct;
        #require YAML::XS;
        #my $data = YAML::XS::Load(File::Slurper::Dash::read_text($source));
        #my $tree = Data::CSel::WrapStruct::wrap_struct($data);
    } elsif ($driver eq 'org') {
        require Tree::FSMethods::Org;
        eval { $fs = Tree::FSMethods::Org->new(org_file => $source) };
        return [500, "Can't load org file: $@"] if $@;
    } else {
        return [500, "Unknown driver '$driver', known drivers: ".join(", ", @drivers)];
    }

    $shell->state('objects')->{$as} = {
        driver => $driver,
        source => $source,
        fs     => $fs,
    };
    $shell->state('curobj', $as) unless defined $shell->state('curobj');
    return [200, "OK"];
}

$SPEC{objects} = {
    v => 1.1,
    summary => 'List loaded objects',
    description => <<'_',

_
    args => {
    },
};
sub objects {
    my %args = @_;
    my $shell  = $args{-shell};

    my $objects = $shell->state('objects');
    my $curobj  = $shell->state('curobj') // '';
    my @rows;
    for my $name (sort keys %$objects) {
        push @rows, {
            name => $name,
            driver => $objects->{$name}{driver},
            source => $objects->{$name}{source},
            active => $name eq $curobj ? 1:0,
            cwd    => $objects->{$name}{fs}->cwd,
        };
    }
    [200, "OK", \@rows, {'table.fields'=>[qw/name driver source active cwd/]}];
}

$SPEC{setcurobj} = {
    v => 1.1,
    summary => 'Set current object',
    args => {
        %arg0_object,
    },
};
sub setcurobj {
    my %args = @_;
    my $shell  = $args{-shell};

    my $objects = $shell->state('objects');
    $objects->{ $args{object} }
        or return [404, "No such object '$args{object}'"];
    $shell->state('curobj', $args{object});
    [200];
}

$SPEC{cat} = {
    v => 1.1,
    summary => 'Print node as string',
    args => {
        %argopt_object,
        %arg0_path,
    },
};
sub cat {
    my %args = @_;
    my $shell  = $args{-shell};

    my $obj = $shell->state('objects')->{ $args{object} // $shell->state('curobj') // '' };
    unless ($obj) {
        return [412, "No such object '$args{object}'"] if defined $args{object};
        return [412, "No loaded objects, load some first using 'loadobj'"];
    }

    my $node;
    eval {
        $node = $obj->{fs}->get($args{path});
    };
    return [500, "Can't cat: $@"] if $@;

    [200, "OK", $node->as_string];
}

$SPEC{dumpobj} = {
    v => 1.1,
    summary => 'Dump a loaded object',
    description => <<'_',

_
    args => {
        name => {
            schema => ['str*'],
            pos => 0,
            completion => $complete_object_name,
        },
    },
};
sub dumpobj {
    my %args = @_;
    my $name   = $args{name};
    my $shell  = $args{-shell};

    $name //= $shell->state('curobj');
    return [412, "Please load an object first"] unless defined $name;

    my $objects = $shell->state('objects');
    return [404, "No object by that name"] unless $objects->{$name};

    require Tree::Dump;
    [200, "OK", Tree::Dump::tdmp($objects->{$name}{fs}{tree}),
     {'cmdline.skip_format'=>1}];
}

$SPEC{ls} = {
    v => 1.1,
    summary => 'List children nodes',
    args => {
        %argopt_object,
        long => {
            summary => 'Long mode (detail=1)',
            schema => ['true*'],
            cmdline_aliases => { l => {} },
        },
        path => {
            summary    => 'Path to node',
            schema     => ['str'],
            pos        => 0,
            completion => $complete_path,
        },
        all => {
            summary     => 'Does nothing, added only to let you type ls -la',
            schema      => ['bool'],
            description => <<'_',

Some of you might type `ls -la` or `ls -al` by muscle memory. So the -a option
is added just to allow this to not produce an error :-).

_
            cmdline_aliases => { a=>{} },
        },
    },
};
sub ls {
    my %args = @_;
    my $shell = $args{-shell};

    my $resmeta = {};

    my $obj = $shell->state('objects')->{ $args{object} // $shell->state('curobj') // '' };
    unless ($obj) {
        return [412, "No such object '$args{object}'"] if defined $args{object};
        return [412, "No loaded objects, load some first using 'loadobj'"];
    }

    my @rows;
    my @entries;
    eval { @entries = $obj->{fs}->ls($args{path}) };
    return [500, "Can't ls: $@"] if $@;

    for my $entry (@entries) {
        if ($args{long}) {
            push @rows, {
                order => $entry->{order},
                name  => $entry->{name},
            };
        } else {
            push @rows, $entry->{name};
        }
    }

    $resmeta->{'table.fields'} = [qw/order name/] if $args{long};
    [200, "OK", \@rows, $resmeta];
}

$SPEC{pwd} = {
    v => 1.1,
    summary => 'Show current directory of object',
    args => {
        %argopt_object,
    },
};
sub pwd {
    my %args = @_;
    my $shell = $args{-shell};

    my $objname = $args{object} // $shell->state('curobj') // '';
    my $obj = $shell->state('objects')->{ $objname };
    unless ($obj) {
        return [412, "No such object '$args{object}'"] if defined $args{object};
        return [412, "No loaded objects, load some first using 'loadobj'"];
    }

    return [200, "OK", "$obj->{fs}{_curpath} ($objname)"];
}

$SPEC{cd} = {
    v => 1.1,
    summary => "Change directory",
    args => {
        %argopt_object,
        path => {
            summary    => '',
            schema     => ['str*'],
            pos        => 0,
            completion => $complete_path,
        },
    },
};
sub cd {
    my %args = @_;
    my $path = $args{path};
    my $shell = $args{-shell};

    my $obj = $shell->state('objects')->{ $args{object} // $shell->state('curobj') // '' };
    unless ($obj) {
        return [412, "No such object '$args{object}'"] if defined $args{object};
        return [412, "No loaded objects, load some first using 'loadobj'"];
    }

    my $cwd = $obj->{fs}->cwd;
    if ($path eq '-') {
        if (defined $obj->{oldcwd}) {
            $path = $obj->{oldcwd};
        } else {
            return [412, "Old directory not set yet, cd to some directory first"];
        }
    }

    eval { $obj->{fs}->cd($path) };
    if ($@) {
        return [500, "Can't cd: $@"];
    } else {
        $obj->{oldcwd} = $cwd;
        return [200, "OK"];
    }
}

$SPEC{tree} = {
    v => 1.1,
    summary => 'Show filesystem tree',
    args => {
        %argopt_object,
        %argopt0_path,
    },
};
sub tree {
    my %args = @_;
    my $shell = $args{-shell};

    my $resmeta = {};

    my $obj = $shell->state('objects')->{ $args{object} // $shell->state('curobj') // '' };
    unless ($obj) {
        return [412, "No such object '$args{object}'"] if defined $args{object};
        return [412, "No loaded objects, load some first using 'loadobj'"];
    }

    [200, "OK", $obj->{fs}->showtree($args{path})];
}

our %args_cp_or_mv = (
    src_path => {
        summary => 'Source path',
        schema => 'str*',
        completion => sub {
            my %args = @_;
            my $shell = $args{-shell};
            my $obj = $shell->state('objects')->{ $shell->state('curobj') // '' };
            return [] unless $obj;
            my $res = $complete_path->(%args);
            $res;
        },
        req => 1,
        pos => 0,
    },
    target_object => {
        summary => 'Target object name',
        schema => ['str*', match=>qr/\A\w+\z/],
        completion => $complete_object_name,
    },
    target_path => {
        summary => 'Target path',
        schema => 'str*',
        completion => sub {
            my %args = @_;
            my $shell = $args{-shell};
            my $target_object = $args{args}{target_object};
            my $obj = $shell->state('objects')->{ $target_object // $shell->state('curobj') // '' };
            return [] unless $obj;
            my $save_curobj = $shell->state('curobj');
            $shell->state('curobj', $target_object) if defined $target_object;
            my $res = $complete_path->(%args);
            $shell->state('curobj', $save_curobj);
            $res;
        },
        req => 1,
        pos => 1,
    },
);

sub _cp_or_mv {
    my $which = shift;

    my %args = @_;
    my $shell = $args{-shell};

    my $src_obj = $shell->state('objects')->{ $shell->state('curobj') // '' }
        or return [412, "No object loaded, please load an object first"];
    my $target_obj = $shell->state('objects')->{ $args{target_object} // $shell->state('curobj') // '' }
        or return [412, "No such target object '$args{target_object}'"];

    eval {
        local $src_obj->{fs}{tree2} = $target_obj->{fs}{tree};
        local $src_obj->{fs}{_curnode2} = $target_obj->{fs}{_curnode};
        local $src_obj->{fs}{_curpath2} = $target_obj->{fs}{_curpath};

        $src_obj->{fs}->$which($args{src_path}, $args{target_path});
    };
    return [500, "Can't $which: $@"] if $@;
    [200];
}

$SPEC{cp} = {
    v => 1.1,
    summary => 'Copy nodes from one object to another',
    args => {
        %args_cp_or_mv,
    },
};
sub cp {
    _cp_or_mv('cp', @_);
}

$SPEC{mv} = {
    v => 1.1,
    summary => 'Move nodes from one object to another',
    args => {
        %args_cp_or_mv,
    },
};
sub mv {
    _cp_or_mv('mv', @_);
}

$SPEC{rm} = {
    v => 1.1,
    summary => 'Remove nodes',
    args => {
        %arg0_path,
        %argopt_object,
    },
};
sub rm {
    my %args = @_;
    my $shell = $args{-shell};

    my $resmeta = {};

    my $obj = $shell->state('objects')->{ $args{object} // $shell->state('curobj') // '' };
    unless ($obj) {
        return [412, "No such object '$args{object}'"] if defined $args{object};
        return [412, "No loaded objects, load some first using 'loadobj'"];
    }

    eval {
        $obj->{fs}->rm($args{path});
    };
    return [500, "Can't rm: $@"] if $@;

    [200];
}

$SPEC{mkdir} = {
    v => 1.1,
    summary => 'Create an empty directory',
    args => {
        %arg0_paths,
        %argopt_object,
        parents => {
            schema => 'true*',
            cmdline_aliases => {p=>{}},
        },
    },
};
sub mkdir {
    my %args = @_;
    my $shell = $args{-shell};

    my $resmeta = {};

    my $obj = $shell->state('objects')->{ $args{object} // $shell->state('curobj') // '' };
    unless ($obj) {
        return [412, "No such object '$args{object}'"] if defined $args{object};
        return [412, "No loaded objects, load some first using 'loadobj'"];
    }

    my %opts;
    $opts{parents} = 1 if $args{parents};

    my $has_error;
    for my $path (@{ $args{paths} }) {
        eval { $obj->{fs}->mkdir(\%opts, $path) };
        if ($@) {
            warn "Can't mkdir $path: $@\n";
            $has_error++;
        }
    }

    [200];
}

$SPEC{set} = {
    v => 1.1,
    summary => "List or set setting",
    args => {
        name => {
            summary    => '',
            schema     => ['str*'],
            pos        => 0,
            # we use custom completion because the list of known settings must
            # be retrieved through the shell object
            completion => $complete_setting_name,
        },
        value => {
            summary    => '',
            schema     => ['any'],
            pos        => 1,
            completion => sub {
                require Perinci::Sub::Complete;

                my %args = @_;
                my $shell = $args{-shell};
                my $args  = $args{args};
                return [] unless $args->{name};
                my $setting = $shell->known_settings->{ $args->{name} };
                return [] unless $setting;

                # a hack, construct a throwaway meta and using that to complete
                # setting argument as function argument
                Perinci::Sub::Complete::complete_arg_val(
                    arg=>'foo',
                    meta=>{v=>1.1, args=>{foo=>{schema=>$setting->{schema}}}},
                );
            },
        },
    },
};
sub set {
    my %args = @_;
    my $shell = $args{-shell};

    my $name  = $args{name};

    if (exists $args{value}) {
        # set setting
        return [400, "Unknown setting, use 'set' to list all known settings"]
            unless exists $shell->known_settings->{$name};
        $shell->setting($name, $args{value});
        [200, "OK"];
    } else {
        # list settings
        my $res = [];
        if (defined $name) {
            return [400,"Unknown setting, use 'set' to list all known settings"]
                unless exists $shell->known_settings->{$name};
        }
        for (sort keys %{ $shell->known_settings }) {
            next if defined($name) && $_ ne $name;
            push @$res, {
                name => $_,
                summary => $shell->known_settings->{$_}{summary},
                value   => $shell->{_settings}{$_},
                default => $shell->known_settings->{$_}{schema}[1]{default},
            };
        }
        [200, "OK", $res, {'table.fields' => [qw/name summary value default/]}];
    }
}

$SPEC{unset} = {
    v => 1.1,
    summary => "Unset a setting",
    args => {
        name => {
            summary    => '',
            schema     => ['str*'],
            req        => 1,
            pos        => 0,
            completion => $complete_setting_name,
        },
    },
};
sub unset {
    my %args = @_;
    my $shell = $args{-shell};

    my $name = $args{name};

    return [400, "Unknown setting, use 'set' to list all known settings"]
        unless exists $shell->known_settings->{$name};
    delete $shell->{_settings}{$name};
    [200, "OK"];
}

$SPEC{history} = {
    v => 1.1,
    summary => 'Show command-line history',
    args => {
        append => {
            summary    => "Append current session's history to history file",
            schema     => 'bool',
            cmdline_aliases => { a=>{} },
        },
        read => {
            summary    => '(Re-)read history from file',
            schema     => 'bool',
            cmdline_aliases => { r=>{} },
        },
        clear => {
            summary    => 'Clear history',
            schema     => 'bool',
            cmdline_aliases => { c=>{} },
        },
    },
};
sub history {
    my %args = @_;
    my $shell = $args{-shell};

    if ($args{add}) {
        $shell->save_history;
        return [200, "OK"];
    } elsif ($args{read}) {
        $shell->load_history;
        return [200, "OK"];
    } elsif ($args{clear}) {
        $shell->clear_history;
        return [200, "OK"];
    } else {
        my @history;
        if ($shell->{term}->Features->{getHistory}) {
            @history = grep { length } $shell->{term}->GetHistory;
        }
        return [200, "OK", \@history,
                {"x.app.riap.default_format"=>"text-simple"}];
    }
}

1;
# ABSTRACT: treesh commands

__END__

=pod

=encoding UTF-8

=head1 NAME

Tree::Shell::Commands - treesh commands

=head1 VERSION

version 0.001

=for Pod::Coverage .+

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
