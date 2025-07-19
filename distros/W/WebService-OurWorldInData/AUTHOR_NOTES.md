## Using Dzil

I started with Dzil to get used to the tools. It may not be necessary, but I use
it because I need to make the release process as frictionless as possible.
It was not frictionless today. Other people express reluctance to deal with
Dzil-using modules and I can see why. I finally got it to work as I was downloading
Module::Release. Next time I'll migrate away if I see this note to self.

The one thing I did learn was not to copy the dist.ini file into the tarball.

### checklist

* ```dzil build```      - builds the module
* ```dzil test```       - tests the module
* ```dzil release```    - builds a distribution for uploading to CPAN
* ```dzil release --trial```      - uploads to CPAN but isn't indexed
* ```dzil authordeps --missing``` - find missing module dependancies
* ```dzil mkrpmspec```  - part of the Fedora RPM build process

from the [Release::Checklist](https://metacpan.org/pod/Release::Checklist)
`cpants_lint.pl WebService-OurWorldInData-*.tar.gz`

## TODO

Either remember to set local::lib to local/ or do this before dzil test or release

```
export PERL5LIB=~/perl5/lib/perl5/:~/perl/api_devel/perl-OurWorldInData/local/lib/perl5
```
