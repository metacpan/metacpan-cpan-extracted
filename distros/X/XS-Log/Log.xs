/***************************************************************************************
* Build  MD5 : bTO8KdNuOXUI/qjnYirIyg
* Build Time : 2025-09-23 11:51:03
* Version    : 5.090124
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
	if ((val = hv_fetch(hv, "with_rep", 8, 0)))         opt->with_rep = SvTRUE(*val);
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

# 包装 bool setLogOptions(const char *key, long val);
void
setLogOptions(key, val)
    const char *key
    long        val
  PREINIT:
    bool ret;
  CODE:
    ret = setLogOptions(key, val);
    if (!ret) {
      XSRETURN_UNDEF;   // 失败返回 undef
    }
    // 成功返回 SV* 类型的 true（Perl 中的真值）
    ST(0) = sv_2mortal(newSViv(1));


void
setLogColor(flag)
    int flag
  CODE:
    setLogColor(flag);

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

void
xs_rep_write(message)
    SV* message
  CODE:
    {
        STRLEN flen, mlen;
        const char *cmessage = SvPV(message, mlen);
        rep_write(cmessage);
    }
