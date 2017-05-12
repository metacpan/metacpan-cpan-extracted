[![Build Status](https://travis-ci.org/pokutuna/p5-Valiemon.svg?branch=master)](https://travis-ci.org/pokutuna/p5-Valiemon)
# NAME

Valiemon - data validator based on json schema

# SYNOPSIS

    use Valiemon;

    # create instance with schema definition
    my $validator = Valiemon->new({
        type => 'object',
        properties => {
            name  => { type => 'string'  },
            price => { type => 'integer' },
        },
        requried => ['name', 'price'],
    });

    # validate data
    my ($res, $error);
    ($res, $error) = $validator->validate({ name => 'unadon', price => 1200 });
    # $res   => 1
    # $error => undef

    ($res, $error) = $validator->validate({ name => 'tendon', price => 'hoge' });
    # $res   => 0
    # $error => object Valiemon::ValidationError
    # $error->position => '/properties/price/type'
    # $error->expected => { type' => 'integer' }
    # $error->actual   => 'hoge'

# DESCRIPTION

This module is under development!
So there are some unimplemented features, and module api will be changed.

# LICENSE

MIT

# AUTHOR

pokutuna &lt;popopopopokutuna@gmail.com>
