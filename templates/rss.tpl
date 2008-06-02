<?xml version="1.0" encoding="UTF-8"?>
<rss version="2.0">
<channel>
<title>RSS feed for proudestfather.inarow.net</title>
<link>http://proudestfather.inarow.net</link>
<description>CDMoyer's wonderful children.</description>
<language>en_us</language>
<lastBuildDate>[% updated %]</lastBuildDate>
[% FOREACH post = posts %]
<item>
<title>[% post.title %]</title>
<description>
[% FILTER html_entity %]
	<table>
		<tr><td align="center"><a href="http://proudestfather.inarow.net/[% post.image %]"><img src="http://proudestfather.inarow.net/[% post.thumb %]"><br/><small>(Click for Full Size)</small></a></td>
	    <td align="left">[% post.caption %]</td></tr>
	</table> 
[% END %]
</description>
<link>http://proudestfather.inarow.net/[% post.image %]</link>
<pubDate>[% post.pretty_date %]</pubDate>
</item>
[% END %]
</channel>
</rss>
