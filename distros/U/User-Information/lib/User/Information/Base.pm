# Copyright (c) 2025 Löwenfelsen UG (haftungsbeschränkt)

# licensed under Artistic License 2.0 (see LICENSE file)

# ABSTRACT: generic module for extracting information from user accounts


package User::Information::Base;

use v5.20;
use strict;
use warnings;

use parent qw(Data::Identifier::Interface::Userdata Data::Identifier::Interface::Known);

use File::Spec;

use User::Information;
use User::Information::Path;
use User::Information::Source;

use Carp;

our $VERSION = v0.04;

use constant {
    PATH_LOCAL_SYSAPI   => User::Information::Path->new([qw(local sysapi)]),
    PATH_LOCAL_ISLOCAL  => User::Information::Path->new([qw(local islocal)]),
};

my %_types = (
    db          => 'Data::TagDB',
    extractor   => 'Data::URIID',
    fii         => 'File::Information',
    store       => 'File::FStore',
);

my %_aux_sources = map {$_ => 1} qw(User::Information::Source::Aggregate User::Information::Source::Tagpool User::Information::Source::Defaults);


sub attach {
    my ($self, %opts) = @_;
    my $weak = delete $opts{weak};

    foreach my $key (keys %_types) {
        my $v = delete $opts{$key};
        next unless defined $v;
        croak 'Invalid type for key: '.$key unless eval {$v->isa($_types{$key})};
        $self->{$key} //= $v;
        croak 'Missmatch for key: '.$key unless $self->{$key} == $v;
        weaken($self->{$key}) if $weak;
    }

    croak 'Stray options passed' if scalar keys %opts;

    return $self;
}


sub get {
    my ($self, $key, %opts) = @_;
    my $o_has_default   = exists $opts{default};
    my $o_default       = delete $opts{default};
    my $o_list          = delete $opts{list};
    my $o_as            = delete $opts{as};
    my $info;
    my $values;
    my @res;

    unless (eval {$key->isa('User::Information::Path')}) {
        $key = User::Information::Path->new($key);
    }

    delete $opts{no_defaults};
    croak 'Stray options passed' if scalar keys %opts;

    $values = $self->{data}{$key->_hashkey};

    unless (defined $values) {
        $info //= eval { $self->_key_info($key) };
        if (defined($info)) {
            my $loadpath = $info->{loadpath} // $key;
            $loadpath = $loadpath->_hashkey;
            unless ($self->{loaded}{$loadpath}) {
                $self->{loaded}{$loadpath} = 1;

                if (defined($info->{loader})) {
                    $values = eval { $info->{loader}->($self, $info, $key) };
                    if (defined $values) {
                        $self->{data}{$key->_hashkey} = $values;
                    }
                }

                $self->_value_add($key, @{$info->{values}}) if ref($info->{values}) eq 'ARRAY';
                $self->_value_add($key,   $info->{values} ) if ref($info->{values}) eq 'HASH';

                $values //= $self->{data}{$key->_hashkey};
            }
        }
    }

    unless (defined $values) {
        if ($o_has_default) {
            if ($o_list) {
                return @{$o_default};
            } else {
                return $o_default;
            }
        } else {
            croak 'No value found';
        }
    }

    unless (defined($o_as)) {
        $info //= eval { $self->_key_info($key) };

        $o_as = $info->{rawtype} if defined $info;

        $o_as //= 'raw';
    }

    foreach my $v (@{$values}) {
        if (defined($v->{$o_as})) {
            push(@res, $v->{$o_as});
        } else {
            my $converted;

            $info //= $self->_key_info($key);

            if (defined($v->{raw}) && defined($info->{rawtype}) && $info->{rawtype} eq $o_as) {
                $converted = $v->{raw};
            }

            if (!defined($converted) && $o_as eq 'raw' && defined($info->{rawtype}) && defined($v->{$info->{rawtype}})) {
                $converted = $v->{$info->{rawtype}};
            }

            if (!defined($converted) && defined($info->{converter})) {
                $converted = $info->{converter}->($self, $info, $key, $v, $o_as);
            }

            if (defined $converted) {
                push(@res, $converted);
                $v->{$o_as} = $converted;
            } else {
                croak 'Converting types is currently not supported';
            }
        }
    }

    return @res if $o_list;
    if (scalar(@res) != 1) {
        croak 'Wrong number of results and not in list mode';
    }
    return $res[0];
}


sub node {
    my ($self, %opts) = @_;
    my $o_has_default   = exists $opts{default};
    my $o_default       = delete $opts{default};

    delete $opts{no_defaults};
    croak 'Stray options passed' if scalar keys %opts;

    return $self->{node} if defined $self->{node};
    return $self->{node} = User::Information->local_node if $self->_is_local;
    return $o_default if $o_has_default;
    croak 'No node known';
}


sub displayname {
    my ($self, %opts) = @_;
    $opts{default} //= 'no name' unless $opts{no_defaults};
    return $self->get(['aggregate' => 'displayname'], %opts);
}


sub file {
    my ($self, $key, %opts) = @_;
    my @filename = $self->get($key, as => 'filename', list => 1);
    my $o_extra = delete $opts{extra};
    my $o_directory = delete $opts{directory};
    my $o_open = delete $opts{open};
    my $o_binmode = delete $opts{binmode};

    croak 'Stray options passed' if scalar keys %opts;

    foreach my $filename (@filename) {
        if (defined $o_extra) {
            my @extra = ref($o_extra) ? @{$o_extra} : ($o_extra);
            $filename = $o_directory ? File::Spec->catdir($filename, @extra) : File::Spec->catfile($filename, @extra);
        }

        if (defined $o_open) {
            my $mode;

            croak 'Invalid open mode: '.$o_open unless $o_open =~ /^[abrw]+$/;

            if ($o_open =~ /w/) {
                $mode = '>';
            } elsif ($o_open =~ /a/) {
                $mode = '>>';
            } else {
                $mode = '<';
            }

            $o_binmode //= 1 if $o_open =~ /b/;

            if ($o_directory) {
                if (opendir(my $fh, $filename)) {
                    return $fh;
                }
            } else {
                if (open(my $fh, $mode, $filename)) {
                    $fh->binmode if $o_binmode;
                    return $fh;
                }
            }
        }

        return $filename if -e $filename;
    }

    croak 'No file found';
}

# ---- Private helpers ----
sub _new {
    my ($pkg, $type, $request, %opts) = @_;
    my $self = bless {data => {}, discovered => {}, loaded => {}, sources => {}}, $pkg;

    # Attach subobjects:
    $self->attach(map {$_ => delete $opts{$_}} keys(%_types), 'weak');

    croak 'Stray options passed' if scalar keys %opts;

    $self->_load('User::Information::Source::Aggregate');
    if ($type eq 'from') {
        if ($request eq User::Information->SPECIAL_ME) {
            $self->_load('User::Information::Source::Local');
            $self->_load('User::Information::Source::Env');
            $self->_load('User::Information::Source::POSIX', data => {real_user => $<, effective_user => $>, real_group => $(, effective_group => $)}) if $self->_is_sysapi('posix');
            $self->_load('User::Information::Source::XDG', me => 1);
        } elsif ($request eq User::Information->SPECIAL_CGI) {
            $self->_load('User::Information::Source::CGI');
            $self->_load('User::Information::Source::Env', cgi => 1);
        } elsif (User::Information->SPECIAL_LOCAL_NODE->eq($request)) {
            $self->_load('User::Information::Source::Local');
            $self->_load('User::Information::Source::VFS');
            $self->_load('User::Information::Source::POSIX', data => {uname => undef});
            $self->_load('User::Information::Source::LocalNodeMisc');
        }
    } elsif ($type eq 'sysuid') {
        $self->_load('User::Information::Source::Local');
        $self->_load('User::Information::Source::POSIX', data => {user => $request}) if $self->_is_sysapi('posix');
    } elsif ($type eq 'sysgid') {
        $self->_load('User::Information::Source::Local');
        $self->_load('User::Information::Source::POSIX', data => {group => $request}) if $self->_is_sysapi('posix');
    }
    if (!$self->{sources}{'User::Information::Source::XDG'} && $self->_is_local && defined(my $username = $self->get(['aggregate', 'username'], default => undef))) {
        $self->_load('User::Information::Source::XDG', username => $username);
    }
    if ($self->_is_local) {
        $self->_load('User::Information::Source::Git');
        $self->_load('User::Information::Source::Tagpool');
    }
    $self->_load('User::Information::Source::Defaults');

    croak 'No matching data sources found for type/request' unless scalar(grep {!$_aux_sources{$_}} keys %{$self->{sources}});

    return $self;
}

sub _key_info {
    my ($self, $key) = @_;
    return $self->{discovered}{$key->_hashkey} // croak 'Unknown key';
}

sub _key_add {
    my ($self, @info) = @_;
    my $discovered = $self->{discovered};

    foreach my $ent (@info) {
        $discovered->{$ent->{path}->_hashkey} //= $ent;
    }
}

sub _load {
    my ($self, $source, %opts) = @_;
    $self->{sources}{$source} = undef;
    $self->_key_add(User::Information::Source->_load($source, $self, %opts));
}

sub _is_sysapi {
    my ($self, $api) = @_;
    my $sysapi = $self->{sysapi} //= $self->get(PATH_LOCAL_SYSAPI, default => '');
    return $sysapi eq $api;
}

sub _is_local {
    my ($self) = @_;
    return $self->{islocal} //= $self->get(PATH_LOCAL_ISLOCAL, default => '', as => 'bool');
}

sub _value_add {
    my ($self, $key, @values) = @_;
    my $d;

    @values = grep {defined} @values;

    return unless scalar @values;

    $d = $self->{data}{$key->_hashkey} //= [];
    push(@{$d}, @values);
    $self->{loaded}{$key->_hashkey} = 1;
}

sub _known_provider {
    my ($self, $class, %opts) = @_;

    croak 'Unsupported options passed' if scalar(keys %opts);

    return [map {$_->{path}} values %{$self->{discovered}}], not_identifiers => 1 if $class eq 'paths';

    croak 'Unknown class';
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

User::Information::Base - generic module for extracting information from user accounts

=head1 VERSION

version v0.04

=head1 SYNOPSIS

    use User::Information;

This module allows extracting information on user accounts.

This package inherits from L<Data::Identifier::Interface::Userdata>, and L<Data::Identifier::Interface::Known>.

Class C<paths> can be used to discover paths for L</get>. See L<Data::Identifier::Interface::Known/known> for details.

=head1 METHODS

=head2 attach

    $base->attach(key => $obj, ...);
    # or:
    $base->attach(key => $obj, ..., weak => 1);

Attaches objects of the given type.

The following types objects are supported:
C<db> (a L<Data::TagDB>),
C<extractor> (a L<Data::URIID>),
C<fii> (a L<File::Information>), and
C<store> (a L<File::FStore>).

If an object is allready attached for the given key this method C<die>s unless the object is actually the same.

If C<weak> is set to a true value the object reference becomes weak.

Returns itself.

=head2 get

    my $value = $base->get($path, %opts);
    # or:
    my @value = $base->get($path, %opts, list => 1);

Gets the value of a property.
C<$path> is a L<User::Information::Path>.

If the value is known, supported, or any other error occurs this method C<die>s.

The following, all optional, options are supported:

=over

=item C<default>

The default value used when there is no value for the given propery or the propery is not known.
This can be set to C<undef> (C<list> being false) or C<[]> (C<list> being true) to switch this method from
C<die>ing to returning C<undef> or a empty list.

=item C<list>

Whether the method should return a list.

=item C<as>

The type to use for the values. This can be a package name or C<raw>.

=item C<no_defaults>

This option is ignored for compatibility.

=back

=head2 node

    my User::Information::Base $node = $base->node(%opts);

Returns the node the subject this object represents is on.
C<die>s if no node is known or supported.

The following, all optional, options are supported:

=over

=item C<default>

The default value used when there is no value for the given propery or the propery is not known.
This can be set to C<undef> to switch this method from C<die>ing to returning C<undef>.

=item C<no_defaults>

This option is ignored for compatibility.

=back

=head2 displayname

    my $displayname = $base->displayname;

Proxy, basically calls C<$base-E<gt>get(['aggregate' =E<gt> 'displayname'], %opts)>.

However a default is enforced unless C<no_defaults> is set.

See also:
L</get>.

=head2 file

    my $filename = $base->file($path, %opts);
    # or:
    my $fh = $base->file($path, open => ..., %opts);

This is a helper to work with values that are filenames.
The method allows finding a working file (or directory), appending path components, and opening.

C<$path> is the same as in L</get>.

The following, all optional, options are supported:

=over

=item C<extra>

Extra path components (arrayref) to append to the filename.
If only one path component is to be added this can also be a plain string (not a ref).
This form however must not be used with multiple elements (e.g. embedded slashes).

=item C<directory>

A boolean value that if true indicates that the final filename refers to a directory.
This is important as plain files and directories are handled differently on some systems.

=item C<open>

If set tries to open the file (or directory).
The value is one of C<'r'>, C<'w'>, or C<'a'>. An optional C<'b'> may be added which changes the I<default> for C<binmode> to be true.

=item C<binmode>

Whether or not L<perlfunc/binmode> is called on the newly open file handle. Defaults to false.

=back

=head1 AUTHOR

Löwenfelsen UG (haftungsbeschränkt) <support@loewenfelsen.net>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2025 by Löwenfelsen UG (haftungsbeschränkt) <support@loewenfelsen.net>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
