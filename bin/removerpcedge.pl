#!/usr/bin/perl

open FILE, "<aidlcallgraphedges" or die $!;

%rpctgts;


while (<FILE>) {
	if ($_ =~ m/^SRC:(.*)TGT:(.*)$/) {
		$rpctgts{$1} = 1;
	}
}
close(FILE);

#foreach (keys %rpctgts) {
#	print $_."\n";
#}

open CALLGRAPH, "<callgraph" or die $!;
while (<CALLGRAPH>) {
	if ($_ =~ m/^.*TGT:(.*)$/) {
		if (! defined $rpctgts{$1}) {
			print $_;
		} else {
		#	print $_;
		}
	}
}


#while (<FILE>) {
#	if ($_ =~ m/^.*TGT:(.*)$/) {
#		$rpctgts{$1} = 1;
#	}
#}
#close(FILE);

#foreach (keys %rpctgts) {
#	print $_."\n";
#}

#open CALLGRAPH, "</home/kathy/dev/svn/data/newct" or die $!;
#while (<CALLGRAPH>) {
#	if ($_ =~ m/^.*TGT:(.*)$/) {
#		if (! defined $rpctgts{$1}) {
#			print $_;
#		}
#	}
#}

