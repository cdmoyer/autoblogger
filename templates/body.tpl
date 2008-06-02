	<body>
		<div id="container">
			<div id="title">
				<h1>ProudestFather</h1>
				<h2>[% title %]</h2>
			</div>
			<div id="navigation">
				<div id="nav-nav">
					<ul class="nav-group">
						<li class="nav-item"><a href="[% indexurl %]">Home</a></li>
					</ul>
					<ul class="nav-group">
							<li class="nav-group-heading">Archive</li>
						[% FOREACH nav = navigation %]
							<li class="nav-item"><a href="[% nav.url %]">[% nav.name %] ([% nav.count %])</a></li>
						[% END %]
					</ul>
				</div>
			</div>
			<div id="content">
				[% count = 0 %]
				[% FOREACH post = posts %]
				<div class="subcontent">
					<div class="post-heading">
						<h3 class="post-title">[% post.title %]</h3>
						<h4 class="post-date">[% post.pretty_date %]</h4>
					</div>
					<div class="post-body">
						<table width="100%">
							<tr>
							[% IF post.caption.replace('(\s|<br\s*/>)','') == '' %]
							<td align="center"><a class="imglink" href="[% post.image %]" title="Full Size: [% post.title %]"><img src="[% post.thumb %]"><br/><small>(Click for Full Size)</small></a></td>
							[% ELSIF (count % 2) == 1 %]
							[% count = count + 1 %]
							<td align="center"><a class="imglink" href="[% post.image %]" title="Full Size: [% post.title %]"><img src="[% post.thumb %]"><br/><small>(Click for Full Size)</small></a></td>
							    <td align="left">[% post.caption %]</td>
							[% ELSE %]
							[% count = count + 1 %]
							<td align="left" width="100%">[% post.caption %]</td>
							<td align="right"><a class="imglink" href="[% post.image %]" title="Full Size: [% post.title %]"><img src="[% post.thumb %]"><br/><small>(Click for Full Size)</small></a></td>
							[% END %]	
							</tr>
						</table>
					</div>
					<div class="post-menu">
					</div>
				</div>
				[% END %]
			</div>
			<div id="clear">
				<div>
				Last Updated: [% updated %]
				</div>
			</div>
		</div>
	</body>
