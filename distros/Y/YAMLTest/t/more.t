#!/usr/bin/env yamltest

- plan: 8

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
