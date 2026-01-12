package Wordsmith::Claude::Options;

use 5.020;
use strict;
use warnings;

use Types::Common -types;
use Marlin
    'model?' => Str,              # Claude model to use
    'max_length?' => Int,         # Maximum output length hint
    'preserve_formatting?' => Bool,  # Try to preserve original formatting
    'language?' => Str,           # Output language (for translation)
    'permission_mode?' => Str;    # Claude Agent permission mode (default: bypassPermissions)

=head1 NAME

Wordsmith::Claude::Options - Configuration options for text rewriting

=head1 SYNOPSIS

    use Wordsmith::Claude::Options;

    my $options = Wordsmith::Claude::Options->new(
        model    => 'haiku',    # Use faster/cheaper model
        language => 'Spanish',  # Translate while rewriting
    );

    my $result = rewrite(
        text    => $input,
        mode    => 'casual',
        options => $options,
    )->get;

=head1 DESCRIPTION

Configuration options for the Wordsmith::Claude rewrite function.

=head1 ATTRIBUTES

=head2 model

Claude model to use. Options: 'sonnet', 'opus', 'haiku'.
Defaults to the Claude Agent default.

=head2 max_length

Hint for maximum output length in characters. Not strictly enforced.

=head2 preserve_formatting

Boolean. If true, attempt to preserve the original formatting
(paragraphs, lists, etc.) in the output.

=head2 language

Output language for translation. If set, the rewritten text will
be in this language regardless of the input language.

=head2 permission_mode

Claude Agent permission mode. Defaults to 'bypassPermissions' which
disables the Claude Agent SDK's permission system. This is required
for text rewriting operations where no file system or tool access
is needed. Advanced users can set this to other values if integrating
with systems that require permission prompts.

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut

1;
