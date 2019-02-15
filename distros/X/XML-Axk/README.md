# axk: awk for XML files

## INSTALLATION

To install this module, run the following commands:

    perl Makefile.PL
    make
    make test
    make install

## USAGE

After installation, run `axk`.  Options are similar to `awk`.  Input scripts
are Perl 5.18 with functions to, e.g., run on any node matching a given XPath.
See [L1.md](L1.md) for more details.  For example, the script

    -L1
    on { xpath(q<//item>) } run { say "$NOW: " . $E->getTagName };

or the equivalent command line

    axk -e 'on { xpath(q<//item>) } run { say "$NOW: " . $E->getTagName }' t/ex/ex1.xml

will print the tag name of each `//item` node in the input, along with an
indication (`$NOW`) of whether the action is being run when `entering` or
`leaving` the node.

## SUPPORT AND DOCUMENTATION

After installing, you can find documentation for this module with the
perldoc command:

 - `perldoc XML::Axk::App` for command-line usage instructions
 - `perldoc XML::Axk::L::L1` or [L1.md](L1.md) for the language reference

## LICENSE AND COPYRIGHT

Copyright (C) 2018 Christopher White

Licensed under the
[Artistic License 2.0](http://perldoc.perl.org/perlartistic.html);
see [LICENSE](LICENSE) for more details.

**Disclaimer of Warranty: This package is provided by the copyright holder and
contributors "as is" and without any express or implied warranties.  The
implied warranties of merchantability, fitness for a particular purpose, or
non-infringement are disclaimed to the extent permitted by your local law.
Unless required by law, no copyright holder or contributor will be liable for
any direct, indirect, incidental, or consequential damages arising in any way
out of the use of the package, even if advised of the possibility of such
damage.**
