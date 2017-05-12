/* trigger __RTC_InitBase and __RTC_Shutdown ctor/dtor to run from rtc.dll
   and not have to do it from API_test.dll.
*/
void dummy_for_RTC(int i, ...) {
    return;
}
