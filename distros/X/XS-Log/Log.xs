/***************************************************************************************
* Build  MD5 : kGCDEla76qeMr72JLP4oqw
* Build Time : 2025-09-20 09:24:15
* Version    : 5.090118
* Author     : H.Q.Wang
****************************************************************************************/
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <stdio.h>
#include <stdlib.h>
#include <stdarg.h>
#include "include/Log.h"
#include "include/Log.c"

static LogOptions* hv_to_LogOptions(HV* hv) {
    LogOptions* opt = (LogOptions*)malloc(sizeof(LogOptions));
    if (!opt) return NULL;
    memset(opt, 0, sizeof(LogOptions));

    SV** val;
    if ((val = hv_fetch(hv, "level", 5, 0)))            opt->level = (LogLevel)SvIV(*val);
    if ((val = hv_fetch(hv, "mode", 4, 0)))             opt->mode = (LogMode)SvIV(*val);
    if ((val = hv_fetch(hv, "targets", 7, 0)))          opt->targets = SvIV(*val);
    if ((val = hv_fetch(hv, "use_color", 9, 0)))        opt->use_color = SvTRUE(*val);
    if ((val = hv_fetch(hv, "show_timestamp", 14, 0)))  opt->show_timestamp = SvTRUE(*val);
    if ((val = hv_fetch(hv, "show_log_level", 14, 0)))  opt->show_log_level = SvTRUE(*val);
    if ((val = hv_fetch(hv, "show_file_info", 14, 0)))  opt->show_file_info = SvTRUE(*val);
    if ((val = hv_fetch(hv, "max_file_size", 13, 0)))   opt->max_file_size = SvIV(*val);
    if ((val = hv_fetch(hv, "max_files", 9, 0)))        opt->max_files = SvIV(*val);
    if ((val = hv_fetch(hv, "flush_immediately", 17, 0))) opt->flush_immediately = SvTRUE(*val);

    return opt;
}

MODULE = XS::Log      PACKAGE = XS::Log

PROTOTYPES: ENABLE

# 打开/关闭/刷新日志
bool
openLog(filepath, options)
    const char* filepath
    HV* options
  CODE:
    {
        LogOptions* opt = hv_to_LogOptions(options);
        RETVAL = openLog(filepath, opt);
        free(opt);
    }
  OUTPUT: RETVAL

void 
closeLog() 
  CODE: 
    closeLog();

void 
flushLog() 
  CODE: 
    flushLog();

# 包装 bool setLogOptions(const char *key, void *val)
bool
setLogOptions(key, val)
    const char *key
    SV *val
  CODE:
    void *c_val;
    
    # 根据Perl值的类型转换为相应的C指针
    if (SvIOK(val)) {
        # 如果是整数，存储其地址
        IV num = SvIV(val);
        c_val = &num;
    } else if (SvPOK(val)) {
        # 如果是字符串，使用其指针
        c_val = (void *)SvPV_nolen(val);
    } else {
        # 不支持的类型
        croak("Unsupported value type for setLogOptions");
        XSRETURN_UNDEF;
    }
    
    RETVAL = setLogOptions(key, c_val);
  OUTPUT:
    RETVAL

# 包装 void setUseColor(int flag)
void
setLogColor(flag)
    int flag
  CODE:
    setLogColor(flag);

void
setLogLevel(level)
    int level
  CODE:
    setLogLevel(level);

void
setLogMode(flag)
    int flag
  CODE:
    setLogMode(flag);

void
setLogTargets(flag)
    int flag
  CODE:
    setLogTargets(flag);

int
get_show_file_info()
  CODE:
    RETVAL = g_config.options.show_file_info;
  OUTPUT:
    RETVAL

void
xs_log_write(level, file,line,message)
    int level
    SV* file
    int line
    SV* message
  CODE:
    {
        STRLEN flen, mlen;
        const char *cmessage = SvPV(message, mlen);
		const char *cfile    = SvPV(file, flen);
        log_write((LogLevel)level, cfile, line, cmessage);
    }
