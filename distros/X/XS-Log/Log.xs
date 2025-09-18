/***************************************************************************************
* Build  MD5 : Xrhks8OILOBduvDSsKMXFA
* Build Time : 2025-09-18 13:22:45
* Version    : 5.090111
* Author     : H.Q.Wang
****************************************************************************************/
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

void
printNote(SV* fmt, ...)
  PPCODE:
    {
        dXSARGS;
        if (items < 1) XSRETURN_EMPTY;

        ENTER; SAVETMPS;

        PUSHMARK(SP);
        for (int i = 0; i < items; i++) {
            XPUSHs(ST(i));
        }
        PUTBACK;

        int count = call_pv("CORE::sprintf", G_SCALAR);

        SPAGAIN;
        if (count == 1) {
            SV* result = POPs;
            printNote("%s", SvPV_nolen(result));
        }

        PUTBACK; FREETMPS; LEAVE;
    }

void
printBug(SV* fmt, ...)
  PPCODE:
    {
        dXSARGS;
        if (items < 1) XSRETURN_EMPTY;

        ENTER; SAVETMPS;

        PUSHMARK(SP);
        for (int i = 0; i < items; i++) {
            XPUSHs(ST(i));
        }
        PUTBACK;

        int count = call_pv("CORE::sprintf", G_SCALAR);

        SPAGAIN;
        if (count == 1) {
            SV* result = POPs;
            printBug("%s", SvPV_nolen(result));
        }

        PUTBACK; FREETMPS; LEAVE;
    }

void
printInf(SV* fmt, ...)
  PPCODE:
    {
        dXSARGS;
        if (items < 1) XSRETURN_EMPTY;

        ENTER; SAVETMPS;

        PUSHMARK(SP);
        for (int i = 0; i < items; i++) {
            XPUSHs(ST(i));
        }
        PUTBACK;

        int count = call_pv("CORE::sprintf", G_SCALAR);

        SPAGAIN;
        if (count == 1) {
            SV* result = POPs;
            printInf("%s", SvPV_nolen(result));
        }

        PUTBACK; FREETMPS; LEAVE;
    }

void
printWarn(SV* fmt, ...)
  PPCODE:
    {
        dXSARGS;
        if (items < 1) XSRETURN_EMPTY;

        ENTER; SAVETMPS;

        PUSHMARK(SP);
        for (int i = 0; i < items; i++) {
            XPUSHs(ST(i));
        }
        PUTBACK;

        int count = call_pv("CORE::sprintf", G_SCALAR);

        SPAGAIN;
        if (count == 1) {
            SV* result = POPs;
            printWarn("%s", SvPV_nolen(result));
        }

        PUTBACK; FREETMPS; LEAVE;
    }

void
printErr(SV* fmt, ...)
  PPCODE:
    {
        dXSARGS;
        if (items < 1) XSRETURN_EMPTY;

        ENTER; SAVETMPS;

        PUSHMARK(SP);
        for (int i = 0; i < items; i++) {
            XPUSHs(ST(i));
        }
        PUTBACK;

        int count = call_pv("CORE::sprintf", G_SCALAR);

        SPAGAIN;
        if (count == 1) {
            SV* result = POPs;
            printErr("%s", SvPV_nolen(result));
        }

        PUTBACK; FREETMPS; LEAVE;
    }

void
printText(SV* fmt, ...)
  PPCODE:
    {
        dXSARGS;
        if (items < 1) XSRETURN_EMPTY;

        ENTER; SAVETMPS;

        PUSHMARK(SP);
        for (int i = 0; i < items; i++) {
            XPUSHs(ST(i));
        }
        PUTBACK;

        int count = call_pv("CORE::sprintf", G_SCALAR);

        SPAGAIN;
        if (count == 1) {
            SV* result = POPs;
            printText("%s", SvPV_nolen(result));
        }

        PUTBACK; FREETMPS; LEAVE;
    }



void
printFail(SV* fmt, ...)
  PPCODE:
    {
        dXSARGS;
        if (items < 1) XSRETURN_EMPTY;

        ENTER; SAVETMPS;

        PUSHMARK(SP);
        for (int i = 0; i < items; i++) {
            XPUSHs(ST(i));
        }
        PUTBACK;

        int count = call_pv("CORE::sprintf", G_SCALAR);

        SPAGAIN;
        if (count == 1) {
            SV* result = POPs;
            printFail("%s", SvPV_nolen(result));
        }

        PUTBACK; FREETMPS; LEAVE;
    }
