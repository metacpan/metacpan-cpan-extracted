use 5.020;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'WebDyne::Cloudflare',
    VERSION_FROM     => 'lib/WebDyne/Cloudflare.pm',
    ABSTRACT         => 'Cloudflare service capabilities for WebDyne::PAGI',
    AUTHOR           => 'Andrew Speer <andrew.speer@isolutions.com.au>',
    LICENSE          => 'perl_5',
    MIN_PERL_VERSION => '5.020',
    PREREQ_PM        => {
        'Encode'             => 0,
        'Future'             => '0.30',
        'Future::AsyncAwait' => 0,
        'JSON::PP'           => 0,
        'MIME::Base64'       => 0,
        'Scalar::Util'       => 0,
    },
    TEST_REQUIRES => {
        'Test::More' => 0.88,
    },
    PM => {
        'lib/WebDyne/Cloudflare/DurableObject.pm' => '$(INST_LIB)/WebDyne/Cloudflare/DurableObject.pm',
        'lib/WebDyne/Cloudflare/DurableObject/Context.pm' => '$(INST_LIB)/WebDyne/Cloudflare/DurableObject/Context.pm',
        'lib/WebDyne/Cloudflare/DurableObject/Handler.pm' => '$(INST_LIB)/WebDyne/Cloudflare/DurableObject/Handler.pm',
        'lib/WebDyne/Cloudflare/DurableObject/Bytes.pm' => '$(INST_LIB)/WebDyne/Cloudflare/DurableObject/Bytes.pm',
        'lib/WebDyne/Cloudflare/DurableObject/Error.pm' => '$(INST_LIB)/WebDyne/Cloudflare/DurableObject/Error.pm',

        'lib/WebDyne/Cloudflare/SecretsStore.pm' => '$(INST_LIB)/WebDyne/Cloudflare/SecretsStore.pm',
        'lib/WebDyne/Cloudflare/SecretsStore/Error.pm' => '$(INST_LIB)/WebDyne/Cloudflare/SecretsStore/Error.pm',
        'lib/WebDyne/Cloudflare.pm'              => '$(INST_LIB)/WebDyne/Cloudflare.pm',
        'lib/WebDyne/Cloudflare/D1/Session.pm' => '$(INST_LIB)/WebDyne/Cloudflare/D1/Session.pm',
        'lib/WebDyne/Cloudflare/D1.pm'           => '$(INST_LIB)/WebDyne/Cloudflare/D1.pm',
        'lib/WebDyne/Cloudflare/D1/Blob.pm'      => '$(INST_LIB)/WebDyne/Cloudflare/D1/Blob.pm',
        'lib/WebDyne/Cloudflare/D1/Error.pm'     => '$(INST_LIB)/WebDyne/Cloudflare/D1/Error.pm',
        'lib/WebDyne/Cloudflare/D1/Statement.pm' => '$(INST_LIB)/WebDyne/Cloudflare/D1/Statement.pm',
        'lib/WebDyne/Cloudflare/Hyperdrive.pm'           => '$(INST_LIB)/WebDyne/Cloudflare/Hyperdrive.pm',
        'lib/WebDyne/Cloudflare/Hyperdrive/Statement.pm' => '$(INST_LIB)/WebDyne/Cloudflare/Hyperdrive/Statement.pm',
        'lib/WebDyne/Cloudflare/Hyperdrive/Transport.pm' => '$(INST_LIB)/WebDyne/Cloudflare/Hyperdrive/Transport.pm',
        'lib/WebDyne/Cloudflare/Hyperdrive/Codec.pm'     => '$(INST_LIB)/WebDyne/Cloudflare/Hyperdrive/Codec.pm',
        'lib/WebDyne/Cloudflare/Hyperdrive/Error.pm'     => '$(INST_LIB)/WebDyne/Cloudflare/Hyperdrive/Error.pm',
        'lib/WebDyne/Cloudflare/Hyperdrive/Blob.pm'      => '$(INST_LIB)/WebDyne/Cloudflare/Hyperdrive/Blob.pm',
        'lib/WebDyne/Cloudflare/KV.pm'           => '$(INST_LIB)/WebDyne/Cloudflare/KV.pm',
        'lib/WebDyne/Cloudflare/KV/Blob.pm'      => '$(INST_LIB)/WebDyne/Cloudflare/KV/Blob.pm',
        'lib/WebDyne/Cloudflare/KV/Error.pm'     => '$(INST_LIB)/WebDyne/Cloudflare/KV/Error.pm',
        'lib/WebDyne/Cloudflare/R2.pm'           => '$(INST_LIB)/WebDyne/Cloudflare/R2.pm',
        'lib/WebDyne/Cloudflare/R2/Blob.pm'      => '$(INST_LIB)/WebDyne/Cloudflare/R2/Blob.pm',
        'lib/WebDyne/Cloudflare/R2/Error.pm'     => '$(INST_LIB)/WebDyne/Cloudflare/R2/Error.pm',
        'lib/WebDyne/Cloudflare/R2/Object.pm'    => '$(INST_LIB)/WebDyne/Cloudflare/R2/Object.pm',
    },
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources => {
            homepage => 'https://github.com/aspeer/pm-WebDyne-Cloudflare',
            repository => {
                type => 'git',
                url  => 'https://github.com/aspeer/pm-WebDyne-Cloudflare.git',
                web  => 'https://github.com/aspeer/pm-WebDyne-Cloudflare',
            },
            bugtracker => {
                web => 'https://github.com/aspeer/pm-WebDyne-Cloudflare/issues',
            },
        },
        x_authority => 'cpan:ASPEER',
    },
);

sub MY::postamble {
    return <<'MAKE_FRAG';

WORKER_DIR ?= /tmp/webdyne-cloudflare-example

.PHONY: test_js d1_local_init d1_local_query d1_smoke kv_smoke r2_smoke worker_stage

test_js:
	$(NOECHO) npm run test:js

test :: test_js

d1_local_init:
	$(NOECHO) npm install
	$(NOECHO) npx wrangler d1 execute DB --local --config t/fixtures/wrangler.jsonc --file t/fixtures/schema.sql

d1_local_query:
	$(NOECHO) npx wrangler d1 execute DB --local --config t/fixtures/wrangler.jsonc --command "SELECT id, name, note FROM webdyne_d1_example ORDER BY id"

d1_smoke:
	$(NOECHO) npm run smoke:d1 -- $(ARGS)

kv_smoke:
	$(NOECHO) npm run smoke:kv -- $(ARGS)

r2_smoke:
	$(NOECHO) npm run smoke:r2 -- $(ARGS)

worker_stage:
	$(NOECHO) $(PERL) tools/stage-worker.pl "$(WORKER_DIR)"

MAKE_FRAG
}
