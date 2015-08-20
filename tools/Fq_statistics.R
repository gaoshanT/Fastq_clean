library(ShortRead);
#此程序不设变量默认值
#先定义子程序
getStatistics <- function(fastqfile, letter, qualityCutoff, RdPerYield=5e6)
{
	#所有变量赋初值
	read_number=0;#记录数据中所有的read的总数
	total_ntCount=0;#记录数据中所有碱基的总数
	total_nCount=0;#记录数据中所有碱基"N"的总数
	total_QCount=0;#记录数据中所有qualityCutoff以上的碱基总数
	iteration=0;
	RdPerYield <- as.numeric(RdPerYield);#这个必须要转换，否则报错 
	inFh <- FastqStreamer(fastqfile, n=RdPerYield);
	while (batch_number <- length(reads <- yield(inFh))) { #每次控制读入5百万个reads
		iteration = iteration+1;
		#########################################
		## Trim low quality nucleotides and Ns ##
		#########################################
		read_number=read_number+length(reads);#累计read总数
		total_ntCount=total_ntCount+sum(width(reads));#累计所有碱基的总数
		seqs <- sread(reads); #取出所有记录（read）的sequence信息,数据格式DNAStringSet 		
		nCount<-alphabetFrequency(seqs)[,"N"];# 统计每条read中的字符（A,T,C,G,N）总数,提取"N"总数那一列,只用于输出
		total_nCount=total_nCount+sum(nCount);#累计"N"总数
		
		if(iteration==1)#第一轮要判断分数系统的类型,不需要作为参数输入
		{
			score_sys = data.class(quality(reads));	
			cat("the quality score system (SFastqQuality=Phred+64,FastqQuality=Phred+33) is",score_sys,"\n")
			raw_len <- max(width(reads));# 得到原始数据中reads长度			
		}
		if(score_sys =="SFastqQuality")#如果是Phred+64计分系统
		{
			#cat("the quality score system of fastqfile is Phred+64","\n");
			qual <- SolexaQuality(quality(quality(reads))); #仅仅做格式转换,SFastqQuality格式->BStringSet格式->PhredQuality或SolexaQuality格式,质量分数（字母形式）不变		
			myqual <- charToRaw(as.character(unlist(qual))); #质量分数转为向量格式,并用raw bytes格式表示
			at <- myqual >= charToRaw(as.character(SolexaQuality(as.integer(qualityCutoff)))); 		
		}
		if(score_sys =="FastqQuality")#如果是Phred+33计分系统
		{
			#cat("the quality score system of fastqfile is Phred+33","\n");
			qual <- PhredQuality(quality(quality(reads))); #仅仅做格式转换,SFastqQuality格式->BStringSet格式->PhredQuality或SolexaQuality格式,质量分数（字母形式）不变		
			myqual <- charToRaw(as.character(unlist(qual))); #质量分数转为向量格式,并用raw bytes格式表示
			at <- myqual >= charToRaw(as.character(PhredQuality(as.integer(qualityCutoff)))); 		
		}
		#先把阈值也转换成raw bytes格式,然后将myqual_mat中所有核苷酸的质量分数与阈值比较（小于的为TRUE）,得到相同大小的逻辑矩阵
		rm(qual);
		rm(myqual);
		total_QCount=total_QCount+sum(at);#累计qualityCutoff以上的碱基总数
		
		
	}#End yield while;
	close(inFh);

	lineofresult <- c(fastqfile, read_number, total_ntCount, total_nCount, total_QCount);#收集5列信息
	write(lineofresult,file = "Fq_statistics.report", ncolumns =5,append = T, sep = "\t");#写入全部5列数据
	#删除全部参数
	rm(qualityCutoff);
	print(paste("Finished processing file:", fastqfile));#屏幕输出,该文件处理完毕
}

#读入处理命令行参数
cmd_args = commandArgs(trailingOnly=TRUE);#读取文件名后全部参数
help_doc <- "
Usage: Rscript Fq_statistics.R fastqfile=[String] letter=[String] qualityCutoff=[INT] RdPerYield=[FLOAT]
Options(4):
	fastqfile
	letter
	qualityCutoff		nucleotides with quality score < qualityCutoff will be replaced into N
	RdPerYield		how many reads will be processed at one time to control the memory usage
"; 
for (arg in cmd_args) {
	#cat("  ",arg, "\n", sep="");#调试用
	if ( grepl("^fastqfile=", arg, ignore.case=TRUE, perl = TRUE, fixed = FALSE, useBytes = FALSE) ) {
		fastq_file <- unlist(strsplit(arg, "=", fixed=TRUE))[2];	
	} else if ( grepl("^letter=", arg, ignore.case=TRUE, perl = TRUE, fixed = FALSE, useBytes = FALSE) ) {
		Letter <- unlist(strsplit(arg, "=", fixed=TRUE))[2]; 
	} else if ( grepl("^qualityCutoff=", arg, ignore.case=TRUE, perl = TRUE, fixed = FALSE, useBytes = FALSE) ) {
		quality_Cutoff <- unlist(strsplit(arg, "=", fixed=TRUE))[2];  
	} else if ( grepl("^RdPerYield=", arg, ignore.case=TRUE, perl = TRUE, fixed = FALSE, useBytes = FALSE) ) {
		Read_PerYield <- unlist(strsplit(arg, "=", fixed=TRUE))[2];  
	} 
}

#主程序开始
getStatistics(fastqfile=fastq_file, letter=Letter, qualityCutoff=quality_Cutoff, RdPerYield=Read_PerYield);