package WWW::Lk4;

use strict;
use warnings;

use DB_File;

our $VERSION = '0.12';

use constant KEYJOINER => "\x1c";

# --- Public methods

sub new {
    my ($cls, %arg) = @_;
    my @contexts = ( { 'name' => '$self', 'stash' => {} } );
    my %scopes;
    my %file2data;
    my $self = bless {
        'config_file' => '/etc/lk4/lk4.conf',
        'data_dir'    => '/var/local/lk4',
        %arg,
        'contexts'    => \@contexts,
        'scopes'      => \%scopes,
        'file2data'   => \%file2data,
    }, $cls;
    $self->load_config;
    return $self;
}

sub resolve {
    my ($self, $req, %env) = @_;
    # Extract path info components and query string from the requested URI
    # These are normalized to remove extra slashes, etc.
    # For example, this:
    #   /proxy/emerson/?url=http://example.com/foo/bar
    # Yields two path components:
    #   /proxy
    #   /emerson
    # And the query string:
    #   ?url=http://example.com/foo/bar
    my ($path_info, $query_string);
    if ($req =~ /^([^?]*)(?:(\?.*))?/) {
        ($path_info, $query_string) = ($1, $2);
        $query_string = '' if !defined $query_string;
    }
    else {
        ($path_info, $query_string) = ('/', '');
    }
    $path_info =~ s{/*$}{/};
    $path_info =~ s{/\./}{//}g;
    $path_info =~ tr{/}{/}s;
    my @path = ('', $path_info =~ m{(/[^/]+)}g);

    # Look for a context under which to redirect
    # For example, we might have this in a config file:
    #   under /proxy {
    #       forward ...
    #   }
    undef $path_info;
    my $scope;
    my $scopes = $self->{'scopes'};
    foreach (reverse 0..$#path) {
        my $str = join '', @path[0..$_];
        next if !defined ($scope = $scopes->{$str});
        splice @path, 0, $_ + 1;
        $path_info = join '', @path;
        $path_info =~ s{(?<=.)/$}{};
        last;
    }
    return err(404, "$req :: no forward") if !defined $path_info;
    my $contexts = $self->{'contexts'};
    push @$contexts, {
        'name' => '$request',
        'stash' => \%env,
    };
    my $forwards = $scope->{'forwards'};
    my %result = ('ok' => 0);
    foreach (@$forwards) {
        my $result;
        eval {
            $result = $_->($scope, $path_info, $query_string);
            if (defined $result) {
                $result{'ok'} = 1;
                if (ref($result) eq 'HASH') {
                    $result{'menu'} = $result;
                }
                else {
                    $result{'uri'} = $result;
                }
            }
        };
        if ($@) {
            chomp $@;
            $result{'message'} = "$req :: $@";
        }
        last if defined $result;
    }
    pop @$contexts;
    return %result;
}

sub let {
    my ($self, %arg) = @_;
    $self->{'contexts'}->[0]->{'stash'}{$_} = $arg{$_} for keys %arg;
    return $self;
}

sub read_config_file {
    my ($self, $f) = @_;
    open my $fh, '<', $f or die "Can't open config file $f: $!";
    my $scopes = $self->{'scopes'};
    my $contexts = $self->{'contexts'};
    while (<$fh>) {
        normalize($_);
        next if /^#|^$/;
        my $stash = $contexts->[-1]->{'stash'};
        if (/^let (\S+) = (.*)$/) {
            $stash->{$1} = $self->compile_general_expression($2);
        }
        elsif (/^under (\S+) {$/) {
            my $context = $scopes->{$1} = {
                'name' => $1,
                'stash' => {},
                'patterns' => {},
            };
            push @$contexts, $context;
        }
        elsif ($_ eq '}') {
            pop @$contexts;
            die "Underflow" if @$contexts == 0;
        }
        elsif (/^function (\S+) :file (\S+)/) {
            my ($key, $code) = $self->compile_function_from_file($1, $2);
            $stash->{$key} = $code;
        }
        elsif (/^function (\S+) {$/) {
            my ($key, $code) = $self->compile_function_inline($1, $fh);
            $stash->{$key} = $code;
        }
        elsif (/^function (\S+) :perl {$/) {
            my ($key, $code) = $self->compile_perl_function_inline($1, $fh);
            $stash->{$key} = $code;
        }
        elsif (/^list (\S+) {$/) {
            my ($key, $code) = $self->compile_list($1, $fh);
            $stash->{$key} = $code;
        }
        elsif (/^menu (\S+) {/) {
            my ($key, $code) = $self->compile_menu($1, $fh);
            $stash->{$key} = $code;
        }
        elsif (/^menu (\S+) "(.+)" :perl {/) {
            my ($key, $code) = $self->compile_perl_menu($1, $2, $fh);
            $stash->{$key} = $code;
        }
        elsif (/^forward(?: \+(\d\d\d))? (\S+) to (.+)$/) {
            # forward /foo to http://example.com/bar
            # forward +301 /foo to http://example.com/bar
            my ($status, $from, $to) = ($1, $2, $3);
            push @{ $contexts->[-1]->{'forwards'} ||= [] }, $self->compile_forward($from, $to, $status);
        }
        elsif (/^match (\S+) to (.*)/) {
            $contexts->[-1]->{'patterns'}{$1} = qr/$2/;
        }
        else {
            die "Syntax error: $_";
        }
    }
    close $fh;
}

sub compile_data_reader {
    my ($self, $f, $arity) = @_;
    return sub {
        my ($c) = @_;
        my @debug = ($f);
        return $self->{'file2data'}->{$f} if exists $self->{'file2data'}->{$f};
        my %data;
        my $fdb = "$f.db";
        if (-e $fdb && ( ! -e $f || -M $fdb < -M $f) ) {
            # Use $f.db
            tie %data, 'DB_File', $fdb, O_RDONLY, 0644, $DB_HASH
                or die;
        }
        elsif (-e $f) {
            open my $fh, '<', $f or die "Can't open data file $f: $!";
            while (<$fh>) {
                chomp;
                my @key = split /\t/;
                my $val = pop @key;
                die "Bad arity: @key (should be $arity)" if $arity != @key;
                $data{join(KEYJOINER, @key)} = $val;
            }
            close $fh;
        }
        return $self->{'file2data'}->{$f} = \%data;
    }
}

sub compile_menu {
    my ($self, $spec, $fh) = @_;
    my ($key, @params) = parse_spec($spec);
    my %menu;
    my @items;
    my ($var, $list);
    my ($uri, $label);
    while (<$fh>) {
        normalize($_);
        if (/^}$/) {
            last;
        }
        elsif (/^(title|template) (.+)$/) {
            $menu{$1} = $2;
        }
        elsif (/^item (\S+) (.+)$/) {
            my ($uri, $label) = ($1, $2);
            push @items, {
                'uri' => $self->compile_general_expression($uri),
                'label' => $label,
            };
        }
        elsif (/^for (\S+) in (\S+) {$/) {
            ($var, $list) = ($1, $2);
            while (<$fh>) {
                normalize($_);
                if (/^}$/) {
                    last;
                }
                elsif (/^item (\S+) (.+)$/) {
                    ($uri, $label) = ($1, $2);
                }
            }
            die "Item not defined" if !defined $uri;
            $uri = $self->compile_general_expression($uri);
            $label = $self->compile_general_expression($label);
        }
        elsif (!/^(?:#.*)?$/) {
            die;
        }
    }
    if (@items) {
        return $key, sub {
            my @debug = ($spec, $key, @params);  # Just for debugging
            my ($c) = @_;
            return {
                %menu,
                'items' => [ map { evaluate($_, $c) } @items ],
            };
        };
    }
    else {
        return $key, sub {
            my @debug = ($spec, $key, @params, $var, $list, $uri, $label);  # Just for debugging
            my ($c) = @_;
            my @list = @{ $c->{$list} || die "No such list: $list" };
            return {
                %menu,
                'items' => [ map {
                    my %c = ( %$c, $var => $_ );
                    evaluate(+{'uri' => $uri, 'label' => $label}, \%c);
                } @list ],
            }
        };
    }
}

sub compile_perl_menu {
    my ($self, $spec, $title, $fh) = @_;
    my ($key, @params) = parse_spec($spec);
    my $src = "sub {\n";
    while (<$fh>) {
        die if !defined $_;
        $src .= $_;
        last if /^\s*}\s*$/;
    }
    my $inner_sub = eval $src;
    return $key, sub {
        my @debug = ($spec, $src);  # Just for debugging
        my $c = shift;
        return $inner_sub->('title' => $title);
    };
}

sub compile_forward {
    my ($self, $from, $to, $status) = @_;
    my (@matchers, @keys);
    my $spec = '';
    my $contexts = $self->{'contexts'};
    foreach ($from =~ m{([^/]+)}g) {
        if (/^<\*>$/) {
            push @keys, '*';
            $spec .= '/(.*)';
        }
        elsif (/^([^<>]*)<(.+)>([^<>]*)$/) {
            my ($pfx, $key, $sfx) = ($1, $2, $3);
            push @keys, $key;
            my $str = $contexts->[-1]->{'patterns'}{$key} ||= '[^/]+';
            $spec .= '/' . $pfx . '(' . $str . ')' . $sfx;
        }
        else {
            push @keys, undef;
            $spec .= '/(' . $_ . ')';
        }
    }
    my $value;
    if ($to =~ s/^:menu //) {
        $value = $self->compile_menu_expression($to);
    }
    elsif ($to =~ s/^:file //) {
        $value = $self->compile_file_expression($to);
    }
    elsif ($to =~ s/^(:uri )?//) {
        $value = $self->compile_general_expression($to);
    }
    $spec = qr/^$spec$/;
    return sub {
        my @debug = ($self, $contexts, $spec, $from, $to, $status);  # Just for debugging
        my ($scope, $path_info, $query_string) = @_;
        my @m = ( $path_info =~ $spec );
        return if !@m;
        my @k = @keys;
        my %context = map { %{ $_->{'stash'} } } (@$contexts, $scope);
        while (@k && @m) {
            my $k = shift @k;
            my $m = shift @m;
            if (defined $k) {
                $context{$k} = $m;
            }
        }
        return $value->(\%context);
    }
}

sub compile_menu_expression {
    my ($self, $str) = @_;
    if ($str =~ /^(\w+(?:\((.+)\))?)$/) {
        my $key = $1;
        return sub {
            my @debug = ($str);
            my ($c) = @_;
            my @keys = ($key);
            my ($val) = grep { defined $_ } map { $c->{$_} } @keys;
            die if !defined $val;
            return evaluate($val, $c);
            # return 'menu' => ( ref($val) eq 'CODE' ? $val->($c) : $val );
        };
    }
    else {
        die;
    }
}

sub compile_function_from_file {
    my ($self, $spec, $file) = @_;
    $file = $self->find_data_file($file);
    my ($key, @params) = parse_spec($spec);
    my $reader = $self->compile_data_reader($file, scalar @params);
    return $key, sub {
        my @debug = ($spec);  # Just for debugging
        my ($c) = @_;
        my $data = $reader->($c);
        my $key = join(KEYJOINER, @$c{@params});
        my $val = $data->{$key};
        die "can't evaluate: $spec => undef" if !defined $val;
        return $val;
    };
}
sub find_data_file {
    my ($self, $f) = @_;
    return $f if $f =~ m{^/};
    my $contexts = $self->{'contexts'};
    my $ddir = $contexts->[0]->{'stash'}->{'data_dir'};
    if (defined $ddir) {
        $ddir = $ddir->($contexts->[0]->{'stash'}) if ref $ddir;
    }
    else {
        $ddir = $self->{'data_dir'};
    }
    $ddir =~ s{/+$}{};
    return $ddir . '/' . $f;
}

# --- Utility functions
#
sub normalize {
    for (@_) {
        chomp;
        s/\s+/ /g;
        s/^ | $//g;
    }
}

sub parse_spec {
    my ($spec) = @_;
    $spec =~ m{(\w+)\(([^()]+)\)} or return ($spec);
    my ($name, @params) = ($1, split /, */, $2);
    my $key = sprintf('%s(%s)', $name, join(',', @params));
    return ($key, @params);
}

sub read_inline_data {
    my ($fh, $arity) = @_;
    my %data;
    while (<$fh>) {
        normalize($_);
        last if /^}$/;
        my ($keyspec, $val) = split / -> /;
        my @key = split /, /, $keyspec;
        die "Bad arity: $keyspec (should be $arity)" if $arity != @key;
        $data{join(KEYJOINER, @key)} = $val;
    }
    return \%data;
}

sub compile_general_expression {
    my ($self, $str) = @_;
    # <base>/<script(resource)>?docid=<resource>
    my @subexpressions;
    while ($str =~ m/([^<>]+)|<([^<>]+)>/g) {
        if (defined $1) {
            push @subexpressions, $1;
        }
        else {
            my $key = $2;
            push @subexpressions, sub {
                my @debug = ($str);  # Just for debugging
                my ($c) = @_;
                my @keys = ($key);
                my ($val) = grep { defined $_ } map { $c->{$_} } @keys;
                die "Can't evaluate: $str" if !defined $val;
                return evaluate($val, $c);
                # return ref($val) ? $val->($c) : $val;
            }
        }
    }
    return sub {
        my @debug = ($str);
        my ($c) = @_;
        my $uri = '';
        foreach my $expr (@subexpressions) {
            $uri .= evaluate($expr, $c);
            # $uri .= ref($expr) ? $expr->($c) : $expr;
        }
        return $uri;
    };
}

sub evaluate {
    my ($x, $c) = @_;
    my $r = ref $x;
    return $x->($c) if $r eq 'CODE';
    return { map { $_ => evaluate($x->{$_}, $c) } keys %$x } if $r eq 'HASH';
    return $x;
}

sub compile_perl_function_inline {
    my ($self, $spec, $fh) = @_;
    my ($key, @params) = parse_spec($spec);
    my $src = "sub {\n";
    while (<$fh>) {
        die if !defined $_;
        $src .= $_;
        last if /^\s*}\s*$/;
    }
    my $inner_sub = eval $src;
    return $key, sub {
        my @debug = ($spec, $src);  # Just for debugging
        my $c = shift;
        my @args = map { evaluate($_, $c) } @$c{@params};
        # my @args = map { ref($_) ? $_->($c) : $_ } @$c{@params};
        $inner_sub->(@args);
    };
    #return eval $src;
}

sub compile_list {
    my ($self, $name, $fh) = @_;
    my @elems;
    while (<$fh>) {
        normalize($_);
        last if /^}$/;
        push @elems, $_;
    }
    return $name, \@elems;
}

# --- Private methods
#
sub load_config {
    my ($self) = @_;
    my $root = { 'name' => '', 'stash' => {} };
    $self->{'scopes'} = { '' => $root };
    push @{ $self->{'contexts'} }, $root;
    my $cfile = $self->{'config_file'};
    my $cdir  = $self->{'config_dir'};
    if (!defined $cdir) {
        $cdir = $cfile;
        $cdir =~ s/\.conf/.d/;
    }
    foreach my $f (grep { -e } map { glob } $cfile, "$cdir/*.conf") {
        $self->read_config_file($f);
    }
    %{ $self->{'file2data'} } = ();  # XXX Untie?
    return 1;
}

sub compile_function_inline {
    my ($self, $spec, $fh) = @_;
    my ($key, @params) = parse_spec($spec);
    my $data = read_inline_data($fh, scalar @params);
    return $key, sub {
        my @debug = ($spec);  # Just for debugging
        my ($c) = @_;
        my $key = join(KEYJOINER, @$c{@params});
        my $val = $data->{$key};
        die "can't evaluate: $spec => undef" if !defined $val;
        return $val;
    };
}

sub ok {
    my ($status, $msg) = @_;
    return (
        'ok' => 1,
        'status' => sprintf('%03d', $status),
        'message' => $msg,
    );
}

sub err {
    my ($status, $msg) = @_;
    return (
        'ok' => 0,
        'status' => sprintf('%03d', $status),
        'message' => $msg,
    );
}

1;

=head1 NAME

WWW::Lk4 - rule- and data-based transformation of URLs

=head1 SYNOPSIS

    use WWW::Lk4;
    $lk4 = WWW::Lk4->new(
        'config_file' => $conf,
        'data_dir'    => $dir,
        ...
    );
    $lk4->let('$foo' => 'bar');
    $lk4->let('foo(bar)' => \&baz);
    %result = $lk4->resolve('/absolute/uri/path');

=head1 DESCRIPTION

B<WWW::Lk4> resolves URIs into target URIs.

It is suitable for use in a general link redirection service.

=head1 METHODS

=over 4

=item B<new>

    $lk4 = WWW::Lk4->new(
        'config_file' => $conf,
        'data_dir'    => $dir,
        ...
    );

Which config files are read may be overridden by specifying C<config_file> or
C<config_dir> arguments (or both):

    $lk4 = WWW::Lk4->new(
        'config_file' => '/etc/lk4/foo/main.conf',
        'config_dir'  => '/etc/lk4/foo/includes',
    );

If B<config_file> is used but not B<config_dir>, then B<config_dir> will be set
to the value of B<config_file> with C<.d> substituted for C<.conf>.

The names of config files within I<config_dir> B<must> match the glob C<*.conf>
or they will be ignored.

=item B<read_config_file>

    $lk4->read_config_file($f);

=item B<let>

    $lk4->let('$foo' => 'bar');
    $lk4->let('foo(bar)' => \&baz);

Define a variable or function.  This is not normally required, as you can
accomplish the same thing using a Perl function in a config file.

=item B<resolve>

    %result = $lk4->resolve($uri);
    if (!$result{ok}) {
        print "Error: $result{message}\n";
    }
    elsif ($result{uri}) {
        print "URI: $result{uri}\n";
    }
    elsif ($result{menu}) {
        print "Menu: $result{menu}{title}\n";
    }

=back

=head1 CONFIGURATION

Config files contain this stuff...

=over 4

=item B<under>

C<under> introduces a scope under which URIs beginning with a particular prefix may be
resolved.  For example:

    under /doc {
        forward /<docid>        to http://public.example.org/read?docID=<docid>
        forward /<docid>/secret to http://secret.example.org/read?docID=<docid>
    }

This would redirect C</doc/12345> to C<<
http://public.example.org/read?docID=12345 >> and C</doc/98765/secret> to C<<
http://secret.example.org/read?docID=98765 >>.

An C<under> block may contain any directive, not just C<redirect>; those
directives will apply only to URIs that fall under the given prefix.

=item B<function>

A function takes zero or more inputs and produces an output.  You can use this,
for example, to map library names to proxy prefixes

    function base(name) {
        main  -> http://example.net
        smith -> http://smith.example.net
        jones -> http://jones.example.net
    }
    forward /foo/<name>/<docid> to <base(name)>/foo/<docid>

Functions may be defined in a data file:

    function new(docid) from doc-id-mapping
    forward /doc/<docid> to http://new.example.org/doc/<new(docid)>

Functions may be written in Perl:

    function qux(docid) :perl {
        my ($docid) = @_;
        my $uri = ...;
        return $uri;
    }

=item B<menu>

A menu is a list of URIs to present to the user.  Example:

    under /doc {
        menu pdf_or_text(docid) {
            title Alternatives
            item /pdf/<docid>.pdf   "PDF"
            item /txt/<docid>.txt   "Text"
        }
        forward /<docid> to :menu pdf_or_text(docid)
    }

=back

=head1 FILES

Default config files are as follows:

=over 4

=item B</usr/local/lk4/conf/lk4.conf>

=item B</usr/local/lk4/conf/lk4.d/*.conf>

=back

=head1 BUGS

Functions must be called using arguments whose names match the formal parameter
names with which the function was declared.  Ditto menus.

=head1 AUTHOR

Paul Hoffman E<lt>paul@flo.orgE<gt>.

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2012 Fenway Libraries Online.

This module is free software; you can redistribute it and/or modify it under
the terms of the GNU General Public License, version 2.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

=cut
