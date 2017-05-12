Change History:

0.61 (enno) 8/2/1999
- Added -H option to xql.pl, which is similar to -h, but it doesn't print a 
  file header when there are no query results for that file.
- Fixed memory leak in xql.pl. It wasn't calling dispose on the XML::DOM
  document after it was done processing it, causing it to run out of memory
  when processing a lot of files.
- Fixed the regular expressions for XML tokens to include Unicode values > 127

0.60 (enno) 3/19/1999
- Fixed $lt$ and $ilt$ (operator '<' was working fine)
  (Thanks again, Ingo)
- Implemented ';;' (precedes) and ';' (immediately precedes) operators.
  - Added test cases t/precedes.t and t/immediately_precedes.t
  - Updated docs.
- Fixed dependancies in Makefile.PL. Date::Manip 5.20 (or less) won't work and
  XML::DOM 1.11 won't work. Since I was using Date::Manip 5.33, I now require
  you to do the same. If you don't want to switch, you're free to change the
  version number in Makefile.PL, but I wouldn't recommend it.
  (Thanks to Andrew McNaughton <andrew@squiz.co.nz>)
- Reimplemented code that sorts nodes in document order.
- Fixed bugs in subscript and filter operators (the ones with square brackets)
  - Added testcases t/subscript2.t and t/index2.t
  - In the subscript2 and index2 testcases only the first node was returned
  (Thanks to Christophe Guillon <christophe.guillon@st.com>)
- Fixed all MacOS related build problems. (Those pesky newlines...)
  (Thanks to Arved Sandstrom for helping to fix them.)

0.59 (enno) 2/15/1999
- Performance improvement:
  - Removed automatic inclusion of XML::XQL::Date. Users must now explicitly
    'use XML::XQL::Date;' if they want to use date() or Date objects.
  - Performance analysis showed that about 75% was spent building the DOM
    (with DOM 1.14), so let's optimize the DOM further first...
- Fixed typos and grammar in the XML::XQL POD and Tutorial.
  (Thanks to John Durand <jrd@oz.net>)
- Fixed the collection functions: comment(), element() etc. They would throw
  exceptions like "Can't call method "_nodesByType" on an undefined value..."
  (Thanks to Ingo Macherius <macherius@darmstadt.gmd.de>)
- Added t/comment.t test case.
- Made most XQL functions process the entire list of input nodes, rather than
  just the first one. This allows queries like "//comment()".
- Fixed bug in 'sort in document order' (sortBySrcNode) 
  This was used by $union$ and now also by collection functions.
- Fixed attribute() function. It ignored the optional parameter.

0.58 (enno) 1/25/1999
- Fixed bug in text() for Element nodes. It would sometimes omit the contents
  of certain text nodes when merging text within an Element node.
  (Thanks to Marcin Jagodzinski <marcinj@quake.org.pl>)
- text(0) and rawText(0) for Element nodes would include child Element nodes
  (contrary to the POD documentation)
- Added t/text.t test case.

0.57 (enno) 1/22/1999
- Fixed code related to sorting in document order when the node list contains
  Attribute nodes.
  (Thanks to Martin Virtel <virtel@zeit.de>)

0.56 (enno) 1/20/1999
- Fixed Subscript related code (e.g. for queries a la "//author[2]") and
  added testcase t/subscript.t
  It used to throw the following exception:
  "Can't call method "setParent" without a package or object reference..."
  (Thanks to Arved Sandstrom <Arved_37@chebucto.ns.ca>)

0.55 (enno) 1/13/1999
- Added XML::DOM to dependancy list in Makefile.PL

0.54 (enno) 1/7/1999
- XQL keywords are now case-insensitive and dollar delimiters may be omitted.
- Changed regexp "s/^(\s*|#.*)*//" to "s/^(\s|#.*)*//" to avoid error "regexp *+
  operand can be empty" with Perl 5.004_4
- Removed build warnings a la 'Ambiguous use of ...' with Perl 5.004_4
  (Thanks to Tony Hammond <tony_hammond@harcourtbrace.com>)

0.53 (enno) 12/21/1998
- Fixed Union operator (bug in sorting code)
- Fixed XQL+ operators
- Changed Element::xql_text and Element::xql_rawText (i.e. text() and rawText() 
  methods) to recurse by default.
- Added defineElementValueConvertor() and defineAttrValueConvertor() to
  support user defined conversion of Element and Attribute value() results.
- Added samples/xql.pl. A nifty utility that performs XQL queries on files
  and formats the output in multiple ways, or modifies XML files in place.
  (Run xql.pl without parameters for Usage description.)
- Wrote Tutorial (use man XML::XQL::Tutorial)
- Added DOM_nodeType() method
- Changed default nodeType() from -1 to 0. This is returned for primitives.
- nodeType returns same as DOM_nodeType for all node types other than 
  CDATASection and EntityReference. It used to return -1 for node types not
  specified in the XQL spec.
- Fixed nodeTypeString() for processing instructions from "pi" to
  "processing_instruction" (as per the XQL spec)
- Fixed prefix(). It used to return the entire nodeName if there was no prefix.
- Changed t/sin2.t test case, so it won't spit out warnings
- Simplified build environment

0.52 (enno) 12/10/1998
- Fixed Makefiles and put submodules in subdirectories.
  (I had some soft links in my development environment, so everything
  worked for me. I forgot to test the installation from scratch. Sorry...)
- Added XML::DOM::Element::xql_rawTextBlocks for use in subst, map etc.
- Changed subst() to work on 'text blocks' for Element nodes by default.
  Added MODE parameter. MODE=1 uses value() for Elements, just like version 0.51
- subst() uses xql_setValue to modify objects that match. It used to create a new
  object when it matched an XQL primitive (to prevent people from modifying
  constants in the XQL query expression), but on second thought it doesn't seem
  likely that that will be a problem. (Hell, it might be a feature :-)
- Fixed generateFunction for when ARGCOUNT = [N, -1]
- Added new() function
- Cleaned up Date class and modified date() function accordingly
- Added defineExpandedTypes()
- Added more stuff to the POD documentation.

0.51 (enno) 12/7/1998
- First alpha release. Announced to Perl-XML mailing list.
