#!/usr/bin/perl
use strict;
use diagnostics;
use Getopt::Std;

my %opts;
getopts('sjJzZxXhHe:c:a:b:dE:C:A:B:',\%opts);
die("
useage:$0 [-e INT -c INT -a INT -b INT -d -C INT -A INT -B INT] file_1 file_2
        -s      sort the comparing files by chromosome and start point using systerm sort
        -j      file_1 is archived by bzip2
        -J      file_2 is archived by bzip2
        -z      file_1 is archived by gzip
        -Z      file_2 is archived by gzip
        -x      file_1 is in bcf format
        -X      file_2 is in bcf format
        -H      ingnor those header lines start by '#' in file_1 and file_2
        -e INT  expanding length from each side of a sv [0]
        -c INT  the column of the chromosome in the file [1]
        -a INT  the column of the start point of sv in the file [2]
        -b INT  the column of the end point of sv in the file [3]
        -d      the format of the input files are different
        -E INT  expanding length from each side of a sv in the second file[-e]
        -C INT  the column of the chromosome in the second file
        -A INT  the column of the start point of sv in the second file
        -B INT  the column of the end point of sv in the second file
        -h      print this help
\n") if @ARGV<2;

my $expand=$opts{e}?$opts{e}:0;
my $chr=$opts{c}?$opts{c}-1:0;
my $start=$opts{a}?$opts{a}-1:1;
my $end=$opts{b}?$opts{b}-1:2;
my ($expand_2,$chr_2,$start_2,$end_2)=($expand,$chr,$start,$end);
if($opts{d})
{
	$expand_2=$opts{E} if defined $opts{E};
	$chr_2=$opts{C}-1 if $opts{C};
	$start_2=$opts{A}-1 if $opts{A};
	$end_2=$opts{B}-1 if $opts{B};
}

if($opts{s})
{
    die("
    Those options -j/-z/-x, -J/-Z/-X can not combine with -s options!!\n")
    if $opts{j} || $opts{z} ||$opts{x} ||$opts{J} ||$opts{Z} ||$opts{X};

    my ($chr_shell,$start_shell)=($chr+1,$start+1);
    system "sort -k$chr_shell,$chr_shell -k$start_shell,${start_shell}n $ARGV[0] > $ARGV[0].sortttttttt";
    open FILE,"$ARGV[0].sortttttttt";
    my ($chr_2_shell,$start_2_shell)=($chr_2+1,$start_2+1);
    system "sort -k$chr_2_shell,$chr_2_shell -k$start_2_shell,${start_2_shell}n $ARGV[1] > $ARGV[1].sorttttttttt";
    open FILE_2,"$ARGV[1].sorttttttttt";
}
else{
    if($opts{j}){
        open FILE,"bzcat $ARGV[0] |";
    }
    elsif($opts{z}){
        open FILE,"zcat $ARGV[0] |";
    }
    elsif($opts{x}){
        open FILE,"bcftools view $ARGV[0] |";
    }
    else
    {
        open FILE,"$ARGV[0]";
    }

    if($opts{J}){
        open FILE_2,"bzcat $ARGV[1] |";
    }
    elsif($opts{Z}){
        open FILE_2,"zcat $ARGV[1] |";
    }
    elsif($opts{X}){
        open FILE_2,"bcftools view $ARGV[1] |";
    }
    else
    {
        open FILE_2,"$ARGV[1]";
    }
}

my (@line,@lines_2);
if($opts{H}){
    while(<FILE>){
        if(!/^#/){
            @line=split;
            last;
        }
    }
    while(<FILE_2>){
        if(!/^#/){
            @lines_2=([split/\s+/,$_],);
            last;
        }
    }
}
else{
    @line=split/\s+/,<FILE>;
    @lines_2=([split/\s+/,<FILE_2>],);
}

my (@non_a,@non_b,@line_2);
for(@line)
{
    push @non_a,'-';
}
for(@{$lines_2[0]})
{
    push @non_b,'-';
}

sub print_a
{
    print join("\t",@{$_[0]},@non_b,'A'),"\n";
}
sub print_b
{
    if(@{$_[0]} == @non_b)
    {
        print join("\t",@non_a,@{$_[0]},'B'),"\n";
    }
} 
while(1)
{
    if(!@lines_2)
    {
         @lines_2=([split/\s+/,<FILE_2>],);
    }
    if(@{$lines_2[0]} && @line)
    {
        if($line[$chr] gt ${$lines_2[0]}[$chr_2])
        {
            print_b($lines_2[0]);
            shift @lines_2;
            redo;
        }
        elsif($line[$chr] lt ${$lines_2[0]}[$chr_2])
        {
            print_a(\@line);
            @line=split/\s+/,<FILE>;
            redo;
        }
        else
        {
            if($line[$start]-$expand>${$lines_2[0]}[$end_2]+$expand_2)
            {
                print_b($lines_2[0]);
                shift @lines_2;
                redo;
            }
            elsif($line[$end]+$expand<${$lines_2[0]}[$start_2]-$expand_2)
            {
                print_a(\@line);
                @line=split/\s+/,<FILE>;
                redo;
            }
            else
            {
                until(${$lines_2[-1]}[$chr_2] gt $line[$chr] || ${$lines_2[-1]}[$start_2]-$expand_2 > $line[$end]+$expand)
                {
                    if($_=<FILE_2>)
                    {
                        push @lines_2,[split/\s+/,$_];
                    }
                    else
                    {
                         last;
                    }
                }
                redo if !@{$lines_2[-1]};
                for(@lines_2)
                {
                    if($$_[$chr_2] eq $line[$chr] && !($$_[$start_2]-$expand_2 > $line[$end]+$expand || $$_[$end_2]+$expand_2 < $line[$start]-$expand))
                    {
                        print join("\t",@line,@$_[0..$#non_b],'Z'),"\n";
                        push @$_,'Z' if @$_ < @non_b+1;
                    }
                }
                @line=split/\s+/,<FILE>;
                redo;
             }
          }  
    }
    elsif(!@{$lines_2[0]} && !@line)
    {
        last;
    }
    elsif(!@{$lines_2[0]})
    {
        until(!@line)
        {
            print_a(\@line);
            @line=split/\s+/,<FILE>;
        } 
        last;
    }
    elsif(!@line)
    {
        for(@lines_2)
        {
            print_b($_);
        }
        while(<FILE_2>)
        {
            my @line_2=split;
            print_b(\@line_2);
        }
        last;
    }
}
                
close FILE;
close FILE_2;

if($opts{s})
{
    system "rm $ARGV[0].sortttttttt $ARGV[1].sorttttttttt";
}
              
      
