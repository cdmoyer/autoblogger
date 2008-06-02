#!/usr/bin/env perl
# autoblogger 
# - a quick and dirty program to create a static blog from an email account
# See LICENSE for licensing details.
# If not included, please visit http://inarow.net/entries/projects/one_evening/autoblogger/ 
#    to obtain a copy

use strict;
use warnings;


package main;
use Getopt::Long;
use AutoBlogger::Post;
use Mail::POP3Client;
use MIME::Parser;
use Date::Manip;
use File::Copy::Recursive qw/dirmove fcopy/;
use List::Util qw/min/;
use Template;
use GD;


# Get and validate args

my %CONFIG;
$CONFIG{thumbsize} = '150x150';
$CONFIG{fullsize} = '800x800';
$CONFIG{tmp} = '/tmp';
$CONFIG{extension} = 'html';
$CONFIG{indexsize} = 10;
GetOptions(
	'verbose!'    => \$CONFIG{verbose},
	'host=s'      => \$CONFIG{host},
	'user=s'      => \$CONFIG{user},
	'pass=s'      => \$CONFIG{pass},
	'ssl!'        => \$CONFIG{ssl},
	'rebuild=s'   => \$CONFIG{rebuild},
	'nopop!'      => \$CONFIG{nopop},
	'thumbsize=s' => \$CONFIG{thumbsize},
	'fullsize=s'  => \$CONFIG{fullsize},
	'extension=s' => \$CONFIG{extension},
	'tmp=s'       => \$CONFIG{tmp},
	'indexsize=i' => \$CONFIG{indexsize},
	'from=s'      => \$CONFIG{fromregex},
);

$CONFIG{storage} = $ARGV[0];
$CONFIG{published} = $ARGV[1];

my $error = '';
for (qw/host user pass storage published/) {
	$error .= $_ . " must be provided\n" unless $CONFIG{$_};
}
usage($error) if (length($error) > 0 );

for (qw/storage published/) {
	$error .= ("path-to-$_ doesn't exist") unless (-d $CONFIG{$_});
}
usage($error) if (length($error) > 0 );

$CONFIG{fromregex} = '.' unless $CONFIG{fromregex};


my $processed = 0;
unless ($CONFIG{nopop}) {
	# First Pop Mail
	my $pop = new Mail::POP3Client(
		HOST      => $CONFIG{host},
		USESSL    => $CONFIG{ssl},
		AUTH_MODE => 'BEST',
		#DEBUG     => 1
	);
	
	$pop->User($CONFIG{user});
	$pop->Pass($CONFIG{pass});
	$pop->Connect();
	
	my $msg_count = $pop->Count();
	if ($msg_count == -1) {
		die $pop->Message() ."\n\nNo Site Updates performed [2]\n";
	}
	elsif ($msg_count > 0 ) {
		debug_tell("Downloading $msg_count messages...", 0);
	}
	
	debug_tell('POP connected');
	for (my $n = 1; $n <= $msg_count; $n++) {
		$processed += process_new_message($pop, $n);
	}
}
	

# Build index if necessary (new items)

if ($processed == 0 && !$CONFIG{rebuild} ) {
	debug_tell('No new messages, exiting.', 0);
	exit;
}

if ($processed > 0 ) { $CONFIG{rebuild} = 'all'; }

my $navigation = get_navigation();

if ($processed > 0 || $CONFIG{rebuild} =~ /(index|all)/) {
	my @files = glob($CONFIG{storage}. '/*/*');	
	@files = reverse sort(@files);
	my $max = min($CONFIG{indexsize}, scalar @files);

	create_file(\@files, 
		'index.' . $CONFIG{extension},
		'index.tpl', 
		'',
		$max);

	create_file(\@files, 
		'rss.xml',
		'rss.tpl', 
		'',
		$max);
}


# Update Archive

my %rebuild;


for my $r (split(/,/, $CONFIG{rebuild})) {
	$rebuild{$r} = 1 if -d $CONFIG{storage} . '/' . $r;
}

if ($CONFIG{rebuild} =~ /all/ || $processed > 0) {
	foreach my $n (@{$navigation}) {
		$rebuild{$n->{mon}} = 1;
	}
}

debug_tell('Rebuilding Archives: '.join(',', keys %rebuild));

foreach my $r (keys %rebuild) {
	build_archive($r);
}


debug_tell('ZOMG, reached the end, exiting.', 0);
exit(0);


sub build_archive {
	my $dir = shift;
	my @files = glob($CONFIG{storage}. "/$dir/*");	
	@files = sort(@files);

	create_file(\@files, 
		'archive_'.$dir.'.'.$CONFIG{extension},
		'archive.tpl',
		UnixDate($dir, '%B %Y'),
		-1);

}

sub create_file {
	my $files = shift;
	my $file = shift;
	my $template = shift;
	my $title = shift;
	my $max = shift || -1;

	my @posts;
	for (my $i=0; $i<$max || $max==-1; $i++) {
		my $file = $files->[$i];

		last unless $file;

		my $p = new AutoBlogger::Post(dir => $file, fromregex => $CONFIG{fromregex});

		unless ($p) {
			debug_tell(AutoBlogger::Post::lasterr(), 1);
			next;
		}  

		push @posts, $p;
		debug_tell('Successfully read '.$file.' -> '.$p->title());
		my ($thumb, $full) = make_images($p);
		my $thumb_t = $thumb;
		my $full_t = $full;;
		$thumb_t =~ s/$CONFIG{storage}/images/;
		$full_t =~ s/$CONFIG{storage}/images/;

		fcopy($thumb, $CONFIG{published} . '/'. $thumb_t) or die $!;
		fcopy($full, $CONFIG{published} . '/' . $full_t) or die $!;
		$p->thumb($thumb_t);
		$p->image($full_t);
	}

	my $vars = {
		indexurl   => 'index.'.$CONFIG{extension},
		title     => $title,
		posts      => \@posts,
		updated    => UnixDate('now','%c'),
		navigation => $navigation
	};

	my $tt = Template->new({
		INCLUDE_PATH => 'templates/',
	});

	open(my $index, '>', $CONFIG{published} . '/' . $file);
	$tt->process($template, $vars, $index) or die $tt->error();
	close($index);
	debug_tell("Wrote $file");
}


sub get_navigation {
	my @months;
	
	my @dirs = glob($CONFIG{storage}. '/2*'); # Y3k bug!  But, seems safer to filter on that.
	@dirs = sort(@dirs);

	foreach my $dir (@dirs) {
		my %m;
		my $mon = $dir;
		$mon =~ s/^.*\/([0-9]*)/$1/;

		$m{name} = UnixDate($mon, '%B %Y');
		$m{mon} = $mon;
		$m{url} = 'archive_'.$mon.'.'.$CONFIG{extension};
		my @fs = glob($dir .'/*');
		$m{count} = scalar @fs;
		push @months, \%m;
	}

	return \@months;
}

sub make_images {
	my $post = shift;
	my @result;
	for (($CONFIG{thumbsize},$CONFIG{fullsize})) {
		my ($maxw, $maxh) = split(/x/, $_);
		my $outfile = $maxw.'x'.$maxh.'.jpg';
		$outfile = $post->dir().'/'.$outfile;
		push @result, $outfile;

		unless (-e $outfile) { 
			debug_tell("Creating new image: $outfile");
			my $orig = GD::Image->new($post->img_part->bodyhandle->as_string);

			my $resw = $orig->width;
			my $resh = $orig->height;
			if ($orig->width > $maxw) {
				$resw = $maxw;
				$resh = int($resh * ($resw/$orig->width));
			}
			if ($resh > $maxh) {
				my $temph = $resh;
				$resh = $maxh;
				$resw = int( $resw * ($resh/$temph));
			}

			my $target = GD::Image->new($resw, $resh, 1);
			$target->copyResampled($orig, 0, 0, 0, 0, $resw, $resh, $orig->width, $orig->height);
	
			open(my $out, '>'.$outfile);
			binmode $out;
			print $out $target->jpeg();
			close $out;
		}
	}

	return @result;
}
	
sub get_msg_path {
	my ($path, $timestamp) = @_;
	my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($timestamp);
	$year=$year+1900;
	$mon += 1;

	my $mon_dir = $path . '/' . sprintf('%04d%02d', $year, $mon);
	mkdir $mon_dir unless -d $mon_dir;

	my $this_dir;
	my $ext_num = 0;
	do {
		$this_dir = sprintf('%s/%02d_%02d%02d%02d%s',
			$mon_dir, $mday, $hour, $min, $sec, ($ext_num++ > 0 ? "_$ext_num" : ''));
	} while (-d $this_dir);

	return $this_dir;
}


# msg, level.  0=verbose (default), 1=always tell
sub debug_tell {
	my $msg = shift;
	my $level = shift;
	$level = 0 unless $level;

	if ($level == 1 || $CONFIG{verbose}) {
		print $msg . "\n";
	}
}

sub usage {
	my $error = shift;
	$error .= "\n" if $error;
	die <<END
Error: $error	
autoblogger.pl [args] path-to-storage path-to-published-site
-v [--verbose]      Verbose mode
-h [--host=]*       Pop Host
-u [--user=]*       Pop User
-p [--pass=]*       Pop Password
-s [--ssl]          Use SSL
-n [--nopop]        Don't get newmessages
-r [--rebuild=]     Rebuild output index,200708 or index o 200708
-i [--indexsize=]   How many posts on the index
-e [--extension=]   Extension for output html (default html)
   [--tmp=]         tmp directory (defaults to /tmp
   [--thumbsize=]   thumbnail size (defaults to 150x150)
   [--fullsize=]    full image size (defaults to 800x800)
   [--from=]        only process messages where the from: matches this regex (Still downloaded)
	* required

END
}



# process_new_message($pop, $msg_number)
# store raw msg
# parse out mime parts
# return number processed (0 or 1)
sub process_new_message {
	my ($pop, $msg_num) = @_;
	debug_tell("Parsing message number $msg_num ...", 0);

	my $tmpdir = tmp_dir();
	my $fname = $tmpdir . '/raw.txt';
	open(my $emltxt, ">$fname");
	$pop->HeadAndBodyToFile($emltxt, $msg_num);

	my $parser = new MIME::Parser;
	$parser->decode_headers(1);
	$parser->output_under($tmpdir);
	close($emltxt);

	open($emltxt, $fname);
	my $msg = $parser->parse($emltxt);

	my $date = AutoBlogger::Post::get_msg_date($msg);
	my $pname = get_msg_path($CONFIG{storage}, UnixDate($date, '%s'));
	print "rename ($tmpdir, $pname)\n";
	dirmove($tmpdir, $pname) or die "dirmove failed $!";
	
	return 1;
}



# make a new direcory in $CONFIG{tmp}
# return the path
sub tmp_dir {
	my $dir;
	my $cnt = 0;
	do {
		$dir = $CONFIG{tmp} . '/' . time() . $cnt++;
	} while (-d $dir);
	mkdir $dir;
	return $dir;
}
