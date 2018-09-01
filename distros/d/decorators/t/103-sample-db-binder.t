#!perl

use strict;
use warnings;

use lib 't/lib';

use Test::More;
use Data::Dumper;

BEGIN {
    # load from t/lib
    use_ok('DB::Binder::Trait::Provider');
    #use_ok('DB::Binder::Trait::Handler');
}

=pod

=cut

BEGIN {
    package Person;
    use strict;
    use warnings;

    use decorators 'DB::Binder::Trait::Provider';

    use parent 'UNIVERSAL::Object';

    sub id   : PrimaryKey;
    sub name : Col;
    sub age  : Col;

    sub comments  : HasMany('Comment', 'author');
    sub approvals : HasMany('Article', 'approver');

    package Comment;
    use strict;
    use warnings;

    use decorators 'DB::Binder::Trait::Provider';

    use parent 'UNIVERSAL::Object';

    sub id   : PrimaryKey;
    sub body : Col;

    sub author  : HasOne('Person');
    sub article : HasOne('Article');

    package Article;
    use strict;
    use warnings;

    use decorators 'DB::Binder::Trait::Provider';

    use parent 'UNIVERSAL::Object';

    sub BUILDARGS {
        my $class = shift;
        my $args  = $class->SUPER::BUILDARGS( @_ );
        if ( not exists $args->{created_on} ) {
            $args->{created_on} = $args->{updated_on} = scalar time();
        }
        return $args;
    }

    sub id       : PrimaryKey;
    sub title    : Col;
    sub body     : Col;
    sub created  : Col('created_on');
    sub updated  : Col('updated_on');
    sub status   : Col;

    sub approver : HasOne('Person');

    sub comments : HasMany('Comment', 'article');
}

{
    can_ok('Person', 'id');
    can_ok('Person', 'name');
    can_ok('Person', 'age');

    can_ok('Person', 'comments');
    can_ok('Person', 'approvals');

    my $meta = MOP::Role->new('Person');

    ok($meta->has_method('id'), '... the expected method (id)');
    ok($meta->has_method('name'), '... the expected method (name)');
    ok($meta->has_method('age'), '... the expected method (age)');

    ok($meta->has_slot('id'), '... have the expected slot (id)');
    ok($meta->has_slot('name'), '... have the expected slot (name)');
    ok($meta->has_slot('age'), '... have the expected slot (age)');

    isa_ok(Person->new, 'Person');

    my $person = Person->new(
        id   => 1,
        name => 'Bob',
        age  => 25,
    );
    isa_ok($person, 'Person');

    is($person->id, 1, '... got the right value for (id)');
    is($person->name, 'Bob', '... got the right value for (name)');
    is($person->age, 25, '... got the right value for (age)');

    is_deeply([ $person->comments ], [], '... got the right value for (comments)');
    is_deeply([ $person->approvals ], [], '... got the right value for (approvals)');
}

{
    can_ok('Comment', 'id');
    can_ok('Comment', 'body');

    can_ok('Comment', 'author');
    can_ok('Comment', 'article');

    my $meta = MOP::Role->new('Comment');

    ok($meta->has_method('id'), '... the expected method (id)');
    ok($meta->has_method('body'), '... the expected method (body)');
    ok($meta->has_method('author'), '... the expected method (author)');
    ok($meta->has_method('article'), '... the expected method (article)');

    ok($meta->has_slot('id'), '... have the expected slot (id)');
    ok($meta->has_slot('body'), '... have the expected slot (body)');
    ok($meta->has_slot('author'), '... have the expected slot (author)');
    ok($meta->has_slot('article'), '... have the expected slot (article)');

    isa_ok(Comment->new, 'Comment');

    my $comment = Comment->new(
        id   => 1,
        body => 'This sucks',
    );
    isa_ok($comment, 'Comment');

    is($comment->id, 1, '... got the right value for (id)');
    is($comment->body, 'This sucks', '... got the right value for (body)');

    isa_ok($comment->author, 'Person');
    isa_ok($comment->article, 'Article');
}

{
    can_ok('Article', 'id');
    can_ok('Article', 'title');
    can_ok('Article', 'body');
    can_ok('Article', 'created');
    can_ok('Article', 'updated');
    can_ok('Article', 'status');

    can_ok('Article', 'approver');

    can_ok('Article', 'comments');

    my $meta = MOP::Role->new('Article');

    ok($meta->has_method('id'), '... have the expected method (id)');
    ok($meta->has_method('title'), '... have the expected method (title)');
    ok($meta->has_method('body'), '... have the expected method (body)');
    ok($meta->has_method('created'), '... have the expected method (created)');
    ok($meta->has_method('updated'), '... have the expected method (updated)');
    ok($meta->has_method('status'), '... have the expected method (status)');
    ok($meta->has_method('approver'), '... have the expected method (approver)');

    ok($meta->has_slot('id'), '... have the expected slot (id)');
    ok($meta->has_slot('title'), '... have the expected slot (title)');
    ok($meta->has_slot('body'), '... have the expected slot (body)');
    ok($meta->has_slot('created_on'), '... have the expected slot (created_on)');
    ok($meta->has_slot('updated_on'), '... have the expected slot (updated_on)');
    ok($meta->has_slot('status'), '... have the expected slot (status)');
    ok($meta->has_slot('approver'), '... have the expected slot (approver)');

    isa_ok(Article->new, 'Article');

    my $article = Article->new(
        id         => 1,
        title      => 'Why Everything Sucks',
        body       => 'Just because',
        status     => 'pending',
    );
    isa_ok($article, 'Article');

    is($article->id, 1, '... got the right value for (id)');
    is($article->title, 'Why Everything Sucks', '... got the right value for (title)');
    is($article->body, 'Just because', '... got the right value for (body)');
    is($article->status, 'pending', '... got the right value for (pending)');

    ok(($article->created <= scalar(time())), '... this was just created');
    ok(($article->updated <= scalar(time())), '... this was just updated');

    isa_ok($article->approver, 'Person');

    is_deeply([ $article->comments ], [], '... got the right value for (comments)');
}

done_testing;

