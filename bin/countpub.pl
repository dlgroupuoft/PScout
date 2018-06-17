#!/usr/bin/perl

$pubfile = "publishedapimapping";

%allresult = ();
$currentperm = "";
open FILE, "<froyo/$pubfile" or die $!;
while (<FILE>) {
	chomp($_);
	$_ =~ s/\n//;
	if ($_ =~ m/^Permission:(.*)/) {
		$currentperm = $1;
	} elsif ($_ =~ m/^(.*) Callers:/) {
		$allresult{$currentperm}{"froyo"} = $1;
	}
	
}
close FILE;
open FILE, "<gingerbread/$pubfile" or die $!;
while (<FILE>) {
	chomp($_);
	$_ =~ s/\n//;
	if ($_ =~ m/^Permission:(.*)/) {
		$currentperm = $1;
	} elsif ($_ =~ m/^(.*) Callers:/) {
		$allresult{$currentperm}{"gingerbread"} = $1;
	}
	
}
close FILE;
open FILE, "<honeycomb/$pubfile" or die $!;
while (<FILE>) {
	chomp($_);
	$_ =~ s/\n//;
	if ($_ =~ m/^Permission:(.*)/) {
		$currentperm = $1;
	} elsif ($_ =~ m/^(.*) Callers:/) {
		$allresult{$currentperm}{"honeycomb"} = $1;
	}
	
}
close FILE;
open FILE, "<ics/$pubfile" or die $!;
while (<FILE>) {
	chomp($_);
	$_ =~ s/\n//;
	if ($_ =~ m/^Permission:(.*)/) {
		$currentperm = $1;
	} elsif ($_ =~ m/^(.*) Callers:/) {
		$allresult{$currentperm}{"ics"} = $1;
	}
	
}
close FILE;

foreach $k (sort keys %allresult) {
	print "$k\t".$allresult{$k}{"froyo"}."\t".$allresult{$k}{"gingerbread"}."\t".$allresult{$k}{"honeycomb"}."\t".$allresult{$k}{"ics"}."\n";
}
