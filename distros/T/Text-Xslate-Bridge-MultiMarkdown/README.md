# NAME

Text::Xslate::Bridge::MultiMarkdown - MultiMarkdown 'filter' for Text::Xslate

# VERSION

version 0.002

# SYNOPSIS

    use Text::Xslate::Bridge::MultiMarkdown;
     

    my $xslate = Text::Xslate->new(
        module => [ 'Text::Xslate::Bridge::MultiMarkdown' ],
    );

    print $xslate->render_string('<: markdown( "# H1 Heading" ) :>');

    print $xslate->render_string('<: markdown( "# H1 Heading", heading_ids => 0 ) :>');

# AUTHOR

William Wolf <throughnothing@gmail.com>

# COPYRIGHT AND LICENSE



William Wolf has dedicated the work to the Commons by waiving all of his
or her rights to the work worldwide under copyright law and all related or
neighboring legal rights he or she had in the work, to the extent allowable by
law.

Works under CC0 do not require attribution. When citing the work, you should
not imply endorsement by the author.
