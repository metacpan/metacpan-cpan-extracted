# -*- perl -*-

# t/002_load.t - check interface

use Test::Most tests => 16+1;
use Test::NoWarnings;

use_ok( 'Text::Phonetic' );


my $t1 = Text::Phonetic->load();

isa_ok($t1,'Text::Phonetic::Phonix');
is($t1->encode('schneider'),'S5300000','Object works');

my $t2 = Text::Phonetic->load(algorithm => 'Phonem');
isa_ok($t2,'Text::Phonetic::Phonem');
is($t2->encode('schneider'),'CNAYDR','Object works');

my $t3 = Text::Phonetic::Phonix->new();
isa_ok($t3,'Text::Phonetic::Phonix');
is($t3->encode('schneider'),'S5300000','Object works');

local @Text::Phonetic::AVAILABLE_ALGORITHMS;
push @Text::Phonetic::AVAILABLE_ALGORITHMS,'Test';

{
    package Text::Phonetic::Test;
    use Moo;
    extends qw(Text::Phonetic);

    has 'attribute' => (
        is  => 'rw',
        required => 1,
    );

    sub _do_encode {
        my ($self,$sting) = @_;
        return $self->attribute;
    }
}

my $t4 = Text::Phonetic::Test->new(attribute => 'test');
isa_ok($t4,'Text::Phonetic::Test');
is($t4->encode('schneider'),'test','Object works');
is($t4->encode('attribute'),'test','Attribute is set');

my $t5 = Text::Phonetic->load(attribute => 'test', algorithm => 'Test');
isa_ok($t5,'Text::Phonetic::Test');
is($t5->encode('schneider'),'test','Object works');
is($t5->encode('attribute'),'test','Attribute is set');

my $t6 = Text::Phonetic->load({attribute => 'test', algorithm => 'Test'});
isa_ok($t6,'Text::Phonetic::Test');
is($t6->encode('schneider'),'test','Object works');
is($t6->encode('attribute'),'test','Attribute is set');
