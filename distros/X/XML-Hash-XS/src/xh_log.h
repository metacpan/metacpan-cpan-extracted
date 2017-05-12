#include "xh_config.h"
#include "xh_core.h"

#ifndef _XH_LOG_H_
#define _XH_LOG_H_

typedef enum {
    XH_LOG_CRITIC = 0,
    XH_LOG_ERROR,
    XH_LOG_WARN,
    XH_LOG_NOTICE,
    XH_LOG_INFO,
    XH_LOG_DEBUG,
    XH_LOG_TRACE
} xh_log_level_t;

#ifdef WITH_TRACE
#define xh_log_debug0(msg)                                                 \
        xh_log(XH_LOG_DEBUG, __FUNCTION__, __LINE__, msg)
#define xh_log_debug1(msg, arg1)                                           \
        xh_log(XH_LOG_DEBUG, __FUNCTION__, __LINE__, msg, arg1)
#define xh_log_debug2(msg, arg1, arg2)                                     \
        xh_log(XH_LOG_DEBUG, __FUNCTION__, __LINE__, msg, arg1, arg2)
#define xh_log_debug3(msg, arg1, arg2, arg3)                               \
        xh_log(XH_LOG_DEBUG, __FUNCTION__, __LINE__, msg, arg1, arg2, arg3)
#define xh_log_debug4(msg, arg1, arg2, arg3, arg4)                         \
        xh_log(XH_LOG_DEBUG, __FUNCTION__, __LINE__, msg, arg1, arg2, arg3, arg4)
#define xh_log_debug5(msg, arg1, arg2, arg3, arg4, arg5)                   \
        xh_log(XH_LOG_DEBUG, __FUNCTION__, __LINE__, msg, arg1, arg2, arg3, arg4, arg5)
#define xh_log_debug6(msg, arg1, arg2, arg3, arg4, arg5, arg6)             \
        xh_log(XH_LOG_DEBUG, __FUNCTION__, __LINE__, msg, arg1, arg2, arg3, arg4, arg5, arg6)
#define xh_log_debug7(msg, arg1, arg2, arg3, arg4, arg5, arg6, arg7)       \
        xh_log(XH_LOG_DEBUG, __FUNCTION__, __LINE__, msg, arg1, arg2, arg3, arg4, arg5, arg6, arg7)
#define xh_log_debug8(msg, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8) \
        xh_log(XH_LOG_DEBUG, __FUNCTION__, __LINE__, msg, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8)
#else
#define xh_log_debug0(msg)
#define xh_log_debug1(msg, arg1)
#define xh_log_debug2(msg, arg1, arg2)
#define xh_log_debug3(msg, arg1, arg2, arg3)
#define xh_log_debug4(msg, arg1, arg2, arg3, arg4)
#define xh_log_debug5(msg, arg1, arg2, arg3, arg4, arg5)
#define xh_log_debug6(msg, arg1, arg2, arg3, arg4, arg5, arg6)
#define xh_log_debug7(msg, arg1, arg2, arg3, arg4, arg5, arg6, arg7)
#define xh_log_debug8(msg, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8)
#endif

#ifdef WITH_TRACE
#define xh_log_trace0(msg)                                                 \
        xh_log(XH_LOG_TRACE, __FUNCTION__, __LINE__, msg)
#define xh_log_trace1(msg, arg1)                                           \
        xh_log(XH_LOG_TRACE, __FUNCTION__, __LINE__, msg, arg1)
#define xh_log_trace2(msg, arg1, arg2)                                     \
        xh_log(XH_LOG_TRACE, __FUNCTION__, __LINE__, msg, arg1, arg2)
#define xh_log_trace3(msg, arg1, arg2, arg3)                               \
        xh_log(XH_LOG_TRACE, __FUNCTION__, __LINE__, msg, arg1, arg2, arg3)
#define xh_log_trace4(msg, arg1, arg2, arg3, arg4)                         \
        xh_log(XH_LOG_TRACE, __FUNCTION__, __LINE__, msg, arg1, arg2, arg3, arg4)
#define xh_log_trace5(msg, arg1, arg2, arg3, arg4, arg5)                   \
        xh_log(XH_LOG_TRACE, __FUNCTION__, __LINE__, msg, arg1, arg2, arg3, arg4, arg5)
#define xh_log_trace6(msg, arg1, arg2, arg3, arg4, arg5, arg6)             \
        xh_log(XH_LOG_TRACE, __FUNCTION__, __LINE__, msg, arg1, arg2, arg3, arg4, arg5, arg6)
#define xh_log_trace7(msg, arg1, arg2, arg3, arg4, arg5, arg6, arg7)       \
        xh_log(XH_LOG_TRACE, __FUNCTION__, __LINE__, msg, arg1, arg2, arg3, arg4, arg5, arg6, arg7)
#define xh_log_trace8(msg, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8) \
        xh_log(XH_LOG_TRACE, __FUNCTION__, __LINE__, msg, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8)
#else
#define xh_log_trace0(msg)
#define xh_log_trace1(msg, arg1)
#define xh_log_trace2(msg, arg1, arg2)
#define xh_log_trace3(msg, arg1, arg2, arg3)
#define xh_log_trace4(msg, arg1, arg2, arg3, arg4)
#define xh_log_trace5(msg, arg1, arg2, arg3, arg4, arg5)
#define xh_log_trace6(msg, arg1, arg2, arg3, arg4, arg5, arg6)
#define xh_log_trace7(msg, arg1, arg2, arg3, arg4, arg5, arg6, arg7)
#define xh_log_trace8(msg, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8)
#endif

#define xh_log_error0(msg)                                                 \
        xh_log(XH_LOG_ERROR, __FUNCTION__, __LINE__, msg)
#define xh_log_error1(msg, arg1)                                           \
        xh_log(XH_LOG_ERROR, __FUNCTION__, __LINE__, msg, arg1)
#define xh_log_error2(msg, arg1, arg2)                                     \
        xh_log(XH_LOG_ERROR, __FUNCTION__, __LINE__, msg, arg1, arg2)
#define xh_log_error3(msg, arg1, arg2, arg3)                               \
        xh_log(XH_LOG_ERROR, __FUNCTION__, __LINE__, msg, arg1, arg2, arg3)
#define xh_log_error4(msg, arg1, arg2, arg3, arg4)                         \
        xh_log(XH_LOG_ERROR, __FUNCTION__, __LINE__, msg, arg1, arg2, arg3, arg4)
#define xh_log_error5(msg, arg1, arg2, arg3, arg4, arg5)                   \
        xh_log(XH_LOG_ERROR, __FUNCTION__, __LINE__, msg, arg1, arg2, arg3, arg4, arg5)
#define xh_log_error6(msg, arg1, arg2, arg3, arg4, arg5, arg6)             \
        xh_log(XH_LOG_ERROR, __FUNCTION__, __LINE__, msg, arg1, arg2, arg3, arg4, arg5, arg6)
#define xh_log_error7(msg, arg1, arg2, arg3, arg4, arg5, arg6, arg7)       \
        xh_log(XH_LOG_ERROR, __FUNCTION__, __LINE__, msg, arg1, arg2, arg3, arg4, arg5, arg6, arg7)
#define xh_log_error8(msg, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8) \
        xh_log(XH_LOG_ERROR, __FUNCTION__, __LINE__, msg, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8)

void xh_log(xh_log_level_t log_level, const char *func, xh_int_t line, const char *msg, ...);

#endif /* _XH_LOG_H_ */
