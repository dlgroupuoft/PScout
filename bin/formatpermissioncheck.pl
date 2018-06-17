#!/usr/bin/perl

my $inputfile = "pchk";
my $seedfile = "stringpermissioncheck";
my $sendreceivefile = "sendreceivepermissioncheck";

#Step 1: build seed hash table in memory
open FILE, "<".$inputfile or die $!;

my %seedhashtable;
my @found;
my $permission;
my $method;

while (<FILE>) {
	$_ =~ s/\n//;
	if ($_ =~ /^PER:(.*)TYPE:(.*)METHOD:(.*)/) {
		$permission = $1;
		$type = $2;
		$method = $3; 
		push (@{$seedhashtable{$permission}{$type}}, $method);
	}
}
close(FILE);

#Step 2: write out seedhashtable
open FILE, ">".$seedfile or die $!;

foreach $p (keys %seedhashtable) {
	print FILE "PERMISSION:".$p."\n";
	foreach $t (sort keys %{$seedhashtable{$p}}) {
		if ($t == 3 | $t == 4) {next;}
		print FILE "TYPE:$t\n";
		foreach $m (@{$seedhashtable{$p}{$t}}) {
			print FILE "".$m."\n";
		}
	}
}
close FILE;

#Step 2: write out seedhashtable
open FILE, ">".$sendreceivefile or die $!;

foreach $p (keys %seedhashtable) {
	print FILE "PERMISSION:".$p."\n";
	foreach $t (sort keys %{$seedhashtable{$p}}) {
		if ($t == 1 | $t == 2) {next;}
	#	print FILE "TYPE:$t\n";
		foreach $m (@{$seedhashtable{$p}{$t}}) {
			print FILE "".$m."\n";
		}
	}
}
close FILE;
