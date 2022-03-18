use Test2::V0;
use Test2::API 'intercept';
use Mojo::DOM58;
use Test2::Tools::DOM;

my $ok = validator sub { ref && ref eq 'Test2::Event::Ok' };

subtest tag => sub {
    is intercept {
        is '<!DOCTYPE html><el></el>', dom { tag 'el' };
    } => [ $ok ] => 'Skips root element';

    is intercept {
        is '<el></el>', dom { tag 'el' };
    } => [ $ok ] => 'Get the tag of the element';
};

subtest attr => sub {
    is intercept {
        is '<el foo=bar></el>', dom {
            attr foo => 'bar';
            attr foo => T;
            attr foo => D;
            attr foo => E;
        }
    } => [ $ok ] => 'Attribute with value is true, defined, and exists';

    is intercept {
        is '<el foo></el>', dom {
            attr foo => T;
            attr foo => U;
            attr foo => E;
        }
    } => [ $ok ] => 'Attribute with no value is true, undefined, and exists';

    is intercept {
        is '<el></el>', dom {
            attr foo => F;
            attr foo => U;
            attr foo => DNE;
        }
    } => [ $ok ] => 'Missing attribute is false, undefined, and does not exist';

    is intercept {
        is '<el a=1 b=2 c ></el>', dom {
            attr hash {
                field a => 1;
                field b => 2;
                field c => U;
                end;
            };
        }
    } => [ $ok ] => 'Without a name fetches all attributes as a hashref';
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
    } => [ $ok ] => 'Find all direct children with no selector';

    is intercept {
        is $html, dom {
            children 'dd' => array {
                item dom { tag 'dd' };
                item dom { tag 'dd' };
                end;
            };
        }
    } => [ $ok ] => 'Find all matching direct children with selector';
};

subtest content => sub {
    my $html = '<p>I sing the body <em>electric</em></p>';

    is intercept {
        is $html, dom {
            text 'I sing the body ';
        };
    } => [ $ok ] => q"'text' gets the text in only this element";

    is intercept {
        is $html, dom {
            content 'I sing the body <em>electric</em>';
        };
    } => [ $ok ] => q"'content' gets the raw content of element and all descendants";

    is intercept {
        is $html, dom {
            all_text 'I sing the body electric';
        };
    } => [ $ok ] => q"'all_text' gets the text in this element and all descendants";
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
    } => [ $ok ] => 'Find first matching direct descendant, but not ancestors';

    is intercept {
        is '<div><a /></div>', dom {
            at a => T;
            at a => D;
            at a => E;
        }
    } => [ $ok ] => 'Matching element is true, defined, and exists';

    is intercept {
        is '<div><a /></div>', dom {
            at b => F;
            at b => U;
            at b => DNE;
        }
    } => [ $ok ] => 'No matching element is false, undefined, and does not exist';
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
    } => [ $ok ] => 'Find all matching descendants, but not ancestors';

    is intercept {
        is $html, dom {
            find '.missing' => array { end };
        }
    } => [ $ok ] => 'Finding no matching descendants returns empty collection';
};

done_testing;
