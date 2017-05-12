requires 'Class::Load';
requires 'Text::Markdown';
requires 'parent';

recommends 'Text::Markdown::Hoedown', '1.00';

suggests 'Text::Markdown::Discount';
suggests 'Text::MultiMarkdown';
suggests 'Text::Textile';
suggests 'Text::Xatena';

on configure => sub {
    requires 'CPAN::Meta';
    requires 'CPAN::Meta::Prereqs';
    requires 'Module::Build';
    requires 'perl', '5.008_001';
};

on test => sub {
    requires 'Test::More', '0.98';
};

on develop => sub {
    requires 'Test::Perl::Critic';
};
