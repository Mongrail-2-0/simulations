# get the haplotypes and the corresponding counts from popA (count format) file

{
    for(j = 2; j <= NF; j++)
    {
	split($j,data,":")
	hap=data[1]
	count=data[2]
	haplotype[hap]=count
	total+=count
    }

}

END{
    for(item in haplotype)
    {
	printf ("%s\t%u\t%u\n",item, haplotype[item], total)
    }

}
