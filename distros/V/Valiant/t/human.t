use Test::Most;

{
    package Person;

    use Moo;
    use Valiant::Validations;
    use Valiant::I18N;

    has 'name' => (is=>'ro');

    validates 'name', sub {
      my ($self, $attribute, $value, $opts) = @_;
      $self->errors->add($attribute => _t('too_long'), +{%$opts, count=>36}) if length($value||'') > 36;
    };
}

ok my $p = Person->new(name=>'x'x100);
ok $p->invalid;

is $p->model_name->human, 'Person';
is $p->human_attribute_name('name'), 'Name';
is_deeply [$p->errors->messages_for('name')], ['is too long (maximum is 36 characters)'];
is_deeply [$p->errors->full_messages_for('name')], ['Name is too long (maximum is 36 characters)'];
done_testing;
