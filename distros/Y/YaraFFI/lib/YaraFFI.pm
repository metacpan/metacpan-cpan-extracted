package YaraFFI;

$YaraFFI::VERSION   = '0.06';
$YaraFFI::AUTHORITY = 'cpan:MANWAR';

=head1 NAME

YaraFFI - Minimal Perl FFI bindings for the YARA malware scanning engine

=head1 VERSION

Version 0.06

=head1 SYNOPSIS

    use YaraFFI;

    my $rules = <<'YARA';
    rule HelloWorld {
        meta:
            author = "John Doe"
            description = "Test rule"
        strings:
            $a = "hello" ascii
        condition:
            $a
    }
    YARA

    my $yara = YaraFFI->new;
    $yara->compile($rules) or die "compile failed";

    $yara->scan_buffer("hello hacker", sub {
        my ($event) = @_;
        print "Event: $event->{event}\n";
        print "Rule: $event->{rule}\n";

        if ($event->{event} eq 'rule_match') {
            if ($event->{metadata}) {
                print "Metadata:\n";
                for my $key (keys %{$event->{metadata}}) {
                    print "  $key = $event->{metadata}{$key}\n";
                }
            }
        }

        if ($event->{event} eq 'string_match') {
            print "String: $event->{string_id}\n";
            print "Offsets: " . join(", ", @{$event->{offsets}}) . "\n" if $event->{offsets};
        }
    });

=head1 DESCRIPTION

C<YaraFFI> provides lightweight C<FFI> bindings to C<libyara>, allowing you to compile
C<YARA> rules from strings and scan memory buffers or files. It supports basic
C<rule_match> and C<string_match> events via a Perl callback.

Currently it focuses on correctness and minimal functionality, not full C<YARA>
feature coverage.

For more information, please follow the L<official documentation|https://yara.readthedocs.io/en/latest>.

=head1 FEATURES

=over 4

=item * Compile C<YARA> rules from string

=item * Scan in-memory buffers (C<scan_buffer>)

=item * Scan files (C<scan_file>)

=item * Events passed to callback are simple objects (C<rule_match>, C<string_match>)

=item * Match offset reporting for string matches (when enabled)

=item * Rule metadata extraction (when enabled)

=back

=head1 NOT YET IMPLEMENTED

=over 4

=item * No support for YARA modules or external variables

=item * No NOT_MATCH, IMPORT, or FINISHED events

=item * Scan flags currently hardcoded to 0

=item * Metadata and offset extraction disabled by default due to YARA version compatibility

=back

=cut

use v5.14;
use strict;
use warnings;
use YaraFFI::Event;
use YaraFFI::Record::YR_RULE;
use YaraFFI::Record::YR_META;
use YaraFFI::Record::YR_STRING;
use YaraFFI::Record::YR_MATCH;
use FFI::Platypus 2.00;
use File::Slurp qw(read_file);

my $ffi = FFI::Platypus->new(api => 2);
$ffi->lib("libyara.so");

# Attach YARA functions
$ffi->attach('yr_initialize'          => [] => 'int');
$ffi->attach('yr_finalize'            => [] => 'int');
$ffi->attach('yr_compiler_create'     => ['opaque*'] => 'int');
$ffi->attach('yr_compiler_destroy'    => ['opaque' ] => 'void');
$ffi->attach('yr_compiler_add_string' => ['opaque', 'string', 'string'] => 'int');
$ffi->attach('yr_compiler_get_rules'  => ['opaque', 'opaque*'] => 'int');
$ffi->attach('yr_rules_destroy'       => ['opaque'] => 'void');

# Callback signature: int callback(YR_SCAN_CONTEXT* context, int message, void* message_data, void* user_data)
$ffi->attach('yr_rules_scan_mem' => ['opaque', 'opaque', 'size_t', 'int', '(opaque, int, opaque, opaque)->int', 'opaque', 'int'] => 'int');

# Define constants for YARA callback messages
use constant {
    CALLBACK_MSG_RULE_MATCHING     => 1,
    CALLBACK_MSG_RULE_NOT_MATCHING => 2,
    CALLBACK_MSG_SCAN_FINISHED     => 3,
    CALLBACK_MSG_IMPORT_MODULE     => 4,
    CALLBACK_CONTINUE              => 0,
    ERROR_SUCCESS                  => 0,

    # Metadata types
    META_TYPE_INTEGER              => 1,
    META_TYPE_STRING               => 2,
    META_TYPE_BOOLEAN              => 3,
};

sub new {
    my ($class) = @_;
    yr_initialize();
    return bless { rules => undef }, $class;
}

sub compile {
    my ($self, $rule_str) = @_;
    my $compiler;
    my $res = yr_compiler_create(\$compiler);
    return 0 if $res != 0;

    $res = yr_compiler_add_string($compiler, $rule_str, undef);
    return 0 if $res != 0;

    my $rules;
    $res = yr_compiler_get_rules($compiler, \$rules);
    return 0 if $res != 0;

    yr_compiler_destroy($compiler);
    $self->{rules} = $rules;
    return 1;
}

sub scan_file {
    my ($self, $filename, $callback) = @_;
    die "Compile rules first" unless $self->{rules};

    my $content = read_file($filename, binmode => ':raw');
    return $self->scan_buffer($content, $callback);
}

# Safe metadata extraction using FFI records
sub _extract_metadata_with_records {
    my ($rule_ptr, $enable_extraction) = @_;
    return undef unless $enable_extraction;
    return undef unless $rule_ptr && $rule_ptr > 4096;

    my %metadata;

    eval {
        # Cast to YR_RULE record
        my $rule = $ffi->cast('opaque', 'record(YaraFFI::Record::YR_RULE)*', $rule_ptr);
        return unless $rule && $rule->metas;

        my $metas_ptr = $rule->metas;
        return unless $metas_ptr > 4096;

        # Iterate through metadata entries
        for my $i (0..19) {
            my $meta_ptr = $metas_ptr + ($i * 32);  # Approximate YR_META size

            my $type_bytes = $ffi->cast('opaque', 'string(4)', $meta_ptr);
            last unless defined $type_bytes && length($type_bytes) == 4;

            my $type = unpack('L', $type_bytes);
            last if $type == 0 || $type > 3;

            # Read identifier pointer
            my $id_ptr_bytes = $ffi->cast('opaque', 'string(8)', $meta_ptr + 8);
            next unless defined $id_ptr_bytes && length($id_ptr_bytes) == 8;

            my $id_ptr = unpack('Q', $id_ptr_bytes);
            next unless $id_ptr > 4096;

            my $identifier = $ffi->cast('opaque', 'string', $id_ptr);
            next unless $identifier && $identifier =~ /^[a-zA-Z_][a-zA-Z0-9_]{0,100}$/;

            if ($type == META_TYPE_STRING) {
                my $str_ptr_bytes = $ffi->cast('opaque', 'string(8)', $meta_ptr + 16);
                if (defined $str_ptr_bytes && length($str_ptr_bytes) == 8) {
                    my $str_ptr = unpack('Q', $str_ptr_bytes);
                    if ($str_ptr > 4096) {
                        my $value = $ffi->cast('opaque', 'string', $str_ptr);
                        $metadata{$identifier} = $value if defined $value && length($value) < 1000;
                    }
                }
            }
            elsif ($type == META_TYPE_INTEGER) {
                my $int_bytes = $ffi->cast('opaque', 'string(8)', $meta_ptr + 16);
                if (defined $int_bytes && length($int_bytes) == 8) {
                    my $value = unpack('q', $int_bytes);  # signed 64-bit
                    $metadata{$identifier} = $value;
                }
            }
            elsif ($type == META_TYPE_BOOLEAN) {
                my $bool_bytes = $ffi->cast('opaque', 'string(4)', $meta_ptr + 16);
                if (defined $bool_bytes && length($bool_bytes) == 4) {
                    my $value = unpack('L', $bool_bytes);
                    $metadata{$identifier} = $value ? 1 : 0;
                }
            }
        }
    };

    return keys %metadata > 0 ? \%metadata : undef;
}

# Safe string match extraction using FFI records
sub _extract_string_matches_with_records {
    my ($rule_ptr, $enable_extraction) = @_;
    return [] unless $enable_extraction;
    return [] unless $rule_ptr && $rule_ptr > 4096;

    my @strings;

    eval {
        # Cast to YR_RULE record
        my $rule = $ffi->cast('opaque', 'record(YaraFFI::Record::YR_RULE)*', $rule_ptr);
        return unless $rule && $rule->strings;

        my $strings_ptr = $rule->strings;
        return unless $strings_ptr > 4096;

        # Iterate through string entries
        for my $i (0..49) {
            my $string_base = $strings_ptr + ($i * 64);  # Approximate YR_STRING size

            # Read identifier pointer
            my $id_ptr_bytes = $ffi->cast('opaque', 'string(8)', $string_base);
            last unless defined $id_ptr_bytes && length($id_ptr_bytes) == 8;

            my $id_ptr = unpack('Q', $id_ptr_bytes);
            last unless $id_ptr > 4096;

            my $identifier = $ffi->cast('opaque', 'string', $id_ptr);
            last unless $identifier && $identifier =~ /^\$[a-zA-Z_][a-zA-Z0-9_]{0,100}$/;

            # Try to find matches for this string
            my @offsets;
            for my $match_offset (40, 48, 56) {
                my $matches_ptr_bytes = $ffi->cast('opaque', 'string(8)', $string_base + $match_offset);
                next unless defined $matches_ptr_bytes && length($matches_ptr_bytes) == 8;

                my $matches_ptr = unpack('Q', $matches_ptr_bytes);
                next unless $matches_ptr > 4096;

                # Read match structures
                for my $j (0..199) {
                    my $match_base = $matches_ptr + ($j * 24);  # YR_MATCH size

                    my $offset_bytes = $ffi->cast('opaque', 'string(8)', $match_base + 8);
                    last unless defined $offset_bytes && length($offset_bytes) == 8;

                    my $offset = unpack('Q', $offset_bytes);
                    last if $offset == 0 && $j > 0;

                    use bigint;
                    my $max_offset = 4294967295;
                    no bigint;
                    last if $offset > $max_offset;

                    push @offsets, $offset;
                }

                last if @offsets > 0;
            }

            push @strings, {
                id => $identifier,
                offsets => \@offsets,
            } if @offsets > 0;
        }
    };

    return \@strings;
}

sub scan_buffer {
    my ($self, $buffer, $callback, %opts) = @_;
    die "Compile rules first" unless $self->{rules};

    my $len = length($buffer);
    my $ptr = $ffi->cast('string' => 'opaque', $buffer);
    my @events;

    my $emit_strings = $opts{emit_string_events} // 1;
    my $enable_metadata = $opts{enable_metadata} // 0;  # Disabled by default
    my $enable_offsets = $opts{enable_offsets} // 0;    # Disabled by default

    my $callback_sub = $ffi->closure(sub {
        my ($context, $message, $message_data, $user_data) = @_;

        if ($message == CALLBACK_MSG_RULE_MATCHING) {
            eval {
                return unless $message_data;

                my $found = 0;

                OFFSET_LOOP: for (my $offset = 8; $offset < 256 && !$found; $offset += 8) {
                    my $rule_name;
                    eval {
                        my $identifier_field_addr = $message_data + $offset;
                        my $ptr_bytes = $ffi->cast('opaque', 'string(8)', $identifier_field_addr);
                        my $name_ptr_value = unpack('Q', $ptr_bytes);

                        return if $name_ptr_value < 4096;
                        use bigint;
                        my $max_addr = 140737488355327;  # 0x7fffffffffff
                        no bigint;
                        return if $name_ptr_value > $max_addr;

                        $rule_name = $ffi->cast('opaque', 'string', $name_ptr_value);
                    };

                    if (!$@ && defined $rule_name && $rule_name =~ /^[a-zA-Z_][a-zA-Z0-9_]*$/) {

                        # Extract metadata only if enabled (try record-based approach first)
                        my $metadata;
                        if ($enable_metadata) {
                            $metadata = eval { _extract_metadata_with_records($message_data, 1) };
                            $metadata = undef if $@;
                        }

                        # Always emit rule_match event
                        my $rule_event = YaraFFI::Event->new(
                            event    => 'rule_match',
                            rule     => $rule_name,
                            metadata => $metadata,
                        );
                        push @events, $rule_event;

                        # Call callback immediately for rule_match
                        if (defined $callback && ref $callback eq 'CODE') {
                            eval { $callback->($rule_event) };
                        }

                        # Emit string_match events if enabled
                        if ($emit_strings) {
                            my @string_events;

                            # Try to extract detailed string matches if enabled (record-based)
                            if ($enable_offsets) {
                                my $strings = eval { _extract_string_matches_with_records($message_data, 1) };

                                if (!$@ && $strings && ref $strings eq 'ARRAY' && @$strings) {
                                    for my $string (@$strings) {
                                        push @string_events, YaraFFI::Event->new(
                                            event     => 'string_match',
                                            rule      => $rule_name,
                                            string_id => $string->{id},
                                            offsets   => $string->{offsets},
                                        );
                                    }
                                }
                            }

                            # If no strings extracted or feature disabled, emit generic event
                            if (@string_events == 0) {
                                push @string_events, YaraFFI::Event->new(
                                    event     => 'string_match',
                                    rule      => $rule_name,
                                    string_id => '$',
                                    offsets   => [],
                                );
                            }

                            # Emit all string match events
                            for my $string_event (@string_events) {
                                push @events, $string_event;
                                if (defined $callback && ref $callback eq 'CODE') {
                                    eval { $callback->($string_event) };
                                }
                            }
                        }

                        $found = 1;
                        last OFFSET_LOOP;
                    }
                }
            };
            # Silently ignore callback processing errors to avoid breaking the scan
        }

        return CALLBACK_CONTINUE;
    });

    my $res = yr_rules_scan_mem($self->{rules}, $ptr, $len, 0, $callback_sub, undef, 0);
    return $res;
}

sub DESTROY {
    my ($self) = @_;
    yr_rules_destroy($self->{rules}) if $self->{rules};
    yr_finalize();
}

=head1 METHODS

=head2 new

Creates a new YaraFFI instance.

    my $yara = YaraFFI->new();

=head2 compile($rules)

Compiles YARA rules from a string. Returns 1 on success, 0 on failure.

    my $rules = '...';
    $yara->compile($rules) or die "Failed to compile";

=head2 scan_buffer($data, $callback, %options)

Scans a buffer/string for matches.

    $yara->scan_buffer($data, sub {
        my ($event) = @_;
        print "Matched: $event->{rule}\n";
    });

Options:

=over 4

=item * emit_string_events - Whether to emit string_match events (default: 1)

=item * enable_metadata - Enable metadata extraction (default: 0, experimental)

=item * enable_offsets - Enable offset extraction (default: 0, experimental)

=back

=head2 scan_file($filename, $callback, %options)

Scans a file for matches. Options are the same as scan_buffer.

    $yara->scan_file('/path/to/file', sub {
        my ($event) = @_;
        print "Matched: $event->{rule}\n";
    });

=head1 EXPERIMENTAL FEATURES

Metadata and offset extraction are considered experimental and disabled by default
due to YARA version compatibility issues. Enable them at your own risk:

    $yara->scan_buffer($data, $callback,
        enable_metadata => 1,
        enable_offsets => 1
    );

These features use FFI::Platypus::Record to safely access YARA internal structures,
but structure layouts may vary between YARA versions.

=head1 DEPENDENCIES

=over 4

=item * FFI::Platypus 2.00 or higher

=item * FFI::Platypus::Record (for metadata/offset features)

=item * File::Slurp

=item * libyara.so (YARA library)

=back

=head1 AUTHOR

Mohammad Sajid Anwar, C<< <mohammad.anwar at yahoo.com> >>

=head1 REPOSITORY

L<https://github.com/manwar/YaraFFI>

=head1 BUGS

Please report any bugs or feature requests through the web interface at L<https://github.com/manwar/YaraFFI/issues>.
I will  be notified and then you'll automatically be notified of progress on your
bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc YaraFFI

You can also look for information at:

=over 4

=item * BUG Report

L<https://github.com/manwar/YaraFFI/issues>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/YaraFFI>

=item * Search MetaCPAN

L<https://metacpan.org/dist/YaraFFI>

=back

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2025 Mohammad Sajid Anwar.

This program  is  free software; you can redistribute it and / or modify it under
the  terms  of the the Artistic License (2.0). You may obtain a  copy of the full
license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any  use,  modification, and distribution of the Standard or Modified Versions is
governed by this Artistic License.By using, modifying or distributing the Package,
you accept this license. Do not use, modify, or distribute the Package, if you do
not accept this license.

If your Modified Version has been derived from a Modified Version made by someone
other than you,you are nevertheless required to ensure that your Modified Version
 complies with the requirements of this license.

This  license  does  not grant you the right to use any trademark,  service mark,
tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge patent license
to make,  have made, use,  offer to sell, sell, import and otherwise transfer the
Package with respect to any patent claims licensable by the Copyright Holder that
are  necessarily  infringed  by  the  Package. If you institute patent litigation
(including  a  cross-claim  or  counterclaim) against any party alleging that the
Package constitutes direct or contributory patent infringement,then this Artistic
License to you shall terminate on the date that such litigation is filed.

Disclaimer  of  Warranty:  THE  PACKAGE  IS  PROVIDED BY THE COPYRIGHT HOLDER AND
CONTRIBUTORS  "AS IS'  AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES. THE IMPLIED
WARRANTIES    OF   MERCHANTABILITY,   FITNESS   FOR   A   PARTICULAR  PURPOSE, OR
NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY YOUR LOCAL LAW. UNLESS
REQUIRED BY LAW, NO COPYRIGHT HOLDER OR CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT,
INDIRECT, INCIDENTAL,  OR CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE
OF THE PACKAGE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=cut

1; # End of YaraFFI
