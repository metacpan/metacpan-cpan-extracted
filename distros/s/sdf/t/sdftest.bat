@echo off
cd general
echo TESTING GENERAL STUFF ...
call sdf -2raw -.test expr.sdf
call sdf -2raw -.test formats.sdf
call sdf -2raw -.test lineno.sdf
call sdf -2raw -.test macro.sdf
call sdf -2raw -.test para1.sdf
call sdf -2raw -.test para2.sdf
call sdf -2raw -.test phrase.sdf
call sdf -2raw -.test zero.sdf
cd ..\macro
echo TESTING MACROS ...
call sdf -2raw -.test block.sdf
call sdf -2raw -.test catalog.sdf
call sdf -2raw -.test cell.sdf
call sdf -2raw -.test class.sdf
call sdf -2raw -.test default.sdf
call sdf -2raw -.test define.sdf
call sdf -2raw -.test else.sdf
call sdf -2raw -.test elsif.sdf
call sdf -2raw -.test endblock.sdf
call sdf -2raw -.test endif.sdf
call sdf -2raw -.test endmacro.sdf
call sdf -2raw -.test endtable.sdf
call sdf -2raw -.test execute.sdf
call sdf -2raw -.test export.sdf
call sdf -2raw -.test if.sdf
call sdf -2raw -.test include.sdf
rem call sdf -2raw -.test inherit.sdf
call sdf -2raw -.test init.sdf
call sdf -2raw -.test insert.sdf
call sdf -2raw -.test line.sdf
call sdf -2raw -.test macro.sdf
call sdf -2raw -.test on_para.sdf
call sdf -2raw -.test on_phras.sdf
call sdf -2raw -.test row.sdf
call sdf -2raw -.test slide.sdf
call sdf -2raw -.test table.sdf
call sdf -2raw -.test undef.sdf
cd ..\filter
echo TESTING FILTERS ...
call sdf -2raw -.test about.sdf
call sdf -2raw -.test address.sdf
call sdf -2raw -.test appendix.sdf
call sdf -2raw -.test comment.sdf
call sdf -2raw -.test default.sdf
call sdf -2raw -.test define.sdf
call sdf -2raw -.test end.sdf
call sdf -2raw -.test example.sdf
call sdf -2raw -.test front.sdf
call sdf -2raw -.test inline.sdf
call sdf -2raw -.test parastyl.sdf
call sdf -2raw -.test plain.sdf
call sdf -2raw -.test script.sdf
call sdf -2raw -.test sdf.sdf
call sdf -2raw -.test table.sdf
cd ..
echo If any tests failed, the unexpected .out or .log file
echo can be found in t\general, t\macro or t\filter.
