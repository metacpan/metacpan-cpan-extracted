" Vim syntax file
" Language:         Vic
" Maintainter:      Vikas N Kumar <vikas@cpan.org>
" URL:              http://github.com/selectiveintellect/vic
" Last Change:      2014-01-30
" Contributors:     Vikas N Kumar <vikas@cpan.org>
"
"
if exists("b:current_syntax")
  finish
endif

syn keyword vicStatement    delay analog_input digital_input digital_output
syn keyword vicStatement    adc_enable adc_disable adc_read delay_ms delay_us delay_s
syn keyword vicStatement    debounce digital_output write read ror rol timer_enable
syn keyword vicStatement    timer shl shr pwm_single pwm_halfbridge pwm_fullbridge pwm_update
syn keyword vicStatement    setup attach sleep
syn keyword vicBlock        Main Loop Action True False ISR Simulator
syn keyword vicModifier     sqrt high low int char hex hang every wave table array shift
syn keyword vicConditional  if while else break continue
" contained is needed to show that the color highlighting is only valid when
" part of another match
syn keyword vicPICStatement PIC contained
syn region  vicString1      start=+'+  end=+'\|$+
syn region  vicString2      start=+"+  end=+"\|$+
syn match   vicNumberUnits  "\<\%([0-9][[:digit:]]*\)\%(s\|ms\|us\|MHz\|kHz\|Hz\)\>"
syn match   vicNumber       "\<\%(0\%(x\x[[:xdigit:]_]*\|b[01][01_]*\|\o[0-7_]*\|\)\|[1-9][[:digit:]_]*\)\>"
syn keyword vicBoolean      TRUE FALSE true false
syn match   vicComment      "#.*"
syn match   vicPIC          "\<PIC\s\+\%(\w\)*" contains=vicPICStatement
syn match   vicVariable     "\$\w*"
syn match   vicValidVars    "\<\%(\%(PORT\|GP\|TRIS\)\w\w*\)\|\%([RAGP][A-Z][0-9]\)\>"
syn match   vicValidVars    "\<\%(\w\+CON[0-9]*\)\|\%(TMR[0-9HL]*\)\|\%(ANSEL\w*\)\>"
syn match   vicValidVars    "\<\%(ADRES\w*\)\|\%(\w\+REG\w?\)\|\%(PCL\w*\)\>"
syn match   vicValidVars    "\<\%(UART\|USART\|WDT\|FSR\|STATUS\|OPTION_REG\|IND\)\w*\>"
syn match   vicValidVars    "\<\%(CCP[0-9]\|P[0-9][A-Z]\)\>"
syn match   vicConfig       "\<pragma\s\+\$\?\%(\w\)*\s\+\%(\w\)*" contains=vicVariable,vicValidVars
syn keyword vicSimulator    log logfile scope stop_after stimulate autorun stopwatch
syn match   vicSimulator    "\<\%(attach_\)\w*\>"
syn match   vicSimAssert    "sim_\w\+"

highlight link vicStatement     Statement 
highlight link vicBlock         Function
highlight link vicString1       String
highlight link vicString2       String
highlight link vicNumber        Number
highlight link vicNumberUnits   Number
highlight link vicBoolean       Number
highlight link vicComment       Comment
highlight link vicPIC           Special
highlight link vicPICStatement  Type
highlight link vicConfig        PreProc
highlight link vicVariable      Identifier
highlight link vicValidVars     Type
highlight link vicModifier      Type
highlight link vicConditional   Type
highlight link vicSimulator     Statement
highlight link vicSimAssert     PreProc

let b:current_syntax = "vic"

" vim: ts=8
