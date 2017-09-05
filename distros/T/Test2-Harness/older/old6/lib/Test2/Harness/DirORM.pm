package Test2::Harness::DirORM;
use strict;
use warnings;

use File::Spec;
use Test2::Harness::Util::ActiveFile;

use Test2::Harness::DirORM::File;

use Carp qw/croak cluck/;
use Test2::Util qw/pkg_to_file/;
use Test2::Harness::Util::JSON qw/encode_json decode_json/;
use Test2::Harness::Util qw/read_file write_file_atomic open_file/;

use Importer;

our @EXPORT = qw/dorm path/;

my %META;

sub import {
    my $class = shift;
    my ($dir_attr, @imports) = @_;
    my $caller = caller;

    croak "$class\->import requires the directory attribute name as the first argument"
        unless $dir_attr;

    $META{$class} = $dir_attr;

    Importer->import_into($class, $caller, @imports);
}

sub path {
    my $self     = shift;
    my $dir_attr = $META{scalar caller()};
    return $self->$dir_attr unless @_;
    return File::Spec->catfile($self->$dir_attr, @_);
}

sub dorm {
    my ($name, %args) = @_;
    my $caller   = caller;
    my $dir_attr = $META{$caller};

    my $trans  = delete($args{transform});
    my $type   = delete($args{type});
    my $file   = delete($args{file}) || $type ? join('.', $name, $type) : $name;
    my $fclass = delete($args{file_class}) || $type ? join('::', 'Test2::Harness::DirORM::File', lc($type)) : 'Test2::Harness::DirORM::File';

    my $fclass_file = pkg_to_file($fclass);
    require $fclass_file;

    my %subs;

    $subs{$name} = sub {
        my $self = shift;
        $self->{$name} ||= $fclass->new(
            file => File::Spec->catfile($self->$dir_attr, $file),
            transform => $trans,
        );
    };

    if (delete $args{is_self}) {
        $subs{load} = sub {
            my $class = shift;
            my ($dir, %params) = @_;

            my $path = File::Spec->catfile($dir, $file);
            my $f = $fclass->new(file => $path);

            my $data = $f->read;

            return bless({%$data, %params, $dir_attr => $dir}, $class);
        };

        $subs{save} = sub {
            my $self = shift;
            $self->$name->write({map {($_ => $self->{$_})} grep {!m/^_/} keys %$self});
        };
    }

    croak "Unrecognised arguments: " . join(', ', sort keys %args)
        if keys %args;

    no strict 'refs';
    *{"$caller\::$_"} = $subs{$_} for sort keys %subs;
}

1;

__END__

sub parse_filename {
    my $class = shift;
    my ($file) = @_;
    my ($name, $ext) = ($file =~ m/^(.*)(\..+)?$/);
    return ($name, $ext || '');
}

sub import {
    my $class = shift;
    my ($dir_attr, %params) = @_;
    my $caller = caller;

    my $serialize = delete $params{serialize};
    my $files     = delete $params{files} || [];
    my $map       = delete $params{map} || {};
    my $transform = delete $params{transform} || {};

    croak "Unrecognised arguments: " . join(', ', sort keys %params)
        if keys %params;

    if ($serialize) {
        croak "'serialize' must be a .json file" unless $serialize =~ m/\.json$/;
        push @$files => $serialize;
    }

    my %subs;

    $subs{$dir_attr} = sub { $_[0]->{$dir_attr} }
        unless $caller->can($dir_attr);

    $subs{new} = sub { my $class = shift; bless {@_}, $class }
        unless $caller->can('new');

    $subs{path} = sub {
        my $self = shift;
        return $self->$dir_attr unless @_;
        return File::Spec->catfile($self->$dir_attr, @_);
    };

    for my $trans_file (sort keys %$transform) {
        croak "'$trans_file' is not a .json file, transform files must be .json files" unless $map_file =~ m/\.json$/;
        
    }

    for my $map_file (sort keys %$map) {
        my $spec = $map->{$map_file};

        my ($name, $ext) = $class->parse_filename($map_file);
        my $attr = "${name}_file";
        my $get_line = "${name}_read_line";
        my $get_all = "${name}_read";

        croak "'$map_file' is not a .jsonl file, map files must be .jsonl files" unless $map_file =~ m/\.jsonl$/;

        my $next  = delete $spec->{next};
        my $first = delete $spec->{first};
        my $all   = delete $spec->{all};
        my $trans = delete $spec->{transform};

        croak "Unrecognised arguments for map file '$map_file': " . join(', ', sort keys %$spec)
            if keys %$spec;

        cluck "Neither 'next' nor 'all' were specified for map file '$map_file'"
            unless $next || $all;

        croak "'first' specified without 'next' for map file '$map_file'"
            if $first && !$next;

        push @$files => $map_file;

        if ($next) {
            $subs{$next} = sub {
                my $self = shift;
                my $line = $self->$get_line(@_);
                return undef unless defined $line;
                return $line unless $trans;
                return $self->$trans($line);
            };
        }

        if ($first) {
            $subs{$first} = sub {
                my $self = shift;
                $self->{"_${name}_line_iter"} = 0;
                return $self->$next(@_);
            };
        }

        if ($all) {
            $subs{$all} = sub {
                my $self = shift;
                my $lines = $self->$get_all(@_);
                return undef unless $lines && @$lines;
                return map { $self->$trans($_) } @$lines;
            };
        }
    }

    my %seen;
    for my $file (@$files) {
        next if $seen{$file}++;
        my ($name, $ext) = $class->parse_filename($file);
        my $attr = "${name}_file";
        $subs{$attr} = sub { $_[0]->{$attr} ||= $_[0]->path($file) };

        $subs{"${name}_make"} = sub {
            my $self = shift;
            return open_file($self->$attr, '>') unless @_;
            write_file_atomic($self->$attr, @_);
        };

        $ext = lc($ext || '');

        my $read = "${name}_read";
        if ($ext eq 'json') {
            $subs{$read} = sub {
                my $self = shift;
                my $data = decode_json(read_file($self->$attr));
                my $trans = $transform->{$file} or return $data;
                return $self->$trans($data);
            };
        }
        else { # line based
            my $decode = $ext eq 'jsonl' ? 1 : 0;
            my $cache  = "_${name}_line_cache";
            my $iter   = "_${name}_line_iter";
            my $handle = "_${name}_line_handle";
            my $reset  = "${name}_read_reset";
            my $rline  = "${name}_read_line";
            my $fline  = "${name}_first_line";

            $subs{$cache}  = sub { $_[0]->{$cache}  ||= [] };
            $subs{$handle} = sub { $_[0]->{$handle} ||= Test2::Harness::Util::ActiveFile->maybe_open_file($_[0]->$attr) };
            $subs{$iter}   = sub { $_[0]->{$iter} };

            $subs{$reset} = sub { delete @{$_[0]}{$cache, $handle, $iter} };

            $subs{$read} = sub {
                my $self = shift;
                my ($eof) = @_;

                my @out;
                local $self->{$iter} = 0;
                while (1) {
                    my $line = $self->$rline($eof);
                    last unless defined $line;
                    push @out => $line;
                }
                return \@out;
            };

            $subs{$rline} = sub {
                my $self = shift;
                my ($eof) = @_;

                my $lines = $self->$cache;

                $self->{$iter} = 0 unless defined $self->{$iter};

                return $lines->[$self->{$iter}++] if @$lines > $self->{$iter};

                my $h = $self->$handle or return undef;

                $h->set_done(1) if $eof;

                until (@$lines > $self->{$iter}) {
                    my $raw = $h->read_line or return undef;
                    my $line = $decode ? decode_json($raw) : $raw;
                    push @$lines => $line;
                }

                return $lines->[$self->{$iter}++];
            };

            $subs{$fline} = sub {
                my $self = shift;
                my ($eof) = @_;

                $self->{$iter} = 0;

                $self->$rline($eof);
            };
        }
    }

    $subs{create} = sub {
        my $class  = shift;
        my %params = @_;

        my $dir = $params{$dir_attr} or croak "'$dir_attr' is a required attribute";

        mkdir($dir) or die "Could not make directory '$dir': $!"
            unless -d $dir;

        my $self = $class->new(%params);

        $self->serialize() if $serialize;

        return $self;
    };

    $subs{load} = sub {
        my $class = shift;
        my ($dir) = @_;

        return $class->deserialize($dir) if $serialize;

        croak "$class\->load() requires a directory as the first argument"
            unless $dir && -d $dir;

        return $class->new($dir_attr => $dir);
    };

    if ($serialize) {
        my ($name, $ext) = ($serialize =~ m/^(.*)(\..+)?$/);
        my $maker  = "${name}_make";

        $subs{serialize} = sub {
            my $self = shift;
            my %config = map { ($_ => $self->{$_}) } grep { !m/^_/ } keys %$self;
            my $json   = encode_json(\%config);
            $self->$maker($json);
        };

        $subs{deserialize} = sub {
            my $class = shift;
            my ($dir) = @_;

            croak "$class\->load() requires a directory as the first argument"
                unless $dir && -d $dir;

            my $file = File::Spec->catfile($dir, $serialize);
            my $json = read_file($file);
            my $data = decode_json($json);
            return $class->new(%$data, $dir_attr => $dir);
        };
    }

    no strict 'refs';
    *{"$caller\::$_"} = $subs{$_} for sort keys %subs;
}

1;
