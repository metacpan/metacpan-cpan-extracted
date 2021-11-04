/* vi: set ft=c : */

#ifndef OP_CHECK_MUTEX_LOCK /* < 5.15.8 */
#  define OP_CHECK_MUTEX_LOCK ((void)0)
#  define OP_CHECK_MUTEX_UNLOCK ((void)0)
#endif

#define wrap_keyword_plugin(func, var)  S_wrap_keyword_plugin(aTHX_ func, var)

static void S_wrap_keyword_plugin(pTHX_ Perl_keyword_plugin_t func, Perl_keyword_plugin_t *var)
{
  /* BOOT can potentially race with other threads (RT123547) */

  /* Perl doesn't really provide us a nice mutex for doing this so this is the
   * best we can find. See also
   *   https://rt.perl.org/Public/Bug/Display.html?id=132413
   */
  if(*var)
    return;

  OP_CHECK_MUTEX_LOCK;
  if(!*var) {
    *var = PL_keyword_plugin;
    PL_keyword_plugin = func;
  }

  OP_CHECK_MUTEX_UNLOCK;
}
