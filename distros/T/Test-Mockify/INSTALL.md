## Installing from CPAN

Mockify has been [released on CPAN](https://metacpan.org/pod/Test::Mockify).
Use your favourite CPAN client to install it.

## Building Mockify

Mockify is using [Minilla](https://metacpan.org/pod/Minilla) and
`Build::Module::Tiny` as build tools.

Here is how you can run an build the project.

* Install dependencies:
  yum install openssl-devel
  cpanm --installdeps --notest .

* Run tests

  minil test

* Create distribution tarball

  minil dist

* Install locally

  minil install

* Create a release on CPAN

  minil release

