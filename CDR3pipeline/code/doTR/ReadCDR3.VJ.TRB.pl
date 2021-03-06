#######Find CDR##############This code is modified from Yaping.Find.CDRseq_SingleEnd_3_2_1.pl
#####filter all CDR seq with stop codon in the CDRseq 
#####in the part of finding best CDR3, using the deep search method (find all possibility) to find the best cdr3. Take longer time than *3_2.
##### this code is for ----vvvvvv-----jjjjjj------ pattern. For human TRB region.  modified from Yaping.ReadCDR3DNA_OutputCDR3prot_1_3.byscore.pl
#####v2:  update to find the indels and mismatchs of TRBV and TRBJ
#####v3:  D gene alignment

#!/usr/bin/perl
#use Bio::DB::Bam;
use strict;
use warnings;
#use Gtk2::Unique


### Auto_120305: 2792192 reads; Auto_..87: 1584373 reads; Auto_..90: 1504752 reads; 
### Auto_120305: Auto_..87 : Auto..90 = 1.86:1.05:1

my %Lcodon_table;
my %Rcodon_table;
my $SegLen =25;
my $line_len = 60;
my $name;
my $seq;

my $TRBD1 = "gggacagggggc";
my $TRBD2 = "gggactagcgggaggg";
           #gggactagcgggaggg
           #     tag
my %codon_table = (
ATT => "I", ATC => "I", ATA => "I", 
CTT => "L", CTC => "L", CTA => "L", CTG => "L", TTA => "L", TTG => "L", 
GTT => "V", GTC => "V", GTA => "V", GTG => "V", 
TTT => "F", TTC => "F", 
ATG => "M", 
TGT => "C", TGC => "C", 
GCT => "A", GCC => "A", GCA => "A", GCG => "A", 
GGT => "G", GGC => "G", GGA => "G", GGG => "G", 
CCT => "P", CCC => "P", CCA => "P", CCG => "P", 
ACT => "T", ACC => "T", ACA => "T", ACG => "T", 
TCT => "S", TCC => "S", TCA => "S", TCG => "S", AGT => "S", AGC => "S", 
TAT => "Y", TAC => "Y", 
TGG => "W", 
CAA => "Q", CAG => "Q", 
AAT => "N", AAC => "N", 
CAT => "H", CAC => "H", 
GAA => "E", GAG => "E", 
GAT => "D", GAC => "D", 
AAA => "K", AAG => "K", 
CGT => "R", CGC => "R", CGA => "R", CGG => "R", AGA => "R", AGG => "R", 
#TAA => "Stop", TAG => "Stop", TGA => "Stop", 
TAA => "*", TAG => "*", TGA => "*", 
);

# part 2, do whatever changes you wish with the data
sub translate {
  my $seq = uc $_[0];
  my $protein;
  for (my $i=0; $i<length($seq); $i+=3) {
    #print STDERR $codon_table{substr($seq, $i, 3)}, "\n";
    $protein .= $codon_table{substr($seq, $i, 3)};
  }
  return $protein;
}

# part 3, format data for output
sub print_name_and_sequence {
  my ($n, $s) = @_;
  print $n, "\n";
  for (my $i=0; $i<length($s); $i+=$line_len) {
    print substr($s, $i, $line_len), "\n";
  }
}

sub print_DNA {
	my $dna =$_[0];
	for (my $i=0;$i<length($dna);$i+=3){
		print Fout substr($dna,$i,3);
		print Fout " ";
	}
	print Fout "\n";
}
sub print_prot{	
	my $prot = $_[0];
	for (my $i=0;$i<length($prot);$i++){
		print Fout " ";
		print Fout substr($prot,$i,1);
		print Fout "  ";
	}
	print Fout "\n";
}
sub gAln_score{
my ($seq0, $seq1) = @_;
#print "$seq0\t$seq1\t";
my @res0 = split(//,$seq0);
my @res1 = split(//,$seq1);

my $match=5;
my $mismatch=-10;
my $gop=-10;
my $gep=-10;
my $gap=-10;
my @smat;
my @tb;
my $sub;
my $del;
my $ins;
my $s;
#evaluate substitutions
my $len0=$#res0+1;
my $len1=$#res1+1;

for (my $i=0; $i<=$len0; $i++){$smat[$i][0]=$i*$gep;$tb[$i][0 ]= 1;}
for (my $j=0; $j<=$len1; $j++){$smat[0][$j]=$j*$gep;$tb[0 ][$j]=-1;}
	
for (my $i=1; $i<=$len0; $i++)
	{
	for (my $j=1; $j<=$len1; $j++)
		{
		#calcul du score
		if ($res0[$i-1] eq $res1[$j-1]){$s=$match;}
		else {$s=$mismatch;}
		
		$sub=$smat[$i-1][$j-1]+$s;
		$del=$smat[$i  ][$j-1]+$gep;
		$ins=$smat[$i-1][$j  ]+$gep;
		
		if   ($sub>$del && $sub>$ins){$smat[$i][$j]=$sub;$tb[$i][$j]=0;}
		elsif($del>$ins){$smat[$i][$j]=$del;$tb[$i][$j]=-1;}
		else {$smat[$i][$j]=$ins;$tb[$i][$j]=1;}
		}
	}

my $i=$len0;
my $j=$len1;
my $aln_len=0;
my $score_out=0;
my @aln0;
my @aln1;
#print "$i\t$j\n";
my $aln_lenex = -1;
	while (!($i==0 && $j==0))
	{
	if ($tb[$i][$j]==0)
		{
		
		$aln0[$aln_len]=$res0[--$i];
		$aln1[$aln_len]=$res1[--$j];
			if ($aln0[$aln_len] eq $aln1[$aln_len]){
				#$score_out+= $match;
				$score_out+=1/($aln_len-$aln_lenex)*$match;
				#print "$aln_lenex\t$aln_len\n";
				$aln_lenex = $aln_len;	
			}
			else{
				$score_out+=$mismatch;
			}
		
		}
	elsif ($tb[$i][$j]==-1)
		{
		$aln0[$aln_len]='-';
		$aln1[$aln_len]=$res1[--$j];
		$score_out+=$gap;
		}
	elsif ($tb[$i][$j]==1)
		{
		$aln0[$aln_len]=$res0[--$i];
		$aln1[$aln_len]='-';
		$score_out+=$gap;
		}
	$aln_len++;
	
	}
#Output en Fasta:
#print "******$score_out\n#######\n";
return ($score_out, $aln_len, @aln0);

}

##########read reference J motif##########
### the last column should not be strings for match, don't know why???
open (FileNameJref,"./files/doTR/ReadCDR/TRBJ.ref.IGMT.motif2.txt");
my @jref;
<FileNameJref>; #remove the head line  
while (<FileNameJref>){
	chomp;
	push @jref, [split('\t', $_)];
	
}
close(FileNameJref);
#print "$#jref\t$jref[1][2]\n";
##########read reference J motif##########


my $datadir=$ARGV[0];
my $inFile = $ARGV[1];  #input file is filtered sam file
open (Fout, ">$datadir/$inFile.prot.txt");
open (FoutTMP, ">$datadir/NO_J_motif.trimmed.CDR3DNAseq.4FindMotif.fasta");
#open (FoutAbn, ">Check.abnormal.txt");
#open (FileName,'test.TCRB.MapAll.txt');
#open (FileName,'atest.fastq.TRA.sort.sam.CDR3.seq');
open (FileName, "$datadir/$inFile");


open(Fin, './files/doTR/ReadCDR/TRBV.ref.IGMT.motif2.txt');
my @ref3end;
while (<Fin>){
	chomp;
	push @ref3end, [split('\t', $_)]; # put trav name and 3'-end reference seq in two-dimensional array @ref3end
}
close(Fin);
#print "$#ref3end\n";

while (<FileName>){
	chomp;
	my @cdrdna = split('\t', $_);  ###$cdrdna[6] to $cdrdna[22] are for indels and mismatches; $cdrdna[3] is the cdr3 DNA sequence
	my $ReadsID_ex = $cdrdna[0];
	
	#print "\t$ReadsID_ex\t$cdrdna[3]\n";
		###################	
		 my $len=length($cdrdna[3]);
		 my $lentmp = length($cdrdna[3])%3;
    	 my $cdrSize = length($cdrdna[3])-length($cdrdna[3])%3-3;
    	 #print "$len\t$lentmp\t$cdrSize\n";  	 
 		 my $cdrSeq1 = substr($cdrdna[3], 0, $cdrSize);
    	 my @protSeq;
    	 my $tmpProt;
    	 my @rankMatch;
    	 #my $vquest = reverseIUPAC($cdrSeq1);
    	
		
    	 ###################### translate and filter sequences with stop codon################
    	 $tmpProt = translate($cdrSeq1);
    	 #print "$tmpProt\n";
        #if ($tmpProt !~ m/\*/ ){
	    	 push (@protSeq,  $tmpProt);
    	 #}
    	 #print "$protSeq[0]\n";
    	  
    	  
    	  my $cdrSeq2 = substr($cdrdna[3], 1, $cdrSize); 
    	  my $tmpProt2 = translate($cdrSeq2);
 		#if ($tmpProt2 !~ m/\*/){
	    	 push (@protSeq,  $tmpProt2);
    	 #}
      
    	  
    	  my $cdrSeq3 = substr($cdrdna[3], 2, $cdrSize);
    	   my $tmpProt3 = translate($cdrSeq3);
    	 #if ($tmpProt3 !~ m/\*/){
	    	 push (@protSeq,  $tmpProt3);
    	 #}
    	 ##################### ###################
    	#print "***************\n";
 		print Fout "$ReadsID_ex\t$cdrdna[2]\t$tmpProt//$tmpProt2//$tmpProt3\t";
 		my @comb = split('\.',$cdrdna[2]);
		my $refseq;
		my $indx=0;
		my $galn_len;
		my @galn0;
		my $galn_lenFinal;
		my @galn0Final;
		my $score;
		my $score2;
		my $score3;
		#print "$comb[0]\n";
		while ($comb[0] ne $ref3end[$indx][0] && $indx<$#ref3end){
			$indx++;
		}
		my $indx4j = 0;
		while ($comb[$#comb] ne $jref[$indx4j][0] && $indx4j<$#jref){
			$indx4j++;
		}
		$refseq = substr($ref3end[$indx][1],length($ref3end[$indx][1])-12,12);
		print Fout "$ref3end[$indx][0]\t$comb[$#comb]\t$refseq\t";
		if ($refseq ne "----"){
			($score, $galn_lenFinal, @galn0Final) = gAln_score($refseq, $tmpProt);
			my $finalcdr = $tmpProt;
			print Fout "$score\t";
		    my $score1 = $score;
		    
			($score2, $galn_len, @galn0) = gAln_score($refseq, $tmpProt2);
			if ($score < $score2 ){
				$score = $score2;
				$finalcdr = $tmpProt2;
				$galn_lenFinal = $galn_len;
				@galn0Final = @galn0;
			}
			print Fout "$score2\t";
			($score3, $galn_len, @galn0) = gAln_score($refseq, $tmpProt3);
			if ($score < $score3 ){
				$score = $score3;
				$finalcdr = $tmpProt3;
				$galn_lenFinal = $galn_len;
				@galn0Final = @galn0;
			}
			print Fout "$score3\t";
		
			#print "#########\n";
			print Fout "$score\t$finalcdr\t";
			my $starti;
			for ($starti=0; $starti<=$galn_lenFinal-1; $starti++){
				if ($galn0Final[$starti] eq $ref3end[$indx][2]){
 				last;
 				}
			}
			$starti = $galn_lenFinal-$starti;
			my $jseq = substr($finalcdr, $starti, length($finalcdr)-$starti);
			if ($jseq =~ m/$jref[$indx4j][2]/){
			#if ($jseq =~ m/FG.G/ || $jseq =~ m/LG.G/){
				my $pos = $-[0];
				#print "$pos###\n";
				my $cdr3out = substr($finalcdr, $starti, $pos);
				print Fout "$cdr3out\t";
			}
			else {
				
				print FoutTMP ">$cdrdna[0]\t$cdrdna[1]\t$cdrdna[2]\n$cdrdna[3]\n";
				print Fout "Out_of_frame\t";
			}	
			
			print Fout "$jref[$indx4j][1]\t";
			#print Fout "$cdrdna[3]\t";
			if ($score == $score1){
				print Fout "1\t";
			}
			elsif ($score == $score2){
				print Fout "2\t";
			}
			elsif($score ==  $score3){
				print Fout "3\t";
			}		
			my $tmpCDRs = $cdrdna[5]-$cdrdna[4]+2;
			my $tmpCDRe = $cdrdna[6]-$cdrdna[4];
			my $outs;
			$outs.= substr($cdrdna[3],0,$tmpCDRs-1);
			$outs.= lc substr($cdrdna[3],$tmpCDRs-1,$cdrdna[10]);
			$outs.= substr($cdrdna[3],$tmpCDRe,length($cdrdna[3])-$tmpCDRe);
#######################################D gene alignment###################
		
			my $cdr4Dalign = lc substr($cdrdna[3],$tmpCDRs-1,$cdrdna[10]);
			my $returnD1align =  alignDgene($TRBD1, $cdr4Dalign);
			my @d1a = split('_', $returnD1align);
			my $returnD2align =  alignDgene($TRBD2, $cdr4Dalign);
			my @d2a = split('_', $returnD2align);
			my $finalDalign;
			if ($d1a[0] eq "unresolved" && $d2a[0] ne "unresolved"){
				$finalDalign =  "$returnD2align\_D2";
			}
			elsif ($d1a[0] ne "unresolved" && $d2a[0] eq "unresolved"){
				$finalDalign =  "$returnD1align\_D1";
			}
			elsif ($d1a[0] ne "unresolved" && $d2a[0] ne "unresolved"){
				if (length($d1a[0])>length($d2a[0])){
					$finalDalign =  "$returnD1align\_D1";
				}
				elsif (length($d1a[0])<length($d2a[0])){
					$finalDalign =  "$returnD2align\_D2";
				}
				#if (length($d1a[0]) == length($d2a[0])){
				else{
					if ($returnD1align eq $returnD2align){
						$finalDalign = "$returnD1align\_D1orD2";
					}
					else {
						#my $x=length($cdr4Dalign)-$d1a[2];
						#my $y=$d1a[2]-1;
						#print "$x\t$y\t";
						my $mlen = length($d1a[0]);
						my $score1=(length($cdr4Dalign)-$d1a[2])*(length($cdr4Dalign)-$d1a[2])+($d1a[2]-$mlen)*($d1a[2]-$mlen);
						my $score2=(length($cdr4Dalign)-$d2a[2])*(length($cdr4Dalign)-$d2a[2])+($d2a[2]-$mlen)*($d2a[2]-$mlen);
						#print "$returnD1align^^^^^$score1\t$returnD2align^^^^^$score2\n";
						if ($score1<$score2){
							$finalDalign =  "$returnD1align\_D1";
						}
						elsif ($score1>$score2){
							$finalDalign =  "$returnD2align\_D2";	
						}
						else{
							$finalDalign = "$returnD1align\_D1\_$returnD2align\_D2";
						}
					}
				}
			}
			else{
				$finalDalign =  $returnD1align;
			}
	###################
			my @tmpVDJ = split("_", $finalDalign);
			my $Dgenename; 
			my $VDins;
			my $DJins;
			my $d5del;
			my $d3del;
			if ($tmpVDJ[0] ne "unresovled" && $#tmpVDJ==3){
				if ($tmpVDJ[3] eq "D1"){
					$Dgenename = "TRBD1";
					$VDins = $tmpVDJ[2]-length($tmpVDJ[0]);
					$DJins = length($cdr4Dalign)-$tmpVDJ[2];
					$d5del = $tmpVDJ[1]-length($tmpVDJ[0]); 
					$d3del = length($TRBD1)-$tmpVDJ[1];
				}
				else {
					$Dgenename = "TRBD2";
					$VDins = $tmpVDJ[2]-length($tmpVDJ[0]);
					$DJins = length($cdr4Dalign)-$tmpVDJ[2];
					$d5del = $tmpVDJ[1]-length($tmpVDJ[0]); 
					$d3del = length($TRBD2)-$tmpVDJ[1];
				}
				
			}
			elsif ($tmpVDJ[0] eq "unresolved") {
				$Dgenename = "NA";
				$VDins = "NA";
				$DJins = "NA";
				$d5del = "NA"; 
				$d3del = "NA";
				
			}
			else{
				$Dgenename = "TRBD1//TRBD2";
				$VDins = $tmpVDJ[2]-length($tmpVDJ[0]);
				$DJins = length($cdr4Dalign)-$tmpVDJ[2];
				$d5del = $tmpVDJ[1]-length($tmpVDJ[0]);  #gc_12_2_D1*gc_9_2_D2
				$d3del = length($TRBD1)-$tmpVDJ[1];
				my $tmpdel = $tmpVDJ[5]-length($tmpVDJ[0]);
				$d5del .= "//$tmpdel";
				$tmpdel = length($TRBD2)-$tmpVDJ[5];
				$d3del .= "//$tmpdel";
			}
			#print "$cdrdna[0]\t$cdr4Dalign\t$returnD1align\t";
			#print "$returnD2align\t$finalDalign\n";
			#print "$cdrdna[0]\t$cdr4Dalign\t$finalDalign\t$Dgenename\t$VDins\t$DJins\t$d5del\t$d3del\n";
			
	#######################################################################		
			print Fout "$outs\t$tmpCDRs\t$tmpCDRe\t";
			for (my $k=8;$k<=23;$k++){
				print Fout "$cdrdna[$k]\t";
			}
			print Fout "$cdr4Dalign\t$finalDalign\t$Dgenename\t$VDins\t$DJins\t$d5del\t$d3del\n";
			print Fout "\n";
			
	
		}
		else {
			print Fout "NO_score\n";
		}
}

close(Fout);
close(FileName);	
#close(FoutAbn);
close(FoutTMP);


####################################################subroutines##########################
			
sub reverseIUPAC {
        my $dna = shift;

	# reverse the DNA sequence
        my $revcomp = reverse($dna);

	# complement the reversed DNA sequence
        $revcomp =~ tr/NABCDGHMNRSTUVWXYabcdghmnrstuvwxy/NTVGHCDKNYSAABWXRtvghcdknysaabwxr/;
        return $revcomp;
}
sub plasmidArray {

	my $bwaCigar = $_;
	

}
sub alignDgene{

my @ad1 = split('', $_[0]);
my @aseq = split('', $_[1]);

my @seqArray;
my @mposD; ##D gene match position
my @mposR; ##Read match position
my $mSeq = "";
my $mSeq_ex = "";
my $upperL;

if ($#ad1>=$#aseq){
	$upperL=$#aseq;
}
else {
	$upperL=$#ad1;
}
#$ct_ex=0;
for (my $i=0; $i<$#ad1+$#aseq+1;$i++){
	my $indx=0;
	my $ct=0;
	my $ct_ex;
	if ($#aseq-$i>=0){
		$ct_ex = $#aseq-$i;
		my $j;
		for ($j=$#aseq-$i;$j<=$#aseq && $indx<=$upperL;$j++){
			#print "$j*$indx**\n";
			$ct = $j;
			if($aseq[$j] eq $ad1[$indx]){
				#print "*$aseq[$j]\t";
				$mSeq.=$aseq[$j];
				$ct_ex = $j;
			}
			else {
				if ($j-$ct_ex == 1 && length($mSeq)>=length($seqArray[$#seqArray])){
					push(@seqArray, $mSeq);
					push(@mposD, $indx);
					push(@mposR, $j);
					
				}
				$ct=0;
				$mSeq="";
				#print "\t";
			}
			
			$indx++;
		}
		if (length($mSeq)>=length($seqArray[$#seqArray])){
			push(@seqArray, $mSeq);
			push(@mposD, $indx);
			push(@mposR, $j);	
		}
		$ct=0;
		$mSeq="";	
	}
	else{
	
		my $j;
		$ct_ex = abs($#aseq-$i);
		my $tmpL =  $upperL-abs($#aseq-$i);
		for ($j=abs($#aseq-$i);$j<=$#aseq && $indx<=$tmpL;$j++){
			
			#print "$tmpL\t$i*$j*$indx";
			if($aseq[$indx] eq $ad1[$j]){
				#print "#$aseq[$indx]";
				$mSeq.=$aseq[$indx];
				$ct_ex = $j;
			}
			else {
				#print "\t";
				if ($j-$ct_ex == 1 && length($mSeq)>=length($seqArray[$#seqArray])){
					push(@seqArray, $mSeq);
					push(@mposD, $j);
					push(@mposR, $indx);
				}
				$ct=0;
				$mSeq="";	
			}
			$indx++;
		}
		if (length($mSeq)>=length($seqArray[$#seqArray])){
			push(@seqArray, $mSeq);
			push(@mposD, $j);
			push(@mposR, $indx);	
		}
		$ct=0;
		$mSeq="";	
	}
	#print "\n";
}
my $output;
if ($seqArray[$#seqArray]){
	$output = "$seqArray[$#seqArray]_$mposD[$#seqArray]_$mposR[$#seqArray]";
}
else {
	$output = "unresolved_0_0";
}
return $output;
}

