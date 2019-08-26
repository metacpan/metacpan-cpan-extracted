#pragma once
#include <xsheader.h>

namespace xs {

namespace next {
    CV* method        (HV* target_class);
    CV* method_strict (HV* target_class);
    CV* method        (HV* target_class, GV* current_sub);
    CV* method_strict (HV* target_class, GV* current_sub);

    inline CV* method        (HV* target_class, CV* current_sub) { dTHX; return method       (target_class, CvGV(current_sub)); }
    inline CV* method_strict (HV* target_class, CV* current_sub) { dTHX; return method_strict(target_class, CvGV(current_sub)); }
}

namespace super {
    CV* method        (HV* target_class, GV* current_sub);
    CV* method_strict (HV* target_class, GV* current_sub);

    inline CV* method        (HV* target_class, CV* current_sub) { dTHX; return method       (target_class, CvGV(current_sub)); }
    inline CV* method_strict (HV* target_class, CV* current_sub) { dTHX; return method_strict(target_class, CvGV(current_sub)); }
}

}
