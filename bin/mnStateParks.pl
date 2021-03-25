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
use File::Path qw(make_path);

my $debug = 0;
my $user_agent    = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_13_6) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/71.0.3578.98 Safari/537.36';
my $dataDirectory = './data';

if (! -e $dataDirectory) {
	make_path($dataDirectory);
}

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
my @parks = ();

# parse the response for the links
$page_p->parse($response->decoded_content());

print "there were " . scalar(@parks) . " parks found\n";

# parse the parks
my $i = 0;
foreach my $obj (@parks) {

	#print Dumper $obj;

	my $name = $obj->{'name'};
	my $url  = $obj->{'url'};
	$url =~ /=(.*)#/;
	my $id = $1 || '';

	print "processing data for $name...";

	#print "\n";
	#print "url : $url...";
	#print "id  : $id\n";

	if ($id ne '') {

		my $time = time();
		my $url_string = 'https://maps1.dnr.state.mn.us/cgi-bin/compass/feature_detail.cgi?callback=foo&id=' . $id . '&_=' . $time ;
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

		print "success\n";

	} else {

		print "error\n";

	}

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

				if ($debug == 1) {
					print "page_start : text : $text\n";
				}

				my $obj = { "url" => $attr->{'href'}, "name" => "" };
				push(@parks, $obj);

				#print "attr->{'href'} : " . $attr->{'href'} . "\n";

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
		if ($debug == 1) {
			print "end of table\n";
		}
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
		my $index = $#parks;

		if ($debug == 1) {
			print "page_default : at index $index " . $text . ' -> ' . "\n";
		}

		# add the park name, note, this comes after the 'page_start' of the tag
		my $obj = $parks[$index];
		$obj->{'name'} = $text;
		$parks[$index] = $obj;
	}

}
