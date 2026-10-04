use strict;
use warnings;

use Test2::V0;

use Unblock::HTTP3::Capsule;
use Unblock::HTTP3::Capsule::Parser;

my $capsule = Unblock::HTTP3::Capsule->new(
    type  => 42,
    value => 'abc',
);

is($capsule->type, '42', 'Capsule exposes its type');
is($capsule->value, 'abc', 'Capsule exposes its value');
is($capsule->length, 3, 'Capsule exposes its value length');
is($capsule->encode, "\x2a\x03abc",
    'Capsule uses QUIC varints for type and length');

my $wide = Unblock::HTTP3::Capsule->new(
    type  => 65,
    value => '',
);

is($wide->encode, "\x40\x41\x00",
    'Capsule type can use a multi-byte varint');

my $parser = Unblock::HTTP3::Capsule::Parser->new;
my $wire = $capsule->encode . $wide->encode;

for my $byte (split //, $wire) {
    $parser->feed($byte);
}

my $first = $parser->next_capsule;
isa_ok($first, ['Unblock::HTTP3::Capsule']);
is($first->type, '42',
    'incremental parser preserves first Capsule type');
is($first->value, 'abc',
    'incremental parser preserves first Capsule value');

my $second = $parser->next_capsule;
isa_ok($second, ['Unblock::HTTP3::Capsule']);
is($second->type, '65',
    'incremental parser preserves second Capsule type');
is($second->value, '',
    'incremental parser accepts empty Capsule values');
is($parser->next_capsule, undef,
    'polling parser has no extra Capsules');

$parser->finish;
ok($parser->is_finished,
    'incremental parser finishes on a Capsule boundary');

my $grease_parser = Unblock::HTTP3::Capsule::Parser->new;
$grease_parser->feed(
    Unblock::HTTP3::Capsule->new(
        type  => 23,
        value => 'grease',
    )->encode
    . Unblock::HTTP3::Capsule->new(
        type  => 42,
        value => 'after-grease',
    )->encode
);

my $after_grease = $grease_parser->next_capsule;
is($after_grease->type, '42',
    'GREASE Capsule type is silently ignored');
is($after_grease->value, 'after-grease',
    'parser continues after a GREASE Capsule');
$grease_parser->finish;

like(
    dies {
        Unblock::HTTP3::Capsule::Parser->new(
            handlers => {
                23 => sub { },
            },
        );
    },
    qr/reserved for greasing/,
    'GREASE Capsule type cannot acquire handler semantics',
);

my @handled;

my $dispatch = Unblock::HTTP3::Capsule::Parser->new(
    max_capsule_size => 2,
    handlers => {
        42 => sub {
            my ($parser, $capsule) = @_;
            push @handled, [ $capsule->type, $capsule->value ];
        },
    },
);

$dispatch->feed(
    Unblock::HTTP3::Capsule->new(
        type  => 99,
        value => 'ignored',
    )->encode
);

$dispatch->feed(
    Unblock::HTTP3::Capsule->new(
        type  => 42,
        value => 'ok',
    )->encode
);

is(
    \@handled,
    [ [ '42', 'ok' ] ],
    'handler dispatch silently skips unregistered Capsule types',
);

$dispatch->finish;

my $callback_failure = Unblock::HTTP3::Capsule::Parser->new(
    handlers => {
        42 => sub {
            die "application Capsule handler failed\n";
        },
    },
);

like(
    dies {
        $callback_failure->feed(
            Unblock::HTTP3::Capsule->new(
                type  => 42,
                value => 'callback-test',
            )->encode
        );
    },
    qr/application Capsule handler failed/,
    'application Capsule handler errors propagate unchanged',
);

my $limited = Unblock::HTTP3::Capsule::Parser->new(
    max_capsule_size => 2,
);

like(
    dies {
        $limited->feed(
            Unblock::HTTP3::Capsule->new(
                type  => 7,
                value => 'abc',
            )->encode
        );
    },
    qr/exceeds configured maximum 2/,
    'retained Capsule values are bounded',
);

my $truncated = Unblock::HTTP3::Capsule::Parser->new;
$truncated->feed("\x2a\x05ab");

like(
    dies { $truncated->finish },
    qr/truncated Capsule/,
    'truncated final Capsule is rejected',
);

my $split_header = Unblock::HTTP3::Capsule::Parser->new;
my $large_type = Unblock::HTTP3::Capsule->new(
    type  => 16_384,
    value => 'x',
)->encode;

$split_header->feed(substr($large_type, 0, 1));
is($split_header->next_capsule, undef,
    'partial multi-byte Capsule type waits for more input');

$split_header->feed(substr($large_type, 1));

my $large_parsed = $split_header->next_capsule;
is($large_parsed->type, '16384',
    'multi-byte Capsule type parses across feed boundaries');
is($large_parsed->value, 'x',
    'Capsule value follows a fragmented type and length');

$split_header->finish;

done_testing;
