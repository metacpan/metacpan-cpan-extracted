# TODO list for Perl module WebService::BambooHR

* support the login method - I haven't needed that, and don't have
  an application key.
* gradually fill in all other methods not currently supported
* the %field hash in WebService::BambooHR::UserAgent is a hack
* private testsuite that can test `add_employee`, `update_employee`
  and other methods that need write access
* catch exception thrown by HTTP::Tiny and wrap them with
  our own exceptions, so the user gets a consistent experience
  and interface
* `update_employee()` and `employee_photo()` should perhaps let you
  pass an employee object as the first arg, instead of a user id.
* better documentation for the Employee class. Currently relying
  on you using the BambooHR documentation.
* maybe `changed_employees()` should have the timestamp default
  to the epoch, which would return all employee changes in the company.

