(module
  (import "Bogus" "log" (func $log (param i32 i32)))
  (import "Bogus" "memory" (memory 1))
  (import "Bogus" "memory_offset" (global $offset i32))

  (func (export "run")
    ;; Our `data` segment initialized our imported memory, so let's print the
    ;; string there now.
    global.get $offset
    i32.const 14
    call $log
  )

  (data (global.get $offset) "Hello, world!\n")
)
