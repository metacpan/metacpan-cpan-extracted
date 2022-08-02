#!/usr/bin/env test-more-bash

plan 6

pass "This test will always 'pass'"

t() (
  fail "This test will always 'fail'"
)
# todo "Testing 'todo'" t

note "NOTE: This is awesome"

diag "This is a WARNING"

ok "$(true)" \
  "Testing 'ok'"

is "$((2 + 2))" 4 \
  "2 + 2 'is' 4"

isnt "$((2 + 2))" 5 \
  "2 + 2 'isnt' 5"

like "I like pie!" \
  "/\<like\>/" \
  "Testing 'like'"

unlike \
  "Please like me on Facebook" \
  "/\<unlike\>/" \
  "Testing 'unlike'"

# t() (
#   danger zone
# )
# skip "Skipping - Highway to the danger zone" t
