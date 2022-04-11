(module
    ;; function import:
    (import "my" "func" (func $mf (param i32 i32) (result f64)))
    (import "my" "func-no-args-all-rets"
        (func $mf2 (result i32 i64 f32 f64))
    )
    (import "my" "func-all-args-no-rets"
        (func $mf3 (param i32 i64 f32 f64))
    )

    (global $g1 (export "global-mut-i32") (mut i32) (i32.const 0))
    (global $g2 (export "global-mut-i64") (mut i64) (i64.const 0))
    (global $g3 (export "global-mut-f32") (mut f32) (f32.const 0))
    (global $g4 (export "global-mut-f64") (mut f64) (f64.const 0))

    (global $g5 (export "global-const-i32") i32 (i32.const 32))
    (global $g6 (export "global-const-i64") i64 (i64.const 64))
    (global $g7 (export "global-const-f32") f32 (f32.const 3.2))
    (global $g8 (export "global-const-f64") f64 (f64.const 6.4))

    (func (export "giveback") (param i32 i64 f32 f64) (result f64 f32 i64 i32)
        local.get 3
        local.get 2
        local.get 1
        local.get 0
        ;; i32.const 1234
        ;; i64.const 5678
        ;; f32.const 1.234
        ;; f64.const 5.678
    )

    (func (export "callfunc") (result f64)
        i32.const 0  ;; pass offset 0 to log
        i32.const 2  ;; pass length 2 to log
        call $mf
    )

    (func (export "call-no-args-all-rets") (result i32 i64 f32 f64)
        call $mf2
    )
    (func (export "call-all-args-no-rets")
        i32.const 123
        i64.const 234
        f32.const 3.45
        f64.const 4.56
        call $mf3
    )
)
