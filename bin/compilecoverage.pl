#!/usr/bin/perl

$coverage = "coverage";
%results = ();

open FILE, "<froyo/$coverage" or die $!;
$currentperm = "";
while (<FILE>) {
	chomp($_);
	$_ =~ s/\n//;
	if ($_ =~ m/^Permission:(.*)$/) {
		$currentperm = $1;
	} elsif ($_ =~ m/^(.*) checks protect (.*) methods/) {
		$results{$currentperm}{"froyo"} = $2;
	}
}
close FILE;
open FILE, "<gingerbread/$coverage" or die $!;
$currentperm = "";
while (<FILE>) {
	chomp($_);
	$_ =~ s/\n//;
	if ($_ =~ m/^Permission:(.*)$/) {
		$currentperm = $1;
	} elsif ($_ =~ m/^(.*) checks protect (.*) methods/) {
		$results{$currentperm}{"gingerbread"} = $2;
	}
}
close FILE;
open FILE, "<honeycomb/$coverage" or die $!;
$currentperm = "";
while (<FILE>) {
	chomp($_);
	$_ =~ s/\n//;
	if ($_ =~ m/^Permission:(.*)$/) {
		$currentperm = $1;
	} elsif ($_ =~ m/^(.*) checks protect (.*) methods/) {
		$results{$currentperm}{"honeycomb"} = $2;
	}
}
close FILE;
open FILE, "<ics/$coverage" or die $!;
$currentperm = "";
while (<FILE>) {
	chomp($_);
	$_ =~ s/\n//;
	if ($_ =~ m/^Permission:(.*)$/) {
		$currentperm = $1;
	} elsif ($_ =~ m/^(.*) checks protect (.*) methods/) {
		$results{$currentperm}{"ics"} = $2;
	}
}
close FILE;

foreach $k (sort keys %results) {
	print "$k\t".$results{$k}{"froyo"}."\t".$results{$k}{"gingerbread"}."\t".$results{$k}{"honeycomb"}."\t".$results{$k}{"ics"}."\n";
}
