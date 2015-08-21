#!/usr/bin/env perl

use strict;
use warnings;
use FindBin;
use Getopt::Long qw(:config no_ignore_case bundling); #ѧϰ
use List::Util qw (shuffle);
# �˳���Դ��trinity�������ԭ����������butterfly_commands.adj(ÿ��һ������)	
# һ���������һ��linux���̣����ע����������̺�������һ����˼
# ��Ҫ��һ����cmd_process_forker.pl��ͬ
my $usage = <<_EOUSAGE_;

#################################################################################
#  --cmds_file	a file containing a list of commands to execute, one cmd per line.  
#  --suffix	the suffiex name of the input data file, fastq or clean       
#  --CPU	Default: 4
#  --shuffle	randomly orders the commands before executing them.
###################################################################################

_EOUSAGE_
	;

#################
##   ȫ�ֱ���  ##
#################
my $cmds_file = "";
my $suffix = "fastq";
my $CPU = 4;
my $shuffle_flag = 0;

my $ENCOUNTERED_FAILURE = 0; #ȫ�ֱ������ӳ����м̳�
#################
## �����������##
#################
&GetOptions (
			 "cmds_file=s" => \$cmds_file,#��Ҫִ�е��������ڵ��ļ�
			 "suffix=s" => \$suffix,    #�����ļ��ĺ�׺��
			 "CPU=i" => \$CPU,    #�����CPU����
             "shuffle" => \$shuffle_flag,#Ĭ����Ҫshuffle
             );

unless ($cmds_file) {
	die $usage;
}

# ������־Ŀ¼����־�ļ�����cmd���н�������̼�ͨѶ���ļ���ȱ���ǣ�����û�û��дȨ�޵Ļ�����������
my $log_dir = "cmds_log.$$";
mkdir($log_dir) or die "Error, cannot mkdir $log_dir";

#################
##  ������ʼ ##
#################
main: {
    mkdir("fastqc_result");
	my %job_tracker;		# ��¼��Ҫ���ٵ���������
	my @failed_jobs;		# ��¼ʧ�ܵ�����
	my $num_running = 0;	
    my @unix_cmds;  #��������¼���е�������
	
    #���ļ������ж���������	
	open (my $fh, $cmds_file) or die "Error, cannot open file $cmds_file";      
	while (<$fh>) {
		chomp;
		my @cols = split(/\t/, $_);
		my $cmd="./FastQC/fastqc -o ./fastqc_result $cols[0].$suffix"; #��Ҫ���������cmd_process_forker.pl��ͬ
		push (@unix_cmds, $cmd);#��һ������洢��������
	}
	close $fh;
	
	#�������������˳��Ŀ���ǰ�����ʱ�䳤�ģ�������ǰ���Ͷ̵���������ں󣩾���һ��
    if ($shuffle_flag) {
        @unix_cmds = shuffle(@unix_cmds);
    }
	
    my $cmd_counter = 0;
    foreach my $cmd (@unix_cmds) {	# ����ִ����������
        $cmd_counter++;      
		$num_running++;	#��¼��ǰ�������е���������
        
		my $pid = fork();	#ÿ��һ��Ϊ�����������ӽ��̺͸����̳���pid��ȫһ���������븸�������ڵĿ�ִ�ж�����ȴ�����
		if ($pid) { #$pidֵ��0����ǰ�����Ǹ����̣����ȵ�����̬��������fork�ӽ���
			$job_tracker{$cmd_counter} = $cmd; #��¼���п�ʼ���еĽ���
		}
		else {#$pidֵΪ0����ǰ�������ӽ��̣����ȵ�����̬��������cmd���Ȼ���˳�������û��û��
			my $ret = &run_cmd($cmd_counter, $cmd);
			exit($ret);  #���ִ����һ������ʧ�ܣ����˳���ǰ����
		}
		
		if ($num_running >= $CPU) { #���ѷ������������cpu����,">"���Բ�Ҫ
			wait(); # ��ͣ��ǰ����ִ��
			my $num_finished = &collect_jobs(\%job_tracker, \@failed_jobs);   #ͳ��ͳ���Ѿ��ɹ���������ʧ�ܵĽ��̣�������%job_tracker
			$num_running -= $num_finished; # �������еĽ���������ȥ�Ѿ���ɵģ�����
           		
            #���⽩ʬ����(Zombie process)�����Ϊʲô��ôд������� 
            for (1..$num_finished-1) {
                wait();
            }
           
		}
	} # ����ִ�������������
	
	# �����ж�wait()�ķ���ֵ��ֱ��û���ӽ���
	while (wait() != -1) { };	#����Ҫ������wait() ����ֵΪ�ӽ���ID�����û���ӽ��̣�����-1��
								#����������ִ�н�������󼸸����̣�������ǡ�õ��ڻ���С�ڹ涨���̣����ӽ����ڴ˴��ȴ�����
	&collect_jobs(\%job_tracker, \@failed_jobs); #�����Ͻ��̽��л���	
	# ȫ������������ϣ�ɾ��log�ļ���
	`rm -rf $log_dir`;
	
	
	# �����ǽ������	
	my $num_failed_jobs = scalar @failed_jobs; #��¼ʧ�����������
	if (! $ENCOUNTERED_FAILURE) {#��������־����Ϊ0����ʾȫ���ɹ��������
		print "\nAll $cmd_counter jobs completed successfully! \n";
		exit(0);
	}
	else {# ��������־������Ϊ0
        unless ($num_failed_jobs == $ENCOUNTERED_FAILURE) {
            print "\n\nError, $ENCOUNTERED_FAILURE jobs failed, but only have recorded $num_failed_jobs ... very strange and unexplained.\n\n";
            # I haven't seen this in my testing, but it's clear that others have, and I haven't figured out why or how yet...  bhaas
        }
        
		#������ʧ�ܵ�����ȫ��д��һ���ļ����Ժ�ֻ��Ҫ����������Щ�����������������ȫ������
		my $failed_cmd_file = "failed_cmds.$$.txt";
		open (my $ofh, ">$failed_cmd_file") or die "Error, cannot write to $failed_cmd_file"; #���ջ����һ����Ϊfailed_cmds.$$.txt���ļ�������Ϊ����ʧ���˵�����
		@failed_jobs = sort {$a->{index}<=>$b->{index}} @failed_jobs;  #���䰴index����
        foreach my $failed_job (@failed_jobs) {
            print $ofh $failed_job->{cmd} . "\n";
        }      
		close $ofh;		
		print "\n\nSorry, $num_failed_jobs of $cmd_counter jobs failed.\n\n"
			. "Failed commands written to file: $failed_cmd_file\n\n";
		exit(1);
	}
}


#################
##  �ӳ���     ##
#################

sub run_cmd {
	my ($index, $cmd) = @_;
	print "\nRUNNING: $cmd\n";	
	my $ret = system($cmd);		
	if ($ret) {  #���㼴Ϊ����
		print STDERR "Error, command: $cmd died with ret $ret";
	}		
	open (my $log_fh, ">$log_dir/$index.ret") or die "Error, cannot write to log file for $index.ret"; #һ���ļ���¼һ�����̵����н��
	print $log_fh $ret; #�������ⲿ������'0'��'1'�������־�ļ�
	close $log_fh;
	return($ret); #���ظ������������
}


sub collect_jobs {
	my ($job_tracker_href, $failed_jobs_aref) = @_;
	my @job_indices = keys %$job_tracker_href;
	my $num_finished = 0;
	foreach my $index (@job_indices) {# ÿ�μ��һ�����̣�job��	
		my $log_file = "$log_dir/$index.ret";	# һ�����̵����н����Ӧһ���ļ�
		if (-s $log_file) { # ���log�����Ҵ�С��Ϊ��
			my $ret_val = `cat $log_file`; # �����ļ�����
			chomp $ret_val; # ȥ�����з�
			my $job = $job_tracker_href->{$index};
			if ($ret_val == 0) {	#�������Ϊ�ַ�'0'�����̳ɹ�����
				print "SUCCESS[$index]: $job\n";				
			}
			else {#���򣬽�������ʧ�ܣ�����Ҳ��������
				print "FAILED[$index]: $job\n";
				$ENCOUNTERED_FAILURE++;   # ��¼ʧ�ܽ����Ľ�������
                push (@$failed_jobs_aref, {index => $index,
                                           cmd => $job_tracker_href->{$index},
                      });
			}			
			unlink $log_file;
			$num_finished++; # ��¼�Ѿ���ɵ�����
            delete $job_tracker_href->{$index}; # һ����ɣ��Ͳ���track
		}
	}

	return($num_finished);
}

