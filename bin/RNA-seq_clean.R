#这一版简化了质量分数计算，并且统一输出为Phred+33
trimRead <- function(fastqfile, outfile, qualityCutoff, region5Len, region3Len, nCutoff, adapterMismatch, readLength, PCR2rc, RdPerYield)
{
	trimmedFile <- gsub(pattern=".fastq", replacement=".trimmed3End", fastqfile);
	#不要后缀的文件名，注意变量名字不能是sample	
	sampleName<-unlist(strsplit(fastqfile,'\\.|_'))[1];
	sampleDirection<-unlist(strsplit(fastqfile,'\\.|_'))[2];
	inFh <- FastqStreamer(fastqfile, n=RdPerYield); 
	if (file.exists(outfile) ) {file.remove(outfile); } #如果输出文件已经存在必须删除，防止追加写
	total_nCount=0;
	raw_reads=0;
	raw_len=0;
	highQua_reads=0;
	trimmed_reads=0;
	trimmed_len=0;
	iteration=0;
	first_number=0;#给fastq文件中所有read的id上面加一个[编号]，从0开始计数
	while (batch_number <- length(reads <- yield(inFh))) { #每次控制读入5百万个reads
		iteration = iteration+1;
		#########################################
		## Trim low quality nucleotides and Ns ##
		#########################################
		seqs <- sread(reads); # 取出所有记录（read）的sequence信息,数据格式DNAStringSet
		nCount<-alphabetFrequency(seqs)[,"N"];# 统计每条read中的字符（A,T,C,G,N）总数,提取"N"总数那一列,只用于输出
		total_nCount=total_nCount+sum(nCount);
		raw_reads=raw_reads+ length(reads);
		rm(nCount);		
		if(iteration==1)#第一轮要自动判断分数系统的类型
		{
			score_sys = data.class(quality(reads));#如果出现字符";"（59）就是FastqQuality，否则就是SFastqQuality
			cat("the quality score system (SFastqQuality=Phred+64,FastqQuality=Phred+33) is",score_sys,"\n");
			raw_len <- max(width(reads));# 得到原始数据中reads长度			
		}
		qual <- quality(quality(reads));#仅仅做格式转换,SFastqQuality或FastqQuality格式->BStringSet格式，qual还是字符表示形式
		myqual_16L <- charToRaw(as.character(unlist(qual)));#质量分数转为16进制表示，是一个很长的向量
		if(score_sys =="FastqQuality")#如果是Phred+33计分系统
		{
			myqual_10L <- strtoi(myqual_16L,16L)-33;#质量分数转为10进制表示				
		}
		if(score_sys =="SFastqQuality")#如果是Phred+64计分系统，需要转为Phred+33计分系统
		{
			myqual_10L <- strtoi(myqual_16L,16L)-64;#质量分数转为10进制表示		
			qual_temp <- PhredQuality (as.integer(myqual_10L));#质量分数转为Phred+33字符表示，一个大向量
			qual <- BStringSet(unlist(qual_temp), start= seq(from = 1, to = raw_len*(length(reads)-1)+1, by = raw_len), width=raw_len);
			rm(qual_temp);		
		}		
		
		last_number <- first_number + batch_number - 1;   #本批数据最后一个read的编号
		#reads的id都要统一格式为sample_R1-number，为了下一步提取成对的reads使用，quality也统一为Phred+33计分系统
		reads <- ShortReadQ(sread=seqs, quality=qual, id= BStringSet(paste0(sampleName, "-", first_number:last_number, "/",sampleDirection) ) );
		first_number <- last_number + 1;  #下批数据第一个read的编号，上一句使用后必须更新
		myqual_mat <- matrix(myqual_10L, nrow=length(qual), byrow=TRUE); #质量分数转为矩阵格式,为了产生at矩阵
		at <- myqual_mat < qualityCutoff;
		rm(myqual_16L);
		rm(myqual_10L);
		rm(qual);
		rm(myqual_mat);

		#下面3行将序列中所有质量低于阈值的核苷酸替换为"N",得到替换后的数据injectedseqs
		letter_subject <- DNAString(paste(rep.int("N", raw_len), collapse=""));
		#得到一个DNAString"对象,只包括一个"N"组成的向量,长度为读长的长度
		letter <- as(Views(letter_subject, start=1, end=rowSums(at)), "DNAStringSet");
		#每行都对应一个N组成的向量,长度等于低质量（小于阈值的）核苷酸的数量
		injectedseqs <- replaceLetterAt(seqs, at, letter);#injectedseqs是所有低质量核苷酸都被"N"替换后得到的所有read的序列
		#seqs中每行数据与at中每行数据对应,at中某个位置为TRUE的,seqs中对应位置的核苷酸替换为letter中的核苷酸"N"
		#特别注意这里的TRUE,表示该位点的质量分数小于前面的qualityCutoff
		rm(at);
		rm(letter_subject);
		rm(letter);
		#gc();

		#从替换过的序列injectedseqs中确定高质量区域的起始和结束位点
		last5endN <- which.isMatchingAt("N", injectedseqs, at=region5Len:1, follow.index=TRUE);#从region5Len开始向5’端找第一个"N"
		last5endN[is.na(last5endN)]=0;#没有"N"的序列会返回NA
		starts <- last5endN+1;
		first3endN <- which.isMatchingAt("N", injectedseqs, at=(raw_len-region3Len+1):raw_len, follow.index=TRUE);
		first3endN[is.na(first3endN)]=raw_len+1;
		ends <- first3endN-1;
		rm(last5endN);
		rm(first3endN);
		rm(injectedseqs);
		
		#注意从原始read中去掉去掉5'和3'端的N
		highQuaReads <- narrow(reads, start=starts, end=ends);#去掉去掉5'和3'端的N,得到start和end之间的部分（原始的）,即中间部分
		highSeqs <- narrow(seqs, start=starts, end=ends);
		rm(reads);
		rm(seqs);
		rm(starts);
		rm(ends);
		
		#根据每条highQuaReads中含N情况，决定留下谁去除谁
		nCount <- alphabetFrequency(highSeqs)[,"N"];#统计中间部分含有的"N",得到一个向量,对应每个read中含有的"N"的数量
		#根据中间部位"N"在所有reads中的分布,设定阈值,去除中间含有"N"过多的reads,并将剩下的reads两端的"N"去掉
		middleN <- nCount < nCutoff; #每个read根据他的nCount是否小于nCutoff来决定这条read是否保留	
		highQuaReads <- highQuaReads[middleN]; #去掉低质量reads，只保留符合上面条件的高质量reads
		highQua_reads=highQua_reads+length(highQuaReads);#累计高质量reads的总数	
		rm(highSeqs);		
		rm(nCount);
		rm(middleN);	
		
		##################################
		##    trim 3' PCR2rc/adapter    ##
		##################################
		
		#去掉reads中含有的部分或整体PCR2rc/adapter
		max.mismatchs <- adapterMismatch*1:nchar(DNAString(PCR2rc));#特别要注意一定是PCR2的反向互补序列
		trimmedCoords <- trimLRPatterns(Rpattern = PCR2rc, subject = sread(highQuaReads), max.Rmismatch= max.mismatchs, with.Rindels=T,ranges=T);#这里得到坐标
		
		#先提取并保存剩下的3'端序列,仅供测试和检查使用
		#trimmed3End <- narrow(highQuaReads, start=end(trimmedCoords)+1, end=width(highQuaReads))#把trimm掉的那部分序列保留，以备人工检查
		#trimmed3End <- trimmed3End[!width(trimmed3End)==0]#去掉空数据		
		#writeFastq(trimmed3End, file=trimmedFile, mode="a", full=FALSE);
		#rm(trimmed3End)
				
		#再提取并保存trim掉3'端剩下的序列
		trimmedReads <- narrow(highQuaReads, start=start(trimmedCoords), end=end(trimmedCoords));#利用上一步得到的坐标，同时trim核苷酸序列和质量分数序列
		rm(highQuaReads);
		rm(trimmedCoords);
		
		#去掉长度不足一定长度的reads,这里保存的reads对应结果表格中的Trimmed_reads和Trimmed_length
		trimmedReads <- trimmedReads[width(trimmedReads)>=readLength];#去掉PCR2rc/adapter的reads有的过短，不再保留	
		trimmed_reads=trimmed_reads+length(trimmedReads);#累计trimmed reads的总数
		trimmed_len=trimmed_len+sum(width(trimmedReads));#累计trimmed reads的总长度	
		writeFastq(trimmedReads, file=outfile, mode="a", compress = FALSE, full=FALSE);		
		rm(trimmedReads);
		#gc();
		
	}#End yield while;
	close(inFh);
	trimmed_len=trimmed_len/trimmed_reads;#得到trimmed reads的平均长度
	lineofresult <- c(outfile, total_nCount, raw_reads, raw_len, highQua_reads, trimmed_reads, trimmed_len);#收集4列信息,样本文件名称、原始数据中"N"总数、reads长度和reads总数
	write(lineofresult,file = "trimmed.report", ncolumns =7,append = T, sep = "\t");#写入全部8列数据
	#删除全部参数
	rm(qualityCutoff);
	rm(region5Len);
	rm(region3Len);
	rm(nCutoff);
	rm(max.mismatchs);
	rm(trimmedFile);	
	rm(lineofresult);
	print(paste("Finished processing file:", fastqfile));#屏幕输出,该文件处理完毕
	#gc();
}
removePatterns <- function(fastqfile, outfile, patterns, RdPerYield)
{
    #这步实际上去除adapter的self-ligation等污染
	inFh <- FastqStreamer(fastqfile, n=RdPerYield); 
	if (file.exists(outfile) ) {file.remove(outfile);} #如果输出文件已经存在必须删除，防止追加写
	cleaned_reads=0;
	cleaned_len=0;
	while (length(reads <- yield(inFh))) { #每次控制读入5百万个reads
		for(i in 1:dim(patterns)[1])#每个pattern都要在所有reads中搜索一遍,因此需要严格控制pattern数量
		{
			currentPattern=as.character(unlist(patterns))[i];#先转成字符串向量,再提取本次循环需要处理的字符串
			max.mismatchs <- as.integer(nchar(currentPattern)*0.1);#先得到字符数量,再得到错配总量,允许出错率为10%,这种模式比较严格
			result <- vcountPattern(currentPattern, sread(reads), max.mismatch= max.mismatchs, min.mismatch=0, with.indels=TRUE);#result是一个向量,每个数表示pattern在对应read中match的次数
			reads <- reads[result==0];#当前pattern没有命中的read保留
		}
		cleaned_reads=cleaned_reads+length(reads);#累计cleaned reads的总数
		cleaned_len=cleaned_len+sum(width(reads));#累计cleaned reads的总长度	
		writeFastq(reads, file=outfile, mode="a", compress = FALSE, full=FALSE);#把pattern没有命中的read保存到sample.clean
	}#End yield while;
	close(inFh);
	cleaned_len=cleaned_len/cleaned_reads;#得到cleaned reads的平均长度
	lineofresult <- c(outfile,cleaned_reads,cleaned_len);#收集3列信息,样本文件名称、reads总数和reads平均长度
	write(lineofresult,file = "clean.report", ncolumns =3,append = T, sep = "\t");#写入3列数据
	print(paste("Finished processing file:", fastqfile));
	#gc();
}