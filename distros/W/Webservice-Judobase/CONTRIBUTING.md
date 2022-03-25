# Hello!

Thanks for considering contributing to this module, it is appreciated.

To help you get started (and to remind me) here is how to get started.

I use carton and the cpanfile to manage dependencies in development. So
you will want to install carton and then install dependencies with that

 carton install

Once you have carton and the dependencies installed you can run the tests
with

  carton exec dzil test

This runs the unit tests and a selection of tests from the dist.ini and
Dist::Zilla. As teh code talks to a real API, the tests that use that
are in `xt` rather than `t` which you can run with:

  carton exec prove -lvr xt

Those tests do fail occasionally if the data in the API changes, as the
tests are perhaps too specific.

All the code is here: https://github.com/lancew/Webservice-Judobase

If you'd like to fibd something to work on, or report something that
does not work, or might be good to add, look at the issues page.
Documentation changes are always appreciated.

