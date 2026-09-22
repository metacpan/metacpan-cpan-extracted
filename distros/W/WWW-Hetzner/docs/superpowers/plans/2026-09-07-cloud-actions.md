# Cloud Actions Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.
>
> **Repo delegation lock:** every task here touches behavior-relevant code and MUST be executed by a `www-hetzner-*` agent (worker / test-writer / doc-writer), never by a generic subagent and never by the orchestrating main agent directly. The recommended agent is named per task. Those agents get `www-hetzner-core`, `getty-perl-moo` and the release skills force-loaded; a generic agent does not.

**Goal:** Make every mutating Cloud call return a first-class `Action` object with progress, error and blocking `->wait`, so a failed action stops looking like success.

**Architecture:** A new `WWW::Hetzner::Cloud::Action` entity carries status/progress/error and knows how to `refresh` and `wait` by polling through the existing `io->call` seam using an injectable `sleeper`. A new `HasActions` controller role turns raw action hashes into `Action` objects; a new `HasAction` entity role hangs the creating action off `create`d entities. The CLI gets a `WaitsForAction` role that waits by default and offers `--no-wait`.

**Tech Stack:** Perl, Moo / Moo::Role, `MooX::Cmd` + `MooX::Options` (CLI), `JSON::MaybeXS`, `Carp`. Tests: `Test::More` + the mock-fixture harness `Test::WWW::Hetzner::MockIO` (`t/lib/`), fixtures in `t/fixtures/*.json`.

**Spec:** `docs/superpowers/specs/2026-09-06-cloud-actions-design.md` — read it alongside this plan. The two open API questions are resolved in its section "Vor der Implementierung geklärt" (verified against `https://docs.hetzner.cloud/cloud.spec.json`, 2026-09-07).

## Global Constraints

- **Tests never hit the network.** Every test injects `Test::WWW::Hetzner::MockIO` via `mock_cloud(%routes)`. No test needs a real token. Copied verbatim from house rules.
- **Never reach past the IO seam.** All requests go `_build_request` → `io->call` → `_parse_response` (i.e. through `$self->client->get/post/...`). Never call LWP directly — it would pass local tests yet break the async client and the mock harness at once.
- **Do not change the *form* of `_build_request` / `_parse_response`.** Their shapes are borrowed by `p5-net-async-hetzner`. Adding `sleeper` and new call sites is fine; changing these two methods' signatures/return shape is a ticket on that repo's board, never a silent cross-repo edit. This plan does not touch their form.
- **No release.** `dzil build` / `dzil test` / `prove -lr t/` anytime. `dzil release`, tag, push, upload: STRICTLY forbidden without the maintainer's explicit go-ahead.
- **Poll path:** global `GET /actions/{id}` is current (not deprecated); `poll_path` defaults to `/actions` and `refresh` appends `/$id`.
- **Version string:** modules in this distribution carry `our $VERSION = '0.101';` — match the exact string used by sibling files when creating a new module.
- **Breaking change goes in `Changes`.** The 66 action methods change their return type; the CLI is unaffected (it discards return values today).

---

## File Structure

New files:
- `lib/WWW/Hetzner/Cloud/Action.pm` — the Action entity (attrs, predicates, `refresh`, `wait`, `data`).
- `lib/WWW/Hetzner/Cloud/API/Actions.pm` — read-only controller (`get`, `list`).
- `lib/WWW/Hetzner/Cloud/Role/HasActions.pm` — `_wrap_action` / `_wrap_actions`, consumed by the 8 action-emitting controllers.
- `lib/WWW/Hetzner/Cloud/Role/HasAction.pm` — `action` / `next_actions` attrs, consumed by the 8 create-returning entities.
- `lib/WWW/Hetzner/CLI/Role/WaitsForAction.pm` — `--no-wait` option + `handle_action` helper.
- `t/cloud_actions.t` — the new Action test file.
- `t/fixtures/actions_get.json`, `t/fixtures/actions_list.json` — new fixtures in `running`/`success`/`error` states.

Modified files:
- `lib/WWW/Hetzner/Role/HTTP.pm` — add `sleeper` attribute.
- `lib/WWW/Hetzner/Cloud.pm` — add `actions` controller accessor.
- `lib/WWW/Hetzner/Cloud/API/{Servers,Volumes,FloatingIPs,LoadBalancers,PrimaryIPs,Certificates,Firewalls,Networks}.pm` — consume `HasActions`; action-methods return `Action`; `create` populates entity action(s).
- `lib/WWW/Hetzner/Cloud/{Server,Volume,FloatingIP,LoadBalancer,PrimaryIP,Certificate,PlacementGroup,Zone}.pm` — consume `HasAction`.
- `lib/WWW/Hetzner/Cloud/Firewall.pm` — add plural `actions` attribute (not `HasAction`).
- `lib/WWW/Hetzner/CLI/Cmd/**` — mutating subcommands consume `WaitsForAction`.
- `t/fixtures/{placement_groups,zones,volumes,firewalls}_create.json` — align to the real API.
- `t/cloud_{servers,volumes,floating_ips,load_balancers,primary_ips,networks}.t` — assert the new `->action->...` shape.
- `Changes` — breaking-change entry.

---

## Task 1: Injectable `sleeper` on `Role::HTTP`

**Recommended agent:** `www-hetzner-worker`

**Files:**
- Modify: `lib/WWW/Hetzner/Role/HTTP.pm` (after the `io` attribute, ~line 56)
- Test: `t/role_http_sleeper.t` (new) — or fold the assertion into Task 2's `t/cloud_actions.t`. A standalone file is cleaner for this atom.

**Interfaces:**
- Produces: `$client->sleeper` — a rw accessor holding a coderef `sub ($seconds) { ... }`, default `sub { sleep $_[0] }`. Consumed by `Action::wait` in Task 2.

- [ ] **Step 1: Write the failing test**

```perl
use Test::More;
use WWW::Hetzner::Cloud;
my $c = WWW::Hetzner::Cloud->new(token => 't');
my @slept;
$c->sleeper(sub { push @slept, $_[0] });
$c->sleeper->(3);
is_deeply(\@slept, [3], 'injected sleeper is called with the interval');
done_testing;
```

- [ ] **Step 2: Run it, verify it fails** — `prove -lr t/role_http_sleeper.t` → FAIL (`Can't locate object method "sleeper"`).

- [ ] **Step 3: Add the attribute** in `lib/WWW/Hetzner/Role/HTTP.pm` next to `io`:

```perl
has sleeper => (
    is      => 'rw',
    default => sub { sub { sleep $_[0] } },
);
```

Add an `=attr sleeper` POD block matching the file's inline-POD style (Task 8 can expand it; a one-line stub is fine here).

- [ ] **Step 4: Run it, verify it passes.**

- [ ] **Step 5: Commit** — `git commit -am "Add injectable sleeper to Role::HTTP (karr #2)"` (with the repo's Co-Authored-By / Claude-Session trailers).

---

## Task 2: `Action` entity + `Actions` controller

**Recommended agent:** `www-hetzner-worker` (TDD, writes its own tests + fixtures). If fixtures are handed off, `www-hetzner-test-writer` authors `t/fixtures/actions_*.json` and `t/cloud_actions.t`.

**Files:**
- Create: `lib/WWW/Hetzner/Cloud/Action.pm`
- Create: `lib/WWW/Hetzner/Cloud/API/Actions.pm`
- Modify: `lib/WWW/Hetzner/Cloud.pm` (add `actions` accessor)
- Create: `t/fixtures/actions_get.json`, `t/fixtures/actions_list.json`
- Test: `t/cloud_actions.t`

**Interfaces:**
- Produces:
  - `WWW::Hetzner::Cloud::Action->new(client => $c, poll_path => '/actions', %$action_hash)` where `%$action_hash` has keys `id, command, status, progress, started, finished, resources, error`.
  - `$action->id / command / status / progress / started / finished / resources / error / data`
  - `$action->is_running / is_success / is_error` → bool
  - `$action->error_message` → `error.message` or `undef`
  - `$action->refresh` → reloads via `GET $poll_path/$id`, updates status/progress, returns `$self`
  - `$action->wait(interval => 1, timeout => 120)` → polls until terminal; returns `$self` on success; `croak`s on `error` (with `error.message`) and on timeout (with id + command)
  - `$cloud->actions->get($id)` → `Action`; `$cloud->actions->list(%params)` → arrayref of `Action`
- Consumes: `$client->sleeper` (Task 1); the `io->call` seam via `$client->get`.

- [ ] **Step 1: Fixtures.** Create `t/fixtures/actions_get.json` (single `{ "action": {...} }`, status `running`) modelled on `t/fixtures/servers_action.json`, and `t/fixtures/actions_list.json` (`{ "actions": [ running, success, error ], "meta": {...} }`). Include one action with `status: "error"` and a populated `error.message` (e.g. `"server does not exist"`).

- [ ] **Step 2: Write failing tests** in `t/cloud_actions.t`:

```perl
use strict; use warnings;
use Test::More;
use lib 't/lib';
use Test::WWW::Hetzner::Mock;

# 1. attributes + predicates from fixture
my $cloud = mock_cloud('GET /actions/13343' => sub { load_fixture('actions_get') });
my $a = $cloud->actions->get(13343);
isa_ok($a, 'WWW::Hetzner::Cloud::Action');
is($a->command, 'poweron', 'command');
ok($a->is_running, 'is_running');
ok(!$a->is_success && !$a->is_error, 'not terminal');

# 3. wait success path: running -> running -> success, counting polls via sleeper
{
    my @states = ('running', 'running', 'success');
    my $i = 0;
    my $c = mock_cloud('GET /actions/1' => sub {
        my $s = $states[$i] // 'success'; $i++;
        return { action => { id => 1, command => 'create_server', status => $s,
                             progress => ($s eq 'success' ? 100 : 0), error => undef } };
    });
    my @slept;
    $c->sleeper(sub { push @slept, $_[0] });
    my $act = $c->actions->get(1);   # first GET -> running
    $act->wait(interval => 5);
    ok($act->is_success, 'wait resolves to success');
    is_deeply(\@slept, [5, 5], 'slept between polls, no real seconds');
}

# 4. wait error path croaks with the API message
{
    my $c = mock_cloud('GET /actions/2' => sub {
        { action => { id => 2, command => 'create_server', status => 'error',
                      error => { code => 'x', message => 'boom' } } };
    });
    my $act = $c->actions->get(2);
    eval { $act->wait; 1 };
    like($@, qr/boom/, 'wait croaks with error.message');
}

# 5. wait timeout croaks with id + command
{
    my $c = mock_cloud('GET /actions/3' => sub {
        { action => { id => 3, command => 'create_server', status => 'running', error => undef } };
    });
    $c->sleeper(sub {});   # no real sleep
    my $act = $c->actions->get(3);
    eval { $act->wait(interval => 1, timeout => 3); 1 };
    like($@, qr/\b3\b.*create_server|create_server.*\b3\b/, 'timeout names id and command');
}

done_testing;
```

- [ ] **Step 3: Run tests, verify they fail** — `prove -lr t/cloud_actions.t` → FAIL (no `Action` class / no `actions` accessor).

- [ ] **Step 4: Implement `lib/WWW/Hetzner/Cloud/Action.pm`.** Follow the `Cloud::Server` entity pattern: `has _client (init_arg => 'client', weak_ref => 1)`, plain attrs for the action fields, `namespace::clean`. Sketch of the behavior (match house Moo idiom; `status`/`progress` are `rwp`):

```perl
has poll_path => ( is => 'ro', default => sub { '/actions' } );
has command   => ( is => 'ro' );
has status    => ( is => 'rwp' );
has progress  => ( is => 'rwp' );
has error     => ( is => 'rwp' );
# ... started, finished, resources, id, data ...

sub is_running { $_[0]->status eq 'running' }
sub is_success { $_[0]->status eq 'success' }
sub is_error   { $_[0]->status eq 'error' }
sub error_message { my $e = $_[0]->error; ref $e ? $e->{message} : undef }

sub refresh {
    my ($self) = @_;
    my $r = $self->_client->get($self->poll_path . '/' . $self->id);
    my $d = $r->{action};
    $self->_set_status($d->{status});
    $self->_set_progress($d->{progress});
    $self->_set_error($d->{error});
    return $self;
}

sub wait {
    my ($self, %opts) = @_;
    my $interval = $opts{interval} // 1;
    my $timeout  = $opts{timeout}  // 120;
    my $waited = 0;
    while ($self->is_running) {
        croak sprintf('Timed out waiting for action %s (%s)', $self->id, $self->command)
            if $waited >= $timeout;
        $self->_client->sleeper->($interval);
        $waited += $interval;
        $self->refresh;
    }
    croak sprintf('Action %s (%s) failed: %s',
        $self->id, $self->command, $self->error_message // 'unknown')
        if $self->is_error;
    return $self;
}
```

Note the terminal-check ordering: `wait` on an already-terminal action must not sleep. The success-path test above expects 2 sleeps for `running → running → success` (get returns running; wait sleeps+refresh→running; sleeps+refresh→success).

- [ ] **Step 5: Implement `lib/WWW/Hetzner/Cloud/API/Actions.pm`** on the `Servers` controller pattern (`has client (weak_ref)`, `_wrap`/`_wrap_list`):

```perl
sub _wrap {
    my ($self, $data) = @_;
    WWW::Hetzner::Cloud::Action->new(client => $self->client, %$data);
}
sub get {
    my ($self, $id) = @_;
    croak "Action ID required" unless $id;
    $self->_wrap($self->client->get("/actions/$id")->{action});
}
sub list {
    my ($self, %params) = @_;
    $self->_wrap_list($self->client->get('/actions', params => \%params)->{actions} // []);
}
```

- [ ] **Step 6: Wire `actions` into `lib/WWW/Hetzner/Cloud.pm`** exactly like the existing `servers` accessor (find how `servers` is declared and mirror it for `actions` → `WWW::Hetzner::Cloud::API::Actions`).

- [ ] **Step 7: Run tests, verify they pass** — `prove -lr t/cloud_actions.t`.

- [ ] **Step 8: Commit** — `"Add Cloud::Action entity, Actions controller and ->wait (karr #2)"`.

---

## Task 3: `HasActions` controller role (`_wrap_action` / `_wrap_actions`)

**Recommended agent:** `www-hetzner-worker`

**Files:**
- Create: `lib/WWW/Hetzner/Cloud/Role/HasActions.pm`
- Test: extend `t/cloud_actions.t`

**Interfaces:**
- Produces (on any consuming controller): `$self->_wrap_action($hash_or_undef)` → `Action` or `undef`; `$self->_wrap_actions($arrayref_or_undef)` → arrayref of `Action` (empty if none).
- Consumes: `$self->client` (present on every controller); `WWW::Hetzner::Cloud::Action`.

- [ ] **Step 1: Failing test** — in `t/cloud_actions.t`, drive a real consumer (Servers) after Task 5 wiring, or unit-test the role directly via a throwaway consumer:

```perl
{
    package My::WrapTest;
    use Moo;
    has client => (is => 'ro');
    with 'WWW::Hetzner::Cloud::Role::HasActions';
}
my $w = My::WrapTest->new(client => $cloud);
is($w->_wrap_action(undef), undef, 'undef action -> undef');
isa_ok($w->_wrap_action({ id => 5, status => 'running' }), 'WWW::Hetzner::Cloud::Action');
is(scalar @{ $w->_wrap_actions([{id=>1,status=>'running'},{id=>2,status=>'success'}]) }, 2, 'plural');
is_deeply($w->_wrap_actions(undef), [], 'undef list -> empty arrayref');
```

- [ ] **Step 2: Run, verify fail.**

- [ ] **Step 3: Implement the role:**

```perl
package WWW::Hetzner::Cloud::Role::HasActions;
use Moo::Role;
use WWW::Hetzner::Cloud::Action;
requires 'client';
sub _wrap_action  { my ($s,$h)=@_; defined $h ? WWW::Hetzner::Cloud::Action->new(client=>$s->client, %$h) : undef }
sub _wrap_actions { my ($s,$l)=@_; [ map { $s->_wrap_action($_) } @{ $l // [] } ] }
1;
```

- [ ] **Step 4: Run, verify pass.**
- [ ] **Step 5: Commit** — `"Add HasActions controller role (karr #2)"`.

---

## Task 4: Controller action-methods return `Action`

**Recommended agent:** `www-hetzner-worker`

This is the return-contract change: 38 methods across 8 controllers. Do it **one controller file at a time**, each with its existing test flipped to the new shape first (red), then the methods converted (green), then commit. That keeps every commit green and reviewable per resource.

**Files (per resource, repeat the cycle):**
- Modify: `lib/WWW/Hetzner/Cloud/API/<Resource>.pm` — `with 'WWW::Hetzner::Cloud::Role::HasActions';` and wrap each action-method return.
- Modify: the resource's existing test (`t/cloud_<resource>.t`) where it reads `$result->{action}{...}`.

**Interfaces:**
- Consumes: `_wrap_action` (Task 3).
- Produces: every method that today returns `$self->client->post(".../actions/...", {...})` now returns an `Action`.

Resources / test files: `servers` (`t/cloud_servers.t`), `volumes` (`t/cloud_volumes.t`), `floating_ips` (`t/cloud_floating_ips.t`), `load_balancers` (`t/cloud_load_balancers.t`), `primary_ips` (`t/cloud_primary_ips.t`), `networks` (`t/cloud_networks.t`), plus `certificates` and `firewalls` (add assertions if none exist).

- [ ] **Step 1 (per resource): Flip the existing test first.** In e.g. `t/cloud_servers.t`, change assertions from `$result->{action}{command}` to `$result->action->command` and `isa_ok($result, 'WWW::Hetzner::Cloud::Action')`. Run → FAIL (still a hashref).

- [ ] **Step 2: Convert the methods.** Pattern, using `power_on` as the model (`lib/WWW/Hetzner/Cloud/API/Servers.pm:234`):

```perl
# before
return $self->client->post("/servers/$id/actions/poweron", {});
# after
return $self->_wrap_action(
    $self->client->post("/servers/$id/actions/poweron", {})->{action}
);
```

Apply to every `post(".../actions/...")` return in the file. Add `with 'WWW::Hetzner::Cloud::Role::HasActions';` near the other `with`/`use` lines.

- [ ] **Step 3: Run the resource's test, verify pass.**
- [ ] **Step 4: `prove -lr t/`** to confirm no other test regressed on that resource.
- [ ] **Step 5: Commit** — `"Cloud <Resource> action methods return Action (karr #2)"`.
- [ ] **Repeat Steps 1–5 for each of the 8 controllers.**

---

## Task 5: `HasAction` entity role + `create` populates the action; align stale fixtures

**Recommended agent:** `www-hetzner-worker`; fixture edits may go to `www-hetzner-test-writer`.

**Files:**
- Create: `lib/WWW/Hetzner/Cloud/Role/HasAction.pm`
- Modify (consume `HasAction`, singular): `lib/WWW/Hetzner/Cloud/{Server,Volume,FloatingIP,LoadBalancer,PrimaryIP,Certificate,PlacementGroup,Zone}.pm`
- Modify (plural attr): `lib/WWW/Hetzner/Cloud/Firewall.pm`
- Modify (populate on create): `lib/WWW/Hetzner/Cloud/API/{Servers,Volumes,FloatingIPs,LoadBalancers,PrimaryIPs,Certificates,PlacementGroups,Zones}.pm` and `Firewalls.pm`
- Modify fixtures: `t/fixtures/{placement_groups,zones,volumes}_create.json`, and `t/fixtures/firewalls_create.json` (non-empty `actions` for the test)
- Test: extend the relevant `t/cloud_<resource>.t`

**Interfaces:**
- `HasAction` produces on the entity: `action` (an `Action` or `undef`), `next_actions` (arrayref of `Action`, default `[]`). `action` reflects creation state and is `undef` after `->refresh` (documented, not maintained).
- `Firewall` produces: `actions` (arrayref of `Action`).
- Controllers' `create` consumes `_wrap_action` / `_wrap_actions` (Task 3) and passes the built objects into `_wrap`.

- [ ] **Step 1: Align fixtures to the real API** (verified against `cloud.spec.json`):
  - `placement_groups_create.json`: add a singular `"action": { ... status: "running" ... }` sibling to `placement_group` (nullable in reality — keep a second scenario or a helper that omits it for the undef test).
  - `zones_create.json`: add a singular `"action": { ... }`.
  - `volumes_create.json`: add `"next_actions": [ ... ]` alongside the existing `action`.
  - `firewalls_create.json`: change `"actions": []` to a one-element list so the plural path is exercised.

- [ ] **Step 2: Failing tests.** For one singular resource (e.g. server):

```perl
my $cloud = mock_cloud('POST /servers' => sub { load_fixture('servers_create') });
my $server = $cloud->servers->create(name=>'x', server_type=>'cx23', image=>'debian-13');
isa_ok($server->action, 'WWW::Hetzner::Cloud::Action', 'create action is an Action');
is($server->action->command, 'create_server', 'action command');
is(scalar @{ $server->next_actions }, 1, 'next_actions populated');
```

For the plural (firewall):

```perl
my $c = mock_cloud('POST /firewalls' => sub { load_fixture('firewalls_create') });
my $fw = $c->firewalls->create(name => 'fw');
isa_ok($fw->actions->[0], 'WWW::Hetzner::Cloud::Action', 'firewall create yields actions list');
```

For the nullable (placement group): assert `is($pg->action, undef)` on a fixture without an action.

- [ ] **Step 3: Run, verify fail.**

- [ ] **Step 4: Implement `HasAction` role:**

```perl
package WWW::Hetzner::Cloud::Role::HasAction;
use Moo::Role;
has action       => ( is => 'ro' );                    # Action or undef
has next_actions => ( is => 'ro', default => sub { [] } );
1;
```

Add `with 'WWW::Hetzner::Cloud::Role::HasAction';` to the 8 singular entities. Add `has actions => (is=>'ro', default=>sub{[]});` to `Firewall.pm`.

- [ ] **Step 5: Populate on create.** In each singular create-controller, change the `create` return from `$self->_wrap($result->{server})` to pass the built action(s). Because `_wrap` currently takes only `$data`, widen it to accept extra pairs:

```perl
sub _wrap {
    my ($self, $data, %extra) = @_;
    WWW::Hetzner::Cloud::Server->new(client => $self->client, %$data, %extra);
}
# in create():
return $self->_wrap(
    $result->{server},
    action       => $self->_wrap_action($result->{action}),
    next_actions => $self->_wrap_actions($result->{next_actions}),
);
```

For `Firewalls::create`: `return $self->_wrap($result->{firewall}, actions => $self->_wrap_actions($result->{actions}));`. Ensure each of these controllers `with 'WWW::Hetzner::Cloud::Role::HasActions'` (done in Task 4 for the 8 action-emitting ones; `PlacementGroups` and `Zones` do NOT emit standalone actions but DO need `_wrap_action` for create — add the `with` there too).

- [ ] **Step 6: Run the touched resource tests, verify pass; then `prove -lr t/`.**
- [ ] **Step 7: Commit** — `"Hang creation Action off created entities via HasAction (karr #2)"`.

---

## Task 6: Entity mirrored action-methods return `Action`

**Recommended agent:** `www-hetzner-worker`

Entity methods like `$server->power_on` delegate to the controller (`$self->_client->servers->power_on($self->id)`), so most inherit the new return type automatically once Task 4 lands. This task **verifies** that and fixes any entity method that re-implements the call instead of delegating.

**Files:**
- Modify (only where a method bypasses the controller): `lib/WWW/Hetzner/Cloud/{Server,Volume,FloatingIP,LoadBalancer,PrimaryIP,Certificate,Firewall,Network}.pm`
- Test: extend the relevant `t/cloud_<resource>.t`

- [ ] **Step 1: Add a failing entity-level assertion** for one resource:

```perl
my $server = $cloud->servers->get(123);   # servers_show fixture
# power_on route returns servers_action fixture
isa_ok($server->power_on, 'WWW::Hetzner::Cloud::Action', 'entity power_on returns Action');
```

- [ ] **Step 2: Run, verify fail** (if the entity method bypasses the controller) or pass (if it delegates). For any that bypass, route them through the controller so wrapping is single-sourced.
- [ ] **Step 3: `prove -lr t/`.**
- [ ] **Step 4: Commit** — `"Entity action methods return Action (karr #2)"`.

---

## Task 7: CLI `WaitsForAction` role — wait by default, `--no-wait`

**Recommended agent:** `www-hetzner-worker`

**Files:**
- Create: `lib/WWW/Hetzner/CLI/Role/WaitsForAction.pm`
- Modify: mutating subcommands under `lib/WWW/Hetzner/CLI/Cmd/**` (start with `Server/Cmd/Poweron.pm` as the reference)
- Test: a CLI test if the suite has one for commands; otherwise a focused unit test of `handle_action`.

**Interfaces:**
- Produces: an option `--no-wait` (via `MooX::Options` `option` in the role) and `sub handle_action { my ($self, $action) = @_; ... }` which returns immediately when the arg is not an `Action` or when `--no-wait` is set, otherwise calls `$action->wait` and reports success/failure.
- Consumes: `Action::wait` (Task 2).

- [ ] **Step 1: Failing test** — drive `handle_action` with a mock Action that records whether `wait` was called, once with `--no-wait` true and once false.

- [ ] **Step 2: Implement the role** (`MooX::Options` allows options declared in a role):

```perl
package WWW::Hetzner::CLI::Role::WaitsForAction;
use Moo::Role;
use MooX::Options;
option no_wait => ( is => 'ro', default => 0, doc => 'return immediately, do not wait for the action' );
sub handle_action {
    my ($self, $action) = @_;
    return unless ref $action && $action->can('wait');
    return if $self->no_wait;
    $action->wait;
    return $action;
}
```

- [ ] **Step 3: Wire `Poweron.pm`** — consume the role, capture and hand off the action:

```perl
use Moo;
use MooX::Cmd;
use MooX::Options ...;
with 'WWW::Hetzner::CLI::Role::WaitsForAction';

sub execute {
    my ($self, $args, $chain) = @_;
    my $id = $args->[0] or die "Usage: hcloud.pl server poweron <id>\n";
    my $cloud = $chain->[0]->cloud;
    print "Powering on server $id...\n";
    my $action = $cloud->servers->power_on($id);
    $self->handle_action($action);
    print $self->no_wait ? "Power-on requested.\n" : "Server powered on.\n";
}
```

The current unconditional `"Server powered on."` (line 19) is the bug this fixes: only print completion after `wait` returns.

- [ ] **Step 4: Repeat the wiring for the other mutating subcommands** (poweroff, reboot, reset, shutdown, volume attach/detach, etc. — enumerate under `CLI/Cmd/**`).
- [ ] **Step 5: `prove -lr t/`; smoke-run `perl -c` on each edited command.**
- [ ] **Step 6: Commit** — `"CLI waits for actions by default, --no-wait to opt out (karr #2)"`.

---

## Task 7b: Preserve sidecar data on Action (spec E5) — fixes karr #6

**Recommended agent:** `www-hetzner-worker`

Five server action methods return sidecar fields alongside `action` that the Task 4 blanket conversion discarded (verified against `cloud.spec.json`). Per spec E5, the `Action` carries them.

**Files:**
- Modify: `lib/WWW/Hetzner/Cloud/Action.pm` — add `result` attr + typed readers.
- Modify: `lib/WWW/Hetzner/Cloud/Role/HasActions.pm` — a way to build an Action with its sidecar (`_wrap_action` extension or a sibling helper).
- Modify: `lib/WWW/Hetzner/Cloud/API/Servers.pm` — the 5 methods pass the sidecar.
- Modify: `lib/WWW/Hetzner/Cloud/Server.pm` — the mirrored 5 methods still delegate (should need no change beyond confirming they return the controller's Action).
- Modify: CLI commands that display the sidecar — `CLI/Cmd/Server/Cmd/Rescue.pm` (and `ResetPassword`/`Rebuild`/`CreateImage` if they exist) to read `$action->root_password` / `$action->result`.
- Test: `t/cloud_servers.t` (or `t/cloud_actions.t`) — assert the sidecar survives.

**Interfaces:**
- Produces: `$action->result` → hashref (default `{}`) of sidecar fields; `$action->root_password`, `$action->image`, `$action->wss_url`, `$action->password` → readers over `result`, `undef` when absent.
- The 5 methods (`enable_rescue`, `rebuild`, `reset_password`, `request_console`, `create_image`) return an `Action` whose `result` holds their sidecar.

- [ ] **Step 1: Failing test.** For `reset_password` (fixture with `{action, root_password}`):

```perl
my $action = $cloud->servers->reset_password($id);
isa_ok($action, 'WWW::Hetzner::Cloud::Action');
is($action->root_password, 'the-generated-pw', 'root_password preserved on the Action');
is($action->result->{root_password}, 'the-generated-pw', 'result carries sidecar');
```
Extend the relevant server-action fixtures (`servers_action.json` or per-method fixtures) so `{action, root_password}` / `{action, image}` are present.

- [ ] **Step 2: Run, verify fail.**

- [ ] **Step 3: Implement.** Add to `Action.pm`:
```perl
has result => ( is => 'ro', default => sub { {} } );
sub root_password { $_[0]->result->{root_password} }
sub image        { $_[0]->result->{image} }
sub wss_url      { $_[0]->result->{wss_url} }
sub password     { $_[0]->result->{password} }
```
In `HasActions`, add a helper that builds an Action from the full response, e.g.:
```perl
sub _wrap_action_result {
    my ($self, $result) = @_;
    my %sidecar = %$result;
    my $action = delete $sidecar{action};
    return undef unless defined $action;
    WWW::Hetzner::Cloud::Action->new(client => $self->client, %$action, result => \%sidecar);
}
```
In `Servers.pm`, the 5 methods use `_wrap_action_result($result)` instead of `_wrap_action($result->{action})`.

- [ ] **Step 4: Wire the CLI display commands** to read `$action->root_password` / `$action->result` (Rescue at minimum — this closes karr #6). Confirm `--output json` for those commands emits the sidecar again.

- [ ] **Step 5: Run tests, verify pass; `prove -lr t/`.**

- [ ] **Step 6: Commit** — `"Preserve action sidecar data on Action::result (spec E5, karr #6)"`.

---

## Task 8: POD + `Changes`

**Recommended agent:** `www-hetzner-doc-writer` (POD), `www-hetzner-worker` may write the `Changes` line.

**Files:**
- POD in: `Action.pm`, `API/Actions.pm`, `Role/HasActions.pm`, `Role/HasAction.pm`, `CLI/Role/WaitsForAction.pm`, and the `sleeper` attr in `Role/HTTP.pm`. Cross-link with `L<>` from `WWW::Hetzner::Cloud`. `wait_for_status`'s POD (`Cloud/API/Servers.pm:488`) gains a `L<.../Action#wait>` pointer.
- `Changes`: breaking-change entry.

- [ ] **Step 1: POD** — `=attr`/`=method`/`=opt` in the house `[@Author::GETTY]` format for every new symbol. State explicitly that `action` is the creation-time snapshot and is `undef` after `->refresh`.
- [ ] **Step 2: `Changes`** — under the current dev version, note: "Mutating Cloud methods now return a WWW::Hetzner::Cloud::Action instead of a raw `{action=>...}` hashref (breaking). New: `->wait`, `$cloud->actions`, entity `->action`/`->next_actions`, CLI `--no-wait`."
- [ ] **Step 3:** `dzil build` to confirm POD weaves cleanly; `prove -lr t/`.
- [ ] **Step 4: Commit** — `"Document Cloud Actions; note breaking return-type change (karr #2)"`.

---

## Self-Review (done at write time)

- **Spec coverage:** E1 (Action returned, no implicit wait) → Tasks 2/4/6. E2 (CLI waits, `--no-wait`) → Task 7. E3 (`create` returns entity carrying `action`) → Task 5. E4 (injectable sleeper) → Task 1 + used in Task 2. Poll-path default `/actions` → Task 2. Eight HasAction entities + Firewall plural + fixture alignment → Task 5. New controller/entity/roles/fixtures/tests → Tasks 2/3/5. `wait_for_status` untouched, POD-linked → Task 8. Breaking change in `Changes` → Task 8. No gaps found.
- **Type consistency:** `_wrap_action`/`_wrap_actions` names identical in Tasks 3/4/5. `action`/`next_actions`/`actions` attr names consistent across Task 5. `wait(interval=>,timeout=>)` identical in Tasks 2/7. `poll_path` default `/actions` consistent Tasks 2 + Global Constraints.
- **Placeholders:** none — every code step shows real code grounded in the read source files.
