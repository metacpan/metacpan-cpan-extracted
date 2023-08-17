#!/usr/bin/env yamltest

plan: 11

pass: "This test will always 'pass'"

note: "The next test has no label:"

pass: []

todo:
- "Testing 'todo'"
- fail: "This test will always 'fail'"

note: "NOTE: This is awesome"

diag: "This is a WARNING!"

ok: true "Testing 'ok'"

is:
  (2 + 2)
  4
  "2 + 2 'is' 4"

isnt:
  (2 + 2)
  5
  "2 + 2 'isnt' 5"

like:
- "I like pie!"
- /\blike\b/
- "Testing 'like'"

unlike:
- "Please like me on Facebook"
- /\bunlike\b/
- "Testing 'unlike'"

skip:
- "Skipping - Highway to the danger zone"
- danger: zone

subtest:
- "Testing skip-all in subtest"
- skip-all: "Skipping all these subtests"
- pass: "I wanna pass..."
- fail: "Gonna fail..."

subtest:
- "Testing 'subtests'"
- pass: "Subtest 1"
- pass: "Subtest 2"
- pass: "Subtest 3"
- done-testing: 3
