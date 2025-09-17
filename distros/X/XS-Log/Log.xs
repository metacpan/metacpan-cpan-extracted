#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

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

# 常量
IV 
LOG_LEVEL_OFF()
  CODE: 
    RETVAL = LOG_LEVEL_OFF;
  OUTPUT: 
    RETVAL

IV
LOG_LEVEL_FATAL()
  CODE: 
    RETVAL = LOG_LEVEL_FATAL; 
  OUTPUT: 
    RETVAL

IV
LOG_LEVEL_ERROR()
  CODE: 
    RETVAL = LOG_LEVEL_ERROR;
  OUTPUT: 
    RETVAL

IV
LOG_LEVEL_WARN()
  CODE: 
    RETVAL = LOG_LEVEL_WARN;  
  OUTPUT: 
    RETVAL

IV 
LOG_LEVEL_INFO()
  CODE: 
    RETVAL = LOG_LEVEL_INFO;  
  OUTPUT: 
    RETVAL

IV 
LOG_LEVEL_TRACE() 
  CODE: 
    RETVAL = LOG_LEVEL_TRACE; 
  OUTPUT: 
    RETVAL

IV 
LOG_LEVEL_DEBUG() 
  CODE: 
    RETVAL = LOG_LEVEL_DEBUG; 
  OUTPUT: 
    RETVAL

IV 
LOG_LEVEL_TEXT()  
  CODE: 
    RETVAL = LOG_LEVEL_TEXT;  
  OUTPUT: 
    RETVAL

IV 
LOG_MODE_CYCLE()  
  CODE: 
    RETVAL = LOG_MODE_CYCLE;  
  OUTPUT: 
    RETVAL

IV 
LOG_MODE_DAILY()  
  CODE: 
    RETVAL = LOG_MODE_DAILY;  
  OUTPUT: 
    RETVAL

IV 
LOG_MODE_HOURLY() 
  CODE: 
    RETVAL = LOG_MODE_HOURLY; 
  OUTPUT: 
    RETVAL

IV 
LOG_TARGET_CONSOLE() 
  CODE: 
    RETVAL = LOG_TARGET_CONSOLE; 
  OUTPUT: 
    RETVAL

IV 
LOG_TARGET_FILE()
  CODE: 
    RETVAL = LOG_TARGET_FILE;
  OUTPUT: 
    RETVAL

IV 
LOG_TARGET_SYSLOG()  
  CODE: 
    RETVAL = LOG_TARGET_SYSLOG;  
  OUTPUT: 
    RETVAL

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

void
printNote(SV* fmt, ...)
  PPCODE:
    {
        dXSARGS;
        if (items < 1) {
            XSRETURN_EMPTY;
        }

        // 创建一个空的 SV 用来拼接
        SV* sv = newSVpv("", 0);

        // 把参数 @_ 里的内容，按照 printf 格式化拼接
        sv_catpvf(sv, SvPV_nolen(fmt), 
                  (items > 1 ? SvPV_nolen(ST(1)) : ""));  

        log_write(LOG_LEVEL_TRACE, __FILE__, __LINE__, "%s", SvPV_nolen(sv));
        SvREFCNT_dec(sv);
    }

void
printBug(SV* fmt, ...)
  PPCODE:
    {
        dXSARGS;
        if (items < 1) {
            XSRETURN_EMPTY;
        }

        // 创建一个空的 SV 用来拼接
        SV* sv = newSVpv("", 0);

        // 把参数 @_ 里的内容，按照 printf 格式化拼接
        sv_catpvf(sv, SvPV_nolen(fmt), 
                  (items > 1 ? SvPV_nolen(ST(1)) : ""));  

        log_write(LOG_LEVEL_DEBUG, __FILE__, __LINE__, "%s", SvPV_nolen(sv));
        SvREFCNT_dec(sv);
    }

void
printInf(SV* fmt, ...)
  PPCODE:
    {
        dXSARGS;
        if (items < 1) {
            XSRETURN_EMPTY;
        }

        // 创建一个空的 SV 用来拼接
        SV* sv = newSVpv("", 0);

        // 把参数 @_ 里的内容，按照 printf 格式化拼接
        sv_catpvf(sv, SvPV_nolen(fmt), 
                  (items > 1 ? SvPV_nolen(ST(1)) : ""));  

        log_write(LOG_LEVEL_INFO, __FILE__, __LINE__, "%s", SvPV_nolen(sv));
        SvREFCNT_dec(sv);
    }

void
printWarn(SV* fmt, ...)
  PPCODE:
    {
        dXSARGS;
        if (items < 1) {
            XSRETURN_EMPTY;
        }

        // 创建一个空的 SV 用来拼接
        SV* sv = newSVpv("", 0);

        // 把参数 @_ 里的内容，按照 printf 格式化拼接
        sv_catpvf(sv, SvPV_nolen(fmt), 
                  (items > 1 ? SvPV_nolen(ST(1)) : ""));  

        log_write(LOG_LEVEL_WARN, __FILE__, __LINE__, "%s", SvPV_nolen(sv));
        SvREFCNT_dec(sv);
    }
	
void
printErr(SV* fmt, ...)
  PPCODE:
    {
        dXSARGS;
        if (items < 1) {
            XSRETURN_EMPTY;
        }

        // 创建一个空的 SV 用来拼接
        SV* sv = newSVpv("", 0);

        // 把参数 @_ 里的内容，按照 printf 格式化拼接
        sv_catpvf(sv, SvPV_nolen(fmt), 
                  (items > 1 ? SvPV_nolen(ST(1)) : ""));  

        log_write(LOG_LEVEL_ERROR, __FILE__, __LINE__, "%s", SvPV_nolen(sv));
        SvREFCNT_dec(sv);
    }

void
printFail(SV* fmt, ...)
  PPCODE:
    {
        dXSARGS;
        if (items < 1) {
            XSRETURN_EMPTY;
        }

        // 创建一个空的 SV 用来拼接
        SV* sv = newSVpv("", 0);

        // 把参数 @_ 里的内容，按照 printf 格式化拼接
        sv_catpvf(sv, SvPV_nolen(fmt), 
                  (items > 1 ? SvPV_nolen(ST(1)) : ""));  

        log_write(LOG_LEVEL_FATAL, __FILE__, __LINE__, "%s", SvPV_nolen(sv));
        SvREFCNT_dec(sv);
    }

void
printText(SV* fmt, ...)
  PPCODE:
    {
        dXSARGS;
        if (items < 1) {
            XSRETURN_EMPTY;
        }

        // 创建一个空的 SV 用来拼接
        SV* sv = newSVpv("", 0);

        // 把参数 @_ 里的内容，按照 printf 格式化拼接
        sv_catpvf(sv, SvPV_nolen(fmt), 
                  (items > 1 ? SvPV_nolen(ST(1)) : ""));  

        log_write(LOG_LEVEL_TEXT, __FILE__, __LINE__, "%s", SvPV_nolen(sv));
        SvREFCNT_dec(sv);
    }