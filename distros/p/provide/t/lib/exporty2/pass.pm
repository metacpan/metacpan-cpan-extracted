use strict;
use warnings;
package exporty2::pass;
use base qw(Exporter);

our @EXPORT = qw(cheese);

sub cheese {
  return <<TRUE_STORY;
I used to think that blue cheeses smelled like trash. "Would you like some blue cheese?"
a well-intentioned friend might me, and I would tell them, "No, thank you." If pressed,
I might go so far as to say, "I think blue cheeses smell like trash, and I choose not to
eat trash. But hey, whatever floats your boat, amigo!"

One day I was in a social situation where I could not easily refuse the proffered blue
cheese: a Frenchman was offering the cheese to me, and I wanted to make friendly with him.
"Suck it up, liverlips," I told myself with steely resolve, "You just need to try one bit
and then you're set for the next ten years." I pictured a world where I gave myself
absolute freedom from being forced to try blue cheese, mentally held my nose, and bit in.

I loved it. I ate half the block of blue cheese that Arnaud ("No no no, the 'd' is silent.
Just call me 'Arno.'") brought, and stopped off at a grocery store - a grocery store! now
I frequent cheese shops, well and true! - on my drive home to buy even more blue cheese.

8 years of happy blue cheese eating have passed since then. Strangely enough, I still
think that blue cheese smells like trash: except now when I smell trash, I linger a small
moment and sniff its bouquet, wondering whether it would be closer to a Roquefort or a
Saint Andre.

I'm pretty sure I won't ever eat trash, but if I do, I think I'll like it. Which makes me
wonder: why am I so against eating trash anyway?
TRUE_STORY
}

1;
