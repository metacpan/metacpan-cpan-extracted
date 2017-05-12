use Test::More tests => 17;
use warnings;
use strict;
use lib 'lib';
BEGIN {
    use_ok('VIM::Packager::MetaReader');
};


open FH , ">" , "test.vim";
print FH <<END;

"=VERSION 0.3

END
close FH;



my $sample =<<END;

# comment

=name       new_plugin

# comment

=author     Cornelius (cornelius.howl\@gmail.com)

=version_from    test.vim   # extract version infomation from this file

=version         1.0

=vim_version < 7.2

=type       syntax

=dependency

    something.vim > 0.3
            # comments

    rainbow.vim      >= 1.2

    autocomplpop.vim
        | autoload/acp.vim | http://c9s.blogspot.com
        | plugin/acp.vim   | http://plurk.com/c9s

    cpan.vim > 0
        git://github.com/c9s/cpan.vim.git

=install_dirs

    plugin/
    autoload/

=script
    bin/parser
    bin/template_generator

=repository git://....../

END


open my $fh , "<" , \$sample;

my $meta = VIM::Packager::MetaReader->new;
ok ( $meta );
$meta->read( $fh );

close $fh;

my $meta_object = $meta->meta;
ok( $meta_object );

is_deeply(
    [ sort @{ $meta_object->{install_dirs} } ],
    [ sort ('plugin/', 'autoload/') ] );

is_deeply(
    $meta_object->{dependency} , [
          {
            'name' => 'autocomplpop.vim',
            'required_files' => [
                                  {
                                    'target' => 'autoload/acp.vim',
                                    'from' => 'http://c9s.blogspot.com'
                                  },
                                  {
                                    'target' => 'plugin/acp.vim',
                                    'from' => 'http://plurk.com/c9s'
                                  }
                                ]
          },
          {
            'version' => '0.3',
            'name' => 'something.vim',
            'op' => '>'
          },
          {
            'name' => 'cpan.vim',
            'version' => 0,
            'op' => '>',
            'git_repo' => 'git://github.com/c9s/cpan.vim.git',
          },
          {
            'version' => '1.2',
            'name' => 'rainbow.vim',
            'op' => '>='
          }
        ] , 'meta object');

ok( $meta_object->{$_} ) for qw(repository script version name type author);

is( $meta_object->{repository} , 'git://....../' );
is( $meta_object->{author} , 'Cornelius (cornelius.howl@gmail.com)' );
is( $meta_object->{type} , 'syntax' );
is( $meta_object->{name} , 'new_plugin' );
is( $meta_object->{version} , 0.3 );

is_deeply( $meta_object->{script}, [ 'bin/parser', 'bin/template_generator' ]);

unlink 'test.vim';
