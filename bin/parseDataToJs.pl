#!/usr/bin/perl
#
# Written by Travis Kent Beste
# Sun Jun 23 15:05:01 UTC 2019

use warnings;
use strict;

# centos install dependancies
# yum -y install perl-JSON

use JSON;
use Data::Dumper;
use Getopt::Long;
my $debug = 0;
my $verbose = 0;
my $help = 0;
my $dataDirectory = './data';
GetOptions (
	"data-directory=s" => \$dataDirectory,
	"help" => \$help,
	"verbose" => \$verbose,
	"debug" => \$debug
) or die("Error in command line arguments\n");

#print "dataDirectory : $dataDirectory\n";
#print "help          : $help\n";
#print "verbose       : $verbose\n";
#print "debug         : $debug\n";

opendir(DIR, $dataDirectory);
my @files = grep(/json/, readdir(DIR));
closedir(DIR);

my @objs = ();
foreach my $file (@files) {
	my $string = '';
	open(FP, $dataDirectory . '/' . $file);
	while(<FP>) {
		$string .= $_;
	}
	close(FP);

	my $json = decode_json($string);
	#print Dumper $json->{'result'};

	my $trails = $json->{'result'}->{'trails'};
	my $maps = $json->{'result'}->{'maps'};
	my $widgets = $json->{'result'}->{'widgets'};
	my $point = $json->{'result'}->{'point'};
	my $overnight_facilities = $json->{'result'}->{'overnight_facilities'};
	my $hours_of_operation = $json->{'result'}->{'hours_of_operation'};
	my $highlights = $json->{'result'}->{'highlights'};
	my $contact = $json->{'result'}->{'contact'};
	my $emt_id = $json->{'result'}->{'emt_id'};
	my $narratives = $json->{'result'}->{'narratives'};
	my $name = $json->{'result'}->{'name'};
	my $amenities = $json->{'result'}->{'amenities'};
	my $directory = $json->{'result'}->{'directory'};
	my $alert = $json->{'result'}->{'alert'};
	my $related_pages = $json->{'result'}->{'related_pages'};
	my $id = $json->{'result'}->{'id'};
	my $bbox = $json->{'result'}->{'bbox'};
	my $notes = $json->{'result'}->{'notes'};
	my $nearest_town = $json->{'result'}->{'neearest_town'};
	my $acres = $json->{'result'}->{'acres'};
	my $recreation_facilities = $json->{'result'}->{'recreation_facilities'};
	my $ta_id = $json->{'result'}->{'ta_id'};
	my $seasonal_update = $json->{'result'}->{'seasonal_update'};

	#print Dumper $contact;
	#exit;

	my $obj = {};
	$obj->{'id'} = $id;
	$obj->{'name'} = $name;
	$obj->{'latitude'} = $point->{'epsg:4326'}[1];
	$obj->{'longitude'} = $point->{'epsg:4326'}[0];
	$obj->{'acres'} = $acres;
	$obj->{'phone'} = $contact->{'phone'};
	$obj->{'address'} = $contact->{'address'};
	$obj->{'hours'} = $contact->{'hours'};
	push(@objs, $obj);

	if ($verbose) {
		print "name      : $name\n";
	}
	my $longitude = $point->{'epsg:4326'}[0];
	my $latitude  = $point->{'epsg:4326'}[1];
	#print "latitude  : $latitude\n";
	#print "longitude : $longitude\n";
	#print "acres     : $acres\n";
	#print "phone     : " . $contact->{'phone'} . "\n";
	#print "address   : " . $contact->{'address'} . "\n";
	#print "hours     : " . $contact->{'hours'} . "\n";
	#print "\n";
}

open(FP, '>' . './data.js');
print FP 'data_callback(' . encode_json(\@objs) . ");\n";
close(FP);
