#!/usr/bin/perl
#
# Written by Travis Kent Beste
# Wed Jun 19 19:20:53 CDT 2019

use strict;
use warnings;

# unbuffered i/o
$|++;

# centos dependancies
# sudo yum -y install perl-libwww-perl
# sudo yum -y install perl-Crypt-SSLeay
# sudo yum -y install perl-WWW-Mechanize
# sudo yum -y install perl-JSON
# sudo yum -y install perl-LWP-Protocol-https

use LWP;
use Data::Dumper;
use HTTP::Cookies;
use Crypt::SSLeay;
use WWW::Mechanize ();
use JSON qw( decode_json );

my $user_agent    = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_13_6) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/71.0.3578.98 Safari/537.36';
my $dataDirectory = './data';

# Create page parser object
my $page_p        = HTML::Parser->new(
	api_version     => 3,
	start_h         => [\&page_start,   "self, tagname, attr, attrseq, text" ],
	end_h           => [\&page_end,     "self, tagname"],
	default_h       => [\&page_default, "self, text"],
	marked_sections => 1,
);

# Create page parser object
my $park_p        = HTML::Parser->new(
	api_version     => 3,
	start_h         => [\&park_start,   "self, tagname, attr, attrseq, text" ],
	end_h           => [\&park_end,     "self, tagname"],
	default_h       => [\&park_default, "self, text"],
	marked_sections => 1,
);

# build the mechanize
my $mech = WWW::Mechanize->new(
	agent => $user_agent,
	cookie_jar => HTTP::Cookies->new(
		file           => './cookies.lwp',
		autosave       => 1,
		ignore_discard => 1,
	),
	ssl_opts => {
		verify_hostname => 0
	},
	noproxy => 0,
);

# save memory
$mech->stack_depth( 5 );

my $url_string = 'https://www.dnr.state.mn.us/state_parks/list_alpha.html';
my $response = $mech->get($url_string);
#print Dumper $response->decoded_content;
#exit;

my $gatherData = 0;
my $urls = {};

# parse the response for the links
$page_p->parse($response->decoded_content());

# parse the urls
foreach my $url (keys %$urls) {
	$url =~ /state_parks\/(.*)\//;

	my $park = $1;

	print "processing data for $park...";

	my $url_string = 'https://www.dnr.state.mn.us' . $url;
	#print $url_string . "\n";

	my $response = $mech->get($url_string);
	my @redirects = $response->redirects;

	if (scalar(@redirects)) {
		my $redirect = $redirects[-1]->header('Location');
		$redirect =~ /id=(.*)$/;
		my $id = $1;
		my $time = time();
		$url_string = 'https://maps1.dnr.state.mn.us/cgi-bin/compass/feature_detail.cgi?callback=foo&id=' . $id . '&_=' . $time ;

		my $debug = 0;
		if ($debug) {
			print "\n";
			print "request uri     : " . $redirects[-1]->request->uri . "\n";
			print "location header : " . $redirects[-1]->header('Location') . "\n";
			print "redirect        : $redirect\n";
			print "id              : $id\n";
			print "time            : $time\n";
			print "url_string      : $url_string\n";
		}
	
		# always print the id
		print "$id...";

		# parse the response for the links
		if (-e $dataDirectory . '/' . $id . '.json') {
			print "error!\n";
			print "request uri     : " . $redirects[-1]->request->uri . "\n";
			print "location header : " . $redirects[-1]->header('Location') . "\n";
			print "redirect        : $redirect\n";
			print "id              : $id\n";
			print "time            : $time\n";
			print "url_string      : $url_string\n";
			exit;
		}

		$response = $mech->get($url_string);
		my $string = $response->decoded_content();
		$string =~ s/foo\(//; # remove the foo
		chop($string); # ')' character
		chop($string); # newline
		my $json = decode_json($string);

		# save the files
		open(FP, ">$dataDirectory/$id.json");
		print FP $string;
		close(FP);

	} else {
		#print "ignored $url_string\n";
	}

	print "done\n";
}

#----------------------------------------#
#
#----------------------------------------#
sub page_start {
	my $self    = shift;
	my $tagname = shift;
	my $attr    = shift;
	my $attrseq = shift;
	my $text    = shift;

	if ($tagname eq 'table') {
		$gatherData++;
	}

	if ($gatherData) {
		if ($tagname eq 'a') {
			if (defined($attr->{'href'})) {
				#print "$text\n";
				#print $attr->{'href'} . "\n";
				$urls->{$attr->{'href'}}++;
			}
		}
	}
	
}

#----------------------------------------#
#
#----------------------------------------#
sub page_end {
	my $self    = shift;
	my $tagname = shift;

	if ($tagname eq 'table') {
		$gatherData = 0;
	}
}

#----------------------------------------#
#
#----------------------------------------#
sub page_default {
	my $self    = shift;
	my $text    = shift;

	if ($gatherData) {
		#print $text . ' -> ' . "\n";
	}

}
