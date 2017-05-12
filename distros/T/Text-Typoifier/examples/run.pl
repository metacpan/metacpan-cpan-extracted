use Text::Typoifier;

$text = new Text::Typoifier;
print 'Text::Typoifier ', $text->VERSION, "\n";
$text->errorRate(9);
while (<STDIN>)
{
    print $text->transform($_);
}
