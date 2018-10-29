# Bug Reporting and General Help Requests

- Use the [Github Issues Page](https://github.com/pscott-au/WebService-GoogleAPI-Client/issues) 

## Github Repo Management

- Aspiring to [Trunk Based Developent](https://paulhammant.com/2013/04/05/what-is-trunk-based-development/)
- Relase branches are created when package is published to CPAN ( starting V1.12 )


# CONTRIBUTING CODE

- Use perlcritic and perltidy if my bracer style is offensive
- This is my first module using dzilla to package a module - I'm not completely sold on it and may be using it incorrectly - advice on improving usage welcome
- There remain a few architectural bad smells from the original source code this was based on - don't assume that the class structure is sane
- Pull reqeusts preferred but whatever works for you I will try to work with

# HELP WANTED 

- Seek reviews from http://prepan.org/module.submit and similar
- refactor to improve test coverage
- clean up the test structure
- survey other Google Perl modules
- explore handling of batch requests
- API worked examples with help functions
- ability to examine CHI cache and introspect on Client instance metrics ( number of HTTP calls, cache size, TTL data sent/received etc )
- comparison with other language Client libraries
- The structure under the AuthStorage is ugly and needs some love


Github Repo: [https://github.com/pscott-au/WebService-GoogleAPI-Client]

## A few notes
`dzil cover -outputdir docs/cover/`
