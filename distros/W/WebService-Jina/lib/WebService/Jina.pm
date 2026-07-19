package WebService::Jina;

use 5.006;
use strict;
use warnings;

our $VERSION = '0.06';

use WebService::Jina::UA;
use Moo;

has api_key => (
	is => 'ro',
	lazy => 1,
	required => 1
);

has ua => (
	is => 'ro',
	default => sub {
		return WebService::Jina::UA->new(
			api_key => $_[0]->api_key
		);
	}
);

sub deepsearch {
	my ($self, %args) = @_;

	$args{model} ||= 'jina-deepsearch-v1';

	if (! $args{messages}) {
		die 'No messages defined for deepsearch';
	}

	$args{stream} = $args{stream} ? \1 : \0;

	$args{reasoning_effort} ||= "medium";

	$self->ua->post(
		url => 'https://deepsearch.jina.ai/v1/chat/completions',
		headers => delete $args{headers},
		data => \%args
	);
}

sub reader {
	my ($self, %args) = @_;

	if (! $args{url}) {
		die "no url defined for reader";
	}
	
	$self->ua->post(
		url => "https://r.jina.ai/",
		headers => delete $args{headers},
		data => \%args
	);
}

sub embedding {
	my ($self, %args) = @_;

	$args{model} ||= 'jina-clip-v2';

	$args{dimensions} ||= 1024;

	$args{normalized} //= 1;
	$args{normalized} = $args{normalized} ? \0 : \1;

	$args{embedding_type} ||= 'float';

	if (! $args{input}) {
		die 'no input defined for embedding';
	}

	for my $input (@{$args{input}}) {
                if ($input->{image_file}) {
                        $input->{image} = $self->ua->base64_images([delete $input->{image_file}])->[0];
                }
        }

	$self->ua->post(
		url => 'https://api.jina.ai/v1/embeddings',
		headers => delete $args{headers},
		data => \%args,
	);
}

sub rerank {
	my ($self, %args) = @_;

	$args{model} ||= 'jina-reranker-v2-base-multilingual';

	$args{top_n} ||= 3;

	if (! $args{query}) {
		die 'no query defined for rerank';
	}

	if (! $args{documents}) {
		die 'no documents defiend for rerank';
	}

	$self->ua->post(
		url => 'https://api.jina.ai/v1/rerank',
		headers => delete $args{headers},
		data => \%args
	);

}

sub classify {
	my ($self, %args) = @_;

	$args{model} ||= 'jina-clip-v2';

	if (! $args{input}) {
		die 'no input defined for classify';
	}

	for my $input (@{$args{input}}) {
                if ($input->{image_file}) {
                        $input->{image} = $self->ua->base64_images([delete $input->{image_file}])->[0];
                }
        }
	
	if (! $args{labels}) {
		die 'no labels defined for classify';
	}

	$self->ua->post(
		url => 'https://api.jina.ai/v1/classify',
		headers => delete $args{headers},
		data => \%args
	);
}

sub segment {
	my ($self, %args) = @_;

	$args{return_tokens} //= 1;
	$args{return_tokens} = $args{return_tokens} ? \1 : \0;

	$args{return_chunks} //= 1;
	$args{return_chunks} = $args{return_chunks} ? \1 : \0;

	$args{max_chunk_length} ||= 1000;
	
	if (! $args{content}) {
		die 'no content defined for segment';
	}

	$self->ua->post(
		url => 'https://api.jina.ai/v1/segment',
		headers => delete $args{headers},
		data => \%args
	);
}


1;

__END__

=encoding utf8

=head1 NAME

WebService::Jina - Jina client

=head1 VERSION

Version 0.06

=cut

=head1 SYNOPSIS


	use WebService::Jina;

	my $jina = WebService::Jina->new(
		api_key => '...'
	);
	
	...

	my $deepsearch = $jina->deepsearch(
		messages => [
			{
				role => "user",
				content => "Hi!"
			},
			{
				role => "assistant",
				content => "Hi, how can I help you?"
			},
			{
				role => "user",
				content => "what's the latest blog post from jina ai?"
			}
		]
	);

	...

	my $reader = $jina->reader(url => "https://lnation.org");

	...

	my $embed = $jina->embedding(
		input => [
	        	{
                        	text => "A beautiful sunset over the beach"
                	},
                	{
                        	text => "Un beau coucher de soleil sur la plage"
                	}
		]
	);

	...

	my $rerank = $jina->rerank(
		query => "Organic skincare products for sensitive skin",
		documents => [
			"Organic skincare for sensitive skin with aloe vera and chamomile: Imagine the soothing embrace of nature with our organic skincare range, crafted specifically for sensitive skin. Infused with the calming properties of aloe vera and chamomile, each product provides gentle nourishment and protection. Say goodbye to irritation and hello to a glowing, healthy complexion.",
			"New makeup trends focus on bold colors and innovative techniques: Step into the world of cutting-edge beauty with this seasons makeup trends. Bold, vibrant colors and groundbreaking techniques are redefining the art of makeup. From neon eyeliners to holographic highlighters, unleash your creativity and make a statement with every look.",
			"Bio-Hautpflege für empfindliche Haut mit Aloe Vera und Kamille: Erleben Sie die wohltuende Wirkung unserer Bio-Hautpflege, speziell für empfindliche Haut entwickelt. Mit den beruhigenden Eigenschaften von Aloe Vera und Kamille pflegen und schützen unsere Produkte Ihre Haut auf natürliche Weise. Verabschieden Sie sich von Hautirritationen und genießen Sie einen strahlenden Teint.",
			"Neue Make-up-Trends setzen auf kräftige Farben und innovative Techniken: Tauchen Sie ein in die Welt der modernen Schönheit mit den neuesten Make-up-Trends. Kräftige, lebendige Farben und innovative Techniken setzen neue Maßstäbe. Von auffälligen Eyelinern bis hin zu holografischen Highlightern – lassen Sie Ihrer Kreativität freien Lauf und setzen Sie jedes Mal ein Statement.",
			"Cuidado de la piel orgánico para piel sensible con aloe vera y manzanilla: Descubre el poder de la naturaleza con nuestra línea de cuidado de la piel orgánico, diseñada especialmente para pieles sensibles. Enriquecidos con aloe vera y manzanilla, estos productos ofrecen una hidratación y protección suave. Despídete de las irritaciones y saluda a una piel radiante y saludable.",
			"Las nuevas tendencias de maquillaje se centran en colores vivos y técnicas innovadoras: Entra en el fascinante mundo del maquillaje con las tendencias más actuales. Colores vivos y técnicas innovadoras están revolucionando el arte del maquillaje. Desde delineadores neón hasta iluminadores holográficos, desata tu creatividad y destaca en cada look.",
			"针对敏感肌专门设计的天然有机护肤产品：体验由芦荟和洋甘菊提取物带来的自然呵护。我们的护肤产品特别为敏感肌设计，温和滋润，保护您的肌肤不受刺激。让您的肌肤告别不适，迎来健康光彩。",
			"新的化妆趋势注重鲜艳的颜色和创新的技巧：进入化妆艺术的新纪元，本季的化妆趋势以大胆的颜色和创新的技巧为主。无论是霓虹眼线还是全息高光，每一款妆容都能让您脱颖而出，展现独特魅力。",
			"敏感肌のために特別に設計された天然有機スキンケア製品: アロエベラとカモミールのやさしい力で、自然の抱擁を感じ てください。敏感肌用に特別に設計された私たちのスキンケア製品は、肌に優しく栄養を与え、保護します。肌トラブルにさようなら、輝>く健康な肌にこんにちは。",
			"新しいメイクのトレンドは鮮やかな色と革新的な技術に焦点を当てています: 今シーズンのメイクアップトレンドは、大 胆な色彩と革新的な技術に注目しています。ネオンアイライナーからホログラフィックハイライターまで、クリエイティビティを解き放ち>、毎回ユニークなルックを演出しましょう。"
		]
	);

	...

	my $classify = $jina->classify(
		input => [
			{
				text => "A sleek smartphone with a high-resolution display and multiple camera lenses"
			},
			{
				text => "Fresh sushi rolls served on a wooden board with wasabi and ginger"
			},
			{
				image => "https://picsum.photos/id/11/367/267"
			},
			{
				image => "https://picsum.photos/id/22/367/267"
			},
			{
				text => "Vibrant autumn leaves in a dense forest with sunlight filtering through"
			},
			{
				image => "https://picsum.photos/id/8/367/267"
			}

		],
		labels => [
			"Technology and Gadgets",
			"Food and Dining",
			"Nature and Outdoors",
			"Urban and Architecture"
		]
	);	

	...

	my $segment = $jina->segment(
		content => "\n  Jina AI: Your Search Foundation, Supercharged! 🚀\n  Ihrer Suchgrundlage, aufgeladen! 🚀\n  您的搜索>底座，从此不同！🚀\n  検索ベース,もう二度と同じことはありません！🚀\n"
	);	



=head1 ABOUT

See L<https://jina.ai/>

=head1 SUBROUTINES/METHODS

=head2 deepsearch

DeepSearch combines web searching, reading, and reasoning for comprehensive investigation. Think of it as an agent that you give a research task to - it searches extensively and works through multiple iterations before providing an answer. This process involves continuous research, reasoning, and approaching the problem from various angles. This is fundamentally different from standard LLMs that generate answers directly from pretrained data, and from traditional RAG systems that rely on one-time, surface-level searches.

	my $deepsearch = $jina->deepsearch(
		stream => 1,
		stream_cb => sub {
			my ($res) = @_;
			...
		},
		messages => [
			{
				role => "user",
				content => "Hi!"
			},
			{
				role => "assistant",
				content => "Hi, how can I help you?"
			},
			{
				role => "user",
				content => "what's the latest blog post from jina ai?"
			}
		]
	);

=head2 reader

Feeding web information into LLMs is an important step of grounding, yet it can be challenging. The simplest method is to scrape the webpage and feed the raw HTML. However, scraping can be complex and often blocked, and raw HTML is cluttered with extraneous elements like markups and scripts. The Reader API addresses these issues by extracting the core content from a URL and converting it into clean, LLM-friendly text, ensuring high-quality input for your agent and RAG systems.

	my $reader = $jina->reader(url => "https://lnation.org");


	my $reader = $jina->reader(
		url => "https://lnation.org",
		jsonSchema => { ... },
		instruction => "...",
		headers => {
                	"Accept" => 'application/json',
                	"X-Respond-With" => "readerlm-v2"
        	}
	);


=cut

=head2 embedding

Top-performing multimodal multilingual long-context embeddings for search, RAG, agents applications.

	my $embed = $jina->embedding(
		input => [
		       	{
			    	text => "A beautiful sunset over the beach"
			},
			{
				text => "Un beau coucher de soleil sur la plage"
			},
			{
			    	text => "海滩上美丽的日落"
			},
			{
			    	text => "浜辺に沈む美しい夕日"
			},
			{
			    	image => "https://i.ibb.co/nQNGqL0/beach1.jpg"
			},
			{
			    	image => "https://i.ibb.co/r5w8hG8/beach2.jpg"
			},
			{
				image => "R0lGODlhEAAQAMQAAORHHOVSKudfOulrSOp3WOyDZu6QdvCchPGolfO0o/XBs/fNwfjZ0frl3/zy7////wAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAACH5BAkAABAALAAAAAAQABAAAAVVICSOZGlCQAosJ6mu7fiyZeKqNKToQGDsM8hBADgUXoGAiqhSvp5QAnQKGIgUhwFUYLCVDFCrKUE1lBavAViFIDlTImbKC5Gm2hB0SlBCBMQiB0UjIQA7"
			}
		]
	);

=cut

=head2 rerank

The goal of a search system is to find the most relevant results quickly and efficiently. Traditionally, methods like BM25 or tf-idf have been used to rank search results based on keyword matching. Recent methods, such as embedding-based cosine similarity, have been implemented in many vector databases. These methods are straightforward but can sometimes miss the subtleties of language, and most importantly, the interaction between documents and a query's intent.

This is where the "reranker" shines. A reranker is an advanced AI model that takes the initial set of results from a search—often provided by an embeddings/token-based search—and reevaluates them to ensure they align more closely with the user's intent. It looks beyond the surface-level matching of terms to consider the deeper interaction between the search query and the content of the documents.

	my $rerank = $jina->rerank(
		query => "Organic skincare products for sensitive skin",
		documents => [
			"Organic skincare for sensitive skin with aloe vera and chamomile: Imagine the soothing embrace of nature with our organic skincare range, crafted specifically for sensitive skin. Infused with the calming properties of aloe vera and chamomile, each product provides gentle nourishment and protection. Say goodbye to irritation and hello to a glowing, healthy complexion.",
			"New makeup trends focus on bold colors and innovative techniques: Step into the world of cutting-edge beauty with this seasons makeup trends. Bold, vibrant colors and groundbreaking techniques are redefining the art of makeup. From neon eyeliners to holographic highlighters, unleash your creativity and make a statement with every look.",
			"Bio-Hautpflege für empfindliche Haut mit Aloe Vera und Kamille: Erleben Sie die wohltuende Wirkung unserer Bio-Hautpflege, speziell für empfindliche Haut entwickelt. Mit den beruhigenden Eigenschaften von Aloe Vera und Kamille pflegen und schützen unsere Produkte Ihre Haut auf natürliche Weise. Verabschieden Sie sich von Hautirritationen und genießen Sie einen strahlenden Teint.",
			"Neue Make-up-Trends setzen auf kräftige Farben und innovative Techniken: Tauchen Sie ein in die Welt der modernen Schönheit mit den neuesten Make-up-Trends. Kräftige, lebendige Farben und innovative Techniken setzen neue Maßstäbe. Von auffälligen Eyelinern bis hin zu holografischen Highlightern – lassen Sie Ihrer Kreativität freien Lauf und setzen Sie jedes Mal ein Statement.",
			"Cuidado de la piel orgánico para piel sensible con aloe vera y manzanilla: Descubre el poder de la naturaleza con nuestra línea de cuidado de la piel orgánico, diseñada especialmente para pieles sensibles. Enriquecidos con aloe vera y manzanilla, estos productos ofrecen una hidratación y protección suave. Despídete de las irritaciones y saluda a una piel radiante y saludable.",
			"Las nuevas tendencias de maquillaje se centran en colores vivos y técnicas innovadoras: Entra en el fascinante mundo del maquillaje con las tendencias más actuales. Colores vivos y técnicas innovadoras están revolucionando el arte del maquillaje. Desde delineadores neón hasta iluminadores holográficos, desata tu creatividad y destaca en cada look.",
			"针对敏感肌专门设计的天然有机护肤产品：体验由芦荟和洋甘菊提取物带来的自然呵护。我们的护肤产品特别为敏感肌设计，温和滋润，保护您的肌肤不受刺激。让您的肌肤告别不适，迎来健康光彩。",
			"新的化妆趋势注重鲜艳的颜色和创新的技巧：进入化妆艺术的新纪元，本季的化妆趋势以大胆的颜色和创新的技巧为主。无论是霓虹眼线还是全息高光，每一款妆容都能让您脱颖而出，展现独特魅力。",
			"敏感肌のために特別に設計された天然有機スキンケア製品: アロエベラとカモミールのやさしい力で、自然の抱擁を感じ てください。敏感肌用に特別に設計された私たちのスキンケア製品は、肌に優しく栄養を与え、保護します。肌トラブルにさようなら、輝>く健康な肌にこんにちは。",
			"新しいメイクのトレンドは鮮やかな色と革新的な技術に焦点を当てています: 今シーズンのメイクアップトレンドは、大胆な色彩と革新的な技術に注目しています。ネオンアイライナーからホログラフィックハイライターまで、クリエイティビティを解き放ち>、毎回ユニークなルックを演出しましょう。"
		]
	);

=cut

=head2 classify

The Classifier is an API service that categorizes text and images using embedding models (jina-embeddings-v3 and jina-clip-v1), supporting both zero-shot classification without training data and few-shot learning with minimal examples.

	my $classify = $jina->classify(
		input => [
			{
				text => "A sleek smartphone with a high-resolution display and multiple camera lenses"
			},
			{
				text => "Fresh sushi rolls served on a wooden board with wasabi and ginger"
			},
			{
				image => "https://picsum.photos/id/11/367/267"
			},
			{
				image => "https://picsum.photos/id/22/367/267"
			},
			{
				text => "Vibrant autumn leaves in a dense forest with sunlight filtering through"
			},
			{
				image => "https://picsum.photos/id/8/367/267"
			}

		],
		labels => [
			"Technology and Gadgets",
			"Food and Dining",
			"Nature and Outdoors",
			"Urban and Architecture"
		]
	);	

=cut

=head2 segment

A segmenter is a crucial component that converts text into tokens or chunks, which are the basic units of data that an embedding/reranker model or LLM processes. Tokens can represent whole words, parts of words, or even individual characters.

	my $segment = $jina->segment(
		content => "\n  Jina AI: Your Search Foundation, Supercharged! 🚀\n  Ihrer Suchgrundlage, aufgeladen! 🚀\n  您的搜索>底座，从此不同！🚀\n  検索ベース,もう二度と同じことはありません！🚀\n"
	);	

=cut

=head1 AUTHOR

lnation, C<< <email at lnation.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-webservice-jina at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=WebService-Jina>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WebService::Jina


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=WebService-Jina>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/WebService-Jina>

=item * Search CPAN

L<https://metacpan.org/release/WebService-Jina>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2025 by lnation.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)


=cut

1; # End of WebService::Jina
