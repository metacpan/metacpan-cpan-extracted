# Tk::ObjScanner

Tk::ObjScanner is a Perl/Tk module that provides a GUI to scan any perl data including the
attributes of an object.

The scanner is a composite widget made of a HList. This widget acts as
a scanner to the object (or hash ref) passed with the 'caller'
parameter. The scanner will retrieve all keys of the hash/object and
insert them in the HList.

When the user double clicks on a key, the corresponding value will be
added in the HList. If the user use the middle button to open a tied
item, the internals of the tied object will be displayed.

If the value is a scalar, the scalar will be displayed in a popup text
window.

If the value is a code ref, the deparsed code will be displayed in a
popup text window.

This widget can be used as a regular widget in a Tk application or can
be used as an autonomous popup widget that will display the content of
a data structure. The latter is like a call to a graphical
Data::Dumper.

The scanner recognizes:
- tied hashes arrays or scalars
- weak reference (See weaken function of Scalar::Util for details)

**Pseudo-hashes are deprecated**

This module was tested with perl5.8.2 and Tk 804.025 (beta). But
should work with older versions of perl (> 5.6.1) or Tk.

See the embedded documentation in the module for more details.

**Note** that test program (in the 't' directory) can be run interactively
this way :

```
 perl t/xxx.t 1
```

### Installation
```
gunzip -c <dist_file>.tar.gz | tar xvf -
cd <dist_directory>
perl Makefile.PL
make test          
make install
```
From github, this module is built with **Dist::Zilla**.

You must make sure that the following modules are installed:

```
Dist::Zilla::Plugin::MetaResources
Dist::Zilla::Plugin::Prepender
Dist::Zilla::Plugin::Prereqs
Dist::Zilla::PluginBundle::Filter
```

On debian or ubuntu, do:

```
sudo aptitude install \
     libdist-zilla-plugin-prepender-perl \
     libdist-zilla-plugins-cjm-perl \
     libdist-zilla-perl
```

Then run:
```
dzil build 
```
or 
```
dzil test
dzil build
```

---

Comments and suggestions are always welcome.

## Contributors

Many thanks to **Achim Bohnet** for all the tests, patches (and reports) he 
made. Many improvements were made thanks to his efforts.

Thanks to **Rudi Farkas** for the 'watch' patch.

Thanks to **Slavec Rezic** for the pseudo-hash prototype.

Thanks to **heytitle** for the documentation fixes

Thanks to **E. Choroba** for the retro compatibility patch

## Legalese

Copyright &copy; 1997-2004,2007,2014,2017 **Dominique Dumont**. All rights reserved.
 
This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

**- Dominique Dumont ( ddumont at cpan.org )**
