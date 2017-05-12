use Test::More tests => 6;

package MyVal;
use Validation::Class;

field this => {
    required => 1,
    error    => 'This aint that.',
    filters  => ['trim', 'strip']
};

field that => {
    required => 1,
    error    => 'That aint this.',
    filters  => ['trim', 'strip']
};

sub my_fields {
    my $fields = {

        this => {
            required => 1,
            error    => 'This aint that.',
            filters  => ['trim', 'strip']
        },

        that => {
            required => 1,
            error    => 'That aint this.',
            filters  => ['trim', 'strip']
        }
    };
    return $fields;
}

my $first_params = {
    this => '0123456789',
    that => ''
};

my $second_params = {
    this => '',
    that => ''
};

package main;

my $v1 = MyVal->new(

    #fields => my_fields,
    params         => $first_params,
    ignore_unknown => 1
);

# validation objects
ok $v1, '1st validation object ok';
$v1->validate(qw/this that/);
ok $v1->fields->{this}->{value} eq '0123456789',
  '1st validation object -this- field value correct';

my $v2 = MyVal->new(

    #fields => my_fields,
    params         => $second_params,
    ignore_unknown => 1
);

ok $v2, '2nd validation object ok';
$v2->validate(qw/this that/);
ok $v2->fields->{this}->{value} eq '',
  '2nd validation object -this- field value correct';

ok !$v2->params->{this}, '2nd validation object -this- param correct';
ok !$v2->fields->{this}->{value},
  '2nd validation object -this- field value correct';
