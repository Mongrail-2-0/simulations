# ACCOUNTING FOR MISSING HAPLOTYPES
# assemble all haplotypes (in pop file and sim file) and adjust their counts


NR==FNR{
    uniq[$1]++;
    hap[$1]=$2;
    sum+=$2;
    next
}


{
    if(uniq[$1]==1)
    {
	hap[$1]=hap[$1]+$2
	sum+=$2
    }
}

END{
    for(item in hap)
    {
	printf ("%s\t%f\n",item, hap[item])
    }
    printf("\n")
}
