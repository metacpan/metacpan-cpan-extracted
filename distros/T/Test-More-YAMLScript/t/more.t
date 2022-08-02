#!/usr/bin/env test-more-yamlscript

- plan: 10

- pass: This test will always 'pass'

- todo:
  - Testing 'todo'
  - fail: This test will always 'fail'

- note: "NOTE: This is awesome"

- diag: This is a WARNING!

- ok:
  - true
  - Testing 'ok'

- is:
  - add: [2, 2]
  - 4
  - 2 + 2 'is' 4

- isnt:
  - add: [2, 2]
  - 5
  - 2 + 2 'isnt' 5

- like:
  - I like pie!
  - /\blike\b/
  - Testing 'like'

- unlike:
  - Please like me on Facebook
  - /\bunlike\b/
  - Testing 'unlike'

- skip:
  - Skipping - Highway to the danger zone
  - danger: zone

- subtest:
  - Testing skip-all in subtest
  - skip-all: Skipping all these subtests
  - pass: I wanna pass...
  - fail: Gonna fail...

- subtest:
  - Testing 'subtests'
  - for:
    - [1, 2, 3]
    - pass: Subtest $_
  - done-testing: 3

# - is_deeply:
#   - { "key": val }
#   - { "key": val }
#   - Testing 'is_deeply'
