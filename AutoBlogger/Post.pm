# autoblogger 
# - a quick and dirty program to create a static blog from an email account
# See LICENSE for licensing details.
# If not included, please visit http://inarow.net/entries/projects/one_evening/autoblogger/ 
#    to obtain a copy

package AutoBlogger::Post;
use MIME::Parser;
use IO::InnerFile;
use Date::Manip;

local $last_error;

sub lasterr { return $last_error; }

# get the date from a MIME::Entity
sub get_msg_date {
	my $msg = shift;
	my $dateh  = $msg->head->get('date');

	my $udate;

	my $text_part;
	foreach ($msg->parts) {
		my ($type, ) =  split(/;/, $_->head->get('content-type'));
		if ($type =~ /text\/plain/ || $type =~ /text\/html/) {
			$text_part = $_;
		}
	}
	if ($text_part && $text_part->stringify_body =~ m/\s*>date:\s*(.*)[\r\n]/) {
		$udate = $1;
	}


	if ($udate && length($udate) != 0) {
		return ParseDate($udate);
	}
	elsif (!$dateh || length($dateh) == 0) {
		return ParseDate('epoch '.time());
	}
	else {
		chomp($dateh);
		return ParseDate($dateh);
	}
}

sub new {
	my ($class) = shift;
	my (%params) = @_;

	my $self = bless {
			"dir"       =>	$params{dir},
			"fromregex" =>	$params{fromregex},
	}, $class;

	return $self->_init() if $params{dir};

	sub _init {
		my $self = shift;
		my $parser = new MIME::Parser;
		$parser->decode_headers(1);
		$parser->output_to_core(1);
		$parser->use_inner_files(1);
		open(my $emltxt, '+<', $self->dir() . '/raw.txt');
		my $m = $parser->parse($emltxt);
		close($emltxt);

		my $from = $m->head->get('from');
		chomp($from);
		my $fromregex = $self->fromregex();
		if ($from !~ /$fromregex/) {
			$last_error = "$from did not match /$fromregex/";
			return 0;
		}

		if ($m->parts < 2) {
			$last_error = "File: ".$self->dir()."/raw.txt didn't even have two mime parts!";
			return undef;
		}

		my $text_part;
		my $img_part;
		foreach ($m->parts) {
			my ($type, ) =  split(/;/, $_->head->get('content-type'));
			if ($type eq 'text/plain' || $type eq 'text/html') {
				$text_part = $_ if !$text_part;
			}
			elsif ($type eq 'image/jpeg' || $type eq 'image/gif' || $type eq 'image/png') {
				$img_part = $_;
			}
		}

		if (!$img_part || !$text_part) {
			$last_error = ("File: ".$self->dir()."/raw.txt didn't have an image and text part");
			return $undef;

		}


		my $caption = '';
		if (my $io = $text_part->open('r')) {
			while (defined($_ = $io->getline)) { $caption .= $_; }
			$io->close;
		}
		$caption =~ s/^\s*>\w+:.*$//gm;
		$caption =~ s/\r?\n\r?\n/<br \/><br \/>\n/g;

		$self->img_part($img_part);
		$self->caption($caption);
		$self->title($m->head->get('subject') || '');
		$self->date(AutoBlogger::Post::get_msg_date($m));

		return $self;
	}


	sub _set {
		my ($self, $what, $new) = @_;
		return $self->{$what} = $new || $self->{$what};
	}

	sub title { 
		$self = shift;
		my $newt = shift; 
		chomp($newt);
		$self->_set('title', $newt); 
	}

	sub pretty_date {
		my $self = shift;
		return UnixDate($self->date(), '%F');
	}

	sub caption { shift()->_set('caption', shift); }
	sub thumb { shift()->_set('thumb', shift); }
	sub image { shift()->_set('image', shift); }
	sub img_part { shift()->_set('img_part', shift); }
	sub date { shift()->_set('date', shift); }
	sub dir { shift()->_set('dir', shift); }
	sub fromregex { shift()->_set('fromregex', shift); }
}

1;
