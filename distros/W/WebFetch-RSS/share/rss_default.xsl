<?xml version="1.0" encoding="utf-8"?>
<!--
    simple RSS style for WebFetch::Output::RSS for use as default (when no other is provided)
    derived from sample by github/natclark at https://gist.github.com/natclark/bc4d993c2d5c70ab692b059a44a75882
-->
<xsl:stylesheet version="3.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:dc="http://purl.org/dc/elements/1.1/">
    <xsl:output method="html" version="1.0" encoding="UTF-8" indent="yes"/>
    <xsl:template match="/">
        <html xmlns="http://www.w3.org/1999/xhtml" lang="en" dir="ltr">
            <head>
                <title><xsl:value-of select="/rss/channel/title"/>RSS Feed</title>
                <meta charset="UTF-8" />
                <meta http-equiv="x-ua-compatible" content="IE=edge,chrome=1" />
                <meta http-equiv="content-language" content="en_US" />
                <meta name="viewport" content="width=device-width,minimum-scale=1,initial-scale=1,shrink-to-fit=no" />
                <meta name="referrer" content="none" />
                <!-- FAVICONS CAN GO HERE -->
                <style type="text/css">
                    body {
                        color: gray8;
                        font-family: sans-serif;
                    }
                    .container {
                        align-item: left;
                        display: flex;
                        justify-content: left;
                    }
                    .item {
                    }
                    a {
                        color: RoyalBlue;
                        text-decoration: none;
                    }
                    a:visited {
                        color: blue;
                    }
                    a:hover {
                        text-decoration: underline;
                    }
                </style>
            </head>
            <body>
                <div class="container">
                    <div class="item">
                        <header>
                            <h1>RSS Feed</h1>
                            <h2>
                                <xsl:value-of select="/rss/channel/title"/>
                            </h2>
                            <p>
                                <xsl:value-of select="/rss/channel/description"/>
                            </p>
                            <a hreflang="en" target="_blank">
                                <xsl:attribute name="href">
                                    <xsl:value-of select="/rss/channel/link"/>
                                </xsl:attribute>
                                Visit Website &#x2192;
                            </a>
                        </header>
                        <main>
                            <h2>Recent Posts</h2>
                            <xsl:for-each select="/rss/channel/item">
                                <article>
                                    <h3>
                                        <a hreflang="en" target="_blank">
                                            <xsl:attribute name="href">
                                                <xsl:value-of select="link"/>
                                            </xsl:attribute>
                                            <xsl:value-of select="title"/>
                                        </a>
                                    </h3>
                                    <footer>
                                        Published:
                                        <time>
                                            <xsl:value-of select="pubDate" />
                                        </time>
                                    </footer>
                                </article>
                            </xsl:for-each>
                        </main>
                    </div>
                </div>
            </body>
        </html>
    </xsl:template>
</xsl:stylesheet>
