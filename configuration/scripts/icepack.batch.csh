#!/bin/csh -f

if ( $1 != "" ) then
  echo "running icepack.batch.csh (creating ${1})"
else
  echo "running icepack.batch.csh"
endif

source ./icepack.settings
source ${ICE_CASEDIR}/env.${ICE_MACHCOMP} || exit 2

set jobfile = $1

set ntasks = ${ICE_NTASKS}
set nthrds = ${ICE_NTHRDS}
set maxtpn = ${ICE_MACHINE_TPNODE}
set acct   = ${ICE_ACCOUNT}

@ ncores = ${ntasks} * ${nthrds}
@ taskpernode = ${maxtpn} / $nthrds
@ nnodes = ${ntasks} / ${taskpernode}
if (${nnodes} * ${taskpernode} < ${ntasks}) @ nnodes = $nnodes + 1
set taskpernodelimit = ${taskpernode}
if (${taskpernodelimit} > ${ntasks}) set taskpernodelimit = ${ntasks}
@ corespernode = ${taskpernodelimit} * ${nthrds}

set ptile = $taskpernode
if ($ptile > ${maxtpn} / 2) @ ptile = ${maxtpn} / 2

set shortcase = `echo ${ICE_CASENAME} | cut -c1-15`

#==========================================

cat >! ${jobfile} << EOF0
#!/bin/csh -f 
EOF0

#==========================================

if (${ICE_MACHINE} =~ cheyenne*) then
cat >> ${jobfile} << EOFB
#PBS -j oe 
###PBS -m ae 
#PBS -V
#PBS -q ${ICE_MACHINE_QUEUE}
#PBS -N ${ICE_CASENAME}
#PBS -A ${acct}
#PBS -l select=${nnodes}:ncpus=${corespernode}:mpiprocs=${taskpernodelimit}:ompthreads=${nthrds}
#PBS -l walltime=${ICE_RUNLENGTH}
EOFB

else if (${ICE_MACHINE} =~ derecho*) then
cat >> ${jobfile} << EOFB
#PBS -q ${ICE_MACHINE_QUEUE}
#PBS -l job_priority=regular
#PBS -N ${ICE_CASENAME}
#PBS -A ${acct}
#PBS -l select=${nnodes}:ncpus=${corespernode}:mpiprocs=${taskpernodelimit}:ompthreads=${nthrds}:mem=5GB
#PBS -l walltime=${ICE_RUNLENGTH}
#PBS -j oe
#PBS -W umask=022
#PBS -o ${ICE_CASEDIR}
###PBS -M username@domain.com
###PBS -m be
EOFB

else if (${ICE_MACHINE} =~ gadi*) then
if (${ICE_MACHINE_QUEUE} =~ *sr) then #sapphire rapids
  @ memuse = ( $ncores * 481 / 100 )
else if (${ICE_MACHINE_QUEUE} =~ *bw) then #broadwell
  @ memuse = ( $ncores * 457 / 100 )
else if (${ICE_MACHINE_QUEUE} =~ *sl) then 
  @ memuse = ( $ncores * 6 )
else #normal queues
  @ memuse = ( $ncores * 395 / 100 )
endif
cat >> ${jobfile} << EOFB
#PBS -q ${ICE_MACHINE_QUEUE}
#PBS -P ${ICE_MACHINE_PROJ}
#PBS -N ${ICE_CASENAME}
#PBS -l storage=gdata/${ICE_MACHINE_PROJ}+scratch/${ICE_MACHINE_PROJ}+gdata/ik11
#PBS -l ncpus=${ncores}
#PBS -l mem=${memuse}gb
#PBS -l walltime=${ICE_RUNLENGTH}
#PBS -j oe 
#PBS -W umask=003
#PBS -o ${ICE_CASEDIR}
source /etc/profile.d/modules.csh
module use `echo ${MODULEPATH} | sed 's/:/ /g'` #copy the users modules
EOFB

else if (${ICE_MACHINE} =~ casper*) then
cat >> ${jobfile} << EOFB
#PBS -q ${ICE_MACHINE_QUEUE}
#PBS -l job_priority=regular
#PBS -N ${ICE_CASENAME}
#PBS -A ${acct}
#PBS -l select=${nnodes}:ncpus=${corespernode}:mpiprocs=${taskpernodelimit}:ompthreads=${nthrds}
#PBS -l walltime=${ICE_RUNLENGTH}
#PBS -j oe
#PBS -W umask=022
#PBS -o ${ICE_CASEDIR}
###PBS -M username@domain.com
###PBS -m be
EOFB

else if (${ICE_MACHINE} =~ hobart*) then
cat >> ${jobfile} << EOFB
#PBS -j oe 
###PBS -m ae 
#PBS -V
#PBS -q short
#PBS -N ${ICE_CASENAME}
#PBS -l nodes=1:ppn=24
EOFB

else if (${ICE_MACHINE} =~ izumi*) then
cat >> ${jobfile} << EOFB
#PBS -j oe 
###PBS -m ae 
#PBS -V
#PBS -q ${ICE_MACHINE_QUEUE}
#PBS -N ${ICE_CASENAME}
#PBS -l nodes=1:ppn=48
###PBS -l walltime=${ICE_RUNLENGTH}
### Give izumi a little more time for tests.
#PBS -l walltime=00:50:00
EOFB

else if (${ICE_MACHINE} =~ gordon* || ${ICE_MACHINE} =~ conrad* || ${ICE_MACHINE} =~ gaffney* || ${ICE_MACHINE} =~ koehr*) then
cat >> ${jobfile} << EOFB
#PBS -N ${shortcase}
#PBS -q ${ICE_MACHINE_QUEUE}
#PBS -A ${acct}
#PBS -l select=${nnodes}:ncpus=${maxtpn}:mpiprocs=${taskpernode}
#PBS -l walltime=${ICE_RUNLENGTH}
#PBS -j oe
###PBS -M username@domain.com
###PBS -m be
EOFB

else if (${ICE_MACHINE} =~ onyx*) then
cat >> ${jobfile} << EOFB
#PBS -N ${ICE_CASENAME}
#PBS -q ${ICE_MACHINE_QUEUE}
#PBS -A ${acct}
#PBS -l select=${nnodes}:ncpus=${maxtpn}:mpiprocs=${taskpernode}
#PBS -l walltime=${ICE_RUNLENGTH}
#PBS -j oe
###PBS -M username@domain.com
###PBS -m be
EOFB

else if (${ICE_MACHINE} =~ cori*) then
@ nthrds2 = ${nthrds} * 2
cat >> ${jobfile} << EOFB
#SBATCH -J ${ICE_CASENAME}
#SBATCH -A ${acct}
#SBATCH --qos shared
#SBATCH --ntasks ${ncores}
#SBATCH --time ${ICE_RUNLENGTH}
#SBATCH --cpus-per-task ${nthrds2}
#SBATCH --constraint haswell
###SBATCH -e filename
###SBATCH -o filename
###SBATCH --mail-type FAIL
###SBATCH --mail-user username@domain.com
EOFB

else if (${ICE_MACHINE} =~ perlmutter*) then
@ nthrds2 = ${nthrds} * 2
cat >> ${jobfile} << EOFB
#SBATCH -J ${ICE_CASENAME}
#SBATCH -A ${acct}
#SBATCH --qos ${ICE_MACHINE_QUEUE}
#SBATCH --time ${ICE_RUNLENGTH}
#SBATCH --nodes ${nnodes}
#SBATCH --ntasks ${ncores}
#SBATCH --cpus-per-task ${nthrds2}
#SBATCH --constraint cpu
###SBATCH -e filename
###SBATCH -o filename
###SBATCH --mail-type FAIL
###SBATCH --mail-user username@domain.com
EOFB

else if (${ICE_MACHINE} =~ compy*) then
cat >> ${jobfile} << EOFB
#SBATCH -J ${ICE_CASENAME}
#SBATCH -A ${acct}
#SBATCH --qos ${ICE_MACHINE_QUEUE}
#SBATCH --time ${ICE_RUNLENGTH}
#SBATCH --nodes ${nnodes}
#SBATCH --ntasks ${ntasks}
#SBATCH --cpus-per-task ${nthrds}
###SBATCH -e filename
###SBATCH -o filename
###SBATCH --mail-type FAIL
###SBATCH --mail-user username@domain.com
EOFB

else if (${ICE_MACHINE} =~ chicoma*) then
cat >> ${jobfile} << EOFB
#SBATCH -J ${ICE_CASENAME}
#SBATCH -t ${ICE_RUNLENGTH}
#SBATCH -A ${acct}
#SBATCH -N ${nnodes}
#SBATCH -e slurm%j.err
#SBATCH -o slurm%j.out
###SBATCH --mail-type END,FAIL
###SBATCH --mail-user=eclare@lanl.gov
#SBATCH --qos=debug
##SBATCH --qos=standard
##SBATCH --qos=standby
EOFB

else if (${ICE_MACHINE} =~ discover*) then
cat >> ${jobfile} << EOFB
#SBATCH -J ${ICE_CASENAME}
#SBATCH -t ${ICE_RUNLENGTH}
#SBATCH -A ${acct}
#SBATCH -N ${nnodes}
#SBATCH -e slurm%j.err
#SBATCH -o slurm%j.out
###SBATCH --mail-type END,FAIL
###SBATCH --mail-user=eclare@lanl.gov
#SBATCH --qos=debug
EOFB

else if (${ICE_MACHINE} =~ daley* || ${ICE_MACHINE} =~ banting* ) then
cat >> ${jobfile} << EOFB
#PBS -N ${ICE_CASENAME}
#PBS -j oe
#PBS -l select=${nnodes}:ncpus=${corespernode}:mpiprocs=${taskpernodelimit}:ompthreads=${nthrds}
#PBS -l walltime=${ICE_RUNLENGTH}
#PBS -W umask=022
EOFB

else if (${ICE_MACHINE} =~ high_Sierra*) then
cat >> ${jobfile} << EOFB
# nothing to do
EOFB

else if (${ICE_MACHINE} =~ testmachine*) then
cat >> ${jobfile} << EOFB
# nothing to do
EOFB

else if (${ICE_MACHINE} =~ travisCI*) then
cat >> ${jobfile} << EOFB
# nothing to do
EOFB

else if (${ICE_MACHINE} =~ conda*) then
cat >> ${jobfile} << EOFB
# nothing to do
EOFB

else
  echo "${0} ERROR: ${ICE_MACHINE} unknown"
  exit -1
endif

exit 0
