#!perl -T

use strict;
use warnings;
use Test::More tests => 32;

use XML::Rules;

my $XML = <<'*END*';
<root>
	<tag>
		<subtag>no spaces</subtag>
		<subtag>     leading spaces</subtag>
		<subtag>trailing spaces      </subtag>
		<subtag>  both spaces    </subtag>
		<subtag>multiple    spaces</subtag>
	</tag>
	<otherroot>
		<other id="no spaces"><empty/></other>
		<other id="no spaces 2"><empty/><empty/></other>
		<other id="leading spaces">  <empty/></other>
		<other id="leading spaces 2">  <empty/><empty/></other>
		<other id="content and leading spaces">blah     <empty/></other>
		<other id="content and leading spaces 2">blah     <empty/><empty/></other>
		<other id="trailing spaces"><empty/>  </other>
		<other id="trailing spaces 2"><empty/><empty/>  </other>
		<other id="content and trailing spaces"><empty/>       blah</other>
		<other id="content and trailing spaces 2"><empty/><empty/>       blah</other>
		<other id="both spaces">   <empty/> </other>
		<other id="both spaces 2">   <empty/><empty/>   </other>
		<other id="all spaces">   <empty/>   <empty/>   </other>
	</otherroot>

	<someroot>
		<some id="mixed"><empty/><nonempty>hello</nonempty></some>
		<some id="mixed1"> <empty/><nonempty>hello</nonempty></some>
		<some id="mixed2"><empty/> <nonempty>hello</nonempty></some>
		<some id="mixed3"><empty/><nonempty>hello</nonempty> </some>
		<some id="mixed12"> <empty/> <nonempty>hello</nonempty></some>
		<some id="mixed13"> <empty/><nonempty>hello</nonempty> </some>
		<some id="mixed123"> <empty/> <nonempty>hello</nonempty> </some>
	</someroot>

	<someroot2>
		<some id="mixed">a<empty/>b<nonempty>hello</nonempty>c</some>
		<some id="mixed1"> a <empty/>b<nonempty>hello</nonempty>c</some>
		<some id="mixed2">a<empty/> b <nonempty>hello</nonempty>c</some>
		<some id="mixed3">a<empty/>b<nonempty>hello</nonempty> c </some>
		<some id="mixed12"> a <empty/> b <nonempty>hello</nonempty>c</some>
		<some id="mixed13"> a <empty/>b<nonempty>hello</nonempty> c </some>
		<some id="mixed123"> a <empty/>	b <nonempty>hello</nonempty> c </some>
	</someroot2>
</root>
*END*

my %good = (
          '12,1' => {
                      'root' => {
                                'someroot' => {
                                              'mixed13' => '(hello)',
                                              'mixed12' => '(hello)',
                                              'mixed2' => '(hello)',
                                              'mixed1' => '(hello)',
                                              'mixed123' => '(hello)',
                                              'mixed3' => '(hello)',
                                              'mixed' => '(hello)'
                                            },
                                'someroot2' => {
                                               'mixed13' => 'a b(hello) c',
                                               'mixed12' => 'a b (hello)c',
                                               'mixed2' => 'a b (hello)c',
                                               'mixed1' => 'a b(hello)c',
                                               'mixed123' => 'a b (hello) c',
                                               'mixed3' => 'ab(hello) c',
                                               'mixed' => 'ab(hello)c'
                                             },
                                'otherroot' => {
                                               'trailing spaces 2' => undef,
                                               'leading spaces 2' => undef,
                                               'leading spaces' => undef,
                                               'no spaces 2' => undef,
                                               'no spaces' => undef,
                                               'trailing spaces' => undef,
                                               'content and trailing spaces 2' => 'blah',
                                               'content and trailing spaces' => 'blah',
                                               'both spaces' => undef,
                                               'all spaces' => undef,
                                               'content and leading spaces' => 'blah',
                                               'both spaces 2' => undef,
                                               'content and leading spaces 2' => 'blah'
                                             },
                                'tag' => '(no spaces) (leading spaces) (trailing spaces) (both spaces) (multiple spaces)'
                              }
                    },
          '12,0' => {
                      'root' => {
                                'someroot' => {
                                              'mixed13' => '(hello)',
                                              'mixed12' => '(hello)',
                                              'mixed2' => '(hello)',
                                              'mixed1' => '(hello)',
                                              'mixed123' => '(hello)',
                                              'mixed3' => '(hello)',
                                              'mixed' => '(hello)'
                                            },
                                'someroot2' => {
                                               'mixed13' => 'a b(hello) c',
                                               'mixed12' => 'a  b (hello)c',
                                               'mixed2' => 'a b (hello)c',
                                               'mixed1' => 'a b(hello)c',
                                               'mixed123' => 'a 	b (hello) c',
                                               'mixed3' => 'ab(hello) c',
                                               'mixed' => 'ab(hello)c'
                                             },
                                'otherroot' => {
                                               'trailing spaces 2' => undef,
                                               'leading spaces 2' => undef,
                                               'leading spaces' => undef,
                                               'no spaces 2' => undef,
                                               'no spaces' => undef,
                                               'trailing spaces' => undef,
                                               'content and trailing spaces 2' => 'blah',
                                               'content and trailing spaces' => 'blah',
                                               'both spaces' => undef,
                                               'all spaces' => undef,
                                               'content and leading spaces' => 'blah',
                                               'both spaces 2' => undef,
                                               'content and leading spaces 2' => 'blah'
                                             },
                                'tag' => '(no spaces)
		(leading spaces)
		(trailing spaces)
		(both spaces)
		(multiple    spaces)'
                              }
                    },
          '10,0' => {
                      'root' => {
                                'someroot' => {
                                              'mixed13' => '(hello)',
                                              'mixed12' => '(hello)',
                                              'mixed2' => '(hello)',
                                              'mixed1' => '(hello)',
                                              'mixed123' => '(hello)',
                                              'mixed3' => '(hello)',
                                              'mixed' => '(hello)'
                                            },
                                'someroot2' => {
                                               'mixed13' => 'a b(hello) c',
                                               'mixed12' => 'a  b (hello)c',
                                               'mixed2' => 'a b (hello)c',
                                               'mixed1' => 'a b(hello)c',
                                               'mixed123' => 'a 	b (hello) c',
                                               'mixed3' => 'ab(hello) c',
                                               'mixed' => 'ab(hello)c'
                                             },
                                'otherroot' => {
                                               'trailing spaces 2' => undef,
                                               'leading spaces 2' => undef,
                                               'leading spaces' => undef,
                                               'no spaces 2' => undef,
                                               'no spaces' => undef,
                                               'trailing spaces' => undef,
                                               'content and trailing spaces 2' => 'blah',
                                               'content and trailing spaces' => 'blah',
                                               'both spaces' => undef,
                                               'all spaces' => undef,
                                               'content and leading spaces' => 'blah',
                                               'both spaces 2' => undef,
                                               'content and leading spaces 2' => 'blah'
                                             },
                                'tag' => '(no spaces)
		(leading spaces)
		(trailing spaces)
		(both spaces)
		(multiple    spaces)'
                              }
                    },
          '7,0' => {
                     'root' => {
                               'someroot' => {
                                             'mixed13' => '(hello)',
                                             'mixed12' => '(hello)',
                                             'mixed2' => '(hello)',
                                             'mixed1' => '(hello)',
                                             'mixed123' => '(hello)',
                                             'mixed3' => '(hello)',
                                             'mixed' => '(hello)'
                                           },
                               'someroot2' => {
                                              'mixed13' => ' ab(hello)c ',
                                              'mixed12' => ' ab(hello)c',
                                              'mixed2' => 'ab(hello)c',
                                              'mixed1' => ' ab(hello)c',
                                              'mixed123' => ' ab(hello)c ',
                                              'mixed3' => 'ab(hello)c ',
                                              'mixed' => 'ab(hello)c'
                                            },
                               'otherroot' => {
                                              'trailing spaces 2' => undef,
                                              'leading spaces 2' => undef,
                                              'leading spaces' => undef,
                                              'no spaces 2' => undef,
                                              'no spaces' => undef,
                                              'trailing spaces' => undef,
                                              'content and trailing spaces 2' => 'blah',
                                              'content and trailing spaces' => 'blah',
                                              'both spaces' => undef,
                                              'all spaces' => undef,
                                              'content and leading spaces' => 'blah',
                                              'both spaces 2' => undef,
                                              'content and leading spaces 2' => 'blah'
                                            },
                               'tag' => '(no spaces)(     leading spaces)(trailing spaces      )(  both spaces    )(multiple    spaces)'
                             }
                   },
          '9,0' => {
                     'root' => {
                               'someroot' => {
                                             'mixed13' => '(hello)',
                                             'mixed12' => '(hello)',
                                             'mixed2' => '(hello)',
                                             'mixed1' => '(hello)',
                                             'mixed123' => '(hello)',
                                             'mixed3' => '(hello)',
                                             'mixed' => '(hello)'
                                           },
                               'someroot2' => {
                                              'mixed13' => 'a b(hello) c',
                                              'mixed12' => 'a  b (hello)c',
                                              'mixed2' => 'a b (hello)c',
                                              'mixed1' => 'a b(hello)c',
                                              'mixed123' => 'a 	b (hello) c',
                                              'mixed3' => 'ab(hello) c',
                                              'mixed' => 'ab(hello)c'
                                            },
                               'otherroot' => {
                                              'trailing spaces 2' => undef,
                                              'leading spaces 2' => undef,
                                              'leading spaces' => undef,
                                              'no spaces 2' => undef,
                                              'no spaces' => undef,
                                              'trailing spaces' => undef,
                                              'content and trailing spaces 2' => 'blah',
                                              'content and trailing spaces' => 'blah',
                                              'both spaces' => undef,
                                              'all spaces' => undef,
                                              'content and leading spaces' => 'blah',
                                              'both spaces 2' => undef,
                                              'content and leading spaces 2' => 'blah'
                                            },
                               'tag' => '(no spaces)
		(leading spaces)
		(trailing spaces)
		(both spaces)
		(multiple    spaces)'
                             }
                   },
          '14,0' => {
                      'root' => {
                                'someroot' => {
                                              'mixed13' => '(hello)',
                                              'mixed12' => '(hello)',
                                              'mixed2' => '(hello)',
                                              'mixed1' => '(hello)',
                                              'mixed123' => '(hello)',
                                              'mixed3' => '(hello)',
                                              'mixed' => '(hello)'
                                            },
                                'someroot2' => {
                                               'mixed13' => 'ab(hello) c',
                                               'mixed12' => 'ab (hello)c',
                                               'mixed2' => 'ab (hello)c',
                                               'mixed1' => 'ab(hello)c',
                                               'mixed123' => 'ab (hello) c',
                                               'mixed3' => 'ab(hello) c',
                                               'mixed' => 'ab(hello)c'
                                             },
                                'otherroot' => {
                                               'trailing spaces 2' => undef,
                                               'leading spaces 2' => undef,
                                               'leading spaces' => undef,
                                               'no spaces 2' => undef,
                                               'no spaces' => undef,
                                               'trailing spaces' => undef,
                                               'content and trailing spaces 2' => 'blah',
                                               'content and trailing spaces' => 'blah',
                                               'both spaces' => undef,
                                               'all spaces' => undef,
                                               'content and leading spaces' => 'blah',
                                               'both spaces 2' => undef,
                                               'content and leading spaces 2' => 'blah'
                                             },
                                'tag' => '(no spaces)
		(leading spaces)
		(trailing spaces)
		(both spaces)
		(multiple    spaces)'
                              }
                    },
          '5,1' => {
                     'root' => {
                               'someroot' => {
                                             'mixed123' => ' (hello) ',
                                             'mixed12' => ' (hello)',
                                             'mixed13' => '(hello) ',
                                             'mixed1' => '(hello)',
                                             'mixed2' => ' (hello)',
                                             'mixed' => '(hello)',
                                             'mixed3' => '(hello) '
                                           },
                               'someroot2' => {
                                              'mixed123' => ' a b (hello) c ',
                                              'mixed12' => ' a b (hello)c',
                                              'mixed13' => ' ab(hello) c ',
                                              'mixed1' => ' ab(hello)c',
                                              'mixed2' => 'a b (hello)c',
                                              'mixed' => 'ab(hello)c',
                                              'mixed3' => 'ab(hello) c '
                                            },
                               'otherroot' => {
                                              'trailing spaces 2' => ' ',
                                              'leading spaces 2' => undef,
                                              'leading spaces' => undef,
                                              'no spaces 2' => undef,
                                              'no spaces' => undef,
                                              'trailing spaces' => ' ',
                                              'content and trailing spaces 2' => ' blah',
                                              'content and trailing spaces' => ' blah',
                                              'both spaces' => ' ',
                                              'all spaces' => ' ',
                                              'content and leading spaces' => 'blah',
                                              'both spaces 2' => ' ',
                                              'content and leading spaces 2' => 'blah'
                                            },
                               'tag' => ' (no spaces) ( leading spaces) (trailing spaces ) ( both spaces ) (multiple spaces) '
                             }
                   },
          '11,1' => {
                      'root' => {
                                'someroot' => {
                                              'mixed13' => '(hello)',
                                              'mixed12' => '(hello)',
                                              'mixed2' => '(hello)',
                                              'mixed1' => '(hello)',
                                              'mixed123' => '(hello)',
                                              'mixed3' => '(hello)',
                                              'mixed' => '(hello)'
                                            },
                                'someroot2' => {
                                               'mixed13' => 'a b(hello) c',
                                               'mixed12' => 'a b (hello)c',
                                               'mixed2' => 'a b (hello)c',
                                               'mixed1' => 'a b(hello)c',
                                               'mixed123' => 'a b (hello) c',
                                               'mixed3' => 'ab(hello) c',
                                               'mixed' => 'ab(hello)c'
                                             },
                                'otherroot' => {
                                               'trailing spaces 2' => undef,
                                               'leading spaces 2' => undef,
                                               'leading spaces' => undef,
                                               'no spaces 2' => undef,
                                               'no spaces' => undef,
                                               'trailing spaces' => undef,
                                               'content and trailing spaces 2' => ' blah',
                                               'content and trailing spaces' => ' blah',
                                               'both spaces' => undef,
                                               'all spaces' => undef,
                                               'content and leading spaces' => 'blah',
                                               'both spaces 2' => undef,
                                               'content and leading spaces 2' => 'blah'
                                             },
                                'tag' => '(no spaces)(leading spaces)(trailing spaces)(both spaces)(multiple spaces)'
                              }
                    },
          '4,0' => {
                     'root' => {
                               'someroot' => {
                                             'mixed123' => '  (hello) ',
                                             'mixed12' => '  (hello)',
                                             'mixed13' => ' (hello) ',
                                             'mixed1' => ' (hello)',
                                             'mixed2' => ' (hello)',
                                             'mixed' => '(hello)',
                                             'mixed3' => '(hello) '
                                           },
                               'someroot2' => {
                                              'mixed123' => ' a 	b (hello) c ',
                                              'mixed12' => ' a  b (hello)c',
                                              'mixed13' => ' a b(hello) c ',
                                              'mixed1' => ' a b(hello)c',
                                              'mixed2' => 'a b (hello)c',
                                              'mixed' => 'ab(hello)c',
                                              'mixed3' => 'ab(hello) c '
                                            },
                               'otherroot' => {
                                              'trailing spaces 2' => '  ',
                                              'leading spaces 2' => '  ',
                                              'leading spaces' => '  ',
                                              'no spaces 2' => undef,
                                              'no spaces' => undef,
                                              'trailing spaces' => '  ',
                                              'content and trailing spaces 2' => '       blah',
                                              'both spaces' => '    ',
                                              'content and trailing spaces' => '       blah',
                                              'all spaces' => '         ',
                                              'content and leading spaces' => 'blah     ',
                                              'both spaces 2' => '      ',
                                              'content and leading spaces 2' => 'blah     '
                                            },
                               'tag' => '
		(no spaces)
		(     leading spaces)
		(trailing spaces      )
		(  both spaces    )
		(multiple    spaces)
	'
                             }
                   },
          '15,0' => {
                      'root' => {
                                'someroot' => {
                                              'mixed13' => '(hello)',
                                              'mixed12' => '(hello)',
                                              'mixed2' => '(hello)',
                                              'mixed1' => '(hello)',
                                              'mixed123' => '(hello)',
                                              'mixed3' => '(hello)',
                                              'mixed' => '(hello)'
                                            },
                                'someroot2' => {
                                               'mixed13' => 'ab(hello)c',
                                               'mixed12' => 'ab(hello)c',
                                               'mixed2' => 'ab(hello)c',
                                               'mixed1' => 'ab(hello)c',
                                               'mixed123' => 'ab(hello)c',
                                               'mixed3' => 'ab(hello)c',
                                               'mixed' => 'ab(hello)c'
                                             },
                                'otherroot' => {
                                               'trailing spaces 2' => undef,
                                               'leading spaces 2' => undef,
                                               'leading spaces' => undef,
                                               'no spaces 2' => undef,
                                               'no spaces' => undef,
                                               'trailing spaces' => undef,
                                               'content and trailing spaces 2' => 'blah',
                                               'content and trailing spaces' => 'blah',
                                               'both spaces' => undef,
                                               'all spaces' => undef,
                                               'content and leading spaces' => 'blah',
                                               'both spaces 2' => undef,
                                               'content and leading spaces 2' => 'blah'
                                             },
                                'tag' => '(no spaces)(leading spaces)(trailing spaces)(both spaces)(multiple    spaces)'
                              }
                    },
          '2,1' => {
                     'root' => {
                               'someroot' => {
                                             'mixed13' => '(hello) ',
                                             'mixed12' => '(hello)',
                                             'mixed2' => ' (hello)',
                                             'mixed1' => '(hello)',
                                             'mixed123' => '(hello) ',
                                             'mixed3' => '(hello) ',
                                             'mixed' => '(hello)'
                                           },
                               'someroot2' => {
                                              'mixed13' => ' a b(hello) c ',
                                              'mixed12' => ' a b (hello)c',
                                              'mixed2' => 'a b (hello)c',
                                              'mixed1' => ' a b(hello)c',
                                              'mixed123' => ' a b (hello) c ',
                                              'mixed3' => 'ab(hello) c ',
                                              'mixed' => 'ab(hello)c'
                                            },
                               'otherroot' => {
                                              'trailing spaces 2' => ' ',
                                              'leading spaces 2' => undef,
                                              'leading spaces' => undef,
                                              'no spaces 2' => undef,
                                              'no spaces' => undef,
                                              'trailing spaces' => ' ',
                                              'content and trailing spaces 2' => ' blah',
                                              'content and trailing spaces' => ' blah',
                                              'both spaces' => undef,
                                              'all spaces' => undef,
                                              'content and leading spaces' => 'blah ',
                                              'both spaces 2' => undef,
                                              'content and leading spaces 2' => 'blah '
                                            },
                               'tag' => ' (no spaces) ( leading spaces) (trailing spaces ) ( both spaces ) (multiple spaces) '
                             }
                   },
          '13,0' => {
                      'root' => {
                                'someroot' => {
                                              'mixed13' => '(hello)',
                                              'mixed12' => '(hello)',
                                              'mixed2' => '(hello)',
                                              'mixed1' => '(hello)',
                                              'mixed123' => '(hello)',
                                              'mixed3' => '(hello)',
                                              'mixed' => '(hello)'
                                            },
                                'someroot2' => {
                                               'mixed13' => 'ab(hello) c',
                                               'mixed12' => 'a b (hello)c',
                                               'mixed2' => 'a b (hello)c',
                                               'mixed1' => 'ab(hello)c',
                                               'mixed123' => 'a	b (hello) c',
                                               'mixed3' => 'ab(hello) c',
                                               'mixed' => 'ab(hello)c'
                                             },
                                'otherroot' => {
                                               'trailing spaces 2' => undef,
                                               'leading spaces 2' => undef,
                                               'leading spaces' => undef,
                                               'no spaces 2' => undef,
                                               'no spaces' => undef,
                                               'trailing spaces' => undef,
                                               'content and trailing spaces 2' => 'blah',
                                               'content and trailing spaces' => 'blah',
                                               'both spaces' => undef,
                                               'all spaces' => undef,
                                               'content and leading spaces' => 'blah',
                                               'both spaces 2' => undef,
                                               'content and leading spaces 2' => 'blah'
                                             },
                                'tag' => '(no spaces)
		(leading spaces)
		(trailing spaces)
		(both spaces)
		(multiple    spaces)'
                              }
                    },
          '1,1' => {
                     'root' => {
                               'someroot' => {
                                             'mixed123' => ' (hello) ',
                                             'mixed12' => ' (hello)',
                                             'mixed13' => '(hello) ',
                                             'mixed1' => '(hello)',
                                             'mixed2' => ' (hello)',
                                             'mixed' => '(hello)',
                                             'mixed3' => '(hello) '
                                           },
                               'someroot2' => {
                                              'mixed123' => ' a b (hello) c ',
                                              'mixed12' => ' a b (hello)c',
                                              'mixed13' => ' a b(hello) c ',
                                              'mixed1' => ' a b(hello)c',
                                              'mixed2' => 'a b (hello)c',
                                              'mixed' => 'ab(hello)c',
                                              'mixed3' => 'ab(hello) c '
                                            },
                               'otherroot' => {
                                              'trailing spaces 2' => ' ',
                                              'leading spaces 2' => undef,
                                              'leading spaces' => undef,
                                              'no spaces 2' => undef,
                                              'no spaces' => undef,
                                              'trailing spaces' => ' ',
                                              'content and trailing spaces 2' => ' blah',
                                              'content and trailing spaces' => ' blah',
                                              'both spaces' => ' ',
                                              'all spaces' => ' ',
                                              'content and leading spaces' => 'blah ',
                                              'both spaces 2' => ' ',
                                              'content and leading spaces 2' => 'blah '
                                            },
                               'tag' => ' (no spaces) ( leading spaces) (trailing spaces ) ( both spaces ) (multiple spaces) '
                             }
                   },
          '1,0' => {
                     'root' => {
                               'someroot' => {
                                             'mixed123' => ' (hello) ',
                                             'mixed12' => ' (hello)',
                                             'mixed13' => '(hello) ',
                                             'mixed1' => '(hello)',
                                             'mixed2' => ' (hello)',
                                             'mixed' => '(hello)',
                                             'mixed3' => '(hello) '
                                           },
                               'someroot2' => {
                                              'mixed123' => ' a 	b (hello) c ',
                                              'mixed12' => ' a  b (hello)c',
                                              'mixed13' => ' a b(hello) c ',
                                              'mixed1' => ' a b(hello)c',
                                              'mixed2' => 'a b (hello)c',
                                              'mixed' => 'ab(hello)c',
                                              'mixed3' => 'ab(hello) c '
                                            },
                               'otherroot' => {
                                              'trailing spaces 2' => '  ',
                                              'leading spaces 2' => undef,
                                              'leading spaces' => undef,
                                              'no spaces 2' => undef,
                                              'no spaces' => undef,
                                              'trailing spaces' => '  ',
                                              'content and trailing spaces 2' => '       blah',
                                              'content and trailing spaces' => '       blah',
                                              'both spaces' => ' ',
                                              'all spaces' => '   ',
                                              'content and leading spaces' => 'blah     ',
                                              'both spaces 2' => '   ',
                                              'content and leading spaces 2' => 'blah     '
                                            },
                               'tag' => '
		(no spaces)
		(     leading spaces)
		(trailing spaces      )
		(  both spaces    )
		(multiple    spaces)
	'
                             }
                   },
          '7,1' => {
                     'root' => {
                               'someroot' => {
                                             'mixed13' => '(hello)',
                                             'mixed12' => '(hello)',
                                             'mixed2' => '(hello)',
                                             'mixed1' => '(hello)',
                                             'mixed123' => '(hello)',
                                             'mixed3' => '(hello)',
                                             'mixed' => '(hello)'
                                           },
                               'someroot2' => {
                                              'mixed13' => ' ab(hello)c ',
                                              'mixed12' => ' ab(hello)c',
                                              'mixed2' => 'ab(hello)c',
                                              'mixed1' => ' ab(hello)c',
                                              'mixed123' => ' ab(hello)c ',
                                              'mixed3' => 'ab(hello)c ',
                                              'mixed' => 'ab(hello)c'
                                            },
                               'otherroot' => {
                                              'trailing spaces 2' => undef,
                                              'leading spaces 2' => undef,
                                              'leading spaces' => undef,
                                              'no spaces 2' => undef,
                                              'no spaces' => undef,
                                              'trailing spaces' => undef,
                                              'content and trailing spaces 2' => 'blah',
                                              'content and trailing spaces' => 'blah',
                                              'both spaces' => undef,
                                              'all spaces' => undef,
                                              'content and leading spaces' => 'blah',
                                              'both spaces 2' => undef,
                                              'content and leading spaces 2' => 'blah'
                                            },
                               'tag' => '(no spaces)( leading spaces)(trailing spaces )( both spaces )(multiple spaces)'
                             }
                   },
          '3,0' => {
                     'root' => {
                               'someroot' => {
                                             'mixed13' => '(hello)',
                                             'mixed12' => '(hello)',
                                             'mixed2' => '(hello)',
                                             'mixed1' => '(hello)',
                                             'mixed123' => '(hello)',
                                             'mixed3' => '(hello)',
                                             'mixed' => '(hello)'
                                           },
                               'someroot2' => {
                                              'mixed13' => ' a b(hello) c ',
                                              'mixed12' => ' a  b (hello)c',
                                              'mixed2' => 'a b (hello)c',
                                              'mixed1' => ' a b(hello)c',
                                              'mixed123' => ' a 	b (hello) c ',
                                              'mixed3' => 'ab(hello) c ',
                                              'mixed' => 'ab(hello)c'
                                            },
                               'otherroot' => {
                                              'trailing spaces 2' => undef,
                                              'leading spaces 2' => undef,
                                              'leading spaces' => undef,
                                              'no spaces 2' => undef,
                                              'no spaces' => undef,
                                              'trailing spaces' => undef,
                                              'content and trailing spaces 2' => '       blah',
                                              'content and trailing spaces' => '       blah',
                                              'both spaces' => undef,
                                              'all spaces' => undef,
                                              'content and leading spaces' => 'blah     ',
                                              'both spaces 2' => undef,
                                              'content and leading spaces 2' => 'blah     '
                                            },
                               'tag' => '(no spaces)(     leading spaces)(trailing spaces      )(  both spaces    )(multiple    spaces)'
                             }
                   },
          '0,1' => {
                     'root' => {
                               'someroot' => {
                                             'mixed123' => ' (hello) ',
                                             'mixed12' => ' (hello)',
                                             'mixed13' => ' (hello) ',
                                             'mixed1' => ' (hello)',
                                             'mixed2' => ' (hello)',
                                             'mixed' => '(hello)',
                                             'mixed3' => '(hello) '
                                           },
                               'someroot2' => {
                                              'mixed123' => ' a b (hello) c ',
                                              'mixed12' => ' a b (hello)c',
                                              'mixed13' => ' a b(hello) c ',
                                              'mixed1' => ' a b(hello)c',
                                              'mixed2' => 'a b (hello)c',
                                              'mixed' => 'ab(hello)c',
                                              'mixed3' => 'ab(hello) c '
                                            },
                               'otherroot' => {
                                              'trailing spaces 2' => ' ',
                                              'leading spaces 2' => ' ',
                                              'leading spaces' => ' ',
                                              'no spaces 2' => undef,
                                              'no spaces' => undef,
                                              'trailing spaces' => ' ',
                                              'content and trailing spaces 2' => ' blah',
                                              'both spaces' => ' ',
                                              'content and trailing spaces' => ' blah',
                                              'all spaces' => ' ',
                                              'content and leading spaces' => 'blah ',
                                              'both spaces 2' => ' ',
                                              'content and leading spaces 2' => 'blah '
                                            },
                               'tag' => ' (no spaces) ( leading spaces) (trailing spaces ) ( both spaces ) (multiple spaces) '
                             }
                   },
          '0,0' => {
                     'root' => {
                               'someroot' => {
                                             'mixed123' => '  (hello) ',
                                             'mixed12' => '  (hello)',
                                             'mixed13' => ' (hello) ',
                                             'mixed1' => ' (hello)',
                                             'mixed2' => ' (hello)',
                                             'mixed' => '(hello)',
                                             'mixed3' => '(hello) '
                                           },
                               'someroot2' => {
                                              'mixed123' => ' a 	b (hello) c ',
                                              'mixed12' => ' a  b (hello)c',
                                              'mixed13' => ' a b(hello) c ',
                                              'mixed1' => ' a b(hello)c',
                                              'mixed2' => 'a b (hello)c',
                                              'mixed' => 'ab(hello)c',
                                              'mixed3' => 'ab(hello) c '
                                            },
                               'otherroot' => {
                                              'trailing spaces 2' => '  ',
                                              'leading spaces 2' => '  ',
                                              'leading spaces' => '  ',
                                              'no spaces 2' => undef,
                                              'no spaces' => undef,
                                              'trailing spaces' => '  ',
                                              'content and trailing spaces 2' => '       blah',
                                              'both spaces' => '    ',
                                              'content and trailing spaces' => '       blah',
                                              'all spaces' => '         ',
                                              'content and leading spaces' => 'blah     ',
                                              'both spaces 2' => '      ',
                                              'content and leading spaces 2' => 'blah     '
                                            },
                               'tag' => '
		(no spaces)
		(     leading spaces)
		(trailing spaces      )
		(  both spaces    )
		(multiple    spaces)
	'
                             }
                   },
          '3,1' => {
                     'root' => {
                               'someroot' => {
                                             'mixed13' => '(hello)',
                                             'mixed12' => '(hello)',
                                             'mixed2' => '(hello)',
                                             'mixed1' => '(hello)',
                                             'mixed123' => '(hello)',
                                             'mixed3' => '(hello)',
                                             'mixed' => '(hello)'
                                           },
                               'someroot2' => {
                                              'mixed13' => ' a b(hello) c ',
                                              'mixed12' => ' a b (hello)c',
                                              'mixed2' => 'a b (hello)c',
                                              'mixed1' => ' a b(hello)c',
                                              'mixed123' => ' a b (hello) c ',
                                              'mixed3' => 'ab(hello) c ',
                                              'mixed' => 'ab(hello)c'
                                            },
                               'otherroot' => {
                                              'trailing spaces 2' => undef,
                                              'leading spaces 2' => undef,
                                              'leading spaces' => undef,
                                              'no spaces 2' => undef,
                                              'no spaces' => undef,
                                              'trailing spaces' => undef,
                                              'content and trailing spaces 2' => ' blah',
                                              'content and trailing spaces' => ' blah',
                                              'both spaces' => undef,
                                              'all spaces' => undef,
                                              'content and leading spaces' => 'blah ',
                                              'both spaces 2' => undef,
                                              'content and leading spaces 2' => 'blah '
                                            },
                               'tag' => '(no spaces)( leading spaces)(trailing spaces )( both spaces )(multiple spaces)'
                             }
                   },
          '8,0' => {
                     'root' => {
                               'someroot' => {
                                             'mixed13' => '(hello)',
                                             'mixed12' => '(hello)',
                                             'mixed2' => '(hello)',
                                             'mixed1' => '(hello)',
                                             'mixed123' => '(hello)',
                                             'mixed3' => '(hello)',
                                             'mixed' => '(hello)'
                                           },
                               'someroot2' => {
                                              'mixed13' => 'a b(hello) c',
                                              'mixed12' => 'a  b (hello)c',
                                              'mixed2' => 'a b (hello)c',
                                              'mixed1' => 'a b(hello)c',
                                              'mixed123' => 'a 	b (hello) c',
                                              'mixed3' => 'ab(hello) c',
                                              'mixed' => 'ab(hello)c'
                                            },
                               'otherroot' => {
                                              'trailing spaces 2' => undef,
                                              'leading spaces 2' => undef,
                                              'leading spaces' => undef,
                                              'no spaces 2' => undef,
                                              'no spaces' => undef,
                                              'trailing spaces' => undef,
                                              'content and trailing spaces 2' => 'blah',
                                              'content and trailing spaces' => 'blah',
                                              'both spaces' => undef,
                                              'all spaces' => undef,
                                              'content and leading spaces' => 'blah',
                                              'both spaces 2' => undef,
                                              'content and leading spaces 2' => 'blah'
                                            },
                               'tag' => '(no spaces)
		(leading spaces)
		(trailing spaces)
		(both spaces)
		(multiple    spaces)'
                             }
                   },
          '5,0' => {
                     'root' => {
                               'someroot' => {
                                             'mixed123' => ' (hello) ',
                                             'mixed12' => ' (hello)',
                                             'mixed13' => '(hello) ',
                                             'mixed1' => '(hello)',
                                             'mixed2' => ' (hello)',
                                             'mixed' => '(hello)',
                                             'mixed3' => '(hello) '
                                           },
                               'someroot2' => {
                                              'mixed123' => ' a	b (hello) c ',
                                              'mixed12' => ' a b (hello)c',
                                              'mixed13' => ' ab(hello) c ',
                                              'mixed1' => ' ab(hello)c',
                                              'mixed2' => 'a b (hello)c',
                                              'mixed' => 'ab(hello)c',
                                              'mixed3' => 'ab(hello) c '
                                            },
                               'otherroot' => {
                                              'trailing spaces 2' => '  ',
                                              'leading spaces 2' => undef,
                                              'leading spaces' => undef,
                                              'no spaces 2' => undef,
                                              'no spaces' => undef,
                                              'trailing spaces' => '  ',
                                              'content and trailing spaces 2' => '       blah',
                                              'content and trailing spaces' => '       blah',
                                              'both spaces' => ' ',
                                              'all spaces' => '   ',
                                              'content and leading spaces' => 'blah',
                                              'both spaces 2' => '   ',
                                              'content and leading spaces 2' => 'blah'
                                            },
                               'tag' => '
		(no spaces)
		(     leading spaces)
		(trailing spaces      )
		(  both spaces    )
		(multiple    spaces)
	'
                             }
                   },
          '14,1' => {
                      'root' => {
                                'someroot' => {
                                              'mixed13' => '(hello)',
                                              'mixed12' => '(hello)',
                                              'mixed2' => '(hello)',
                                              'mixed1' => '(hello)',
                                              'mixed123' => '(hello)',
                                              'mixed3' => '(hello)',
                                              'mixed' => '(hello)'
                                            },
                                'someroot2' => {
                                               'mixed13' => 'ab(hello) c',
                                               'mixed12' => 'ab (hello)c',
                                               'mixed2' => 'ab (hello)c',
                                               'mixed1' => 'ab(hello)c',
                                               'mixed123' => 'ab (hello) c',
                                               'mixed3' => 'ab(hello) c',
                                               'mixed' => 'ab(hello)c'
                                             },
                                'otherroot' => {
                                               'trailing spaces 2' => undef,
                                               'leading spaces 2' => undef,
                                               'leading spaces' => undef,
                                               'no spaces 2' => undef,
                                               'no spaces' => undef,
                                               'trailing spaces' => undef,
                                               'content and trailing spaces 2' => 'blah',
                                               'content and trailing spaces' => 'blah',
                                               'both spaces' => undef,
                                               'all spaces' => undef,
                                               'content and leading spaces' => 'blah',
                                               'both spaces 2' => undef,
                                               'content and leading spaces 2' => 'blah'
                                             },
                                'tag' => '(no spaces) (leading spaces) (trailing spaces) (both spaces) (multiple spaces)'
                              }
                    },
          '2,0' => {
                     'root' => {
                               'someroot' => {
                                             'mixed13' => '(hello) ',
                                             'mixed12' => '(hello)',
                                             'mixed2' => ' (hello)',
                                             'mixed1' => '(hello)',
                                             'mixed123' => '(hello) ',
                                             'mixed3' => '(hello) ',
                                             'mixed' => '(hello)'
                                           },
                               'someroot2' => {
                                              'mixed13' => ' a b(hello) c ',
                                              'mixed12' => ' a  b (hello)c',
                                              'mixed2' => 'a b (hello)c',
                                              'mixed1' => ' a b(hello)c',
                                              'mixed123' => ' a 	b (hello) c ',
                                              'mixed3' => 'ab(hello) c ',
                                              'mixed' => 'ab(hello)c'
                                            },
                               'otherroot' => {
                                              'trailing spaces 2' => '  ',
                                              'leading spaces 2' => undef,
                                              'leading spaces' => undef,
                                              'no spaces 2' => undef,
                                              'no spaces' => undef,
                                              'trailing spaces' => '  ',
                                              'content and trailing spaces 2' => '       blah',
                                              'content and trailing spaces' => '       blah',
                                              'both spaces' => undef,
                                              'all spaces' => undef,
                                              'content and leading spaces' => 'blah     ',
                                              'both spaces 2' => undef,
                                              'content and leading spaces 2' => 'blah     '
                                            },
                               'tag' => '
		(no spaces)
		(     leading spaces)
		(trailing spaces      )
		(  both spaces    )
		(multiple    spaces)
	'
                             }
                   },
          '13,1' => {
                      'root' => {
                                'someroot' => {
                                              'mixed13' => '(hello)',
                                              'mixed12' => '(hello)',
                                              'mixed2' => '(hello)',
                                              'mixed1' => '(hello)',
                                              'mixed123' => '(hello)',
                                              'mixed3' => '(hello)',
                                              'mixed' => '(hello)'
                                            },
                                'someroot2' => {
                                               'mixed13' => 'ab(hello) c',
                                               'mixed12' => 'a b (hello)c',
                                               'mixed2' => 'a b (hello)c',
                                               'mixed1' => 'ab(hello)c',
                                               'mixed123' => 'a b (hello) c',
                                               'mixed3' => 'ab(hello) c',
                                               'mixed' => 'ab(hello)c'
                                             },
                                'otherroot' => {
                                               'trailing spaces 2' => undef,
                                               'leading spaces 2' => undef,
                                               'leading spaces' => undef,
                                               'no spaces 2' => undef,
                                               'no spaces' => undef,
                                               'trailing spaces' => undef,
                                               'content and trailing spaces 2' => 'blah',
                                               'content and trailing spaces' => 'blah',
                                               'both spaces' => undef,
                                               'all spaces' => undef,
                                               'content and leading spaces' => 'blah',
                                               'both spaces 2' => undef,
                                               'content and leading spaces 2' => 'blah'
                                             },
                                'tag' => '(no spaces) (leading spaces) (trailing spaces) (both spaces) (multiple spaces)'
                              }
                    },
          '6,0' => {
                     'root' => {
                               'someroot' => {
                                             'mixed13' => '(hello) ',
                                             'mixed12' => '(hello)',
                                             'mixed2' => ' (hello)',
                                             'mixed1' => '(hello)',
                                             'mixed123' => '(hello) ',
                                             'mixed3' => '(hello) ',
                                             'mixed' => '(hello)'
                                           },
                               'someroot2' => {
                                              'mixed13' => ' ab(hello) c ',
                                              'mixed12' => ' ab (hello)c',
                                              'mixed2' => 'ab (hello)c',
                                              'mixed1' => ' ab(hello)c',
                                              'mixed123' => ' ab (hello) c ',
                                              'mixed3' => 'ab(hello) c ',
                                              'mixed' => 'ab(hello)c'
                                            },
                               'otherroot' => {
                                              'trailing spaces 2' => '  ',
                                              'leading spaces 2' => undef,
                                              'leading spaces' => undef,
                                              'no spaces 2' => undef,
                                              'no spaces' => undef,
                                              'trailing spaces' => '  ',
                                              'content and trailing spaces 2' => '       blah',
                                              'content and trailing spaces' => '       blah',
                                              'both spaces' => undef,
                                              'all spaces' => undef,
                                              'content and leading spaces' => 'blah',
                                              'both spaces 2' => undef,
                                              'content and leading spaces 2' => 'blah'
                                            },
                               'tag' => '
		(no spaces)
		(     leading spaces)
		(trailing spaces      )
		(  both spaces    )
		(multiple    spaces)
	'
                             }
                   },
          '10,1' => {
                      'root' => {
                                'someroot' => {
                                              'mixed13' => '(hello)',
                                              'mixed12' => '(hello)',
                                              'mixed2' => '(hello)',
                                              'mixed1' => '(hello)',
                                              'mixed123' => '(hello)',
                                              'mixed3' => '(hello)',
                                              'mixed' => '(hello)'
                                            },
                                'someroot2' => {
                                               'mixed13' => 'a b(hello) c',
                                               'mixed12' => 'a b (hello)c',
                                               'mixed2' => 'a b (hello)c',
                                               'mixed1' => 'a b(hello)c',
                                               'mixed123' => 'a b (hello) c',
                                               'mixed3' => 'ab(hello) c',
                                               'mixed' => 'ab(hello)c'
                                             },
                                'otherroot' => {
                                               'trailing spaces 2' => undef,
                                               'leading spaces 2' => undef,
                                               'leading spaces' => undef,
                                               'no spaces 2' => undef,
                                               'no spaces' => undef,
                                               'trailing spaces' => undef,
                                               'content and trailing spaces 2' => 'blah',
                                               'content and trailing spaces' => 'blah',
                                               'both spaces' => undef,
                                               'all spaces' => undef,
                                               'content and leading spaces' => 'blah',
                                               'both spaces 2' => undef,
                                               'content and leading spaces 2' => 'blah'
                                             },
                                'tag' => '(no spaces) (leading spaces) (trailing spaces) (both spaces) (multiple spaces)'
                              }
                    },
          '4,1' => {
                     'root' => {
                               'someroot' => {
                                             'mixed123' => ' (hello) ',
                                             'mixed12' => ' (hello)',
                                             'mixed13' => ' (hello) ',
                                             'mixed1' => ' (hello)',
                                             'mixed2' => ' (hello)',
                                             'mixed' => '(hello)',
                                             'mixed3' => '(hello) '
                                           },
                               'someroot2' => {
                                              'mixed123' => ' a b (hello) c ',
                                              'mixed12' => ' a b (hello)c',
                                              'mixed13' => ' a b(hello) c ',
                                              'mixed1' => ' a b(hello)c',
                                              'mixed2' => 'a b (hello)c',
                                              'mixed' => 'ab(hello)c',
                                              'mixed3' => 'ab(hello) c '
                                            },
                               'otherroot' => {
                                              'trailing spaces 2' => ' ',
                                              'leading spaces 2' => ' ',
                                              'leading spaces' => ' ',
                                              'no spaces 2' => undef,
                                              'no spaces' => undef,
                                              'trailing spaces' => ' ',
                                              'content and trailing spaces 2' => ' blah',
                                              'both spaces' => ' ',
                                              'content and trailing spaces' => ' blah',
                                              'all spaces' => ' ',
                                              'content and leading spaces' => 'blah ',
                                              'both spaces 2' => ' ',
                                              'content and leading spaces 2' => 'blah '
                                            },
                               'tag' => ' (no spaces) ( leading spaces) (trailing spaces ) ( both spaces ) (multiple spaces) '
                             }
                   },
          '8,1' => {
                     'root' => {
                               'someroot' => {
                                             'mixed13' => '(hello)',
                                             'mixed12' => '(hello)',
                                             'mixed2' => '(hello)',
                                             'mixed1' => '(hello)',
                                             'mixed123' => '(hello)',
                                             'mixed3' => '(hello)',
                                             'mixed' => '(hello)'
                                           },
                               'someroot2' => {
                                              'mixed13' => 'a b(hello) c',
                                              'mixed12' => 'a b (hello)c',
                                              'mixed2' => 'a b (hello)c',
                                              'mixed1' => 'a b(hello)c',
                                              'mixed123' => 'a b (hello) c',
                                              'mixed3' => 'ab(hello) c',
                                              'mixed' => 'ab(hello)c'
                                            },
                               'otherroot' => {
                                              'trailing spaces 2' => undef,
                                              'leading spaces 2' => undef,
                                              'leading spaces' => undef,
                                              'no spaces 2' => undef,
                                              'no spaces' => undef,
                                              'trailing spaces' => undef,
                                              'content and trailing spaces 2' => 'blah',
                                              'content and trailing spaces' => 'blah',
                                              'both spaces' => undef,
                                              'all spaces' => undef,
                                              'content and leading spaces' => 'blah',
                                              'both spaces 2' => undef,
                                              'content and leading spaces 2' => 'blah'
                                            },
                               'tag' => '(no spaces) (leading spaces) (trailing spaces) (both spaces) (multiple spaces)'
                             }
                   },
          '15,1' => {
                      'root' => {
                                'someroot' => {
                                              'mixed13' => '(hello)',
                                              'mixed12' => '(hello)',
                                              'mixed2' => '(hello)',
                                              'mixed1' => '(hello)',
                                              'mixed123' => '(hello)',
                                              'mixed3' => '(hello)',
                                              'mixed' => '(hello)'
                                            },
                                'someroot2' => {
                                               'mixed13' => 'ab(hello)c',
                                               'mixed12' => 'ab(hello)c',
                                               'mixed2' => 'ab(hello)c',
                                               'mixed1' => 'ab(hello)c',
                                               'mixed123' => 'ab(hello)c',
                                               'mixed3' => 'ab(hello)c',
                                               'mixed' => 'ab(hello)c'
                                             },
                                'otherroot' => {
                                               'trailing spaces 2' => undef,
                                               'leading spaces 2' => undef,
                                               'leading spaces' => undef,
                                               'no spaces 2' => undef,
                                               'no spaces' => undef,
                                               'trailing spaces' => undef,
                                               'content and trailing spaces 2' => 'blah',
                                               'content and trailing spaces' => 'blah',
                                               'both spaces' => undef,
                                               'all spaces' => undef,
                                               'content and leading spaces' => 'blah',
                                               'both spaces 2' => undef,
                                               'content and leading spaces 2' => 'blah'
                                             },
                                'tag' => '(no spaces)(leading spaces)(trailing spaces)(both spaces)(multiple spaces)'
                              }
                    },
          '6,1' => {
                     'root' => {
                               'someroot' => {
                                             'mixed13' => '(hello) ',
                                             'mixed12' => '(hello)',
                                             'mixed2' => ' (hello)',
                                             'mixed1' => '(hello)',
                                             'mixed123' => '(hello) ',
                                             'mixed3' => '(hello) ',
                                             'mixed' => '(hello)'
                                           },
                               'someroot2' => {
                                              'mixed13' => ' ab(hello) c ',
                                              'mixed12' => ' ab (hello)c',
                                              'mixed2' => 'ab (hello)c',
                                              'mixed1' => ' ab(hello)c',
                                              'mixed123' => ' ab (hello) c ',
                                              'mixed3' => 'ab(hello) c ',
                                              'mixed' => 'ab(hello)c'
                                            },
                               'otherroot' => {
                                              'trailing spaces 2' => ' ',
                                              'leading spaces 2' => undef,
                                              'leading spaces' => undef,
                                              'no spaces 2' => undef,
                                              'no spaces' => undef,
                                              'trailing spaces' => ' ',
                                              'content and trailing spaces 2' => ' blah',
                                              'content and trailing spaces' => ' blah',
                                              'both spaces' => undef,
                                              'all spaces' => undef,
                                              'content and leading spaces' => 'blah',
                                              'both spaces 2' => undef,
                                              'content and leading spaces 2' => 'blah'
                                            },
                               'tag' => ' (no spaces) ( leading spaces) (trailing spaces ) ( both spaces ) (multiple spaces) '
                             }
                   },
          '11,0' => {
                      'root' => {
                                'someroot' => {
                                              'mixed13' => '(hello)',
                                              'mixed12' => '(hello)',
                                              'mixed2' => '(hello)',
                                              'mixed1' => '(hello)',
                                              'mixed123' => '(hello)',
                                              'mixed3' => '(hello)',
                                              'mixed' => '(hello)'
                                            },
                                'someroot2' => {
                                               'mixed13' => 'a b(hello) c',
                                               'mixed12' => 'a  b (hello)c',
                                               'mixed2' => 'a b (hello)c',
                                               'mixed1' => 'a b(hello)c',
                                               'mixed123' => 'a 	b (hello) c',
                                               'mixed3' => 'ab(hello) c',
                                               'mixed' => 'ab(hello)c'
                                             },
                                'otherroot' => {
                                               'trailing spaces 2' => undef,
                                               'leading spaces 2' => undef,
                                               'leading spaces' => undef,
                                               'no spaces 2' => undef,
                                               'no spaces' => undef,
                                               'trailing spaces' => undef,
                                               'content and trailing spaces 2' => '       blah',
                                               'content and trailing spaces' => '       blah',
                                               'both spaces' => undef,
                                               'all spaces' => undef,
                                               'content and leading spaces' => 'blah',
                                               'both spaces 2' => undef,
                                               'content and leading spaces 2' => 'blah'
                                             },
                                'tag' => '(no spaces)(leading spaces)(trailing spaces)(both spaces)(multiple    spaces)'
                              }
                    },
          '9,1' => {
                     'root' => {
                               'someroot' => {
                                             'mixed13' => '(hello)',
                                             'mixed12' => '(hello)',
                                             'mixed2' => '(hello)',
                                             'mixed1' => '(hello)',
                                             'mixed123' => '(hello)',
                                             'mixed3' => '(hello)',
                                             'mixed' => '(hello)'
                                           },
                               'someroot2' => {
                                              'mixed13' => 'a b(hello) c',
                                              'mixed12' => 'a b (hello)c',
                                              'mixed2' => 'a b (hello)c',
                                              'mixed1' => 'a b(hello)c',
                                              'mixed123' => 'a b (hello) c',
                                              'mixed3' => 'ab(hello) c',
                                              'mixed' => 'ab(hello)c'
                                            },
                               'otherroot' => {
                                              'trailing spaces 2' => undef,
                                              'leading spaces 2' => undef,
                                              'leading spaces' => undef,
                                              'no spaces 2' => undef,
                                              'no spaces' => undef,
                                              'trailing spaces' => undef,
                                              'content and trailing spaces 2' => 'blah',
                                              'content and trailing spaces' => 'blah',
                                              'both spaces' => undef,
                                              'all spaces' => undef,
                                              'content and leading spaces' => 'blah',
                                              'both spaces 2' => undef,
                                              'content and leading spaces 2' => 'blah'
                                            },
                               'tag' => '(no spaces) (leading spaces) (trailing spaces) (both spaces) (multiple spaces)'
                             }
                   }
);
my %got;

$XML =~ s/(?:\x0D\x0A?|\x0A)/\x0D\x0A/sg;

for my $stripspaces (0 .. 15) {
	for my $normalizespaces (0,1) {
		my $parser = XML::Rules->new(
			stripspaces => $stripspaces,
			normalizespaces => $normalizespaces,
			rules => [
				'subtag,nonempty' => sub {'(' . $_[1]->{_content} . ')'},
				'empty' => sub {return},
				'other,some' => sub { $_[1]->{id} => $_[1]->{_content}},
				tag => 'content',
				'root,otherroot,someroot,someroot2' => 'no content',
			],
		);
		$got{$stripspaces .','. $normalizespaces} = $parser->parse($XML);

#		if ($stripspaces == 14) {
#			print "'$got{$stripspaces .','. $normalizespaces}{root}{tag}'\n'$good{$stripspaces .','. $normalizespaces}{root}{tag}'\n";
#			exit;
#		}

		is_deeply( $got{$stripspaces .','. $normalizespaces}, $good{$stripspaces .','. $normalizespaces}, "stripspaces, normalizespaces => $stripspaces, $normalizespaces");
	}
}

__END__

use Data::Dumper;
open my $OUT, '>', 't\\08-whitespace_more.txt';
print $OUT Dumper(\%got);
close $OUT;
