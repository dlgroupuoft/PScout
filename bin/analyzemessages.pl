#!/usr/bin/perl

$foundmsgfile = "message";
$calltablefile = "callgraph";
$classhierarchyfile = "classhierarchy";
$switchresultfile = "handlemessageswitch";

#load class hierarchy
open CLASS, "<$classhierarchyfile" or die $!;
%handlerhasparent = ();
while (<CLASS>) {
	chomp($_);
	if ($_ =~ m/^([^,]*),.*SUPER:([^,]*),.*ISHANDLER/) {
		$handlerhashandlerparent{$1} = $2;
	}
}
close CLASS;

open FILE, "<$switchresultfile" or die $!;
$handlertgts = ();
$currenthandler = "";
$currentcase = "";
while (<FILE>) {
	$_ =~ s/\n//;
	$line = $_;
	if ($line =~ m/^Handler<(.*)>/) {
		$currenthandler = $1;
	} elsif ($line =~ m/^Case (.*)/) {
		$currentcase = $1;
	} elsif ($line =~ m/^Default/) {
		$currentcase = "default";
	} elsif ($line =~ m/^Common/) {
		$currentcase = "common";
	} elsif ($line =~ m/^</) {
		$handlertgts{$currenthandler}{$currentcase}{$line} = 1;
	}
}
close FILE;

open FILE, "<$foundmsgfile" or die $!;
%handlerfield = ();
while (<FILE>) {
	$_ =~ s/\n//;
	if ($_ =~ m/^FIELD/) {
		if ($_ =~ m/^FIELD:(.*)ASSIGNEDVALUE:(.*)INMETHOD:/) {
			$handlerfield{$1} = $2;
		} elsif ($_ =~ m/^FIELD:(.*)ASSIGNEDPARAM:(.*)INMETHOD:/) {
			$handlerfield{$1} = $2;
		}
	} elsif ($_ =~ m/^METHOD/) {
		if ($_ =~ m/^METHOD:(.*)HANDLERNOTFIELD:(.*)WHAT:(.*)$/) {
			print "M:$1H:$2W:$3\n";	
			#print "SRC:$1TGT:<$2: void handleMessage(android.os.Message)>\n";
			$s = $1;
			$h = $2;
			$w = $3;
			$all = 0;
			if ($w =~ m/ /) { $all = 1; }
			while ($h ne "android.os.Handler") {
				if (defined $handlertgts{$h}) {
					if (defined $handlertgts{$h}{"common"}) {
						foreach (keys %{$handlertgts{$h}{"common"}}) {
							print "SRC:$s"."TGT:".$_."\n";
						}
					} elsif ($all == 1) {
						foreach $c(keys %{$handlertgts{$h}}) {
							foreach (keys %{$handlertgts{$h}{$c}}) {
								print "SRC:$s"."TGT:".$_."\n";
							}
						}						
					} elsif (defined $handlertgts{$h}{$w}) {
						foreach (keys %{$handlertgts{$h}{$w}}) {
							print "SRC:$s"."TGT:".$_."\n";
						}
					} else {
						foreach (keys %{$handlertgts{$h}{"default"}}) {
							print "SRC:$s"."TGT:".$_."\n";
						}
					}
					$h = "android.os.Handler";
				} elsif (defined $handlerhasparent{$h}) {
					$h = $handlerhasparent{$h};
				} else {
					$h = "android.os.Handler";
				}
			}
		} elsif ($_ =~ m/^METHOD:(.*)HANDLERFIELD:(.*)WHAT:(.*)$/) {
			$s = $1;
			$h = $2;
			$w = $3;
			$all = 0;
			if ($w =~ m/ /) { $all = 1; }
			#print "M:$m"."H:".$handlerfield{$h}."W:$w\n";	
			if ($handlerfield{$h} =~ / / || ! (exists $handlerfield{$h})) {
				#contain space or empty
				next;
			}
			#print "SRC:$m"."TGT:<".$handlerfield{$h}.": void handleMessage(android.os.Message)>\n";
			$h = $handlerfield{$h};

			while ($h ne "android.os.Handler") {
				if (defined $handlertgts{$h}) {
					if (defined $handlertgts{$h}{"common"}) {
						foreach (keys %{$handlertgts{$h}{"common"}}) {
							print "SRC:$s"."TGT:".$_."\n";
						}
					} elsif ($all == 1) {
						foreach $c(keys %{$handlertgts{$h}}) {
							foreach (keys %{$handlertgts{$h}{$c}}) {
								print "SRC:$s"."TGT:".$_."\n";
							}
						}	
					} elsif (defined $handlertgts{$h}{$w}) {
						foreach (keys %{$handlertgts{$h}{$w}}) {
							print "SRC:$s"."TGT:".$_."\n";
						}
					} else {
						foreach (keys %{$handlertgts{$h}{"default"}}) {
							print "SRC:$s"."TGT:".$_."\n";
						}
					}
					$h = "android.os.Handler";					
				} elsif (defined $handlerhasparent{$h}) {
					$h = $handlerhasparent{$h};
				} else {
					$h = "android.os.Handler";
				}
			}
		}
	}
}
