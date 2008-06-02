	<head>
		<title>ProudestFather</title>
		<link rel="stylesheet" href="styles.css" type="text/css" media="screen" />
		<link rel="stylesheet" href="js/modalbox.css" type="text/css" media="screen" />
		<link rel="alternate" type="application/rss+xml" title=" RSS feed" href="http://proudestfather.inarow.net/rss.xml" /> 
		<style type='text/css'>
			#content .subcontent img{ border: 1px solid black; margin: .5em; padding: 1px;}
			#content .subcontent table {border: 0; text-align: center; padding: 0; margin:0; }
			#content .subcontent .post-body {text-align: center;}
			#content .subcontent table td {vertical-align: top; }
			div.photopop { text-align: center; background-color: #fff; color: #990;}
			div.photopop img { border: 2px solid black; margin: 2px; }
		</style>
		<script type="text/javascript" src="js/prototype.js"></script>
		<script type="text/javascript" src="js/scriptaculous.js?load=builder,effects"></script>
		<script type="text/javascript" src="js/modalbox.js"></script>
		<script type="text/javascript">
			window.onload = function () {
				var as = document.getElementsByClassName('imglink');
				for (i=0; i<as.length; i++) {
					as[i].onclick = function () { 
						Modalbox.show('<div onclick="Modalbox.hide()" class="photopop"><img src="'+(this.href)+'" /><br />(Click Anywhere or hit Esc to close)</div>', {title: this.title, width: 810, overlayDuration: 0, slideDownDuration: .1, slideUpDuration: .1});
						return false;	
					}
				}
			}
		</script>
	</head>
