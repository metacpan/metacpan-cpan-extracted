#pragma once
#include <xsheader.h>

namespace xs {

namespace next {
    CV* method        (pTHX_ HV* target_class);
    CV* method_strict (pTHX_ HV* target_class);
    CV* method        (pTHX_ HV* target_class, GV* current_sub);
    CV* method_strict (pTHX_ HV* target_class, GV* current_sub);

    inline CV* method        (pTHX_ HV* target_class, CV* current_sub) { return method       (aTHX_ target_class, CvGV(current_sub)); }
    inline CV* method_strict (pTHX_ HV* target_class, CV* current_sub) { return method_strict(aTHX_ target_class, CvGV(current_sub)); }

}

namespace super {
    CV* method        (pTHX_ HV* target_class, GV* current_sub);
    CV* method_strict (pTHX_ HV* target_class, GV* current_sub);

    inline CV* method        (pTHX_ HV* target_class, CV* current_sub) { return method       (aTHX_ target_class, CvGV(current_sub)); }
    inline CV* method_strict (pTHX_ HV* target_class, CV* current_sub) { return method_strict(aTHX_ target_class, CvGV(current_sub)); }
}

}
