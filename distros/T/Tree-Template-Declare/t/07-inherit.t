#!perl
package Base;{
use strict;
use warnings;
use Tree::Template::Declare builder => '+DAG_Node';

sub doc {
    my ($self)=@_;
    tree {
        node {
            name 'doc';
            $self->head();
            $self->body();
        }
    }
}

sub head {
    node { name 'title' };
}

sub body {
    node {
        name 'content';
        $_[0]->content();
    }
}

sub content {
    node { name 'stuff' }
}

}

package Derived;{
use strict;
use warnings;
use Tree::Template::Declare builder => '+DAG_Node';
use base 'Base';

sub head {
    node { name 'whatever' };
    $_[0]->SUPER::head();
}

sub content {
    node { name 'something' }
}

}

package main;
use Test::Most tests=>2,'die';
use strict;
use warnings;

my $base_tree=Base->doc();

cmp_deeply($base_tree->tree_to_lol(),
           [[re(qr{title})],[[re(qr{stuff})],re(qr{content})],re(qr{doc})],
           'base tree');

my $deriv_tree=Derived->doc();

cmp_deeply($deriv_tree->tree_to_lol(),
           [[re(qr{whatever})],[re(qr{title})],[[re(qr{something})],re(qr{content})],re(qr{doc})],
           'derived tree');
