(module
  (global $g (import "Foo::Bar::X1" "x1") (mut i32))
  (func (export "get_x1") (result i32)
    (global.get $g))
  (func (export "inc_x1")
    (global.set $g
      (i32.add (global.get $g) (i32.const 1))))
)
