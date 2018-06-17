#!/usr/bin/perl

open FILE, "<classhierarchy" or die $!;
while (<FILE>) {
	chomp($_);
	if ($_ =~ m/([^,]*),.*ISINTERFACE/) {
		print $1."\n";
	}
}
close FILE;



