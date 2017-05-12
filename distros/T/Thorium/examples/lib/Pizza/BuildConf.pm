package Pizza::BuildConf;

use Moose;

use Pizza::BuildConf::Knob::CrustType;

extends 'Thorium::BuildConf';

has '+type' => (default => 'Pizza Maker');

has '+files' => ('default' => 'pizza.tt2');

has '+knobs' => (
    'default' => sub {
        [
            Pizza::BuildConf::Knob::CrustType->new(
                'conf_key_name' => 'pizza.crust_type',
                'name'          => 'Crust type',
                'question'      => 'What kind of crust do you want?'
            )
        ];
    }
);

__PACKAGE__->meta->make_immutable;
no Moose;
