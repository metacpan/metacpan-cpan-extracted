# Test::FitNesse::Slim documentation

This index separates user instructions, fixture contracts, implementation
design, compatibility limits, and recorded acceptance evidence. The
README is the short installation path; the documents below are the
authoritative source for their named topics.

## Install and use

- [README](../README.md) — installation, pipe and TCP startup, external fixture
  discovery, and the first FitNesse test.
- [Test::FitNesse::Slim POD](../lib/Test/FitNesse/Slim.pm) — installed module purpose and
  executable overview.
- [perl-slim POD](../bin/perl-slim) — options, invocation, exit status, and
  FitNesse configuration.
- [CLI runner configuration](fitnesse-cli-runner-configuration.md) —
  verified FitNesse v20251025 command-line variable overrides.
- [Pipe transport](slim-pipe-transport.md) — v0.5 child-process lifecycle,
  framing, and diagnostic tunneling.
- [License terms](../LICENSE) — choose either GPL version 1 or later, or
  Artistic License 1.0 for Test::FitNesse::Slim's original code. The full texts are
  [GPL](../LICENSE.GPL-1.0-or-later) and
  [Artistic](../LICENSE.Artistic-1.0); scoped fixture notices and the
  separate CPL text are in [THIRD-PARTY-NOTICES.md](../THIRD-PARTY-NOTICES.md).

## Fixture authoring

- [Fixture conversion](fixture-conversion.md) — constructor and method
  signatures, scalar and sequence converters, enums, names, and examples.
- [Standalone counter fixture](../examples/lib/Example/Counter.pm) and
  [FitNesse page](../examples/fitnesse/CounterTest.wiki) — the independent
  packaging example.
- [Order-management acceptance suite](../examples/order-management/README.md)
  — a business-readable suite running against the installed distribution,
  with [business rules](../examples/order-management/BUSINESS-RULES.md),
  [test-author guidance](../examples/order-management/TEST-AUTHORS.md),
  [developer guidance](../examples/order-management/DEVELOPERS.md), and a
  [usability audit](../examples/order-management/USABILITY-AUDIT.md).

## Architecture and development

- [DESIGN](../DESIGN.md) — server layers, executor state, dispatch, and
  acceptance-infrastructure boundaries.
- [Development and verification](development.md) — local commands, CI
  gates, packaging smoke test, and generated diagnostics.
- [AGENTS.md](../AGENTS.md) — repository-specific contributor workflow.

## Protocol and compatibility

- [Protocol conformance matrix](slim-protocol-conformance.md) — audited
  requirements, implementation locations, evidence, and gaps.
- [Malformed input policy](slim-protocol-malformed-input.md) — framing,
  deserialization, defensive limits, and failure isolation.
- [SLiM expressions](slim-symbol-expression-compatibility.md) — Java-only
  FitNesse table expressions and the Perl compatibility boundary.
- [Comparator and rendering context](fitnesse-rendering-comparator-compatibility.md)
  — verified nested FitNesse context limitations.

## Acceptance evidence and inventories

- [Acceptance coverage](fitnesse-acceptance-coverage.md) — exact isolated
  and native-suite set comparison, with its
  [machine-readable inventory](fitnesse-acceptance-coverage.json).
- [Individual-page baseline](fitnesse-slim-acceptance-baseline.md) and
  [JSON baseline](fitnesse-slim-acceptance-baseline.json).
- [Native-suite audit](fitnesse-native-suite-audit.md) and
  [machine-readable audit](fitnesse-native-suite-audit.json).
- [Native-suite baseline](fitnesse-slim-native-suite-baseline.json).
- [Fixture gap triage](fitnesse-native-fixture-gap-triage.md) and
  [machine-readable triage](fitnesse-native-fixture-gap-triage.json).
- [Pipe migration findings](fitnesse-acceptance-pipe-migration.md) —
  reviewed transport-specific cases and acceptance behavior.

The inventories and JSON files retain historical reference evidence and
reviewed expected behavior. They are not regenerated automatically. A
baseline match means no unreviewed change against those expectations; it
does not mean every upstream assertion is conformant.
