#
# Copyright (C) 2014-2016 by Tomasz Konojacki
#
# This library is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself, either Perl version 5.18.2 or,
# at your option, any later version of Perl 5 you may have available.
#

package Tie::ConfigFile;

use strict;
use warnings;

use IO::File;
use File::AtomicWrite;

use Carp;

our $VERSION = '1.3';

sub __init {
    my $self = shift;

    $self->{_fh} = IO::File->new(
        $self->{filename},
        ($self->{readonly} ? O_RDONLY : O_RDWR) |
        ($self->{create_file} ? O_CREAT : 0)
    ) or croak sprintf('Unable to open file "%s".', $self->{filename});
    # we utf-8, baby
    $self->{_fh}->binmode(':utf8');

    $self->{_cache} = {};

    $self->__read;

    close $self->{_fh};
    undef $self->{_fh};

    return 1;
}

sub __read {
    my $self = shift;

    # separator character
    my $SEP = '=';
    # comment character
    my $COMM = ';';

    my $cache = $self->{_cache};

    my $i = 0;
    while (defined(my $line = $self->{_fh}->getline)) {
        chomp $line;

        # is it comment?
        if ($line =~ /^\s*$COMM/) {
            push @{ $cache->{structure} },
                 {
                    type => 'comment',
                    value => $line,
                 };
        }
        # is it just whitespace?
        elsif ($line =~ /^\s*$/) {
            push @{ $cache->{structure} },
            {
                type => 'whitespace',
                value => $line,
            }
        }
        # is it key-value pair?
        elsif ($line =~ /$SEP/) {
            my($key, $value) = split /\s*$SEP\s*/, $line, 2;

            push @{ $cache->{structure} },
            {
                type => 'value',
                value => $line,
            };

            # these are needed for fast retrieval of values
            $cache->{values}{$key} = $value;
            $cache->{key_to_struct}{$key} = $cache->{structure}->[$i];
        }
        # we can't parse it
        else {
            croak sprintf(
                "Found garbage at <%s>, line %d.",
                $self->{filename}, $i + 1
            );
        }

        $i++;
    }

    return
}

sub __write {
    my $self = shift;

    my $cache = $self->{_cache};

    my $faw = File::AtomicWrite->new({
        file => $self->{filename},
        binmode_layer => ':utf8'
    });

    my $fh = $faw->fh;
    for my $item (@{ $cache->{structure} }) {
        next if $item->{deleted};

        $fh->print($item->{value}, "\n");
    }

    $faw->commit;

    return;
}

sub TIEHASH {
    my($class, %args) = @_;

    my $self = {
        filename         => undef,
        readonly         => 1,
        create_file      => 0,
        %args
    };

    unless (defined $self->{filename}) {
        croak 'Filename is required.';
    }

    bless $self, $class;

    $self->__init;

    return $self;
}

sub FETCH {
    my($self, $key) = @_;

    my $cache = $self->{_cache};

    return $cache->{values}{$key};
}

sub STORE {
    my($self, $key, $value) = @_;

    my $cache = $self->{_cache};

    if ($self->{readonly}) {
        croak 'STORE is not allowed on read-only config file.';
    }

    if (exists $self->{_cache}{values}{$key}) {
        # key already exist, just update it
        $cache->{values}{$key} = $value;
        $cache->{key_to_struct}{$key}{value} = "$key=$value",
    }
    else {
        # create new key
        push @{ $cache->{structure} },
        {
            type => 'value',
            value => "$key=$value",
        };
        # index of element we just pushed
        my $index = $#{ $cache->{structure} };

        $cache->{values}{$key} = $value;
        $cache->{key_to_struct}{$key} = $cache->{structure}->[$index],
    }

    $self->__write;

    return;
}

sub DELETE {
    my($self, $key) = @_;

    my $cache = $self->{_cache};

    if ($self->{readonly}) {
        croak 'DELETE is not allowed on read-only config file.';
    }

    $cache->{key_to_struct}{$key}{deleted} = 1;
    delete $cache->{key_to_struct}{$key};
    delete $cache->{values}{$key};

    $self->__write;

    return;
}

sub CLEAR {
    my $self = shift;

    %{$self->{_cache}} = ();
    $self->__write;

    return;
}

sub EXISTS {
    my($self, $key) = @_;

    # Empty keys have '' value, so if value is undefined, key doesn't exist.
    return exists $self->{_cache}{values}{$key};
}

sub FIRSTKEY {
    my $self = shift;

    return (each %{ $self->{_cache}{values} } )
}

sub NEXTKEY {
    my $self = shift;

    return (each %{ $self->{_cache}{values} } )
}

sub UNTIE {
    my($self, $count) = @_;

    carp "untie attempted while $count inner references still exist" if $count;

    return
}

'thank you based god';

__END__

=head1 NAME

Tie::ConfigFile - Tie configuration file to a hash

=head1 SYNOPSIS

    use Tie::ConfigFile;

    my %hash;
    tie %hash, 'Tie::ConfigFile', filename => 'foobar.conf', readonly => 0;

    $hash{foo} = 'bar'; # will be written to foobar.conf

    untie %hash;

=head1 DESCRIPTION

This module allows you to tie configuration file to a hash. To understand what
"tie" means in this context, read L<perltie>. Comments, empty lines and order
in configuration file are always preserved. Formatting of a line is preserved
unless you modify its value.

=head1 EXAMPLE CONFIG FILE

    key=value
    ;comment
    another_key = value
    key with spaces=value with spaces

    key after break=1

=head1 OPTIONS

=over 4

=item *

C<filename> (string, mandatory) - Path to a configuration file.

=item *

C<create_file> (boolean, default: C<0>) - Try to create configuration file if
it doesn't exist.

=item *

C<readonly> (boolean, default: C<1>) - Disallow writing to the config file.

=back

=head1 EXPORT

Nothing is exported.

=head1 CAVEATS

=over 4

=item *

When more than one process uses configuration file in non-readonly mode, data
loss may happen.

=item *

Multidimensional hashes are not supported.

=back

=head1 SEE ALSO

=over 4

=item *

L<Tie::Cfg>

=item *

L<Tie::Config>

=back

=head1 FOSSIL REPOSITORY

Tie::ConfigFile Fossil repository is hosted at my own server:

    http://code.xenu.pl/repos.cgi/tie-configfile

=head1 AUTHOR

    Tomasz Konojacki <me@xenu.pl>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014-2016 by Tomasz Konojacki

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.18.2 or,
at your option, any later version of Perl 5 you may have available.

=cut
