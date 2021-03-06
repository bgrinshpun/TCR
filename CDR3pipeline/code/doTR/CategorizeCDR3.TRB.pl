###categorizing CDR3 by V J cassette
####not count out_of_frame and * (stop code) CDR3
#!/usr/bin/perl
#use Bio::DB::Bam;
use strict;
use warnings;
#use Gtk2::Unique

open(Fin, './files/doTR/ReadCDR/TRBV.ref.IGMT.motif2.txt');
my @vref;
<Fin>; #remove the header line
while (<Fin>){
	chomp;
	#print "$_\n";
	push @vref, [split('\t', $_)]; # put trav name and 3'-end reference seq in two-dimensional array @ref3end
}
close(Fin);
open (FileNameJref,"./files/doTR/ReadCDR/TRBJ.ref.IGMT.motif2.txt");
my @jref;
<FileNameJref>; #remove the head line  
while (<FileNameJref>){
	chomp;
	push @jref, [split('\t', $_)];
	
}
close(FileNameJref);


my $datadir=$ARGV[0];
my $inFile = $ARGV[1];  #input file is filtered sam file

open (FileName, "$datadir/$inFile");
my %cdr3count;

#open (Fout1, ">$inFile.CDR3Length.txt");
while (<FileName>){
	chomp;
	#print "$_\n";
	my @cdrProt = split('\t', $_);
	if ($cdrProt[11]){
		my $dnaSeq;
		if ($cdrProt[11] =~ /\*/g){
			$cdr3count{"byHasStop.$cdrProt[3]_$cdrProt[4]_$cdrProt[35]_$cdrProt[11]_hasStop"}++;
		
		}
		elsif ($cdrProt[10] =~ /$cdrProt[11]/g){
			my $posS = $cdrProt[13]-1+3*$-[0];
			my $lenSeq = ($+[0]-$-[0])*3;
			$dnaSeq = substr($cdrProt[14], $posS, $lenSeq);
			$cdr3count{"byVDJseq.$cdrProt[3]_$cdrProt[4]_$cdrProt[35]_$dnaSeq\_$cdrProt[11]"}++;
		
			#print "$cdrProt[13]\t$cdrProt[14]\t$cdrProt[10]\t$cdrProt[11]\t$-[0]\t$+[0]\t$dnaSeq\n";
		
		#if($cdrProt[1] eq $cdrProt[2]){
			#print "$cdrProt[0]\t$cdrProt[1]\n";
		#}
		#if($vref[$cdrProt[3]][0] eq $jref[$cdrProt[4]][0]){
		#	print "$cdrProt[0]\t$$#vref[$cdrProt[3]]\n";
		#}
			if ($cdrProt[35] ne "NA"){
				if ($cdrProt[35]=~ m/\/\//g){
					my @dgene = split("//",$cdrProt[35]);
				 	my @d5del = split("//",$cdrProt[38]);	
				 	my @d3del = split("//",$cdrProt[39]);	
				 	$cdr3count{"byVDJseqIndel.$cdrProt[3]_$cdrProt[4]_$dgene[0]_$cdrProt[11]_$cdrProt[17]_$cdrProt[18]_$cdrProt[36]_$cdrProt[37]_$d5del[0]_$d3del[0]"}+=0.5;	
					$cdr3count{"byVDJseqIndel.$cdrProt[3]_$cdrProt[4]_$dgene[1]_$cdrProt[11]_$cdrProt[17]_$cdrProt[18]_$cdrProt[36]_$cdrProt[37]_$d5del[1]_$d3del[1]"}+=0.5;	
				}
			
				else {
					$cdr3count{"byVDJseqIndel.$cdrProt[3]_$cdrProt[4]_$cdrProt[35]_$cdrProt[11]_$cdrProt[17]_$cdrProt[18]_$cdrProt[36]_$cdrProt[37]_$cdrProt[38]_$cdrProt[39]"}++;
				}
			}
			$cdr3count{"byIndelNoDgene.$cdrProt[3]_$cdrProt[4]_$cdrProt[35]_$cdrProt[11]_$dnaSeq\t_$cdrProt[17]_$cdrProt[18]_$cdrProt[19]"}++;
			$cdr3count{"byVJseq.$cdrProt[3]_$cdrProt[4]_$cdrProt[11]"}++;
			$cdr3count{"byCDR3.$cdrProt[11]"}++;
			$cdr3count{"byVJcomb.$cdrProt[3]_$cdrProt[4]"}++;
			$cdr3count{"byVsum.$cdrProt[3]"}++;
			$cdr3count{"byJsum.$cdrProt[4]"}++;
		}
		elsif ($cdrProt[11] eq "Out_of_frame"){
			if ($cdrProt[35] ne "NA"){
				if ($cdrProt[35]=~ m/\/\//g){
					my @dgene = split("//",$cdrProt[35]);
				 	my @d5del = split("//",$cdrProt[38]);	
				 	my @d3del = split("//",$cdrProt[39]);	
				 	$cdr3count{"byVDJseqIndelOOF.$cdrProt[3]_$cdrProt[4]_$dgene[0]_$cdrProt[11]_$cdrProt[17]_$cdrProt[18]_$cdrProt[36]_$cdrProt[37]_$d5del[0]_$d3del[0]"}+=0.5;	
					$cdr3count{"byVDJseqIndelOOF.$cdrProt[3]_$cdrProt[4]_$dgene[1]_$cdrProt[11]_$cdrProt[17]_$cdrProt[18]_$cdrProt[36]_$cdrProt[37]_$d5del[1]_$d3del[1]"}+=0.5;	
				}
			
				else {
					$cdr3count{"byVDJseqIndelOOF.$cdrProt[3]_$cdrProt[4]_$cdrProt[35]_$cdrProt[11]_$cdrProt[17]_$cdrProt[18]_$cdrProt[36]_$cdrProt[37]_$cdrProt[38]_$cdrProt[39]"}++;
				}
			}
			$cdr3count{"byAlloof.$cdrProt[3]_$cdrProt[4]_$cdrProt[11]"}++;
			$cdr3count{"byCDR3oof.$cdrProt[11]"}++;
			$cdr3count{"byVJcomboof.$cdrProt[3]_$cdrProt[4]"}++;
			$cdr3count{"byVsumoof.$cdrProt[3]"}++;
			$cdr3count{"byJsumoof.$cdrProt[4]"}++;
			
		}
		
	}
}


close(FileName);
#close(Fout1);
#open(Fout3, ">$inFile.byVJ.txt");
open(Fout3, ">$datadir/$inFile.byEverything.txt");
######print "\nGRADES IN ASCENDING NUMERIC ORDER:\n";
#foreach $key (sort hashValueAscendingNum (keys(%grades))) {
#   print "\t$grades{$key} \t\t $key\n";
#}

####print "\nGRADES IN DESCENDING NUMERIC ORDER:\n";
foreach my $key (sort hashValueDescendingNum (keys(%cdr3count))) {
  # print Fout3 "$cdr3count{$key}\t$key\n";
  
    my @Keycdr = split('\.',$key);
    my @output = split('_',$Keycdr[1]);
  
   print Fout3 "$cdr3count{$key}\t$Keycdr[0]\t";
	for (my $i=0; $i<=$#output;$i++){
   	print Fout3 "$output[$i]\t";
   }
   print Fout3 "\n";
   
}

sub hashValueDescendingNum {
  $cdr3count{$b} <=> $cdr3count{$a};
}
sub hashValueAscendingNum {
   $cdr3count{$a} <=> $cdr3count{$b};
}

close(Fout3);
