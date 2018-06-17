#!/usr/bin/perl

$callgraphfile = "callgraph";
%methods = ();

open FILE, "<$callgraphfile" or die $!;
while (<FILE>) {
	chomp($_);
	$_ =~ s/\n//;
	if ($_ =~ m/^SRC:(.*)TGT:(.*)/) {
		$methods{$1} = 1;
		$methods{$2} = 1;
	}
}
close FILE;

@keys = keys %methods;
print "Number of methods: ".scalar(@keys)."\n";
