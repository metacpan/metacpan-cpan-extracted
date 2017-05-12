use Test::Mini::Unit;

{
    package X;

    package Y;
    use Test::Mini::Unit::Sugar::Test into => 'X';
}

{
    package Z;
    use Test::Mini::Unit::Sugar::Test;
}

case t::Test::Mini::Unit::Sugar::Test::Import {
    test imports_keyword_into_class {
        assert_can(Z => 'test');
    }

    test into_option_imports_keyword_into_specified_class {
        assert_can(X => 'test');
    }

    test into_option_does_not_import_keyword_into_current_class {
        refute_can(Y => 'test');
    }
}
