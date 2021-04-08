#pragma once

#define PANDA_PP__CONCAT(name, n) name##n
#define PANDA_PP_CONCAT(name, n) PANDA_PP__CONCAT(name, n)

// ===================== examine if is __VA_ARGS__ is empty with PANDA_PP_IS_EMPTY_ARGS ==============================
#define PANDA_PP_ISEMPTY(...) PANDA_PP__ISEMPTY(                                                                  \
    /* test if there is just one argument, eventually an empty one */                           \
    PANDA_PP__ISEMPTY_HAS_COMMA(__VA_ARGS__),                                                   \
    /* test if _TRIGGER_PARENTHESIS_ together with the argument adds a comma */                 \
    PANDA_PP__ISEMPTY_HAS_COMMA(PANDA_PP__ISEMPTY_TRIGGER_PARENTHESIS_ __VA_ARGS__),            \
    /* test if the argument together with a parenthesis adds a comma */                         \
    PANDA_PP__ISEMPTY_HAS_COMMA(__VA_ARGS__ (/*empty*/)),                                       \
    /* test if placing it between _TRIGGER_PARENTHESIS_ and the parenthesis adds a comma */     \
    PANDA_PP__ISEMPTY_HAS_COMMA(PANDA_PP__ISEMPTY_TRIGGER_PARENTHESIS_ __VA_ARGS__ (/*empty*/)) \
)
#define PANDA_PP__ISEMPTY(_0, _1, _2, _3)            PANDA_PP__ISEMPTY_HAS_COMMA(PANDA_PP__ISEMPTY_PASTE5(PANDA_PP__ISEMPTY_CASE_, _0, _1, _2, _3))
#define PANDA_PP__ISEMPTY_HAS_COMMA(...)             PANDA_PP__ISEMPTY_ARG16(__VA_ARGS__, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0)
#define PANDA_PP__ISEMPTY_TRIGGER_PARENTHESIS_(...)  ,
#define PANDA_PP__ISEMPTY_PASTE5(_0, _1, _2, _3, _4) _0 ## _1 ## _2 ## _3 ## _4
#define PANDA_PP__ISEMPTY_CASE_0001                  ,
#define PANDA_PP__ISEMPTY_ARG16(_0,_1,_2,_3,_4,_5,_6,_7,_8,_9,_10,_11,_12,_13,_14,_15,...) _15

// ===================== get number of arguments ==============================
#define PANDA_PP_NARG(...)     PANDA_PP_CONCAT(PANDA_PP__NARG, PANDA_PP_ISEMPTY(__VA_ARGS__)) (__VA_ARGS__)
#define PANDA_PP__NARG1(...)   0
#define PANDA_PP__NARG0(...)   PANDA_PP__NARG_I_(__VA_ARGS__,PANDA_PP__RSEQ_N())
#define PANDA_PP__NARG_I_(...) PANDA_PP__ARG_N(__VA_ARGS__)
#define PANDA_PP__RSEQ_N()     16,15,14,13,12,11,10,9,8,7,6,5,4,3,2,1,0
#define PANDA_PP__ARG_N(_1,_2,_3,_4,_5,_6,_7,_8,_9,_10,_11,_12,_13,_14,_15,_16,N,...) N

// ===================== Variadic args overloading ==============================
#define PANDA_PP_VFUNC(func, ...) PANDA_PP_VFUNC1(func, __VA_ARGS__)
#define PANDA_PP_VFUNC1(func, ...) PANDA_PP_CONCAT(func, PANDA_PP_NARG(__VA_ARGS__)) (__VA_ARGS__)

#define PANDA_PP_VJOIN(...)        PANDA_PP__VJOIN(__VA_ARGS__)
#define PANDA_PP__VJOIN(arg, ...)  PANDA_PP_CONCAT(PANDA_PP__VJOIN, PANDA_PP_ISEMPTY(__VA_ARGS__)) (arg, __VA_ARGS__)
#define PANDA_PP__VJOIN1(arg, ...) arg
#define PANDA_PP__VJOIN0(arg, ...) arg, __VA_ARGS__
