About this basic/* tests
====================

This directory contains extended tests for WebMVC0 layer.

* To add a new test, run `addtest.zsh`.
* Each `N/t/*.xhf` is run by the test scripts in `N/t/*.t`
  (built on `YATT::Lite::Test::XHFTest2`), for example:

        prove -r samples/basic/
        prove samples/basic/1/t/psgi_offline.t
