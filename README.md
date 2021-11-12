# overlap
compare two files with chromosome coordinate

```
	useage: overlap.pl [-e INT -c INT -a INT -b INT -d -C INT -A INT -B INT] file_1 file_2
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
```
