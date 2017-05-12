BEGIN {

    use FindBin;
    use lib $FindBin::Bin . "/myapp/lib";

}

use Test::More;

SKIP: {

    eval { require 'Class/Method/Modifiers.pm' };

    $@
      ? plan skip_all => 'Class::Method::Modifiers is not installed.'
      : eval <<'CLASS';

package TestClass::Modified;

use Validation::Class;
use Class::Method::Modifiers;

fld name => {
    required => 1
};

has log => 0;

after validate => sub {

    my ($self) = @_;
    $self->log($self->error_count ? 1 : 0);

};

mth change_log => {
    input => ['name'],
    using => sub {
        shift->log('thank you')
    }
};

after change_log => sub {

    my ($self) = @_;

    $self->log($self->log eq 'thank you' ? 1 : 0);

};

CLASS

    package main;

    my $class = "TestClass::Modified";
    my $self  = $class->new;

    ok $class eq ref $self, "$class instantiated";

    $self->validate('name');

    ok $self->log, "validate() modifier setting log attribute as expected";

    $self->name('iamlegend');
    $self->validate('name');

    ok !$self->log, "validate() modifier setting log attribute as expected";

    ok $self->change_log, "change_log() validates as expected";

    ok $self->log, "change_log() modifier setting log attribute as expected";

    $self->name('');
    $self->change_log;

    ok !$self->log, "change_log() modifier setting log attribute as expected";

}

done_testing;
