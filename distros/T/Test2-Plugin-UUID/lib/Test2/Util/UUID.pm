package Test2::Util::UUID;
use strict;
use warnings;

our $VERSION = '0.002009';

use Carp qw/croak/;

my %EXPORT = (
    looks_like_uuid => 1,
    gen_uuid => 1,
    GEN_UUID_BACKEND => 1,
    uuid2bin => 1,
    bin2uuid => 1,
);

sub import {
    my $class  = shift;
    my $caller = caller;

    my %gen_params;
    my %import;

    while (my $arg = shift @_) {
        if ($EXPORT{$arg}) {
            $import{$arg}++;
            next;
        }

        if ($arg eq 'warn' || $arg eq 'backends') {
            $gen_params{$arg} = shift @_;
            next;
        }

        croak "Invalid argument '$arg'";
    }

    my $subs = $class->get_gen_uuid(%gen_params);

    for my $name (keys %import) {
        my $sub = $subs->{$name} || $class->can($name) or croak "'$name' is not available for import";

        no strict 'refs';
        *{"$caller\::$name"} = $sub;
    }

    return;
}

my %GEN_UUID_CACHE;

sub clear_cache { %GEN_UUID_CACHE = () }

sub get_gen_uuid {
    my $class  = shift;
    my %params = @_;

    my $warn     = $params{warn}     // ($ENV{TEST2_UUID_NO_WARN} ? 0                                           : 1);
    my $backends = $params{backends} // ($ENV{TEST2_UUID_BACKEND} ? [split /\s*,\s*/, $ENV{TEST2_UUID_BACKEND}] : ['UUID', 'Data::UUID::MT', 'UUID::Tiny', 'Data::UUID']);

    for my $backend (@$backends) {
        return $GEN_UUID_CACHE{$backend} if $GEN_UUID_CACHE{$backend};

        my $meth = lc("_gen_$backend");
        $meth =~ s/::/_/g;

        croak "'$backend' is not supported" unless $class->can($meth);

        $GEN_UUID_CACHE{$backend} = $class->$meth($warn) or next;
        $GEN_UUID_CACHE{$backend}->{GEN_UUID_BACKEND} = sub() { $backend };
        return $GEN_UUID_CACHE{$backend};
    }

    croak "No UUID generator found, please install one of these: UUID, Data::UUID::MT, Data::UUID, or UUID::Tiny. ('UUID' is preferred over the others)\n";
}

sub _gen_uuid {
    my $class = shift;
    my ($warn) = @_;

    local $@;
    return undef unless eval { require UUID; 1 };

    unless (eval { UUID->VERSION('0.35'); 1 }) {
        warn "UUID version is too old, need 0.35 or greater to avoid a fork related bug. Please upgrade the UUID module.\n"
            if $warn;

        return;
    }

    return {
        gen_uuid => sub { uc(UUID::uuid7->()) },
        bin2uuid => sub { my $out; UUID::unparse($_[0], $out); uc($out) },
        uuid2bin => sub { my $out; UUID::parse($_[0], $out); $out },
    };
}

sub _gen_data_uuid_mt {
    my $class = shift;
    my ($warn) = @_;

    local $@;
    return undef unless eval { require Data::UUID::MT; 1 };

    my $ug = Data::UUID::MT->new(version => 4);
    my $out = {
        gen_uuid => sub { uc($ug->create_string()) },
    };

    if (eval { require UUID::Tiny; 1 }) {
        $out->{uuid2bin} = sub { UUID::Tiny::string_to_uuid($_[0]) },
        $out->{bin2uuid} = sub { uc(UUID::Tiny::uuid_to_string($_[0])) },
    }

    return $out;
}

sub _gen_uuid_tiny {
    my $class = shift;
    my ($warn) = @_;

    local $@;

    return undef unless eval { require UUID::Tiny; 1 };

    warn "Using UUID::Tiny for uuid generation. UUID::Tiny is significantly slower than the 'UUID' or 'Data::UUID::MT' modules, please install 'UUID' or 'Data::UUID::MT' if possible. If you insist on using UUID::Tiny you can set the TEST2_UUID_NO_WARN environment variable.\n"
        if $warn;

    return {
        gen_uuid => sub { uc(UUID::Tiny::create_uuid_as_string(UUID::Tiny::UUID_V4())) },
        bin2uuid => sub { uc(UUID::Tiny::uuid_to_string($_[0])) },
        uuid2bin => sub { UUID::Tiny::string_to_uuid($_[0]) },
    };
}

sub _gen_data_uuid {
    my $class = shift;
    my ($warn) = @_;

    local $@;
    return undef unless eval { require Data::UUID; 1 };

    warn "Using Data::UUID to generate UUIDs, this works, but the UUIDs will not be suitible as database keys. Please install the 'UUID', 'Data::UUID::MT' or the slower but pure perl 'UUID::Tiny' cpan modules for better UUIDs. If you insist on using Data::UUID you can set the TEST2_UUID_NO_WARN environment variable.\n"
        if $warn;

    my ($UG, $UG_PID);

    my $UG_INIT = sub {
        return $UG if $UG && $UG_PID && $UG_PID == $$;

        $UG_PID = $$;
        return $UG = Data::UUID->new;
    };

    # Initialize it here in this PID to start
    $UG_INIT->();

    return {
        gen_uuid => sub { uc($UG_INIT->()->create_str()) },
        bin2uuid => sub { uc($UG_INIT->()->to_string($_[0])) },
        uuid2bin => sub { $UG_INIT->()->from_string($_[0]) },
    };
}

sub looks_like_uuid {
    my ($in) = @_;
    return $in if $in && $in =~ m/^[A-F0-9]{8}-[A-F0-9]{4}-[A-F0-9]{4}-[A-F0-9]{4}-[A-F0-9]{12}$/i;
    return undef;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Test2::Util::UUID - Utils for generating UUIDs under Test2.

=head1 DESCRIPTION

This module provides a consistent UUID source for all of Test2.

=head1 SYNOPSIS

    use Test2::Util::UUID qw/gen_uuid looks_like_uuid uuid2bin bin2uuid/;

    my $uuid = gen_uuid;

    my $bin = bin2uuid($uuid);

    my $uuid_again = uuid2bin($uuid);

=head1 UNDER THE HOOD

One of the following modules will be used under the hood, they are listed here
in order of preference.

=over 4

=item L<UUID> >= 0.35

When possible this module will use the L<UUID> cpan module, but it must be
version 0.35 or greater to avoid a fork related bug. It will generate version 7
UUIDs as they are most suitible for database entry.

=item L<Data::UUID::MT>

L<Data::UUID::MT> is the second choice for UUID generation. With this module
version 4 UUIDs are generated as they are fairly usable in databases.

=item L<UUID::Tiny> - slow

L<UUID::Tiny> is used if the previous 2 are not available. This module is pure
perl and thus could be slower than the others. Version 4 UUIDs are generated
when this module is used.

A warning will be issued with this module. You can surpress the warning with
either the C<$TEST2_UUID_NO_WARN> environment variable or the C<< warn => 0 >>
import argument.

=item L<Data::UUID> - Not Suitible for Databases

This is the last resort module. This generates UUIDs fast, but they are of a
type/version that is not suitible for database keys.

A warning will be issued with this module. You can surpress the warning with
either the C<$TEST2_UUID_NO_WARN> environment variable or the C<< warn => 0 >>
import argument.

=back

=head2 CONTROLLING WARNINGS

=head3 AT IMPORT

    use Test2::Util::UUID 'gen_uuid', warn => 0;

Passing in C<< warn => 0 >> will disable the warnings normally issued when
using L<UUID::Tiny> or L<Data::UUID> as a backend.

=head2 SELECTING A BACKEND

=head3 AT IMPORT

If you wish to override the order and specify which backend to use you may do
so by listing them during import prefixed with ':'.

    use Test2::Util::UUID 'gen_uuid', backends => [':UUID', ':UUID::Tiny'];

The above will try the L<UUID> module first, followed by the L<UUID::Tiny>
module. It will not try L<Data::UUID::MT> or L<Data::UUID>.

B<Note:> You must include these import arguments anywhere you import this
module, otherwise the other imports will use the default list, resulting in
different places using different UUIDs.

=head3 THE $TEST2_UUID_BACKEND ENV VAR

Setting the $TEST2_UUID_BACKEND env var to one of the backends, or a comma
seperated list will override the default list for all imports. It will B<NOT>
override imports that specify their own lists.

=head1 EXPORTS

=over 4

=item $uuid = gen_uuid()

Generate a UUID, always normalized to upper case.

=item $uuid_or_undef = looks_like_uuid($UUID)

Checks if the provided value looks like a UUID. Make sure it is defined, 36
characters long, has dashes, and only contains 0-9 a-f and dash (case
insensitive).

Returns the input value if it looks like a UUID, otherise it returns undef.

=back

=head1 SOURCE

The source code repository for Test2-Plugin-UUID can be found at
F<https://github.com/Test-More/Test2-Plugin-UUID/>.

=head1 MAINTAINERS

=over 4

=item Chad Granum E<lt>exodist@cpan.orgE<gt>

=back

=head1 AUTHORS

=over 4

=item Chad Granum E<lt>exodist@cpan.orgE<gt>

=back

=head1 COPYRIGHT

Copyright Chad Granum E<lt>exodist@cpan.orgE<gt>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See F<http://dev.perl.org/licenses/>

=cut
