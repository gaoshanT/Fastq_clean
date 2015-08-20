rm(list=ls());#清空内存，重新开始计算
sub_routines<-paste(getwd(),"/bin/RNA-seq_clean.R",sep = "");
source(sub_routines);#特别注意每次查看是否是对应分数系统
library(ShortRead);
#变量默认值
quality_Cutoff=20;
region_5Len= 10;
region_3Len= 20;
n_Cutoff=2;
adapter_mismatch=0.1;#100bp以内0.1最合适
read_Length=25; 
Read_PerYield=5e5;#5Mreads*4*100=2G字节

#读入处理命令行参数
cmd_args = commandArgs(trailingOnly=TRUE);#读取文件名后全部参数
help_doc <- "
Usage: Rscript RNA-seq_clean_batch.R filelist=<FILE> pattern=<FILE> qualityCutoff=[INT] region5Len=[INT] region3Len=[INT] nCutoff=[INT] adapterMismatch=[FLOAT] readLength=[INT] RdPerYield=[FLOAT]
Required(2):
	filelist		The name of a txt file containing a list of input file names without any suffix
	pattern			The name of a txt file containing a list of pattern in the adapters
Options(7):
	qualityCutoff		nucleotides with quality score < qualityCutoff will be replaced into N
	region5Len		in the first region5Len bp of reads from the 5' end, the N containing segment will be trimmed 
	region3Len		in the last region3Len bp of reads from the 3' end, the N containing segment will be trimmed
	nCutoff			reads with N number >= nCutoff after 5' and 3' end cleaned will be removed
	adapterMismatch 	the 3' end sequence matching adapter/PCR primer with this ratio should be trimmed
	readLength		reads with length < readLength after trimming will be removed
	RdPerYield		how many reads will be processed at one time to control the memory usage
"; 
for (arg in cmd_args) {
	#cat("  ",arg, "\n", sep="");#调试用
	if ( grepl("^h(elp)?$", arg, ignore.case=TRUE, perl = TRUE, fixed = FALSE, useBytes = FALSE) ) {
		cat(help_doc); 
		stop("Stop for help.\n"); 
	} else if ( grepl("^filelist=", arg, ignore.case=TRUE, perl = TRUE, fixed = FALSE, useBytes = FALSE) ) {
		file_list <- unlist(strsplit(arg, "=", fixed=TRUE))[2]; 
	} else if ( grepl("^pattern=", arg, ignore.case=TRUE, perl = TRUE, fixed = FALSE, useBytes = FALSE) ) {
		pattern_file <- unlist(strsplit(arg, "=", fixed=TRUE))[2];  
	} else if ( grepl("^qualityCutoff=", arg, ignore.case=TRUE, perl = TRUE, fixed = FALSE, useBytes = FALSE) ) {
		quality_Cutoff <- as.numeric(unlist(strsplit(arg, "=", fixed=TRUE))[2]);  #arg默认是character类型
	} else if ( grepl("^region5Len=", arg, ignore.case=TRUE, perl = TRUE, fixed = FALSE, useBytes = FALSE) ) {
		region_5Len <- as.numeric(unlist(strsplit(arg, "=", fixed=TRUE))[2]);  #arg默认是character类型  
	} else if ( grepl("^region3Len=", arg, ignore.case=TRUE, perl = TRUE, fixed = FALSE, useBytes = FALSE) ) {
		region_3Len <- as.numeric(unlist(strsplit(arg, "=", fixed=TRUE))[2]);  #arg默认是character类型  
	} else if ( grepl("^nCutoff=", arg, ignore.case=TRUE, perl = TRUE, fixed = FALSE, useBytes = FALSE) ) {
		n_Cutoff <- as.numeric(unlist(strsplit(arg, "=", fixed=TRUE))[2]);  #arg默认是character类型  
	} else if ( grepl("^adapterMismatch=", arg, ignore.case=TRUE, perl = TRUE, fixed = FALSE, useBytes = FALSE) ) {
		adapter_mismatch <- as.numeric(unlist(strsplit(arg, "=", fixed=TRUE))[2]);  #arg默认是character类型  
	} else if ( grepl("^readLength=", arg, ignore.case=TRUE, perl = TRUE, fixed = FALSE, useBytes = FALSE) ) {
		read_Length <- as.numeric(unlist(strsplit(arg, "=", fixed=TRUE))[2]);  #arg默认是character类型 
	} else if ( grepl("^RdPerYield=", arg, ignore.case=TRUE, perl = TRUE, fixed = FALSE, useBytes = FALSE) ) {
		Read_PerYield <- as.numeric(unlist(strsplit(arg, "=", fixed=TRUE))[2]);  #arg默认是character类型  
	}
}

#主程序开始
fastqfiles <- read.table(file_list);#读入所有的输入文件名称
inputfiles <- as.matrix(fastqfiles)[,1];#第1列是文件名
inputfiles <- paste(inputfiles,".fastq",sep="");#添加fastq后缀
#outputfiles <- paste(inputfiles,".trimmed",sep="");#定义所有的输出文件名称，输入文件名无后缀
outputfiles <- gsub(pattern=".fastq", replacement=".trimmed", inputfiles);#定义所有的输出文件名称，输入文件名有后缀".fastq"
PCR2rcprimer <- as.matrix(fastqfiles)[,2];#第2列是对应的primer sequence, 注意不是反向互补序列
title <- c("file","N_number_in_raw_data","Raw_reads","Raw_len","High_quality_reads","Trimmed_reads","Trimmed_len");
write(title,file = "trimmed.report", ncolumns =7,append = T, sep = "\t");
for(i in 1:length(inputfiles))
{
 trimRead(fastqfile=inputfiles[i], outfile=outputfiles[i], qualityCutoff=quality_Cutoff, region5Len= region_5Len, region3Len= region_3Len, nCutoff=n_Cutoff, adapterMismatch=adapter_mismatch, readLength=read_Length, PCR2rc=PCR2rcprimer[i], RdPerYield=Read_PerYield);
 #system(paste("rm", inputfiles[i]));#数据trimmed后，删除原始数据文件（*.fastq），也可以最后一起手工删除
}

#fastqfiles <- read.table(file_list);#读入所有的输入文件名称,分开运行时才用
inputfiles <- as.matrix(fastqfiles)[,1];#第1列是文件名
inputfiles <- paste(inputfiles,".trimmed",sep="");#添加fastq后缀
#inputfiles <- gsub(pattern=".fastq", replacement=".trimmed", inputfiles);#后缀名称需要改一下
outputfiles <- gsub(pattern=".trimmed", replacement=".clean", inputfiles);#定义所有的输出文件名称，输入文件名有后缀".trimmed"
title <- c("File_clean","Cleaned_reads","Cleaned_len");
write(title,file = "clean.report", ncolumns =3,append = T, sep = "\t");
patterns <- read.table(pattern_file);#可以直接传data.frame形式参数给函数，不必转换
for(i in 1:length(inputfiles))#所有的fastq文件逐个用模板filtering
{
 removePatterns(fastqfile=inputfiles[i], outfile=outputfiles[i], patterns, RdPerYield=Read_PerYield);
 system(paste("rm", inputfiles[i]));#数据cleaned后，删除原始数据文件（*.trimmed），也可以最后一起手工删除
}