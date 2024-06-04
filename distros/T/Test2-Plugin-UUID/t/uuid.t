use Test2::V0;
use Test2::API qw/intercept context/;

require Test2::Require::RealFork;
require Test2::Require::Module;
require Test2::Plugin::UUID;

use Test2::Util::UUID qw/looks_like_uuid/;

my %backends = (
    'UUID'           => [0.35,  []],
    'Data::UUID::MT' => [undef, []],
    'UUID::Tiny'     => [undef, ["Using UUID::Tiny for uuid generation. UUID::Tiny is significantly slower than the 'UUID' or 'Data::UUID::MT' modules, please install 'UUID' or 'Data::UUID::MT' if possible.\n"]],
    'Data::UUID'     => [undef, ["Using Data::UUID to generate UUIDs, this works, but the UUIDs will not be suitible as database keys. Please install the 'UUID', 'Data::UUID::MT' or the slower but pure perl 'UUID::Tiny' cpan modules for better UUIDs.\n"]],
);

for my $backend (sort keys %backends) {
    subtest $backend => sub {
        my ($ver, $warn) = @{$backends{$backend}};
        Test2::Require::Module->import($backend, $ver ? $ver : ());

        subtest import => sub {
            Test2::Util::UUID->clear_cache;

            is(
                warnings { Test2::Plugin::UUID->import(backends => [$backend], warn => 0) },
                [],
                "No warnings",
            );

            my $events = intercept { sub { ok(1) }->() };

            my $uuid_check = validator(is_uuid => sub { looks_like_uuid($_) });

            like(
                $events->[0],
                hash {
                    field uuid  => $uuid_check;
                    field trace => {uuid => $uuid_check, huuid => $uuid_check};
                    field hubs  => [{uuid => $uuid_check}];
                    etc;
                },
                "Used uuids"
            );
        };

        subtest apply => sub {
            Test2::Util::UUID->clear_cache;

            is(
                warnings {
                    is(
                        Test2::Plugin::UUID->apply_plugin(backends => [$backend], warn => 0),
                        $backend,
                        "Used correct backend",
                    );
                },
                [],
                "No warnings",
            );

            my $events = intercept { sub { ok(1) }->() };

            my $uuid_check = validator(is_uuid => sub { looks_like_uuid($_) });

            like(
                $events->[0],
                hash {
                    field uuid  => $uuid_check;
                    field trace => {uuid => $uuid_check, huuid => $uuid_check};
                    field hubs  => [{uuid => $uuid_check}];
                    etc;
                },
                "Used uuids"
            );
        };

        subtest util => sub {
            $SIG{__WARN__} = sub {
                return if $_[0] =~ m/redefine/;
                die "Got warning: $_[0]";
            };

            Test2::Util::UUID->clear_cache;
            Test2::Util::UUID->import('gen_uuid', 'uuid2bin', 'bin2uuid', 'GEN_UUID_BACKEND', 'looks_like_uuid', warn => 0, backends => [$backend]);
            imported_ok('gen_uuid', 'GEN_UUID_BACKEND', 'looks_like_uuid');
            is(GEN_UUID_BACKEND(), $backend, "Got correct backend");
            ok(looks_like_uuid(gen_uuid()), "Generated a UUID");
        };

        subtest bin_string_convert => sub {
            my $subs;
            warnings { $subs = Test2::Util::UUID->get_gen_uuid(backends => [$backend]) },

            my $uuid = $subs->{gen_uuid}->();
            ok(looks_like_uuid($uuid), "Looks like a uuid ($uuid)");
            my $bin = $subs->{uuid2bin}->($uuid);
            isnt($bin, $uuid, "Not the same");
            is($subs->{bin2uuid}->($bin), $uuid, "Round trip!");
        };

        subtest fork => sub {
            Test2::Require::RealFork->import();
            Test2::Require::Module->import('Atomic::Pipe');

            Test2::Util::UUID->clear_cache;

            my $subs;
            like(
                warnings { $subs = Test2::Util::UUID->get_gen_uuid(backends => [$backend]) },
                $warn,
                "Got expected warnings"
            );

            is($subs->{GEN_UUID_BACKEND}->(), $backend, "Used correct backend");
            my $gen_uuid = $subs->{gen_uuid};

            my ($r, $w) = Atomic::Pipe->pair;

            my @uuids;
            push @uuids => $gen_uuid->() for 1 .. 5;

            my @pids;
            for (1 .. 4) {
                my $pid = fork // die "Could not fork: $!";

                if ($pid) {
                    push @pids => $pid;
                    next;
                }

                $w->write_message($gen_uuid->()) for 1 .. 10;

                exit 0;
            }

            push @uuids => $gen_uuid->() for 1 .. 5;

            waitpid($_, 0) for @pids;

            $w->close;

            while (my $new_uuid = $r->read_message) {
                push @uuids => $new_uuid;
            }

            $r->close;

            is(@uuids, 50, "Got 50 uuids");

            my %seen;
            $seen{$_}++ for @uuids;

            ok(!(grep { $_ > 1 } values %seen), "Did not generate any duplicate UUIDs");
        };
    };
}

done_testing;
