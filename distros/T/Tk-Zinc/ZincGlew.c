/* Build the bundled GLEW with the same compiler as the Perl extension.
 * TKZINC_PRIVATE_GLEW hides GLEW declarations on Unix; on Windows the
 * MakeMaker-generated .def file exports only the Perl bootstrap function.
 */
#define GLEW_STATIC
#include "third_party/glew/src/glew.c"
