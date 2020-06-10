(module
  (func (export "add") (param i32 i32) (result i32)
    local.get 0
    local.get 1
    i32.add)
  (func (export "subtract") (param i32 i32) (result i32)
    local.get 0
    local.get 1
    i32.sub)
  (memory (export "frooble") 2 3)
)
