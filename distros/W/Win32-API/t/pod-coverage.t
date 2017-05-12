use Test::More;
eval "use Test::Pod::Coverage";
plan skip_all => "Test::Pod::Coverage required for testing pod coverage" if $@;

plan tests => 1;
pod_coverage_ok( "Win32::API", {also_private =>
[qr/DEBUG|ERROR_NOACCESS|FreeLibrary|FromUnicode/,
 qr/GetProcAddress|IVSIZE|IsBadStringPtr|IsUnicode|LoadLibrary|PointerAt/,
 qr/PointerTo|ToUnicode|calltype_to_num|parse_prototype|type_to_num/,
 qr/GetModuleFileName|PTRSIZE|ISCYG|APICONTROL_CC_C|APICONTROL_CC_STD/,
 qr/APICONTROL_CC_mask|APICONTROL_UseMI64|APICONTROL_has_proto/,
 qr/APICONTROL_is_more|ERROR_NOT_ENOUGH_MEMORY|ERROR_INVALID_PARAMETER/,
 qr/T_CHAR|T_NUMCHAR|T_CODE|T_DOUBLE/,
 qr/T_FLAG_NUMERIC|T_FLAG_UNSIGNED|T_FLOAT|T_INTEGER|T_NUMBER|T_POINTER/,
 qr/T_POINTERPOINTER|T_QUAD|T_SHORT|T_STRUCTURE|T_VOID|GetMagicSV|IsGCC/,
 qr/SetMagicSV/
 ]});
