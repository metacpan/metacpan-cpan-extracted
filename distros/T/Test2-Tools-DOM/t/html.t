use Test2::V0;
use Test2::API 'intercept';
use Test2::Tools::Tester 'facets';
use Test2::Tools::DOM;

my $ok = object {
    call state => hash { field failed => F; etc };
    call sub {
        shift->causes_failure->map(sub { diag shift->the_info->details });
        return 1;
    } => T;
};

subtest tag => sub {
    is intercept {
        is '<!DOCTYPE html><el></el>', dom { tag 'el' };
    } => $ok => 'Skips root element';

    is intercept {
        is '<el></el>', dom { tag 'el' };
    } => $ok => 'Get the tag of the element';
};

subtest attr => sub {
    is intercept {
        is '<el foo=bar></el>', dom {
            attr foo => 'bar';
            attr foo => T;
            attr foo => D;
            attr foo => E;
        }
    } => $ok => 'Attribute with value is true, defined, and exists';

    is intercept {
        is '<el foo></el>', dom {
            attr foo => T;
            attr foo => U;
            attr foo => E;
        }
    } => $ok => 'Attribute with no value is true, undefined, and exists';

    is intercept {
        is '<el></el>', dom {
            attr foo => F;
            attr foo => U;
            attr foo => DNE;
        }
    } => $ok => 'Missing attribute is false, undefined, and does not exist';

    is intercept {
        is '<el a=1 b=2 c ></el>', dom {
            attr hash {
                field a => 1;
                field b => 2;
                field c => U;
                end;
            };
        }
    } => $ok => 'Without a name fetches all attributes as a hashref';
};

subtest children => sub {
    my $html = <<'HTML';
        <dl>
            <dt><em>a</em></dt>
            <dd>A</dd>

            <dt><em>b</em></dt>
            <dd>B</dd>
        </dl>
HTML

    is intercept {
        is $html, dom {
            children array {
                item dom { tag 'dt' };
                item dom { tag 'dd' };
                item dom { tag 'dt' };
                item dom { tag 'dd' };
                end;
            };
        }
    } => $ok => 'Find all direct children with no selector';

    is intercept {
        is $html, dom {
            children 'dd' => array {
                item dom { tag 'dd' };
                item dom { tag 'dd' };
                end;
            };
        }
    } => $ok => 'Find all matching direct children with selector';
};

subtest content => sub {
    my $html = '<p>I sing the body <em>electric</em></p>';

    is intercept {
        is $html, dom {
            text 'I sing the body ';
        };
    } => $ok => q"'text' gets the text in only this element";

    is intercept {
        is $html, dom {
            content 'I sing the body <em>electric</em>';
        };
    } => $ok => q"'content' gets the raw content of element and all descendants";

    is intercept {
        is $html, dom {
            all_text 'I sing the body electric';
        };
    } => $ok => q"'all_text' gets the text in this element and all descendants";
};

subtest at => sub {
    my $html = <<'HTML';
        <div class=parent>
            <div class=child>
                <div class=child>
                    <p>Bottom</p>
                </div>
            </div>
        </div>
HTML

    is intercept {
        is $html, dom {
            attr class => 'parent';

            # Finds first descentant match
            at '.child' => dom {
                children array {
                    item dom { tag 'div' };
                    end;
                };

                # Finds first descendant child
                at '.child' => dom {
                    children array {
                        item dom { tag 'p' };
                        end;
                    };
                };

                # Does not find ancestors
                at '.parent' => U;
            };
        }
    } => $ok => 'Find first matching direct descendant, but not ancestors';

    is intercept {
        is '<div><a /></div>', dom {
            at a => T;
            at a => D;
            at a => E;
        }
    } => $ok => 'Matching element is true, defined, and exists';

    is intercept {
        is '<div><a /></div>', dom {
            at b => F;
            at b => U;
            at b => DNE;
        }
    } => $ok => 'No matching element is false, undefined, and does not exist';
};

subtest find => sub {
    my $html = <<'HTML';
        <div id=a class=child>
            <div id=b class=child>
                <div id=c class=child>
                    <div id=d></div>
                </div>
            </div>
        </div>
HTML

    is intercept {
        is $html, dom {
            find '.child' => array {
                # One level down
                item dom { attr id => 'b' };

                # Two levels down
                item dom { attr id => 'c' };

                end;
            };
        }
    } => $ok => 'Find all matching descendants, but not ancestors';

    is intercept {
        is $html, dom {
            find '.missing' => array { end };
        }
    } => $ok => 'Finding no matching descendants returns empty collection';
};

subtest empty => sub {
    is intercept {
        is '<el value="">', dom {
            attr value => '';
        }
    } => $ok => 'Match empty value';

    is intercept {
        is '', dom {
            attr {};
        }
    } => $ok => 'Can handle root without children';
};

subtest val => sub {
    my $html = '<el value=42>';

    is intercept {
        is $html, dom {
            attr value => 42;
            val 42;
        }
    } => $ok => 'Can directly retrieve value';
};

subtest call => sub {
    my $html = '<ol foo=123 bar=234><li>A</li><li>B</li></ol>';

    is intercept {
        is $html, dom {
            call tag => 'ol';
            call sub { shift->tag } => 'ol';

            call [ children => 'li' ] => [
                dom { text 'A' },
                dom { text 'B' },
            ];

            call_hash sub { %{ shift->attr } } => {
                foo => 123,
                bar => 234,
            };

            call_list tag => [ 'ol' ];
        };
    } => $ok => 'Can use call on DOM object';

    is intercept {
        is '<a />', dom {
            call sub { die "oops" } => T;
        };
    } => object {
        call state => hash { field failed => T; etc };
    }, 'Can capture exceptions on code calls';

    like dies { is '<a />' => dom { call missing => F } },
        qr/Cannot call 'missing' on an object of type/,
        'Calling a missing method fails';
};

subtest error => sub {
    my $html = '<ol><li>A</li><li>B</li></ol>';

    my $events = intercept {
        is $html, dom {
            children li => [
                dom { text 'A' },
                dom { text 'X' },
            ];
        }
    };

    like $events->state => { failed => T }, 'Test failed as expected';

    is facets( info => $events ) => [
        object {
            call table => hash {
                field rows => [
                    array { item 2 => '<ol><li>A</li><li>B</li></ol>'; etc },
                    array { item 2 => '<li>B</li>'; etc },
                    array { item 2 => 'B'; etc },
                ];

                etc;
            };
        }
    ], 'Render partial DOM on failed steps';

    like dies { is 'dom' => object { tag 'error' } },
        qr/'tag' is not supported in a \S+ build/,
        'Exported functions require dom context';

    like dies { tag 'error' },
        qr/'tag' cannot be called in a context with no test build/,
        'Exported functions require test build';
};

done_testing;
