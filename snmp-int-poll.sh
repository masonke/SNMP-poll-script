#!/bin/bash
#
# Polls the given device interface and pulls the In and Out octets (Bytes)
# The value pulled is in Bytes and is a cumulative counter
# Next, convert to bits (bps) and divide by the POLLRATE to create an Average bps
#
#1.3.6.1.2.1.31.1.1.1.1 = IF-MIB::ifName
#1.3.6.1.2.1.31.1.1.1.6 = IF-MIB::ifHCOutOctets Bytes
#1.3.6.1.2.1.31.1.1.1.10 = IF-MIB::ifHCInOctets Bytes
#1.3.6.1.2.1.31.1.1.1.15 = IF-MIB::ifHighSpeed  Int Speed in Megabits/s
# http://tools.cisco.com/Support/SNMP/do/BrowseOID.do?local=en&translate=Translate&objectInput=1.3.6.1.2.1.31.1.1.1

POLLRATE=10
OutputSelect=1
DEVICE=10.89.254.200
#CSTRING=y9ugiq7vEqOB
CSTRING=wPeZ6kiG42oZhg
# Set the IfIndex for the device here using "sh snmp mib ifmib ifindex eth 0/0"
IfIndex=1
# Grab these 4 variables
IfName=0
IfInOctets=0
IfOutOctets=0
IfHighSpeed=0
#Convert to bits and average over POLLRATE
AvgInbpsNew=0
AvgOutbpsNew=0
AvgInbps=0
AvgOutbps=0
AvgInbpsOld=0
AvgOutbpsOld=0
FirstRun=1


#Grab interface name, this does not change, so grab it once
IfName=$(snmpget -v2c -c $CSTRING $DEVICE 1.3.6.1.2.1.31.1.1.1.1.$IfIndex | awk '{print $4}' )

#echo Date,Time,InOctets,OutOctets,AvgInBPS,AvgOutBPS

## main polling loop
while [ "a" != "b" ]
do
        DAY=$(date +%F)
        TIME=$(date +%T)
        IfInOctets=$(snmpget -v2c -c $CSTRING $DEVICE 1.3.6.1.2.1.31.1.1.1.6.$IfIndex | awk '{print $4}')
        IfOutOctets=$(snmpget -v2c -c $CSTRING $DEVICE 1.3.6.1.2.1.31.1.1.1.10.$IfIndex  | awk '{print $4}')
        IfHighSpeed=$(snmpget -v2c -c $CSTRING $DEVICE 1.3.6.1.2.1.31.1.1.1.15.$IfIndex  | awk '{print $4}')

# Convert Octets to bits       
        AvgInbpsNew=$(($IfInOctets*8/$POLLRATE))
        AvgOutbpsNew=$(($IfOutOctets*8/$POLLRATE))

# Find the difference from the previous run through 
        let AvgInbps=$AvgInbpsNew-$AvgInbpsOld
        let AvgOutbps=$AvgOutbpsNew-$AvgOutbpsOld

# Make this run's values the previous run
        AvgInbpsOld=$AvgInbpsNew
        AvgOutbpsOld=$AvgOutbpsNew

# Check if this is the first run through the polling. If it is, do not print out the values to prevent a counter spike
    if [ $FirstRun == 0 ]
      then
        if [ $OutputSelect == 1 ] 
          then
# Key Value Pair for Sumo
            echo DAY:$DAY TIME:$TIME IfName:$IfName IfSpeed:$IfHighSpeed INOctets:$IfInOctets INOutOctets:$IfOutOctets AvgInbps:$AvgInbps AvgOutbps:$AvgOutbps
          else
# CSV output
           echo $DAY,$TIME,$IfName,$IfHighSpeed,$IfInOctets,$IfOutOctets,$AvgInbps,$AvgOutbps
        fi
      fi
      
# Now that a run has been completed, set FirtsRun to 0 so values are printed
    FirstRun=0
        sleep $POLLRATE

done

